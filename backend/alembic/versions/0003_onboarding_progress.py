"""Persist private onboarding progress without treating it as a completed profile."""

import sqlalchemy as sa

from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "profiles", sa.Column("onboarding_state", sa.JSON(), nullable=False, server_default="{}")
    )


def downgrade():
    op.drop_column("profiles", "onboarding_state")
