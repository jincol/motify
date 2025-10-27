"""Convert orders.status from estadopedido_enum (ES) to orderstatusenum (EN)

Revision ID: 20251022_convert_status_to_orderstatusenum
Revises: 0fa1f4ae4f5c
Create Date: 2025-10-22 14:30:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'conv_status_20251022'
down_revision = '0fa1f4ae4f5c'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1) Create EN enum type if not exists
    op.execute("""
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'orderstatusenum') THEN
        CREATE TYPE orderstatusenum AS ENUM ('pending','in_process','finished','cancelled','with_issue');
      END IF;
    END$$;
    """)
    # 2) Add temporary column as TEXT, fill mapping, then convert to enum
    op.add_column('orders', sa.Column('status_new', sa.Text(), nullable=True))

    # 3) Map existing values (ES -> EN). DB stored labels in uppercase, map accordingly
    op.execute("""
    UPDATE orders SET status_new = CASE status::text
      WHEN 'PENDIENTE' THEN 'pending'
      WHEN 'EN_PROCESO' THEN 'in_process'
      WHEN 'FINALIZADO' THEN 'finished'
      WHEN 'CANCELADO' THEN 'cancelled'
      WHEN 'CON_INCIDENCIA' THEN 'with_issue'
      ELSE 'pending'
    END;
    """)

    # 4) Ensure no NULLs
    op.execute("UPDATE orders SET status_new = 'pending' WHERE status_new IS NULL;")

    # 5) Convert status_new text values to the enum type using USING cast
    op.execute("ALTER TABLE orders ALTER COLUMN status_new TYPE orderstatusenum USING status_new::orderstatusenum;")

    # 6) Drop index on old status (if exists), drop old column, rename new column, recreate index
    try:
        op.drop_index('ix_orders_status', table_name='orders')
    except Exception:
        # ignore if index doesn't exist in metadata
        pass

    op.drop_column('orders', 'status')
    op.alter_column('orders', 'status_new', new_column_name='status', nullable=False)
    op.create_index('ix_orders_status', 'orders', ['status'])

    # 7) Try to drop old enum type (if no dependencies)
    op.execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estadopedido_enum') THEN
        BEGIN
          DROP TYPE estadopedido_enum;
        EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'Could not drop estadopedido_enum: %', SQLERRM;
        END;
      END IF;
    END$$;
    """)


def downgrade() -> None:
    # Reverse: recreate spanish enum, convert values back and restore
    op.execute("""
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estadopedido_enum') THEN
        CREATE TYPE estadopedido_enum AS ENUM ('PENDIENTE','EN_PROCESO','FINALIZADO','CANCELADO','CON_INCIDENCIA');
      END IF;
    END$$;
    """)

    op.add_column('orders', sa.Column('status_old', sa.Enum('PENDIENTE','EN_PROCESO','FINALIZADO','CANCELADO','CON_INCIDENCIA', name='estadopedido_enum'), nullable=True))

    op.execute("""
    UPDATE orders SET status_old = CASE status::text
      WHEN 'pending' THEN 'PENDIENTE'
      WHEN 'in_process' THEN 'EN_PROCESO'
      WHEN 'finished' THEN 'FINALIZADO'
      WHEN 'cancelled' THEN 'CANCELADO'
      WHEN 'with_issue' THEN 'CON_INCIDENCIA'
      ELSE 'PENDIENTE'
    END;
    """)

    op.execute("UPDATE orders SET status_old = 'PENDIENTE' WHERE status_old IS NULL;")

    try:
        op.drop_index('ix_orders_status', table_name='orders')
    except Exception:
        pass

    op.drop_column('orders', 'status')
    op.alter_column('orders', 'status_old', new_column_name='status', nullable=False)
    op.create_index('ix_orders_status', 'orders', ['status'])

    # Try to drop EN type
    op.execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'orderstatusenum') THEN
        BEGIN
          DROP TYPE orderstatusenum;
        EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'Could not drop orderstatusenum: %', SQLERRM;
        END;
      END IF;
    END$$;
    """)
