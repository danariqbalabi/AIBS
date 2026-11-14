from pydantic import ValidationError
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from app.core.errors import ApiError
from app.models.entities import Assessment, Consent, Profile, now
from app.schemas.domain import AssessmentAnswers, DietProfile


def profile_for(db, owner):
    profile = db.scalar(select(Profile).where(Profile.owner_id == owner))
    if profile is None:
        raise ApiError(404, "profile_missing", "Buat profil terlebih dahulu.")
    return profile


def create_profile(db, owner):
    existing = db.scalar(select(Profile).where(Profile.owner_id == owner))
    if existing:
        return existing
    profile = Profile(owner_id=owner, diet=DietProfile().model_dump(mode="json"))
    db.add(profile)
    db.add(Assessment(owner_id=owner, answers={}))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        return profile_for(db, owner)
    return profile


def current_consent(db, owner):
    return db.scalar(
        select(Consent)
        .where(Consent.owner_id == owner)
        .order_by(Consent.created_at.desc(), Consent.id.desc())
        .limit(1)
    )


def require_basic(db, owner):
    consent = current_consent(db, owner)
    if consent is None or not consent.basic:
        raise ApiError(
            403, "basic_consent_required", "Tentukan izin penggunaan data terlebih dahulu."
        )
    return consent


def versioned_update(db, row, version, changes):
    model = type(row)
    result = db.execute(
        update(model)
        .where(
            model.id == row.id,
            model.owner_id == row.owner_id,
            model.version == version,
        )
        .values(**changes, version=version + 1, updated_at=now()),
        execution_options={"synchronize_session": False},
    )
    if result.rowcount != 1:
        raise ApiError(409, "version_conflict", "Data sudah berubah. Muat ulang sebelum menyimpan.")
    db.expire(row)
    db.flush()
    return row


def profile_response(row):
    return {
        "id": row.id,
        "version": row.version,
        "display_name": row.display_name,
        "age_band": row.age_band,
        "diagnosis_reported": row.diagnosis_reported,
        "clinician_guidance": row.clinician_guidance,
        "timezone": row.timezone,
        "diet": row.diet,
        "demo_template": row.demo_template,
        "save_photos": row.save_photos,
    }


def patch_profile(db, owner, payload, storage=None):
    require_basic(db, owner)
    profile = profile_for(db, owner)
    profile = db.scalar(select(Profile).where(Profile.id == profile.id).with_for_update())
    changes = payload.model_dump(mode="json", exclude_unset=True, exclude={"version"})
    for key in ("display_name", "timezone", "diet", "save_photos"):
        if key in changes and changes[key] is None:
            raise ApiError(422, "invalid_profile", "Nama, zona waktu dan diet tidak boleh null.")
    if profile.version != payload.version:
        raise ApiError(409, "version_conflict", "Profil berubah. Muat ulang sebelum menyimpan.")
    if changes.get("save_photos") is False and profile.save_photos:
        from app.services.privacy import remove_photos

        remove_photos(db, owner, storage)
    versioned_update(db, profile, payload.version, changes)
    db.commit()
    return profile_response(profile)


def assessment_for(db, owner):
    result = db.scalar(select(Assessment).where(Assessment.owner_id == owner))
    if result is None:
        raise ApiError(404, "assessment_missing", "Buat profil terlebih dahulu.")
    return result


def patch_assessment(db, owner, payload):
    require_basic(db, owner)
    assessment = assessment_for(db, owner)
    merged = {**assessment.answers, **payload.answers.model_dump(exclude_unset=True)}
    try:
        answers = AssessmentAnswers.model_validate(merged).model_dump(mode="json")
    except ValidationError as exc:
        raise ApiError(422, "invalid_assessment", "Periksa kembali jawaban pengecekan.") from exc
    versioned_update(db, assessment, payload.version, {"answers": answers, "result": {}})
    # Assessment affects the menu access gate as much as changes to the diet profile.
    profile = profile_for(db, owner)
    versioned_update(db, profile, profile.version, {})
    db.commit()
    return {
        "version": assessment.version,
        "answers": assessment.answers,
        "result": assessment.result,
    }
