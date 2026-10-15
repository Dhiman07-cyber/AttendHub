"""add_working_days_to_semesters

Revision ID: e2ae719cf625
Revises: a1b2c3d4e5f6
Create Date: 2026-10-14 21:44:56.113905

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = 'e2ae719cf625'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # Add working_days JSONB column to semesters
    # Stores array of weekday integers: 0=Monday, 1=Tuesday, ..., 6=Sunday
    # Default: [0,1,2,3,4,5] (Monday-Saturday) for existing semesters
    op.execute("""
        ALTER TABLE semesters 
        ADD COLUMN working_days JSONB DEFAULT '[0,1,2,3,4,5]'::jsonb;
    """)
    
    # Set default for all existing rows
    op.execute("""
        UPDATE semesters 
        SET working_days = '[0,1,2,3,4,5]'::jsonb 
        WHERE working_days IS NULL;
    """)


def downgrade() -> None:
    op.drop_column('semesters', 'working_days')
