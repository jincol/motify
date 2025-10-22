"""Make courier_id column nullable in orders

Revision ID: 20251022_make_courier_nullable
Revises: 
Create Date: 2025-10-22 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '20251022_make_courier_nullable'
down_revision = '0fa1f4ae4f5c'
branch_labels = None
depends_on = None


def upgrade():
    # Alter the `courier_id` column to be nullable to allow creating orders
    # without providing a courier from the frontend.
    op.alter_column('orders', 'courier_id', existing_type=sa.INTEGER(), nullable=True)


def downgrade():
    # Revert to NOT NULL. Be cautious: this will fail if there are orders with
    # a NULL courier_id; manual cleanup may be required before downgrading.
    op.alter_column('orders', 'courier_id', existing_type=sa.INTEGER(), nullable=False)
