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

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: SecretStr) -> SecretStr:
        if not value.get_secret_value().startswith(("postgresql+psycopg://", "sqlite")):
            raise ValueError("DATABASE_URL must use postgresql+psycopg or SQLite for local tests")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
