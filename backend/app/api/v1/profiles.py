from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.auth import User, get_user
from app.core.database import get_db
from app.models.entities import Consent
from app.schemas.domain import AssessmentPatch, ConsentInput, ProfilePatch
from app.services import profiles

router = APIRouter(prefix="/api/v1/me", tags=["profile"])


@router.post("/profile")
def create(user: User = Depends(get_user), db: Session = Depends(get_db)):
    return profiles.profile_response(profiles.create_profile(db, user.id))


@router.get("/profile")
def get(user: User = Depends(get_user), db: Session = Depends(get_db)):
    return profiles.profile_response(profiles.profile_for(db, user.id))


@router.patch("/profile")
def patch(payload: ProfilePatch, user: User = Depends(get_user), db: Session = Depends(get_db)):
    return profiles.patch_profile(db, user.id, payload)


@router.get("/consents")
def get_consents(user: User = Depends(get_user), db: Session = Depends(get_db)):
    consent = profiles.current_consent(db, user.id)
    if consent is None:
        return {"basic": False, "ai": False, "policy_version": None}
    return {"basic": consent.basic, "ai": consent.ai, "policy_version": consent.policy_version}


@router.put("/consents")
def put_consents(
    payload: ConsentInput, user: User = Depends(get_user), db: Session = Depends(get_db)
):
    profile = profiles.create_profile(db, user.id)
    # Serialize consent changes and the later AI dispatch guard using this owned profile row.
    profiles.versioned_update(db, profile, profile.version, {})
    db.add(Consent(owner_id=user.id, **payload.model_dump()))
    db.commit()
    return payload


@router.get("/assessment")
def get_assessment(user: User = Depends(get_user), db: Session = Depends(get_db)):
    profiles.require_basic(db, user.id)
    result = profiles.assessment_for(db, user.id)
    return {"version": result.version, "answers": result.answers, "result": result.result}


@router.patch("/assessment")
def patch_assessment(
    payload: AssessmentPatch,
    user: User = Depends(get_user),
    db: Session = Depends(get_db),
):
    return profiles.patch_assessment(db, user.id, payload)
