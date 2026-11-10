from functools import lru_cache
from typing import Literal

from pydantic import AnyHttpUrl, Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", hide_input_in_errors=True)

    app_env: Literal["local", "test", "production"] = "local"
    database_url: SecretStr = Field(min_length=1)
    supabase_url: AnyHttpUrl
    cors_origins: list[str] = []
    supabase_service_role_key: SecretStr | None = None
    storage_bucket: str = Field(default="aibs-food-photos", pattern=r"^[a-z0-9-]+$")
    gemini_api_key: SecretStr | None = None
    gemini_model: str | None = Field(default=None, pattern=r"^[A-Za-z0-9_.-]+$")
    ai_daily_limit: int = Field(default=20, ge=1, le=100)

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: SecretStr) -> SecretStr:
        if not value.get_secret_value().startswith(("postgresql+psycopg://", "sqlite")):
            raise ValueError("DATABASE_URL must use postgresql+psycopg or SQLite for local tests")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
