from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, field_validator, model_validator

Answer = Literal["yes", "no", "unknown"]
AgeBand = Literal["under_18", "18_29", "30_39", "40_49", "50_plus"]
Intent = Literal["before_meal", "consumed", "journal"]
PositiveQuantity = Annotated[Decimal, Field(gt=0, le=10000, max_digits=10, decimal_places=3)]


class Contract(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class EventTime(Contract):
    date: date
    occurred_at: datetime | None = None
    period: Literal["morning", "midday", "late_afternoon", "evening", "night"] | None = None
    precision: Literal["exact", "approximate"]
    confirmed: bool = False

    @model_validator(mode="after")
    def check_time(self):
        if self.precision == "exact":
            if self.occurred_at is None or self.occurred_at.utcoffset() is None:
                raise ValueError("Exact time requires an offset-aware occurred_at")
            if self.occurred_at.date() != self.date:
                raise ValueError("date must match occurred_at in its supplied offset")
            if self.period is not None:
                raise ValueError("Exact time must not also contain an approximate period")
        elif self.occurred_at is not None or self.period is None:
            raise ValueError("Approximate time requires period and no invented exact time")
        return self


class IngredientInput(Contract):
    ingredient_id: UUID | None = None
    display_name: str = Field(min_length=1, max_length=100)
    quantity: PositiveQuantity | None = None
    unit: str | None = Field(default=None, min_length=1, max_length=30)
    certainty: Literal["candidate", "confirmed", "unknown"] = "unknown"

    @model_validator(mode="after")
    def check_quantity(self):
        if self.quantity is not None and self.unit is None:
            raise ValueError("A quantity requires a unit")
        return self


class FoodCard(Contract):
    name: str = Field(min_length=1, max_length=160)
    consumed: bool = False
    time: EventTime | None = None
    ingredients: list[IngredientInput] = Field(default_factory=list, max_length=100)
    ingredients_complete: bool = False
    notes: str | None = Field(default=None, max_length=2000)


class SymptomCard(Contract):
    code: Literal[
        "pain", "bloating", "nausea", "vomiting", "diarrhea", "constipation", "bowel", "other"
    ]
    label: str | None = Field(default=None, min_length=1, max_length=100)
    present: bool
    severity: int | None = Field(default=None, ge=1, le=5)
    time: EventTime
    bristol_type: int | None = Field(default=None, ge=1, le=7)
    stress: Literal["low", "medium", "high", "unknown"] | None = None
    notes: str | None = Field(default=None, max_length=2000)
    linked_food_index: int | None = Field(default=None, ge=0)
    linked_food_event_id: UUID | None = None

    @model_validator(mode="after")
    def preserve_negation(self):
        if self.linked_food_index is not None and self.linked_food_event_id is not None:
            raise ValueError("Choose a food in this draft or an existing food event, not both")
        if not self.present and (self.severity is not None or self.bristol_type is not None):
            raise ValueError("Negated symptoms cannot carry severity or a bowel observation")
        if self.bristol_type is not None and self.code != "bowel":
            raise ValueError("Bristol type is only valid for bowel observations")
        return self


class DraftContent(Contract):
    story: str | None = Field(default=None, max_length=10000)
    foods: list[FoodCard] = Field(default_factory=list, max_length=20)
    symptoms: list[SymptomCard] = Field(default_factory=list, max_length=50)
    questions: list[str] = Field(default_factory=list, max_length=100)

    @model_validator(mode="after")
    def check_links(self):
        for symptom in self.symptoms:
            if symptom.linked_food_index is not None and symptom.linked_food_index >= len(
                self.foods
            ):
                raise ValueError("linked_food_index must reference a food in this draft")
        return self


class DraftCreate(Contract):
    intent: Intent
    content: DraftContent


class DraftPatch(Contract):
    version: int = Field(ge=1)
    intent: Intent
    content: DraftContent


class CommitDraft(Contract):
    version: int = Field(ge=1)
    confirmed: Literal[True]


class PortionLimit(Contract):
    ingredient_id: UUID
    quantity: PositiveQuantity
    unit: str = Field(min_length=1, max_length=30)


class DietProfile(Contract):
    directive: Literal["low_fodmap", "low_fat", "high_fiber", "other", "none"] = "none"
    phase: Literal["elimination", "reintroduction", "personalization", "unknown"] = "unknown"
    allergies: list[UUID] = Field(default_factory=list, max_length=100)
    avoided_ingredients: list[UUID] = Field(default_factory=list, max_length=100)
    portion_limits: list[PortionLimit] = Field(default_factory=list, max_length=100)
    tolerances: list[UUID] = Field(default_factory=list, max_length=100)
    budget_rupiah: int | None = Field(default=None, gt=0, le=10000000)
    spicy: Literal["none", "little", "medium", "hot"] | None = None
    preferences: list[str] = Field(default_factory=list, max_length=30)


class ProfilePatch(Contract):
    version: int = Field(ge=1)
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    age_band: AgeBand | None = None
    diagnosis_reported: Answer | None = None
    clinician_guidance: Answer | None = None
    timezone: str | None = Field(default=None, max_length=60)
    diet: DietProfile | None = None

    @field_validator("timezone")
    @classmethod
    def valid_timezone(cls, value):
        if value is not None:
            try:
                ZoneInfo(value)
            except ZoneInfoNotFoundError as exc:
                raise ValueError("Unknown IANA timezone") from exc
        return value


class ConsentInput(Contract):
    basic: bool
    ai: bool
    policy_version: Literal["demo-v1"] = "demo-v1"

    @model_validator(mode="after")
    def ai_requires_basic(self):
        if self.ai and not self.basic:
            raise ValueError("AI consent requires basic consent")
        return self


class AssessmentAnswers(Contract):
    severe_active: Answer | None = None
    bleeding: Answer | None = None
    bleeding_active: Answer | None = None
    weight_loss: Answer | None = None
    anemia: Answer | None = None
    family_history: Answer | None = None
    q1: Answer | None = None
    q2_days: Annotated[int, Field(strict=True, ge=0, le=31)] | Literal["unknown"] | None = None
    q2_band: Literal["under_1", "1_2", "3_4", "5_plus", "unknown"] | None = None
    q3_months: Annotated[int, Field(strict=True, ge=0, le=1200)] | Literal["unknown"] | None = None
    q3_band: Literal["under_3", "3_5", "6_12", "over_12", "unknown"] | None = None
    q4: Answer | None = None
    q5: Answer | None = None
    q6: Answer | None = None

    @model_validator(mode="after")
    def frequency_is_one_representation(self):
        if self.q2_days is not None and self.q2_band is not None:
            raise ValueError("Provide q2_days or q2_band, not both")
        if self.q3_months is not None and self.q3_band is not None:
            raise ValueError("Provide q3_months or q3_band, not both")
        return self


class AssessmentPatch(Contract):
    version: int = Field(ge=1)
    answers: AssessmentAnswers


class FoodCheckInput(Contract):
    profile_version: int = Field(ge=1)
    ingredients: list[IngredientInput] = Field(max_length=100)
    ingredients_complete: bool = False


class PhotoAnalysisInput(Contract):
    request_id: UUID
    media_id: UUID
    intent: Literal["before_meal", "consumed"]
    reference_date: date


class JournalAnalysisInput(Contract):
    request_id: UUID
    text: str = Field(min_length=1, max_length=10000)
    reference_date: date


class ErrorDetail(Contract):
    code: str
    message: str
    fields: list[dict[str, str]] = Field(default_factory=list)
    retryable: bool = False


class FoodEventPatch(Contract):
    kind: Literal["food"]
    version: int = Field(ge=1)
    payload: FoodCard


class SymptomEventPatch(Contract):
    kind: Literal["symptom"]
    version: int = Field(ge=1)
    payload: SymptomCard


class PlanInput(Contract):
    menu_id: UUID
    scheduled_at: AwareDatetime


class PlanPatch(Contract):
    version: int = Field(ge=1)
    scheduled_at: AwareDatetime


class ShoppingInput(Contract):
    ingredient_id: UUID | None = None
    name: str = Field(min_length=1, max_length=100)
    quantity: PositiveQuantity
    unit: str = Field(min_length=1, max_length=30)


class ShoppingPatch(Contract):
    version: int = Field(ge=1)
    quantity: PositiveQuantity
    checked: bool


class ShoppingFromMenu(Contract):
    menu_id: UUID
    servings: PositiveQuantity = Decimal(1)


class ErrorResponse(Contract):
    error: ErrorDetail
    request_id: str
