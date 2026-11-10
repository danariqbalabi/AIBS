from collections import Counter
from datetime import UTC, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select

from app.core.errors import ApiError
from app.models.entities import EventLink, FoodEvent, Ingredient, MealPlan, SymptomEvent
from app.schemas.domain import FoodCheckInput
from app.services.assessment import access_for
from app.services.catalog import check_food, list_menus
from app.services.history import view
from app.services.planning import plan_view
from app.services.profiles import profile_for, require_basic


def event_day(event, timezone):
    value = event.payload["time"]
    if value.get("occurred_at"):
        return datetime.fromisoformat(value["occurred_at"]).astimezone(ZoneInfo(timezone)).date()
    return event.local_date


def in_period(db, owner, start, end, timezone):
    events = []
    # Exact events can move at most two calendar days if the profile timezone changes.
    for kind, model in (("food", FoodEvent), ("symptom", SymptomEvent)):
        rows = db.scalars(
            select(model).where(
                model.owner_id == owner,
                model.local_date >= start - timedelta(days=2),
                model.local_date <= end + timedelta(days=2),
            )
        ).all()
        events.extend(
            (kind, row, event_day(row, timezone))
            for row in rows
            if start <= event_day(row, timezone) <= end
        )
    return events


def summary(db, owner, days, end=None):
    if days not in (7, 30):
        raise ApiError(422, "invalid_period", "Pilih ringkasan 7 atau 30 hari.")
    require_basic(db, owner)
    profile = profile_for(db, owner)
    end = end or datetime.now(ZoneInfo(profile.timezone)).date()
    start = end - timedelta(days=days - 1)
    events = in_period(db, owner, start, end, profile.timezone)
    foods = [event for kind, event, _ in events if kind == "food"]
    symptoms = [
        event for kind, event, _ in events if kind == "symptom" and event.payload["present"]
    ]
    coverage = {day for _, _, day in events}
    symptoms_by_day = Counter(
        day for kind, row, day in events if kind == "symptom" and row.payload["present"]
    )
    food_ids, symptom_ids = {row.id for row in foods}, {row.id for row in symptoms}
    links = db.scalars(select(EventLink).where(EventLink.owner_id == owner)).all()
    return {
        "start": start,
        "end": end,
        "timezone": profile.timezone,
        "days": days,
        "status": "insufficient_data" if len(coverage) < 7 else "descriptive_only",
        "coverage_target_days": 7,
        "logged_days": len(coverage),
        "food_count": len(foods),
        "symptom_count": len(symptoms),
        "negated_observation_count": sum(
            kind == "symptom" and not row.payload["present"] for kind, row, _ in events
        ),
        "unknown_composition_count": sum(
            not row.payload.get("ingredients_complete", False) for row in foods
        ),
        "approximate_time_count": sum(
            row.payload["time"]["precision"] == "approximate" for _, row, _ in events
        ),
        "symptom_types": dict(Counter(row.payload["code"] for row in symptoms)),
        "daily": [
            {
                "date": start + timedelta(days=index),
                "recorded": start + timedelta(days=index) in coverage,
                "symptom_count": symptoms_by_day[start + timedelta(days=index)],
            }
            for index in range(days)
        ],
        "evidence": {
            "food_event_ids": sorted(map(str, food_ids)),
            "symptom_event_ids": sorted(map(str, symptom_ids)),
            "links": [
                {
                    "food_event_id": str(link.food_event_id),
                    "symptom_event_id": str(link.symptom_event_id),
                }
                for link in links
                if link.food_event_id in food_ids and link.symptom_event_id in symptom_ids
            ],
        },
        "limitations": [
            "Belum tentu penyebab.",
            "Hari tanpa catatan bukan berarti tanpa gejala.",
            "Ambang kelengkapan hanya untuk demo; bukan validitas medis.",
        ],
        "demo_only": True,
    }


def dashboard(db, owner, day=None):
    require_basic(db, owner)
    profile, access = profile_for(db, owner), access_for(db, owner)
    timezone = ZoneInfo(profile.timezone)
    day = day or datetime.now(timezone).date()
    start = datetime.combine(day, time.min, timezone).astimezone(UTC)
    end = datetime.combine(day + timedelta(days=1), time.min, timezone).astimezone(UTC)
    plans = db.scalars(
        select(MealPlan)
        .where(
            MealPlan.owner_id == owner, MealPlan.scheduled_at >= start, MealPlan.scheduled_at < end
        )
        .order_by(MealPlan.scheduled_at)
    ).all()
    planned = []
    for row in plans:
        item = plan_view(row)
        item["current_evaluation"] = check_food(
            db,
            owner,
            FoodCheckInput(
                profile_version=profile.version,
                ingredients=row.snapshot["ingredients"],
                ingredients_complete=True,
            ),
        )
        planned.append(item)
    events = in_period(db, owner, day, day, profile.timezone)
    cards = [view(db, kind, row) for kind, row, _ in sorted(events, key=lambda e: str(e[1].id))]
    recommendations = (
        list_menus(db, owner, recommendations=True)["items"][:3]
        if access["route"] == "diet_support"
        else []
    )
    return {
        "date": day,
        "timezone": profile.timezone,
        "display_name": profile.display_name,
        "mode": "diet_support" if access["route"] == "diet_support" else "logging_only",
        "access": access,
        "profile_version": profile.version,
        "plans": planned,
        "events": cards,
        "empty": not cards and not planned,
        "recommendations": recommendations,
        "week": summary(db, owner, 7, day),
    }


def consultation(db, owner, days, end=None):
    result = summary(db, owner, days, end)
    profile = profile_for(db, owner)
    names = {str(row.id): row.name for row in db.scalars(select(Ingredient))}
    allergies = profile.diet.get("allergies", [])
    result["profile"] = {
        "directive": profile.diet.get("directive", "none"),
        "allergies": [names.get(str(key), "Bahan belum dikenal") for key in allergies],
    }
    events = in_period(db, owner, result["start"], result["end"], profile.timezone)
    result["records"] = [view(db, kind, row) for kind, row, _ in events]
    result["questions"] = ["Bagaimana catatan ini dapat membantu meninjau arahan makan saya?"]
    return result
