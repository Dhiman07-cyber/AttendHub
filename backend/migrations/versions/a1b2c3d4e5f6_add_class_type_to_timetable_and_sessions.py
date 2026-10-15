"""Add class_type to timetable_entries and class_sessions

Revision ID: a1b2c3d4e5f6
Revises: 5d88f7da594e
Create Date: 2026-10-14 00:00:00.000000

Adds a nullable class_type column (THEORY/LAB/UNSPECIFIED) to both
timetable_entries and class_sessions so Theory and Lab attendance can
be tracked and reported separately.

- timetable_entries.class_type: persisted slot classification (THEORY, LAB, UNSPECIFIED)
- class_sessions.class_type: snapshotted from the timetable entry at session creation time

Both default to NULL (UNSPECIFIED) so that legacy rows are not silently
re-classified. The application reads NULL as UNSPECIFIED and counts those
sessions only in subject overall metrics, not in Theory or Lab breakdowns.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '5d88f7da594e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add class_type to timetable_entries
    op.add_column(
        'timetable_entries',
        sa.Column('class_type', sa.String(20), nullable=True, server_default=None)
    )
    # Add class_type to class_sessions (snapshotted from timetable entry)
    op.add_column(
        'class_sessions',
        sa.Column('class_type', sa.String(20), nullable=True, server_default=None)
    )
    # Add timetable_entry_id FK reference to class_sessions (already present in model but
    # may not have a FK constraint in the initial migration - add if missing, ignore if exists)
    # NOTE: The FK is already in the model as a plain column without SA FK constraint;
    # we intentionally leave it as a plain string column to avoid migration churn on
    # databases that already have data. The application enforces ownership via joins.


def downgrade() -> None:
    op.drop_column('class_sessions', 'class_type')
    op.drop_column('timetable_entries', 'class_type')
