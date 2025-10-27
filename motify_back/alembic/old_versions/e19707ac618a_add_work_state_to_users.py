"""add work_state to users

Revision ID: e19707ac618a
Revises: afbc8f034555
Create Date: 2025-09-24 17:25:50.597218

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'e19707ac618a'
down_revision = 'afbc8f034555'
branch_labels = None
depends_on = None


def upgrade():
    # Crear el tipo ENUM primero
    op.execute("CREATE TYPE workstate_enum AS ENUM ('INACTIVE', 'ACTIVE_SHIFT', 'ON_ROUTE')")
    # Se agrega la columna
    op.add_column('users', sa.Column('work_state', sa.Enum('INACTIVE', 'ACTIVE_SHIFT', 'ON_ROUTE', name='workstate_enum'), nullable=False, server_default='INACTIVE'))


def downgrade():
    op.drop_column('users', 'work_state')
    op.execute('DROP TYPE workstate_enum')