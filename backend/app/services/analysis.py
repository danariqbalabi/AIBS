import time
from datetime import UTC, datetime

from sqlalchemy import func, select

from app.core.errors import ApiError
from app.integrations.gemini import PROMPT_VERSION
from app.models.entities import AiRun, Draft, Ingredient, Media, Profile
from app.repositories.owned import owned
from app.services.drafts import view
from app.services.profiles import require_basic
from app.services.records import payload_hash


def normalize(db, content, payload, feature):
    names = {}
    for ingredient in db.scalars(select(Ingredient)):
        for alias in [ingredient.name, *ingredient.aliases]:
            names.setdefault(alias.casefold(), set()).add(ingredient.id)
    for food in content.foods:
        food.ingredients_complete = False
        if feature == "photo_to_draft":
            food.consumed = payload.intent == "consumed"
            food.time = None
        elif food.time:
            food.time.confirmed = False
        for ingredient in food.ingredients:
            matches = names.get(ingredient.display_name.casefold(), set())
            ingredient.ingredient_id = next(iter(matches)) if len(matches) == 1 else None
            ingredient.certainty = "candidate" if ingredient.ingredient_id else "unknown"
    for symptom in content.symptoms:
        symptom.time.confirmed = False
    if feature == "photo_to_draft":
        content.symptoms = []
        if not content.foods:
            raise ApiError(
                502, "ai_invalid_output", "Makanan belum terlihat jelas. Isi manual dulu."
            )
        content.questions = sorted(
            set([*content.questions, "Konfirmasi saus, bumbu, porsi dan waktu."])
        )
        content.story = None
    else:
        content.story = payload.text
    return content


def run(db, owner, payload, feature, settings, provider, storage):
    # Serialize per-owner quota/consent/dispatch. Revocation that wins this lock prevents egress;
    # a provider request already in flight cannot be recalled. No cross-user serialization.
    profile = db.scalar(select(Profile).where(Profile.owner_id == owner).with_for_update())
    if profile is None:
        raise ApiError(404, "profile_missing", "Buat profil terlebih dahulu.")
    consent = require_basic(db, owner)
    if not consent.ai:
        raise ApiError(403, "ai_consent_required", "Bantuan AI dimatikan. Kamu bisa isi manual.")
    digest = payload_hash({"feature": feature, **payload.model_dump(mode="json")})
    previous = db.scalar(
        select(AiRun).where(AiRun.owner_id == owner, AiRun.request_id == payload.request_id)
    )
    if previous:
        if previous.payload_hash != digest:
            raise ApiError(
                409, "analysis_request_conflict", "ID analisis sudah dipakai untuk isi berbeda."
            )
        if previous.status == "completed":
            draft = owned(db, Draft, previous.draft_id, owner)
            return {"analysis_status": "needs_confirmation", "draft": view(draft)}
        raise ApiError(
            409,
            "analysis_already_attempted",
            "Analisis ini sudah dicoba. Isi manual atau mulai percobaan baru.",
        )
    start_of_day = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.scalar(
        select(func.count())
        .select_from(AiRun)
        .where(AiRun.owner_id == owner, AiRun.created_at >= start_of_day)
    )
    if count >= settings.ai_daily_limit:
        raise ApiError(429, "ai_daily_limit", "Batas AI hari ini tercapai. Kamu bisa isi manual.")
    image, media = None, None
    if feature == "photo_to_draft":
        media = owned(db, Media, payload.media_id, owner, lock=True)
        image = storage.download(media.path)
    attempt = AiRun(
        owner_id=owner,
        request_id=payload.request_id,
        feature=feature,
        payload_hash=digest,
        status="processing",
        model=settings.gemini_model or "unconfigured",
        prompt_version=PROMPT_VERSION,
    )
    db.add(attempt)
    db.flush()
    started = time.monotonic()
    try:
        content, usage = provider.generate(
            feature,
            reference_date=payload.reference_date,
            timezone=profile.timezone,
            text=payload.text if feature == "journal_to_draft" else None,
            image=image,
        )
        content = normalize(db, content, payload, feature)
    except ApiError:
        attempt.status = "failed"
        attempt.latency_ms = int((time.monotonic() - started) * 1000)
        db.commit()
        raise
    draft = Draft(
        owner_id=owner,
        source="photo" if media else "journal",
        intent=payload.intent if media else "journal",
        content=content.model_dump(mode="json"),
        profile_version=profile.version,
        media_id=media.id if media else None,
    )
    db.add(draft)
    db.flush()
    attempt.draft_id, attempt.status = draft.id, "completed"
    attempt.input_tokens = usage.get("input_tokens")
    attempt.output_tokens = usage.get("output_tokens")
    attempt.latency_ms = int((time.monotonic() - started) * 1000)
    db.commit()
    return {"analysis_status": "needs_confirmation", "draft": view(draft)}
