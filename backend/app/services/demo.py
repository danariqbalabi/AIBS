from datetime import UTC, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select

from app.core.errors import ApiError
from app.models.entities import (
    Assessment,
    Consent,
    Draft,
    EventLink,
    FoodEvent,
    Profile,
    RecordBatch,
    SymptomEvent,
)
from app.schemas.domain import DietProfile, FoodCard, FoodCheckInput, SymptomCard
from app.services.catalog import check_food
from app.services.records import event_fields
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
    "manda": {
        "name": "Manda",
        "age": 23,
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
        phase="elimination" if data["directive"] == "low_fodmap" else "unknown",
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
    session.flush()
    if template == "manda":
        seed_manda_history(session, profile)
    session.commit()
    return {"profile_id": profile.id, "template": template, "isolated": True}


def seed_manda_history(session, profile):
    """Seed once in the same transaction as the new isolated demo profile."""
    zone = ZoneInfo(profile.timezone)
    now = datetime.now(zone)
    note = "Data demo sintetis Manda; bukan riwayat pasien atau bukti penyebab."

    def timestamp(day, hour, minutes_ago):
        value = (
            (
                datetime.combine(day, time.min, zone)
                + (now - datetime.combine(day, time.min, zone))
                * {30: 0.25, 20: 0.5, 10: 0.75}[minutes_ago]
            )
            if day == now.date()
            else datetime.combine(day, time(hour), zone)
        )
        return {
            "date": value.date().isoformat(),
            "precision": "exact",
            "occurred_at": value.isoformat(),
            "confirmed": True,
        }

    def ingredient(key, name, quantity, unit):
        return {
            "ingredient_id": str(stable_id(key)),
            "display_name": name,
            "quantity": quantity,
            "unit": unit,
            "certainty": "confirmed",
        }

    for offset in range(13, -1, -1):
        day = now.date() - timedelta(days=offset)
        with_onion = offset % 3 == 0
        foods = [
            FoodCard.model_validate(
                {
                    "name": "Nasi telur",
                    "consumed": True,
                    "time": timestamp(day, 8, 30),
                    "notes": note,
                    "ingredients_complete": True,
                    "ingredients": [
                        ingredient("rice", "Nasi putih", 1, "porsi"),
                        ingredient("egg", "Telur", 1, "butir"),
                    ],
                }
            ),
            FoodCard.model_validate(
                {
                    "name": "Ayam bawang" if with_onion else "Ayam jahe",
                    "consumed": True,
                    "time": timestamp(day, 12, 20),
                    "notes": note,
                    "ingredients_complete": True,
                    "ingredients": [
                        ingredient("chicken", "Ayam", 100, "g"),
                        ingredient(
                            "onion" if with_onion else "ginger",
                            "Bawang bombay" if with_onion else "Jahe",
                            10,
                            "g",
                        ),
                    ],
                }
            ),
        ]
        symptom = SymptomCard.model_validate(
            {
                "code": "bloating" if with_onion else ("gas" if offset % 2 else "pain"),
                "present": True,
                "severity": 3 if with_onion else 1,
                "time": timestamp(day, 15, 10),
                "linked_food_index": 1,
                "notes": note,
                "stress": "medium" if with_onion else "low",
            }
        )
        draft = Draft(
            owner_id=profile.owner_id,
            source="manual",
            intent="journal",
            status="saved",
            profile_version=profile.version,
            content={
                "foods": [f.model_dump(mode="json") for f in foods],
                "symptoms": [symptom.model_dump(mode="json")],
            },
        )
        session.add(draft)
        session.flush()
        batch = RecordBatch(owner_id=profile.owner_id, draft_id=draft.id)
        session.add(batch)
        session.flush()
        events = []
        for card in foods:
            evaluation = check_food(
                session,
                profile.owner_id,
                FoodCheckInput(
                    profile_version=profile.version,
                    ingredients=card.ingredients,
                    ingredients_complete=card.ingredients_complete,
                ),
            )
            evaluation["profile_snapshot"] = {"version": profile.version, "diet": profile.diet}
            created = card.time.occurred_at.astimezone(UTC)
            event = FoodEvent(
                owner_id=profile.owner_id,
                batch_id=batch.id,
                evaluation=evaluation,
                created_at=created,
                **event_fields(card, profile),
            )
            session.add(event)
            events.append(event)
        symptom_event = SymptomEvent(
            owner_id=profile.owner_id, batch_id=batch.id, **event_fields(symptom, profile)
        )
        session.add(symptom_event)
        session.flush()
        session.add(
            EventLink(
                owner_id=profile.owner_id,
                food_event_id=events[1].id,
                symptom_event_id=symptom_event.id,
            )
        )
