"""Render entrypoint: serialize schema/catalog preparation before accepting traffic."""

import os

from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.orm import Session

from alembic import command
from app.core.config import get_settings
from app.core.database import make_engine
from seeds.catalog import seed_catalog


def prepare_database(engine):
    with engine.begin() as connection:
        if engine.dialect.name == "postgresql":
            connection.execute(text("SET LOCAL lock_timeout = '90s'"))
            connection.execute(text("SELECT pg_advisory_xact_lock(714084206)"))
        config = Config("alembic.ini")
        config.attributes["connection"] = connection
        command.upgrade(config, "head")
        with Session(bind=connection) as session:
            seed_catalog(session)
    engine.dispose()


def main():
    port = int(os.environ.get("PORT", "8000"))
    if not 1 <= port <= 65535:
        raise ValueError("PORT must be between 1 and 65535")
    prepare_database(make_engine(get_settings()))
    import uvicorn

    uvicorn.run("app.main:create_app", factory=True, host="0.0.0.0", port=port, access_log=False)


if __name__ == "__main__":
    main()
