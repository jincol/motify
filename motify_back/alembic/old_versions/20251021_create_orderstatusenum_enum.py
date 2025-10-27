from alembic import op

revision = 'create_orderstatusenum_enum'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.execute("""
    DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'orderstatusenum') THEN
            CREATE TYPE orderstatusenum AS ENUM ('pending', 'in_process', 'finished', 'cancelled', 'with_issue');
        END IF;
    END $$;
    """)

def downgrade():
    op.execute("""
    DO $$ BEGIN
        IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'orderstatusenum') THEN
            DROP TYPE orderstatusenum;
        END IF;
    END $$;
    """)