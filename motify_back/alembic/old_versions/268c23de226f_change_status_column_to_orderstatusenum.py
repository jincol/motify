"""Change status column to orderstatusenum

Revision ID: 268c23de226f
Revises: 0fa1f4ae4f5c
Create Date: 2025-10-21 23:24:06.783608

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '268c23de226f'
down_revision = '0fa1f4ae4f5c'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Cambiar tipo de columna status en orders de estadopedido_enum a orderstatusenum
    from alembic import op
    import sqlalchemy as sa
    op.alter_column('orders', 'status', new_column_name='status_old')
    op.add_column('orders', sa.Column('status', sa.Enum('pending', 'in_process', 'finished', 'cancelled', 'with_issue', name='orderstatusenum'), nullable=False, server_default='pending'))
    op.execute("UPDATE orders SET status = status_old::text::orderstatusenum")
    op.drop_column('orders', 'status_old')
    op.execute("DROP TYPE IF EXISTS estadopedido_enum")


def downgrade() -> None:
    # Revertir el cambio: volver a estadopedido_enum
    from alembic import op
    import sqlalchemy as sa
    op.alter_column('orders', 'status', new_column_name='status_old')
    op.add_column('orders', sa.Column('status', sa.Enum('pendiente', 'en_proceso', 'finalizado', 'cancelado', 'con_incidencia', name='estadopedido_enum'), nullable=False, server_default='pendiente'))
    op.execute("UPDATE orders SET status = status_old::text::estadopedido_enum")
    op.drop_column('orders', 'status_old')
    op.execute("DROP TYPE IF EXISTS orderstatusenum")
