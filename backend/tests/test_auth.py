from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from uuid import uuid4

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi.testclient import TestClient
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.auth import JWTVerifier, User, get_user
from app.core.errors import ApiError
from app.main import create_app
from app.models.entities import Profile


@pytest.fixture
def signed_verifier(settings):
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    verifier = JWTVerifier(str(settings.supabase_url))
    verifier.jwks = SimpleNamespace(
        get_signing_key_from_jwt=lambda _: SimpleNamespace(key=key.public_key())
    )
    claims = {
        "sub": str(uuid4()),
        "role": "authenticated",
        "aud": "authenticated",
        "iss": verifier.issuer,
        "iat": datetime.now(UTC),
        "exp": datetime.now(UTC) + timedelta(minutes=5),
    }
    return verifier, key, claims


def test_signed_token_and_anonymous_identity(signed_verifier):
    verifier, key, claims = signed_verifier
    claims["is_anonymous"] = True
    user = verifier.verify(jwt.encode(claims, key, algorithm="RS256"))
    assert str(user.id) == claims["sub"]
    assert user.anonymous


@pytest.mark.parametrize(
    "change",
    [
        {"aud": "wrong"},
        {"iss": "https://wrong.example"},
        {"role": "service_role"},
        {"exp": 1},
        {"sub": "invalid"},
    ],
)
def test_invalid_claims_rejected(signed_verifier, change):
    verifier, key, claims = signed_verifier
    claims.update(change)
    with pytest.raises(ApiError) as exc:
        verifier.verify(jwt.encode(claims, key, algorithm="RS256"))
    assert exc.value.status == 401


def test_forged_token_signature_rejected(signed_verifier):
    verifier, _, claims = signed_verifier
    other = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    with pytest.raises(ApiError):
        verifier.verify(jwt.encode(claims, other, algorithm="RS256"))


def test_session_requires_bearer(client):
    assert client.get("/api/v1/me/session").status_code == 401


def test_demo_data_is_private_to_each_anonymous_session(settings, db_engine):
    app = create_app(settings, engine=db_engine)
    first, second = User(uuid4(), True), User(uuid4(), True)
    with TestClient(app) as client:
        for user in (first, second):
            app.dependency_overrides[get_user] = lambda current=user: current
            response = client.post("/api/v1/demo/sessions", json={"template": "nadia"})
            assert response.status_code == 200
        app.dependency_overrides[get_user] = lambda: first
        conflict = client.post("/api/v1/demo/sessions", json={"template": "raka"})
        assert conflict.status_code == 409
    with Session(db_engine) as db:
        assert db.scalar(select(func.count()).select_from(Profile)) == 2
        assert len(set(db.scalars(select(Profile.owner_id)))) == 2


def test_regular_account_cannot_be_overwritten_with_demo(settings, db_engine):
    app = create_app(settings, engine=db_engine)
    app.dependency_overrides[get_user] = lambda: User(uuid4(), False)
    with TestClient(app) as client:
        assert client.post("/api/v1/demo/sessions", json={"template": "nadia"}).status_code == 403
