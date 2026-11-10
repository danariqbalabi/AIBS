import hashlib
import json
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.core.errors import ApiError
from app.models.entities import (
    EventLink,
    FoodEvent,
    IdempotencyRequest,
    Profile,
    RecordBatch,
    SymptomEvent,
)
from app.schemas.domain import DraftContent, FoodCheckInput
from app.services.catalog import check_food
from app.services.drafts import get_draft
from app.services.profiles import require_basic, versioned_update


def payload_hash(payload):
    return hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def replay(db, owner, key, digest):
    request = db.scalar(
        select(IdempotencyRequest).where(
            IdempotencyRequest.owner_id == owner,
            IdempotencyRequest.operation == "commit_draft",
            IdempotencyRequest.key == key,
        )
    )
    if request is None:
        return None
    if request.payload_hash != digest:
        raise ApiError(
            409, "idempotency_conflict", "ID permintaan sudah dipakai untuk isi berbeda."
        )
    if request.response is None:
        raise ApiError(409, "request_in_progress", "Penyimpanan masih berlangsung.", retryable=True)
    return request.response


def event_fields(card, profile):
    event_time = card.time
    local_date = (
        event_time.occurred_at.astimezone(ZoneInfo(profile.timezone)).date()
        if event_time.occurred_at
        else event_time.date
    )
    return {
        "payload": card.model_dump(mode="json"),
        "local_date": local_date,
        "occurred_at": event_time.occurred_at,
    }


def commit(db, owner, draft_id, payload, key):
    require_basic(db, owner)
    digest = payload_hash({"draft_id": str(draft_id), **payload.model_dump(mode="json")})
    previous = replay(db, owner, key, digest)
    if previous is not None:
        return previous
    request = IdempotencyRequest(
        owner_id=owner, operation="commit_draft", key=key, payload_hash=digest
    )
    db.add(request)
    try:
        # The unique key reservation and all event writes share one transaction.
        # Concurrent same-key inserts wait on PostgreSQL until the first transaction finishes.
        db.flush()
    except IntegrityError as exc:
        db.rollback()
        previous = replay(db, owner, key, digest)
        if previous is not None:
            return previous
        raise ApiError(
            409, "save_conflict", "Muat ulang lalu coba simpan lagi.", retryable=True
        ) from exc

    profile = db.scalar(select(Profile).where(Profile.owner_id == owner).with_for_update())
    if profile is None:
        raise ApiError(404, "profile_missing", "Buat profil terlebih dahulu.")
    row = get_draft(db, owner, draft_id, lock=True)
    if row.status != "draft":
        raise ApiError(409, "draft_already_saved", "Draft sudah diproses.")
    if row.profile_version != profile.version:
        raise ApiError(409, "profile_changed", "Profil berubah. Tinjau dan cek kembali draft.")
    if row.version != payload.version:
        raise ApiError(409, "version_conflict", "Draft berubah. Muat ulang sebelum menyimpan.")
    content = DraftContent.model_validate(row.content)
    if not content.foods and not content.symptoms:
        raise ApiError(422, "empty_draft", "Tambahkan makanan atau gejala terlebih dahulu.")
    if content.foods and (
        row.intent == "before_meal" or any(not food.consumed for food in content.foods)
    ):
        raise ApiError(
            422, "consumption_unconfirmed", "Konfirmasi sudah dimakan sebelum mencatat konsumsi."
        )
    if any(
        card.time is None or not card.time.confirmed for card in [*content.foods, *content.symptoms]
    ):
        raise ApiError(
            422, "time_unconfirmed", "Tinjau waktu makanan dan gejala sebelum menyimpan."
        )

    batch = RecordBatch(owner_id=owner, draft_id=row.id)
    db.add(batch)
    db.flush()
    foods, symptoms = [], []
    for food in content.foods:
        evaluation = check_food(
            db,
            owner,
            FoodCheckInput(
                profile_version=profile.version,
                ingredients=food.ingredients,
                ingredients_complete=food.ingredients_complete,
            ),
        )
        evaluation["profile_snapshot"] = {"version": profile.version, "diet": profile.diet}
        event = FoodEvent(
            owner_id=owner, batch_id=batch.id, evaluation=evaluation, **event_fields(food, profile)
        )
        db.add(event)
        db.flush()
        foods.append(event)
    for symptom in content.symptoms:
        event = SymptomEvent(owner_id=owner, batch_id=batch.id, **event_fields(symptom, profile))
        db.add(event)
        db.flush()
        symptoms.append(event)
        if symptom.linked_food_index is not None:
            db.add(
                EventLink(
                    owner_id=owner,
                    food_event_id=foods[symptom.linked_food_index].id,
                    symptom_event_id=event.id,
                )
            )
    versioned_update(db, row, row.version, {"status": "saved"})
    response = {
        "batch_id": str(batch.id),
        "draft_id": str(row.id),
        "persistence_status": "saved",
        "food_event_ids": [str(event.id) for event in foods],
        "symptom_event_ids": [str(event.id) for event in symptoms],
    }
    request.response = response
    db.commit()
    return response
