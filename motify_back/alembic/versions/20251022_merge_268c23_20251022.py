"""Merge revision for 268c23de226f and 20251022_convert_status_to_orderstatusenum

Revision ID: 20251022_merge_268c23_20251022
Revises: 268c23de226f, 20251022_convert_status_to_orderstatusenum
Create Date: 2025-10-22 14:45:00.000000
"""
from alembic import op

# revision identifiers, used by Alembic.
revision = 'merge_268c23_conv'
down_revision = ('268c23de226f','conv_status_20251022')
branch_labels = None
depends_on = None


def upgrade() -> None:
    # merge-only revision: no DB changes
    pass


def downgrade() -> None:
    # nothing to do on downgrade for a merge-only revision
    pass
