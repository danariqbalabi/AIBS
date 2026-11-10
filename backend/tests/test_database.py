from datetime import date
from uuid import uuid4

import pytest
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.entities import Draft, FoodEvent, Ingredient, Menu, RecordBatch
from seeds.catalog import seed_catalog


def test_catalog_seed_is_repeatable(db_engine):
    with Session(db_engine) as session, session.begin():
        seed_catalog(session)
        seed_catalog(session)
        assert session.scalar(select(func.count()).select_from(Menu)) == 6
        assert session.scalar(select(func.count()).select_from(Ingredient)) == 10


def test_cross_owner_event_batch_foreign_key_is_rejected(db_engine):
    owner, stranger = uuid4(), uuid4()
    with Session(db_engine) as session, session.begin():
        draft = Draft(
            owner_id=owner, source="manual", intent="consumed", content={}, profile_version=1
        )
        session.add(draft)
        session.flush()
        batch = RecordBatch(owner_id=owner, draft_id=draft.id)
        session.add(batch)
        session.flush()
        batch_id = batch.id
    with Session(db_engine) as session:
        session.add(
            FoodEvent(
                owner_id=stranger,
                batch_id=batch_id,
                local_date=date(2026, 11, 10),
                payload={},
                evaluation={},
            )
        )
        with pytest.raises(IntegrityError):
            session.commit()
