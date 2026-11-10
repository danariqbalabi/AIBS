import os
from pathlib import Path
from uuid import uuid4

import pytest
from alembic.config import Config
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

from alembic import command
from app.core.config import get_settings
from app.models import Base


def test_migration_upgrade_downgrade_on_disposable_database(tmp_path, monkeypatch):
    url = "sqlite+pysqlite:///" + str(tmp_path / "migration.db")
    monkeypatch.setenv("DATABASE_URL", url)
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    get_settings.cache_clear()
    config = Config(str(Path(__file__).resolve().parents[1] / "alembic.ini"))
    try:
        command.upgrade(config, "head")
        engine = create_engine(url)
        assert set(inspect(engine).get_table_names()) == set(Base.metadata.tables) | {
            "alembic_version"
        }
        command.check(config)
        command.downgrade(config, "base")
        assert inspect(engine).get_table_names() == ["alembic_version"]
        command.upgrade(config, "head")
        engine.dispose()
    finally:
        get_settings.cache_clear()


@pytest.mark.skipif(
    not os.environ.get("TEST_DATABASE_URL"), reason="Requires disposable PostgreSQL"
)
def test_postgres_migration_rls_and_schema_match(monkeypatch):
    url = make_url(os.environ["TEST_DATABASE_URL"])
    assert (url.database or "").endswith("_test")
    schema = "migration_" + uuid4().hex
    admin = create_engine(url)
    with admin.begin() as connection:
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
    isolated_url = url.update_query_dict({"options": f"-csearch_path={schema}"})
    monkeypatch.setenv("DATABASE_URL", isolated_url.render_as_string(hide_password=False))
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    get_settings.cache_clear()
    config = Config(str(Path(__file__).resolve().parents[1] / "alembic.ini"))
    try:
        command.upgrade(config, "head")
        command.check(config)
        with admin.connect() as connection:
            tables = connection.execute(
                text(
                    "SELECT relname, relrowsecurity FROM pg_class c "
                    "JOIN pg_namespace n ON n.oid=c.relnamespace "
                    "WHERE n.nspname=:schema AND c.relkind='r' AND relname!='alembic_version'"
                ),
                {"schema": schema},
            ).all()
        assert len(tables) == len(Base.metadata.tables)
        assert all(row.relrowsecurity for row in tables)
        command.downgrade(config, "base")
        command.upgrade(config, "head")
    finally:
        get_settings.cache_clear()
        with admin.begin() as connection:
            connection.execute(text(f'DROP SCHEMA "{schema}" CASCADE'))
        admin.dispose()
