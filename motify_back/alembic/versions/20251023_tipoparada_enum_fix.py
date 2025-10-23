"""migrate tipoparada_enum to english values and rename notas to notes

Revision ID: 20251023_tipoparada_enum_fix
Revises: daba2bd359b6
Create Date: 2025-10-23

"""
from alembic import op


# revision identifiers, used by Alembic.
revision = '20251023_tipoparada_enum_fix'
down_revision = 'daba2bd359b6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE TYPE tipoparada_enum_new AS ENUM ('pickup','delivery');")

    op.execute("""
        ALTER TABLE stops
        ALTER COLUMN "type" TYPE tipoparada_enum_new
        USING (
            (
            CASE
                WHEN "type"::text ILIKE 'RECOJO' THEN 'pickup'
                WHEN "type"::text ILIKE 'ENTREGA' THEN 'delivery'
                WHEN "type"::text ILIKE 'pickup' THEN 'pickup'
                WHEN "type"::text ILIKE 'delivery' THEN 'delivery'
                ELSE "type"::text
            END
            )::text::tipoparada_enum_new
        );
    """)

    op.execute("""
    DO $$
    BEGIN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name='stops' AND column_name='notas'
        ) THEN
            ALTER TABLE stops RENAME COLUMN notas TO notes;
        END IF;
    END
    $$;
    """)

    op.execute("DROP TYPE IF EXISTS tipoparada_enum;")
    op.execute("ALTER TYPE tipoparada_enum_new RENAME TO tipoparada_enum;")


def downgrade() -> None:
    op.execute("CREATE TYPE tipoparada_enum_old AS ENUM ('RECOJO','ENTREGA');")

    op.execute("""
        ALTER TABLE stops
        ALTER COLUMN "type" TYPE tipoparada_enum_old
        USING (
            (
            CASE
                WHEN "type"::text ILIKE 'pickup' THEN 'RECOJO'
                WHEN "type"::text ILIKE 'delivery' THEN 'ENTREGA'
                WHEN "type"::text ILIKE 'RECOJO' THEN 'RECOJO'
                WHEN "type"::text ILIKE 'ENTREGA' THEN 'ENTREGA'
                ELSE "type"::text
            END
            )::text::tipoparada_enum_old
        );
    """)

    op.execute("""
    DO $$
    BEGIN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name='stops' AND column_name='notes'
        ) THEN
            ALTER TABLE stops RENAME COLUMN notes TO notas;
        END IF;
    END
    $$;
    """)

    op.execute("DROP TYPE IF EXISTS tipoparada_enum;")
    op.execute("ALTER TYPE tipoparada_enum_old RENAME TO tipoparada_enum;")
