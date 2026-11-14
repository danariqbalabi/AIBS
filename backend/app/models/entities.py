from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import (
    JSON,
    CheckConstraint,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Numeric,
    String,
    UniqueConstraint,
    false,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, declared_attr, mapped_column


def now() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    pass


class Owned:
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    owner_id: Mapped[UUID] = mapped_column(index=True)
    version: Mapped[int] = mapped_column(default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, onupdate=now)

    @declared_attr.directive
    def __table_args__(cls):
        return (UniqueConstraint("id", "owner_id"),)


class Profile(Owned, Base):
    __tablename__ = "profiles"
    __table_args__ = (UniqueConstraint("id", "owner_id"), UniqueConstraint("owner_id"))
    display_name: Mapped[str] = mapped_column(String(80), default="Kamu")
    age_band: Mapped[str | None] = mapped_column(String(20))
    diagnosis_reported: Mapped[str | None] = mapped_column(String(10))
    clinician_guidance: Mapped[str | None] = mapped_column(String(10))
    timezone: Mapped[str] = mapped_column(String(60), default="Asia/Jakarta")
    diet: Mapped[dict] = mapped_column(JSON, default=dict)
    demo_template: Mapped[str | None] = mapped_column(String(30))
    save_photos: Mapped[bool] = mapped_column(default=False, server_default=false())
    onboarding_state: Mapped[dict] = mapped_column(JSON, default=dict, server_default="{}")


class Consent(Owned, Base):
    __tablename__ = "consents"
    basic: Mapped[bool]
    ai: Mapped[bool]
    policy_version: Mapped[str] = mapped_column(String(30))


class Assessment(Owned, Base):
    __tablename__ = "assessments"
    __table_args__ = (UniqueConstraint("id", "owner_id"), UniqueConstraint("owner_id"))
    answers: Mapped[dict] = mapped_column(JSON, default=dict)
    result: Mapped[dict] = mapped_column(JSON, default=dict)


class Ingredient(Base):
    __tablename__ = "ingredients"
    id: Mapped[UUID] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    aliases: Mapped[list] = mapped_column(JSON, default=list)
    source: Mapped[str] = mapped_column(String(200))


class Menu(Base):
    __tablename__ = "menus"
    __table_args__ = (CheckConstraint("price_rupiah > 0"),)
    id: Mapped[UUID] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    kind: Mapped[str] = mapped_column(String(10))
    price_rupiah: Mapped[int]
    instructions: Mapped[str]
    tags: Mapped[list] = mapped_column(JSON, default=list)
    directives: Mapped[list] = mapped_column(JSON, default=list)
    ingredients_complete: Mapped[bool] = mapped_column(default=True)
    source: Mapped[str] = mapped_column(String(200))


class MenuIngredient(Base):
    __tablename__ = "menu_ingredients"
    __table_args__ = (CheckConstraint("quantity > 0"),)
    menu_id: Mapped[UUID] = mapped_column(ForeignKey("menus.id"), primary_key=True)
    ingredient_id: Mapped[UUID] = mapped_column(ForeignKey("ingredients.id"), primary_key=True)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    unit: Mapped[str] = mapped_column(String(30))


class Media(Owned, Base):
    __tablename__ = "media"
    path: Mapped[str] = mapped_column(String(300), unique=True)
    mime: Mapped[str] = mapped_column(String(30))
    size: Mapped[int]
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), index=True)


class Draft(Owned, Base):
    __tablename__ = "drafts"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        ForeignKeyConstraint(["media_id", "owner_id"], ["media.id", "media.owner_id"]),
    )
    source: Mapped[str] = mapped_column(String(20))
    intent: Mapped[str] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(20), default="draft")
    content: Mapped[dict] = mapped_column(JSON)
    profile_version: Mapped[int]
    media_id: Mapped[UUID | None]


class RecordBatch(Owned, Base):
    __tablename__ = "record_batches"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        UniqueConstraint("draft_id"),
        ForeignKeyConstraint(["draft_id", "owner_id"], ["drafts.id", "drafts.owner_id"]),
    )
    draft_id: Mapped[UUID]


class EventFields(Owned):
    batch_id: Mapped[UUID]
    local_date: Mapped[date] = mapped_column(index=True)
    occurred_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    payload: Mapped[dict] = mapped_column(JSON)


def event_constraints(table: str):
    return (
        UniqueConstraint("id", "owner_id"),
        ForeignKeyConstraint(
            ["batch_id", "owner_id"], ["record_batches.id", "record_batches.owner_id"]
        ),
        Index(f"ix_{table}_owner_date", "owner_id", "local_date"),
    )


class FoodEvent(EventFields, Base):
    __tablename__ = "food_events"
    __table_args__ = event_constraints("food_events")
    evaluation: Mapped[dict] = mapped_column(JSON)


class SymptomEvent(EventFields, Base):
    __tablename__ = "symptom_events"
    __table_args__ = event_constraints("symptom_events")


class EventLink(Owned, Base):
    __tablename__ = "event_links"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        UniqueConstraint("food_event_id", "symptom_event_id"),
        ForeignKeyConstraint(
            ["food_event_id", "owner_id"],
            ["food_events.id", "food_events.owner_id"],
            ondelete="CASCADE",
        ),
        ForeignKeyConstraint(
            ["symptom_event_id", "owner_id"],
            ["symptom_events.id", "symptom_events.owner_id"],
            ondelete="CASCADE",
        ),
    )
    food_event_id: Mapped[UUID]
    symptom_event_id: Mapped[UUID]


class MealPlan(Owned, Base):
    __tablename__ = "meal_plans"
    menu_id: Mapped[UUID] = mapped_column(ForeignKey("menus.id"))
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    snapshot: Mapped[dict] = mapped_column(JSON)


class ShoppingItem(Owned, Base):
    __tablename__ = "shopping_items"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        UniqueConstraint("owner_id", "ingredient_id", "unit"),
        CheckConstraint("quantity > 0"),
    )
    ingredient_id: Mapped[UUID | None] = mapped_column(ForeignKey("ingredients.id"))
    name: Mapped[str] = mapped_column(String(100))
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 3))
    unit: Mapped[str] = mapped_column(String(30))
    checked: Mapped[bool] = mapped_column(default=False)


class IdempotencyRequest(Owned, Base):
    __tablename__ = "idempotency_requests"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        UniqueConstraint("owner_id", "operation", "key"),
    )
    operation: Mapped[str] = mapped_column(String(40))
    key: Mapped[str] = mapped_column(String(100))
    payload_hash: Mapped[str] = mapped_column(String(64))
    response: Mapped[dict | None] = mapped_column(JSON)


class AiRun(Owned, Base):
    __tablename__ = "ai_runs"
    __table_args__ = (
        UniqueConstraint("id", "owner_id"),
        UniqueConstraint("owner_id", "request_id"),
    )
    request_id: Mapped[UUID]
    feature: Mapped[str] = mapped_column(String(30))
    payload_hash: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(20))
    model: Mapped[str] = mapped_column(String(100))
    prompt_version: Mapped[str] = mapped_column(String(30))
    input_tokens: Mapped[int | None]
    output_tokens: Mapped[int | None]
    latency_ms: Mapped[int | None]
    draft_id: Mapped[UUID | None] = mapped_column(ForeignKey("drafts.id"))
