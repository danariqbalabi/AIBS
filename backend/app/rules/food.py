from decimal import Decimal

from app.schemas.domain import DietProfile

RULES_VERSION = "food_constraints_demo_v1"


def check(profile, ingredients, complete, access, known_ids, *, directive_supported=False):
    diet = DietProfile.model_validate(profile.diet)
    reasons, missing = [], []
    if not complete:
        missing.append("Komposisi makanan belum lengkap.")
    totals = {}
    for item in ingredients:
        key = str(item.ingredient_id) if item.ingredient_id else None
        if item.certainty != "confirmed" or key not in known_ids:
            missing.append(f"Konfirmasi bahan: {item.display_name}.")
        if item.quantity is None:
            missing.append(f"Konfirmasi porsi: {item.display_name}.")
        else:
            totals[(key, item.unit)] = totals.get((key, item.unit), Decimal(0)) + item.quantity
        for ids, code, message in (
            (diet.allergies, "allergy_conflict", "Ada bahan yang tercatat sebagai alergimu."),
            (diet.avoided_ingredients, "directive_conflict", "Ada bahan dalam daftar hindari."),
            (diet.tolerances, "personal_tolerance", "Ada bahan yang kamu tandai kurang nyaman."),
        ):
            if item.ingredient_id in ids:
                reasons.append({"code": code, "ingredient_id": key, "message": message})
    for limit in diet.portion_limits:
        key = str(limit.ingredient_id)
        matching = [item for item in ingredients if str(item.ingredient_id) == key]
        if any(item.unit != limit.unit or item.quantity is None for item in matching):
            missing.append("Satuan atau jumlah belum cocok dengan batas porsi profil.")
        elif totals.get((key, limit.unit), Decimal(0)) > limit.quantity:
            reasons.append(
                {
                    "code": "portion_limit",
                    "ingredient_id": key,
                    "message": "Porsi melebihi batas yang kamu simpan.",
                }
            )
    if access["route"] != "diet_support":
        missing.append("Pendampingan diet belum tersedia pada akses profil ini.")
    if diet.directive == "none" or (
        not directive_supported and not diet.avoided_ingredients and not diet.portion_limits
    ):
        missing.append("Arahan diet belum dapat dinilai dari data bahan yang tersedia.")
    hard = any(reason["code"] in ("allergy_conflict", "directive_conflict") for reason in reasons)
    status = "bad" if hard else "unknown" if missing else "warn" if reasons else "ok"
    return {
        "status": status,
        "reasons": reasons,
        "missing_information": sorted(set(missing)),
        "profile_version": profile.version,
        "rules_version": RULES_VERSION,
        "scope": "synthetic_catalog_and_reported_constraints",
        "demo_only": True,
    }
