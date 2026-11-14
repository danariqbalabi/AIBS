from app.schemas.domain import AssessmentAnswers

RULES_VERSION = "rome_v_c1_demo"


def evaluate(profile, raw_answers):
    answers = AssessmentAnswers.model_validate(raw_answers)
    result = {
        "rules_version": RULES_VERSION,
        "demo_only": True,
        "profile_version": profile.version,
        "pattern_status": "not_evaluated",
        "route": "logging_only",
        "reasons": [],
        "missing_fields": [],
        "allowed_actions": ["log", "consultation_summary"],
    }

    def route(value, reason, actions=None):
        result.update(route=value, reasons=[reason])
        if actions is not None:
            result["allowed_actions"] = actions
        return result

    if profile.age_band == "under_18":
        return route("out_of_scope", "AIBS demo ditujukan untuk usia 18+.", ["edit_profile"])
    if answers.severe_active == "yes" or (
        answers.bleeding == "yes" and answers.bleeding_active == "yes"
    ):
        return route(
            "help",
            "Ada jawaban yang memerlukan jalur bantuan pada aturan demo.",
            ["help", "consultation_summary"],
        )
    if any(
        getattr(answers, field) == "yes"
        for field in (
            "bleeding",
            "weight_loss",
            "anemia",
            "family_history",
        )
    ):
        return route("consultation", "Ada jawaban yang perlu dibawa untuk konsultasi.")

    missing = [
        field
        for field in (
            "severe_active",
            "bleeding",
            "weight_loss",
            "anemia",
            "family_history",
            "q1",
            "q4",
            "q5",
            "q6",
        )
        if getattr(answers, field) in (None, "unknown")
    ]
    if answers.q2_days in (None, "unknown") and answers.q2_band in (None, "unknown"):
        missing.append("q2_frequency")
    if answers.q3_months in (None, "unknown") and answers.q3_band in (None, "unknown"):
        missing.append("q3_duration")
    for field in ("age_band", "diagnosis_reported", "clinician_guidance"):
        if getattr(profile, field) in (None, "unknown"):
            missing.append(field)
    if missing:
        result.update(missing_fields=missing, pattern_status="incomplete")
        return route(
            "complete_answers",
            "Lengkapi jawaban yang belum diketahui.",
            ["complete_answers", "log", "consultation_summary"],
        )

    frequency_matches = (
        answers.q2_days >= 3
        if isinstance(answers.q2_days, int)
        else answers.q2_band in ("3_4", "5_plus")
    )
    duration_matches = (
        answers.q3_months >= 6
        if isinstance(answers.q3_months, int)
        else answers.q3_band in ("6_12", "over_12")
    )
    result["criteria"] = [
        answers.q1 == "yes",
        frequency_matches,
        duration_matches,
        sum(getattr(answers, field) == "yes" for field in ("q4", "q5", "q6")) >= 2,
    ]
    matches = all(result["criteria"])
    result["pattern_status"] = "matches_demo" if matches else "does_not_match_demo"
    if profile.diagnosis_reported == "yes" and profile.clinician_guidance == "yes":
        return route(
            "diet_support",
            "Pendampingan mengikuti diagnosis dan arahan yang kamu laporkan.",
            ["log", "edit_diet", "recommendations", "consultation_summary"],
        )
    return route("logging_only", "Catat makanan dan gejala untuk dibawa saat konsultasi.")
