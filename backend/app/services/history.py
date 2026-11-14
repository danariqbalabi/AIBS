import base64
import json
from datetime import date, datetime
from uuid import UUID

from sqlalchemy import and_, delete, literal, or_, select, union_all

from app.core.errors import ApiError
from app.models.entities import EventLink, FoodEvent, SymptomEvent
from app.schemas.domain import EventTime, FoodCheckInput
from app.services.catalog import check_food
from app.services.profiles import profile_for, require_basic, versioned_update
from app.services.records import (
    event_fields,
    validate_existing_food_link,
    validate_food_precedes_symptom,
)


def find(db, owner, event_id):
    require_basic(db, owner)
    for kind, model in (("food", FoodEvent), ("symptom", SymptomEvent)):
        row = db.scalar(select(model).where(model.id == event_id, model.owner_id == owner))
        if row:
            return kind, row
    raise ApiError(404, "not_found", "Catatan tidak ditemukan.")


def view(db, kind, row):
    links = db.scalars(
        select(EventLink).where(
            EventLink.owner_id == row.owner_id,
            (EventLink.food_event_id == row.id)
            if kind == "food"
            else (EventLink.symptom_event_id == row.id),
        )
    ).all()
    return {
        "id": row.id,
        "kind": kind,
        "version": row.version,
        "batch_id": row.batch_id,
        "local_date": row.local_date,
        "payload": row.payload,
        "evaluation": row.evaluation if kind == "food" else None,
        "linked_event_ids": [
            link.symptom_event_id if kind == "food" else link.food_event_id for link in links
        ],
    }


def list_events(db, owner, start=None, end=None, kind=None, cursor=None, limit=50):
    require_basic(db, owner)
    if start and end and end < start:
        raise ApiError(422, "invalid_period", "Tanggal akhir harus setelah tanggal awal.")
    selects = []
    for event_kind, model in (("food", FoodEvent), ("symptom", SymptomEvent)):
        if kind and event_kind != kind:
            continue
        query = select(
            model.id, model.local_date, model.created_at, literal(event_kind).label("kind")
        )
        query = query.where(model.owner_id == owner)
        if start:
            query = query.where(model.local_date >= start)
        if end:
            query = query.where(model.local_date <= end)
        selects.append(query)
    timeline = union_all(*selects).subquery()
    query = select(timeline)
    if cursor:
        try:
            values = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
            day, stamp, event_id = (
                date.fromisoformat(values[0]),
                datetime.fromisoformat(values[1]),
                UUID(values[2]),
            )
        except (ValueError, TypeError, IndexError, KeyError) as exc:
            raise ApiError(422, "invalid_cursor", "Cursor riwayat tidak valid.") from exc
        query = query.where(
            or_(
                timeline.c.local_date < day,
                and_(timeline.c.local_date == day, timeline.c.created_at < stamp),
                and_(
                    timeline.c.local_date == day,
                    timeline.c.created_at == stamp,
                    timeline.c.id < event_id,
                ),
            )
        )
    rows = db.execute(
        query.order_by(
            timeline.c.local_date.desc(), timeline.c.created_at.desc(), timeline.c.id.desc()
        ).limit(limit + 1)
    ).all()
    items = [
        view(db, row.kind, db.get(FoodEvent if row.kind == "food" else SymptomEvent, row.id))
        for row in rows[:limit]
    ]
    next_cursor = None
    if len(rows) > limit:
        last = rows[limit - 1]
        next_cursor = (
            base64.urlsafe_b64encode(
                json.dumps(
                    [
                        last.local_date.isoformat(),
                        last.created_at.isoformat(),
                        str(last.id),
                    ]
                ).encode()
            )
            .decode()
            .rstrip("=")
        )
    return {
        "items": items,
        "next_cursor": next_cursor,
        "ordering": "local_date_desc_then_entry_time_desc",
    }


def patch(db, owner, event_id, payload):
    kind, row = find(db, owner, event_id)
    if kind != payload.kind:
        raise ApiError(422, "event_kind_mismatch", "Jenis catatan tidak dapat diubah.")
    card = payload.payload
    if card.time is None or not card.time.confirmed or (kind == "food" and not card.consumed):
        raise ApiError(422, "confirmation_required", "Konfirmasi isi dan waktu catatan.")
    if (
        kind == "symptom"
        and card.linked_food_index is not None
        and card.linked_food_index != row.payload.get("linked_food_index")
    ):
        raise ApiError(
            422, "link_change_unsupported", "Tautan batch tidak dapat diubah lewat edit ini."
        )
    profile = profile_for(db, owner)
    linked_food = (
        validate_existing_food_link(db, owner, card, profile) if kind == "symptom" else None
    )
    if kind == "symptom" and card.linked_food_index is not None:
        for food in db.scalars(
            select(FoodEvent)
            .join(EventLink, EventLink.food_event_id == FoodEvent.id)
            .where(EventLink.owner_id == owner, EventLink.symptom_event_id == row.id)
        ):
            validate_food_precedes_symptom(
                EventTime.model_validate(food.payload["time"]), card.time, profile.timezone
            )
    changes = event_fields(card, profile)
    if kind == "food":
        linked_symptoms = db.scalars(
            select(SymptomEvent)
            .join(EventLink, EventLink.symptom_event_id == SymptomEvent.id)
            .where(EventLink.owner_id == owner, EventLink.food_event_id == row.id)
        )
        for symptom in linked_symptoms:
            validate_food_precedes_symptom(
                card.time, EventTime.model_validate(symptom.payload["time"]), profile.timezone
            )
        changes["evaluation"] = check_food(
            db,
            owner,
            FoodCheckInput(
                profile_version=profile.version,
                ingredients=card.ingredients,
                ingredients_complete=card.ingredients_complete,
            ),
        )
        changes["evaluation"]["profile_snapshot"] = {
            "version": profile.version,
            "diet": profile.diet,
        }
    versioned_update(db, row, payload.version, changes)
    if kind == "symptom" and card.linked_food_index is None:
        db.execute(
            delete(EventLink).where(
                EventLink.owner_id == owner, EventLink.symptom_event_id == row.id
            )
        )
        if linked_food is not None:
            db.add(EventLink(owner_id=owner, food_event_id=linked_food.id, symptom_event_id=row.id))
    db.commit()
    return view(db, kind, row)


def remove(db, owner, event_id, version):
    _, row = find(db, owner, event_id)
    model = type(row)
    result = db.execute(
        delete(model).where(model.id == event_id, model.owner_id == owner, model.version == version)
    )
    if result.rowcount != 1:
        raise ApiError(409, "version_conflict", "Catatan berubah. Muat ulang sebelum menghapus.")
    db.commit()
