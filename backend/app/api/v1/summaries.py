from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.services import summaries

router = APIRouter(prefix="/api/v1", tags=["dashboard"])


@router.get("/dashboard")
def today(date: date | None = None, user: User = Depends(get_user), db: Session = Depends(get_db)):
    return summaries.dashboard(db, user.id, date)


@router.get("/summaries")
def summary(
    days: int = Query(7, ge=7, le=30, json_schema_extra={"enum": [7, 30]}),
    end: date | None = None,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return summaries.summary(db, user.id, days, end)


@router.get("/consultation-summary")
def consultation(
    days: int = Query(7, ge=7, le=30, json_schema_extra={"enum": [7, 30]}),
    end: date | None = None,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return summaries.consultation(db, user.id, days, end)
