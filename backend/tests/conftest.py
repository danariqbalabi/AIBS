import os
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text

from app.core.config import Settings
from app.core.database import make_engine
from app.main import create_app
from app.models import Base


@pytest.fixture
def settings():
    return Settings(
        _env_file=None,
        app_env="test",
        database_url="sqlite+pysqlite:///:memory:",
        supabase_url="https://example.supabase.co",
    )


@pytest.fixture
def db_engine(settings, tmp_path):
    url = os.environ.get("TEST_DATABASE_URL")
    if url:
        # The configured CI database must be dedicated to tests, never a live Supabase database.
        from sqlalchemy.engine import make_url

        if not (make_url(url).database or "").endswith("_test"):
            raise RuntimeError("TEST_DATABASE_URL must point to a dedicated *_test database")
        schema = "test_" + uuid4().hex
        admin = create_engine(url)
        with admin.begin() as connection:
            connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        engine = create_engine(url, connect_args={"options": f"-csearch_path={schema}"})
    else:
        settings = settings.model_copy(
            update={
                "database_url": type(settings.database_url)(
                    "sqlite+pysqlite:///" + str(tmp_path / "test.db")
                )
            }
        )
        engine = make_engine(settings)
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()
    if url:
        with admin.begin() as connection:
            connection.execute(text(f'DROP SCHEMA "{schema}" CASCADE'))
        admin.dispose()


@pytest.fixture
def client(settings):
    with TestClient(create_app(settings)) as client:
        yield client
