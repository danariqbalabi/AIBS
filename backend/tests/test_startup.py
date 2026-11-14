from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.entities import Ingredient, Menu
from app.start import prepare_database


def test_startup_migrates_empty_database_and_seeds_repeatably(tmp_path, monkeypatch):
    url = "sqlite+pysqlite:///" + str(tmp_path / "startup.db")
    monkeypatch.setenv("DATABASE_URL", url)
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    get_settings.cache_clear()
    try:
        prepare_database(create_engine(url))
        prepare_database(create_engine(url))
        engine = create_engine(url)
        with Session(engine) as session:
            assert session.scalar(select(func.count()).select_from(Ingredient)) == 22
            assert session.scalar(select(func.count()).select_from(Menu)) == 6
        engine.dispose()
    finally:
        get_settings.cache_clear()
