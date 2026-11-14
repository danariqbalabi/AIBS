from types import SimpleNamespace

from app.rules.food import check
from app.schemas.domain import IngredientInput


def test_unmapped_restriction_is_retained_and_cannot_produce_a_positive_verdict():
    profile = SimpleNamespace(
        version=1, diet={"directive": "low_fat", "custom_allergies": ["Jamur khusus"]}
    )
    ingredients = [
        IngredientInput(display_name="Nasi", quantity=1, unit="porsi", certainty="confirmed")
    ]
    result = check(
        profile, ingredients, True, {"route": "diet_support"}, set(), directive_supported=True
    )
    assert result["status"] == "unknown"
    assert any("luar katalog" in text for text in result["missing_information"])
    ingredients[0].display_name = "  JAMUR  khusus "
    result = check(
        profile, ingredients, True, {"route": "diet_support"}, set(), directive_supported=True
    )
    assert result["status"] == "bad"
    assert result["reasons"][0]["code"] == "allergy_conflict"
