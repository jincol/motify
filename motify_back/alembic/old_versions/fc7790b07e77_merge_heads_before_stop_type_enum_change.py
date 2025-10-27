"""merge heads before stop-type-enum-change

Revision ID: fc7790b07e77
Revises: 20251022_make_courier_nullable, merge_268c23_conv
Create Date: 2025-10-23 15:08:17.886757

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'fc7790b07e77'
down_revision = ('20251022_make_courier_nullable', 'merge_268c23_conv')
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
