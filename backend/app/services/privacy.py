import json
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


def cleanup_expired(engine, storage):
    with Session(engine) as db:
        rows = db.scalars(
            select(Media)
            .where(Media.expires_at <= datetime.now(UTC))
            .limit(10)
            .with_for_update(skip_locked=True)
        ).all()
        for row in rows:
            detach_photo(db, row, storage)
        db.commit()


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
