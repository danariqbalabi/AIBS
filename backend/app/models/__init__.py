"""Database models. Migrations are immutable snapshots, not create_all at startup."""

from app.models.entities import Base

__all__ = ["Base"]
