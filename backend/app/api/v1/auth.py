from typing import Literal

from fastapi import APIRouter, Depends, Request
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.core.errors import ApiError
from app.schemas.domain import Contract
from app.services.demo import TEMPLATES, bootstrap_demo

router = APIRouter(prefix="/api/v1", tags=["sessions"])


class DemoInput(Contract):
    template: Literal["nadia", "raka"]


@router.get("/me/session")
def session_info(user: User = Depends(get_user)):
    return {"subject": user.id, "anonymous": user.anonymous}


@router.get("/demo/profiles")
def demo_profiles():
    return {
        "items": [{"id": key, **value} for key, value in TEMPLATES.items()],
        "next_cursor": None,
    }


@router.post("/demo/sessions")
def demo_session(
    payload: DemoInput,
    request: Request,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    # Per-user fixed limit prevents repeated demo initialization. Supabase signup rate limits
    # must also be enabled; multi-worker/network limits belong at the hosting gateway.
    hits = request.app.state.demo_attempts
    if hits.get(user.id, 0) >= 10:
        raise ApiError(429, "rate_limited", "Terlalu banyak percobaan demo.", retryable=True)
    hits[user.id] = hits.get(user.id, 0) + 1
    try:
        return bootstrap_demo(db, user, payload.template)
    except IntegrityError as exc:
        db.rollback()
        raise ApiError(409, "demo_initialization_conflict", "Muat ulang profil demo.") from exc
