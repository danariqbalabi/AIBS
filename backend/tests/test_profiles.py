from uuid import uuid4

from app.core.auth import User


def test_profile_persists_with_version_conflict(account):
    client, _ = account
    initial = client.get("/api/v1/me/profile").json()
    change = {"version": initial["version"], "age_band": "18_29", "display_name": "Nadia"}
    assert client.patch("/api/v1/me/profile", json=change).status_code == 200
    assert client.patch("/api/v1/me/profile", json=change).status_code == 409
    assert client.get("/api/v1/me/profile").json()["display_name"] == "Nadia"


def test_profile_owner_is_derived_from_token(account):
    client, context = account
    profile = client.get("/api/v1/me/profile").json()
    assert (
        client.patch(
            "/api/v1/me/profile",
            json={
                "version": profile["version"],
                "owner_id": str(uuid4()),
            },
        ).status_code
        == 422
    )
    context["user"] = User(uuid4())
    assert client.get("/api/v1/me/profile").status_code == 404


def test_assessment_autosave_keeps_unknown_separate(account):
    client, _ = account
    result = client.patch(
        "/api/v1/me/assessment",
        json={
            "version": 1,
            "answers": {"q1": "unknown", "q2_band": "3_4"},
        },
    )
    assert result.status_code == 200
    result = client.patch(
        "/api/v1/me/assessment",
        json={
            "version": result.json()["version"],
            "answers": {"q4": "no"},
        },
    )
    assert result.json()["answers"]["q1"] == "unknown"
    assert result.json()["answers"]["q4"] == "no"
    assert result.json()["answers"]["q2_days"] is None


def test_consent_revocation_is_independent_and_blocks_mutations(account):
    client, _ = account
    assert client.put("/api/v1/me/consents", json={"basic": True, "ai": True}).status_code == 200
    client.put("/api/v1/me/consents", json={"basic": True, "ai": False})
    assert client.get("/api/v1/me/consents").json()["ai"] is False
    client.put("/api/v1/me/consents", json={"basic": False, "ai": False})
    profile = client.get("/api/v1/me/profile").json()
    assert (
        client.patch(
            "/api/v1/me/profile",
            json={
                "version": profile["version"],
                "display_name": "X",
            },
        ).status_code
        == 403
    )
