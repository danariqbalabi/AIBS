import io
import warnings
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from PIL import Image, ImageOps, UnidentifiedImageError
from sqlalchemy import select, update

from app.core.errors import ApiError
from app.models.entities import Draft, Media, Profile
from app.repositories.owned import owned
from app.services.profiles import profile_for, require_basic

MAX_INPUT = 5 * 1024 * 1024


def sanitize(data):
    if not data or len(data) > MAX_INPUT:
        raise ApiError(413, "image_too_large", "Gunakan foto maksimal 5 MB.")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(data)) as image:
                if image.format not in ("JPEG", "PNG") or image.width * image.height > 16000000:
                    raise ApiError(
                        422, "unsupported_image", "Gunakan foto JPEG/PNG maksimal 16 megapiksel."
                    )
                image.load()
                clean = ImageOps.exif_transpose(image).convert("RGB")
                output = io.BytesIO()
                clean.save(output, format="JPEG", quality=90)
                result = output.getvalue()
                if len(result) > 6 * 1024 * 1024:
                    raise ApiError(413, "image_too_large", "Perkecil ukuran fotomu.")
                return result
    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        SyntaxError,
        Image.DecompressionBombError,
        Image.DecompressionBombWarning,
    ) as exc:
        raise ApiError(422, "invalid_image", "File belum dapat dibaca sebagai foto.") from exc


def upload(db, owner, data, storage):
    consent = require_basic(db, owner)
    if not consent.ai:
        raise ApiError(403, "ai_consent_required", "Bantuan AI dimatikan. Kamu bisa isi manual.")
    profile = profile_for(db, owner)
    profile = db.scalar(select(Profile).where(Profile.id == profile.id).with_for_update())
    data = sanitize(data)
    media_id = uuid4()
    path = f"{owner}/{media_id}.jpg"
    storage.upload(path, data)
    row = Media(
        id=media_id,
        owner_id=owner,
        path=path,
        mime="image/jpeg",
        size=len(data),
        expires_at=None if profile.save_photos else datetime.now(UTC) + timedelta(hours=24),
    )
    db.add(row)
    try:
        db.commit()
    except Exception:
        db.rollback()
        storage.delete(path)
        raise
    return {"id": row.id, "mime": row.mime, "size": row.size, "private": True}


def require_unexpired(row):
    expires = row.expires_at
    if expires is not None and expires.replace(tzinfo=UTC) <= datetime.now(UTC):
        raise ApiError(410, "photo_expired", "Foto sementara sudah kedaluwarsa. Pilih foto lagi.")


def remove(db, owner, media_id, storage):
    require_basic(db, owner)
    row = owned(db, Media, media_id, owner, lock=True)
    storage.delete(row.path)
    # Drafts keep reviewed content, but cannot keep a dangling reference to deleted media.
    db.execute(
        update(Draft).where(Draft.owner_id == owner, Draft.media_id == row.id).values(media_id=None)
    )
    db.delete(row)
    db.commit()
