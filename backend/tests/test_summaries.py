from tests.test_records import journal_payload, save


def test_dashboard_counts_only_saved_present_symptoms_and_refreshes_after_mutation(account):
    client, _ = account
    draft = client.post("/api/v1/drafts", json=journal_payload()).json()
    assert client.get("/api/v1/dashboard?date=2026-11-10").json()["week"]["food_count"] == 0
    batch = save(client, draft).json()
    today = client.get("/api/v1/dashboard?date=2026-11-10").json()
    assert today["week"]["food_count"] == 1
    assert today["week"]["symptom_count"] == 1
    assert today["week"]["negated_observation_count"] == 1
    assert today["week"]["status"] == "insufficient_data"
    assert today["week"]["logged_days"] == 1
    client.delete(f"/api/v1/events/{batch['food_event_ids'][0]}?version=1")
    assert client.get("/api/v1/dashboard?date=2026-11-10").json()["week"]["food_count"] == 0
    assert client.get("/api/v1/summaries?end=2026-11-10&days=7").json()["symptom_count"] == 1


def test_exact_time_obeys_profile_timezone_and_approximate_time_remains_uncertain(account):
    client, _ = account
    payload = journal_payload()
    payload["content"]["symptoms"] = []
    payload["content"]["foods"][0]["time"] = {
        "date": "2026-11-09",
        "precision": "exact",
        "occurred_at": "2026-11-09T18:30:00+00:00",
        "confirmed": True,
    }
    draft = client.post("/api/v1/drafts", json=payload).json()
    assert save(client, draft).status_code == 200
    assert len(client.get("/api/v1/dashboard?date=2026-11-10").json()["events"]) == 1
    assert len(client.get("/api/v1/dashboard?date=2026-11-09").json()["events"]) == 0
    assert client.get("/api/v1/summaries?days=14").status_code == 422
