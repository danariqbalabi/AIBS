"""Run once from a trusted release environment, never from a request or preview build."""

from app.core.config import get_settings
from app.core.database import make_engine
from app.start import prepare_database

if __name__ == "__main__":
    prepare_database(make_engine(get_settings()))
    print("Schema and synthetic catalog are current.")
