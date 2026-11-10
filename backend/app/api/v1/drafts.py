from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.schemas.domain import DraftCreate, DraftPatch
from app.services import drafts

router = APIRouter(prefix="/api/v1/drafts", tags=["drafts"])


@router.post("", status_code=201)
def create(payload: DraftCreate, user: User = Depends(get_user), db: Session = Depends(get_db)):
    return drafts.create(db, user.id, payload)


@router.get("")
def list_drafts(
    cursor: UUID | None = None,
    limit: int = Query(50, ge=1, le=100),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return drafts.list_drafts(db, user.id, cursor, limit)


@router.get("/{draft_id}")
def detail(draft_id: UUID, user: User = Depends(get_user), db: Session = Depends(get_db)):
    return drafts.view(drafts.get_draft(db, user.id, draft_id))


@router.patch("/{draft_id}")
def patch(
    draft_id: UUID,
    payload: DraftPatch,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return drafts.patch(db, user.id, draft_id, payload)


@router.delete("/{draft_id}", status_code=204)
def discard(
    draft_id: UUID,
    version: int = Query(ge=1),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    drafts.discard(db, user.id, draft_id, version)
    return Response(status_code=204)
