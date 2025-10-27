"""add confirmed_by column to stops

Revision ID: 3e270b509772
Revises: 20251023_tipoparada_enum_fix
Create Date: 2025-10-27 16:03:24.852700

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '3e270b509772'
down_revision = '20251023_tipoparada_enum_fix'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "stops",
        sa.Column("confirmed_by", sa.Integer(), nullable=True),
    )
    # create FK if users.id exists (optional)
    op.create_foreign_key(
        "fk_stops_confirmed_by_users", "stops", "users", ["confirmed_by"], ["id"]
    )

def downgrade() -> None:
    op.drop_constraint("fk_stops_confirmed_by_users", "stops", type_="foreignkey")
    op.drop_column("stops", "confirmed_by")
