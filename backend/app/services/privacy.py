import json
import time
from datetime import UTC, datetime
from tempfile import SpooledTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile

from fastapi.encoders import jsonable_encoder
from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from app.models import Base
from app.models.entities import Draft, Media, Profile


def detach_photo(db, row, storage):
    storage.delete(row.path)
    db.execute(
        update(Draft)
        .where(Draft.owner_id == row.owner_id, Draft.media_id == row.id)
        .values(media_id=None)
    )
    db.delete(row)


def remove_photos(db, owner, storage):
    for row in db.scalars(select(Media).where(Media.owner_id == owner).with_for_update()):
        detach_photo(db, row, storage)
    db.flush()


def cleanup_expired(engine, storage, *, owner=None, limit=100, budget_seconds=80):
    from app.core.errors import ApiError

    deadline = time.monotonic() + budget_seconds
    with Session(engine) as db:
        query = select(Media.id).where(Media.expires_at <= datetime.now(UTC))
        if owner is not None:
            query = query.where(Media.owner_id == owner)
        ids = db.scalars(query.order_by(Media.expires_at, Media.id).limit(limit)).all()
    deleted, failed = 0, 0
    for media_id in ids:
        if time.monotonic() >= deadline:
            break
        # Separate transactions let a failed storage object retry without blocking other rows.
        with Session(engine) as db:
            row = db.scalar(
                select(Media)
                .where(Media.id == media_id, Media.expires_at <= datetime.now(UTC))
                .with_for_update(skip_locked=True)
            )
            if row is None:
                continue
            try:
                detach_photo(db, row, storage)
                db.commit()
                deleted += 1
            except ApiError:
                db.rollback()
                failed += 1
    return {"deleted": deleted, "failed": failed, "batch_full": len(ids) == limit}


def export_data(db, owner, storage):
    data = {"format_version": 1, "exported_at": datetime.now(UTC).isoformat(), "tables": {}}
    for table in Base.metadata.sorted_tables:
        if "owner_id" in table.c:
            rows = db.execute(select(table).where(table.c.owner_id == owner)).mappings().all()
            data["tables"][table.name] = jsonable_encoder([dict(row) for row in rows])
    archive = SpooledTemporaryFile(max_size=8 * 1024 * 1024)
    try:
        with ZipFile(archive, "w", compression=ZIP_DEFLATED) as output:
            output.writestr("data.json", json.dumps(data, ensure_ascii=False, indent=2))
            for media in db.scalars(select(Media).where(Media.owner_id == owner)):
                output.writestr(f"photos/{media.id}.jpg", storage.download(media.path))
        archive.seek(0)
        return archive
    except Exception:
        archive.close()
        raise


def delete_data(db, owner, storage):
    # Delete objects first: a storage failure keeps metadata available for retry.
    db.scalar(select(Profile).where(Profile.owner_id == owner).with_for_update())
    remove_photos(db, owner, storage)
    for table in reversed(Base.metadata.sorted_tables):
        if "owner_id" in table.c:
            db.execute(delete(table).where(table.c.owner_id == owner))
    db.commit()
