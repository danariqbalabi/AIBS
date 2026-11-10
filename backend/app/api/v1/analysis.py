from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.schemas.domain import JournalAnalysisInput, PhotoAnalysisInput
from app.services.analysis import run

router = APIRouter(prefix="/api/v1/analysis", tags=["analysis"])


@router.post("/photo")
def photo(
    payload: PhotoAnalysisInput,
    request: Request,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return run(
        db,
        user.id,
        payload,
        "photo_to_draft",
        request.app.state.settings,
        request.app.state.gemini,
        request.app.state.storage,
    )


@router.post("/journal")
def journal(
    payload: JournalAnalysisInput,
    request: Request,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return run(
        db,
        user.id,
        payload,
        "journal_to_draft",
        request.app.state.settings,
        request.app.state.gemini,
        request.app.state.storage,
    )
