"""Generate API docs without reading local secrets or contacting providers."""

import json
from pathlib import Path

from app.core.config import Settings
from app.main import create_app

if __name__ == "__main__":
    settings = Settings(
        _env_file=None,
        app_env="test",
        database_url="sqlite+pysqlite:///:memory:",
        supabase_url="https://example.supabase.co",
    )
    app = create_app(settings)
    target = Path(__file__).resolve().parents[2] / "docs/api/openapi.json"
    target.write_text(
        json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    app.state.engine.dispose()
    print(target)
