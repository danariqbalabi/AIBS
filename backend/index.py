"""ASGI entrypoint for Vercel; database migrations are an explicit release step."""

from app.core.config import get_settings
from app.main import create_app

settings = get_settings().model_copy(update={"runtime_mode": "serverless"})
app = create_app(settings)
