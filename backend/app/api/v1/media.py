from uuid import UUID

from fastapi import APIRouter, Depends, File, Request, Response, UploadFile
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.models.entities import Media
from app.repositories.owned import owned
from app.services import media
from app.services.profiles import require_basic

router = APIRouter(prefix="/api/v1/media", tags=["media"])


@router.post("", status_code=201)
def upload(
    request: Request,
    file: UploadFile = File(),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    require_basic(db, user.id)
    data = file.file.read(media.MAX_INPUT + 1)
    return media.upload(db, user.id, data, request.app.state.storage)


@router.get("/{media_id}/access")
def access(
    media_id: UUID, request: Request, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    require_basic(db, user.id)
    row = owned(db, Media, media_id, user.id)
    media.require_unexpired(row)
    return {"url": request.app.state.storage.sign(row.path), "expires_in": 60}


@router.delete("/{media_id}", status_code=204)
def remove(
    media_id: UUID, request: Request, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    media.remove(db, user.id, media_id, request.app.state.storage)
    return Response(status_code=204)
