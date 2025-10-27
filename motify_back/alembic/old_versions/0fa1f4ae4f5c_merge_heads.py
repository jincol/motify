"""Merge heads

Revision ID: 0fa1f4ae4f5c
Revises: 1edcf9cdaed0, create_orderstatusenum_enum
Create Date: 2025-10-21 23:21:03.183680

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0fa1f4ae4f5c'
down_revision = ('1edcf9cdaed0', 'create_orderstatusenum_enum')
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
