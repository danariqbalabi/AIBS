from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import ApiError


def owned(session: Session, model, object_id, owner_id, *, lock=False):
    statement = select(model).where(model.id == object_id, model.owner_id == owner_id)
    if lock:
        statement = statement.with_for_update()
    result = session.scalar(statement)
    if result is None:
        raise ApiError(404, "not_found", "Catatan tidak ditemukan.")
    return result
