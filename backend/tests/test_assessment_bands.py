from types import SimpleNamespace

import pytest
from pydantic import ValidationError

from app.rules.assessment import evaluate
from app.schemas.domain import AssessmentAnswers


@pytest.mark.parametrize(
    "band,matches", [("under_3", False), ("3_5", False), ("6_12", True), ("over_12", True)]
)
def test_duration_bucket_preserves_threshold_without_inventing_months(band, matches):
    profile = SimpleNamespace(
        version=1, age_band="18_29", diagnosis_reported="yes", clinician_guidance="yes"
    )
    answers = dict(
        severe_active="no",
        bleeding="no",
        weight_loss="no",
        anemia="no",
        family_history="no",
        q1="yes",
        q2_band="3_4",
        q3_band=band,
        q4="yes",
        q5="yes",
        q6="no",
    )
    result = evaluate(profile, answers)
    assert result["criteria"] == [True, True, matches, True]
    assert (result["pattern_status"] == "matches_demo") is matches
    assert AssessmentAnswers.model_validate(answers).q3_months is None


def test_duration_must_have_only_one_representation():
    with pytest.raises(ValidationError):
        AssessmentAnswers(q3_months=8, q3_band="6_12")
