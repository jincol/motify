"""change stop type enum values to english and rename notas to notes

Revision ID: daba2bd359b6
Revises: fc7790b07e77
Create Date: 2025-10-23 15:08:39.187202

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'daba2bd359b6'
down_revision = 'fc7790b07e77'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create a new enum type with english values
    op.execute("CREATE TYPE tipoparada_enum_new AS ENUM ('pickup','delivery');")

    # Convert existing values to the new enum safely (map Spanish -> English and preserve existing english values)
    op.execute("""
        ALTER TABLE stops
        ALTER COLUMN "type" TYPE tipoparada_enum_new
        USING (
            CASE
                WHEN "type"::text ILIKE 'RECOJO' THEN 'pickup'
                WHEN "type"::text ILIKE 'ENTREGA' THEN 'delivery'
                WHEN "type"::text ILIKE 'pickup' THEN 'pickup'
                WHEN "type"::text ILIKE 'delivery' THEN 'delivery'
                ELSE "type"::text
            END
        );
    """)

    # Rename column 'notas' to 'notes' if it exists (safe guard)
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

    # Drop the old enum type if present, then rename the new one to the original name
    op.execute("DROP TYPE IF EXISTS tipoparada_enum;")
    op.execute("ALTER TYPE tipoparada_enum_new RENAME TO tipoparada_enum;")


def downgrade() -> None:
    # Recreate old enum type with Spanish values
    op.execute("CREATE TYPE tipoparada_enum_old AS ENUM ('RECOJO','ENTREGA');")

    # Convert current english values back to spanish equivalents
    op.execute("""
        ALTER TABLE stops
        ALTER COLUMN "type" TYPE tipoparada_enum_old
        USING (
            CASE
                WHEN "type"::text ILIKE 'pickup' THEN 'RECOJO'
                WHEN "type"::text ILIKE 'delivery' THEN 'ENTREGA'
                WHEN "type"::text ILIKE 'RECOJO' THEN 'RECOJO'
                WHEN "type"::text ILIKE 'ENTREGA' THEN 'ENTREGA'
                ELSE "type"::text
            END
        );
    """)

    # Rename column 'notes' back to 'notas' if it exists
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

    # Drop the current enum and rename the old one back
    op.execute("DROP TYPE IF EXISTS tipoparada_enum;")
    op.execute("ALTER TYPE tipoparada_enum_old RENAME TO tipoparada_enum;")
