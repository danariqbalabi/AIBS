from datetime import date
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Body, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.schemas.domain import FoodEventPatch, SymptomEventPatch
from app.services import history

router = APIRouter(prefix="/api/v1/events", tags=["history"])


@router.get("")
def timeline(
    start: date | None = None,
    end: date | None = None,
    kind: Literal["food", "symptom"] | None = None,
    cursor: str | None = Query(None, max_length=500),
    limit: int = Query(50, ge=1, le=100),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return history.list_events(db, user.id, start, end, kind, cursor, limit)


@router.get("/{event_id}")
def detail(event_id: UUID, user: User = Depends(get_user), db: Session = Depends(get_db)):
    kind, row = history.find(db, user.id, event_id)
    return history.view(db, kind, row)


@router.patch("/{event_id}")
def patch(
    event_id: UUID,
    payload: Annotated[FoodEventPatch | SymptomEventPatch, Body(discriminator="kind")],
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return history.patch(db, user.id, event_id, payload)


@router.delete("/{event_id}", status_code=204)
def delete(
    event_id: UUID,
    version: int = Query(ge=1),
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    history.remove(db, user.id, event_id, version)
    return Response(status_code=204)
