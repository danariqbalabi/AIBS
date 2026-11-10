import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.export_contracts import contracts
from app.schemas.domain import AssessmentAnswers, DraftContent, EventTime, IngredientInput


def test_generated_contracts_are_current():
    path = Path(__file__).resolve().parents[2] / "docs/api/contracts.json"
    assert json.loads(path.read_text(encoding="utf-8")) == contracts()


@pytest.mark.parametrize("fixture", ["photo-v1.json", "journal-v1.json"])
def test_frontend_fixture_matches_draft_contract(fixture):
    path = Path(__file__).resolve().parents[2] / "docs/fixtures/backend" / fixture
    DraftContent.model_validate_json(path.read_text(encoding="utf-8"))


def test_exact_time_requires_timezone_and_approximation_is_not_fabricated():
    with pytest.raises(ValidationError):
        EventTime(date="2026-11-10", precision="exact", occurred_at="2026-11-10T12:00:00")
    time = EventTime(date="2026-11-10", precision="approximate", period="midday")
    assert time.occurred_at is None


def test_unknown_frequency_is_not_no_and_range_is_not_exact():
    assert AssessmentAnswers(q2_days="unknown").q2_days == "unknown"
    assert AssessmentAnswers(q2_band="3_4").q2_days is None
    with pytest.raises(ValidationError):
        AssessmentAnswers(q2_days=3, q2_band="3_4")


def test_quantity_must_have_unit_and_cannot_be_negative():
    with pytest.raises(ValidationError):
        IngredientInput(display_name="Nasi", quantity=-1, unit="porsi")
    with pytest.raises(ValidationError):
        IngredientInput(display_name="Nasi", quantity=1)


def test_errors_have_request_id_and_do_not_echo_private_input(client):
    response = client.get("/does-not-exist?private=secret-journal")
    assert response.status_code == 404
    assert response.json()["request_id"] == response.headers["X-Request-ID"]
    assert "secret-journal" not in response.text
