"""
Apply class_type migration to SQLite test database.
Run once to add class_type columns to timetable_entries and class_sessions.
"""
import sqlite3
import os

def apply_migration():
    db_paths = [
        'attendhub.db',
        'test_attendhub.db',
        '../test_attendhub.db'
    ]
    
    for db_path in db_paths:
        if not os.path.exists(db_path):
            continue
        
        print(f"Applying migration to {db_path}...")
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        try:
            # Check if column already exists
            cursor.execute("PRAGMA table_info(timetable_entries)")
            cols = [row[1] for row in cursor.fetchall()]
            
            if 'class_type' not in cols:
                print("  Adding class_type to timetable_entries...")
                cursor.execute("ALTER TABLE timetable_entries ADD COLUMN class_type VARCHAR(20)")
            else:
                print("  class_type already exists in timetable_entries")
            
            # Check class_sessions
            cursor.execute("PRAGMA table_info(class_sessions)")
            sess_cols = [row[1] for row in cursor.fetchall()]
            
            if 'class_type' not in sess_cols:
                print("  Adding class_type to class_sessions...")
                cursor.execute("ALTER TABLE class_sessions ADD COLUMN class_type VARCHAR(20)")
            else:
                print("  class_type already exists in class_sessions")
            
            conn.commit()
            print(f"✓ Migration applied successfully to {db_path}")
        
        except Exception as e:
            print(f"✗ Error applying migration to {db_path}: {e}")
            conn.rollback()
        finally:
            conn.close()

if __name__ == "__main__":
    apply_migration()
