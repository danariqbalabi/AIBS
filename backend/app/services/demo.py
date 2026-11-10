from sqlalchemy import select

from app.core.errors import ApiError
from app.models.entities import Assessment, Consent, Profile
from app.schemas.domain import DietProfile
from seeds.catalog import stable_id

TEMPLATES = {
    "nadia": {
        "name": "Nadia",
        "age": 21,
        "directive": "low_fodmap",
        "budget": 25000,
        "allergy": "shrimp",
        "avoid": ["garlic", "onion"],
    },
    "raka": {
        "name": "Raka",
        "age": 24,
        "directive": "low_fat",
        "budget": 35000,
        "allergy": "peanut",
        "avoid": ["coconut"],
    },
}


def bootstrap_demo(session, user, template):
    if not user.anonymous:
        raise ApiError(403, "demo_session_required", "Gunakan sesi demo terpisah.")
    existing = session.scalar(select(Profile).where(Profile.owner_id == user.id))
    if existing:
        if existing.demo_template != template:
            raise ApiError(
                409, "demo_already_initialized", "Buat sesi baru untuk profil demo lain."
            )
        return {"profile_id": existing.id, "template": template, "isolated": True}
    data = TEMPLATES[template]
    diet = DietProfile(
        directive=data["directive"],
        phase="elimination" if template == "nadia" else "unknown",
        allergies=[stable_id(data["allergy"])],
        avoided_ingredients=[stable_id(key) for key in data["avoid"]],
        budget_rupiah=data["budget"],
        preferences=["halal"],
    )
    profile = Profile(
        owner_id=user.id,
        display_name=data["name"],
        age_band="18_29",
        diagnosis_reported="yes",
        clinician_guidance="yes",
        diet=diet.model_dump(mode="json"),
        demo_template=template,
    )
    session.add(profile)
    # Initial demo consent is basic only. AI always requires a separate explicit opt-in.
    session.add(Consent(owner_id=user.id, basic=True, ai=False, policy_version="demo-v1"))
    session.add(
        Assessment(
            owner_id=user.id,
            answers={
                "severe_active": "no",
                "bleeding": "no",
                "bleeding_active": "no",
                "weight_loss": "no",
                "anemia": "no",
                "family_history": "no",
                "q1": "yes",
                "q2_days": 4,
                "q3_months": 8,
                "q4": "yes",
                "q5": "yes",
                "q6": "no",
            },
        )
    )
    session.commit()
    return {"profile_id": profile.id, "template": template, "isolated": True}
