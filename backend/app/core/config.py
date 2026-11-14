from functools import lru_cache
from typing import Literal

from pydantic import AnyHttpUrl, Field, SecretStr, field_validator, model_validator
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
    runtime_mode: Literal["server", "serverless"] = "server"
    cron_secret: SecretStr | None = Field(default=None, min_length=16)
    max_photo_bytes: int = Field(default=5 * 1024 * 1024, ge=1024, le=5 * 1024 * 1024)

    @field_validator(
        "supabase_service_role_key", "gemini_api_key", "gemini_model", "cron_secret", mode="before"
    )
    @classmethod
    def empty_optional_config(cls, value):
        return None if value == "" else value

    @model_validator(mode="after")
    def production_uses_postgres_and_https(self):
        if self.app_env == "production":
            if not self.database_url.get_secret_value().startswith("postgresql+psycopg://"):
                raise ValueError("Production requires PostgreSQL")
            if self.supabase_url.scheme != "https":
                raise ValueError("Production requires HTTPS Supabase URL")
        return self

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: SecretStr) -> SecretStr:
        if not value.get_secret_value().startswith(("postgresql+psycopg://", "sqlite")):
            raise ValueError("DATABASE_URL must use postgresql+psycopg or SQLite for local tests")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
