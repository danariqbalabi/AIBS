from datetime import UTC

from sqlalchemy import select

from app.core.errors import ApiError
from app.models.entities import Draft
from app.repositories.owned import owned
from app.services.profiles import profile_for, require_basic, versioned_update


def view(row):
    return {
        "id": row.id,
        "version": row.version,
        "source": row.source,
        "intent": row.intent,
        "persistence_status": row.status,
        "content": row.content,
        "profile_version": row.profile_version,
        "media_id": row.media_id,
        "created_at": row.created_at.replace(tzinfo=UTC)
        if row.created_at.tzinfo is None
        else row.created_at,
    }


def get_draft(db, owner, draft_id, *, lock=False):
    require_basic(db, owner)
    row = owned(db, Draft, draft_id, owner, lock=lock)
    if row.status == "discarded":
        raise ApiError(404, "not_found", "Draft tidak ditemukan.")
    return row


def create(db, owner, payload):
    require_basic(db, owner)
    profile = profile_for(db, owner)
    row = Draft(
        owner_id=owner,
        source="manual",
        intent=payload.intent,
        content=payload.content.model_dump(mode="json"),
        profile_version=profile.version,
    )
    db.add(row)
    db.commit()
    return view(row)


def list_drafts(db, owner, cursor=None, limit=50):
    require_basic(db, owner)
    statement = select(Draft).where(Draft.owner_id == owner, Draft.status == "draft")
    if cursor:
        statement = statement.where(Draft.id > cursor)
    rows = db.scalars(statement.order_by(Draft.id).limit(limit + 1)).all()
    return {
        "items": [view(row) for row in rows[:limit]],
        "next_cursor": str(rows[limit - 1].id) if len(rows) > limit else None,
    }


def patch(db, owner, draft_id, payload):
    row = get_draft(db, owner, draft_id)
    if row.status != "draft":
        raise ApiError(409, "draft_closed", "Catatan sudah tersimpan. Edit melalui riwayat.")
    versioned_update(
        db,
        row,
        payload.version,
        {
            "content": payload.content.model_dump(mode="json"),
            "intent": payload.intent,
            "profile_version": profile_for(db, owner).version,
        },
    )
    db.commit()
    return view(row)


def discard(db, owner, draft_id, version):
    row = get_draft(db, owner, draft_id)
    if row.status != "draft":
        raise ApiError(409, "draft_closed", "Catatan sudah tersimpan. Hapus melalui riwayat.")
    versioned_update(db, row, version, {"status": "discarded"})
    db.commit()
