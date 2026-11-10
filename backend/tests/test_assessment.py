from types import SimpleNamespace

import pytest

from app.rules.assessment import evaluate

ANSWERS = {
    "severe_active": "no",
    "bleeding": "no",
    "weight_loss": "no",
    "anemia": "no",
    "family_history": "no",
    "q1": "yes",
    "q2_days": 4,
    "q3_months": 8,
    "q4": "yes",
    "q5": "yes",
    "q6": "no",
}


def profile(**changes):
    return SimpleNamespace(
        **{
            "age_band": "18_29",
            "version": 1,
            "diagnosis_reported": "yes",
            "clinician_guidance": "yes",
            **changes,
        }
    )


@pytest.mark.parametrize(
    "changes,expected",
    [
        ({}, "matches_demo"),
        ({"q2_days": 2}, "does_not_match_demo"),
        ({"q3_months": 5}, "does_not_match_demo"),
        ({"q1": "no"}, "does_not_match_demo"),
        ({"q5": "no"}, "does_not_match_demo"),
        ({"q6": "unknown"}, "incomplete"),
        ({"q2_days": None, "q2_band": "3_4"}, "matches_demo"),
    ],
)
def test_demo_pattern_thresholds(changes, expected):
    assert evaluate(profile(), {**ANSWERS, **changes})["pattern_status"] == expected


def test_urgent_flag_and_age_scope_precede_pattern():
    assert evaluate(profile(), {**ANSWERS, "severe_active": "yes"})["route"] == "help"
    assert evaluate(profile(age_band="under_18"), ANSWERS)["route"] == "out_of_scope"
    assert evaluate(profile(), {**ANSWERS, "weight_loss": "yes"})["route"] == "consultation"


def test_pattern_does_not_grant_diet_without_reported_guidance():
    result = evaluate(profile(clinician_guidance="no"), ANSWERS)
    assert result["pattern_status"] == "matches_demo"
    assert result["route"] == "logging_only"
    assert "recommendations" not in result["allowed_actions"]


def test_evaluate_endpoint_persists_versioned_result(account):
    client, _ = account
    result = client.post("/api/v1/me/assessment/evaluate")
    assert result.status_code == 200
    assert result.json()["rules_version"] == "rome_v_c1_demo"
    assert result.json()["route"] == "complete_answers"
    assert client.get("/api/v1/me/assessment").json()["result"]["demo_only"] is True
