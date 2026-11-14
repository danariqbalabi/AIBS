"""Persist photo preferences and temporary media deadlines."""

from datetime import UTC, datetime, timedelta

import sqlalchemy as sa

from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "profiles",
        sa.Column("save_photos", sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    op.add_column("media", sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_media_expires_at", "media", ["expires_at"])
    media = sa.table("media", sa.column("expires_at", sa.DateTime(timezone=True)))
    op.execute(media.update().values(expires_at=datetime.now(UTC) + timedelta(hours=24)))


def downgrade():
    op.drop_index("ix_media_expires_at", table_name="media")
    op.drop_column("media", "expires_at")
    op.drop_column("profiles", "save_photos")
