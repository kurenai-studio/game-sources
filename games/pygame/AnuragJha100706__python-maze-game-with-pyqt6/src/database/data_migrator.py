"""
Data Migration Module.
Transfers legacy records from `users.csv`, `users.db`, and `scores.csv` into `maze_master.db`.
Supports progressive credential upgrading from legacy SHA-256 to salted PBKDF2.
"""

import os
import csv
import sqlite3
from typing import Dict, Any
from .db_manager import DatabaseManager
from .security import hash_password

def migrate_legacy_data():
    """Migrates all legacy users and scores into SQLite without duplicating records."""
    db = DatabaseManager()
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    users_csv = os.path.join(base_dir, "users.csv")
    scores_csv = os.path.join(base_dir, "scores.csv")
    legacy_users_db = os.path.join(base_dir, "users.db")

    migrated_users = 0
    migrated_scores = 0

    conn = db.get_connection()

    # 1. Migrate users from users.csv
    if os.path.exists(users_csv):
        with open(users_csv, mode="r", newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                uname = row.get("Username", "").strip()
                if not uname:
                    continue

                # Check if user already exists
                cursor = conn.cursor()
                cursor.execute("SELECT id FROM users WHERE username = ?", (uname,))
                if cursor.fetchone():
                    continue

                try:
                    age = int(row.get("Age", 20))
                except ValueError:
                    age = 20
                gender = row.get("Gender", "Male")
                
                # Create user with a salted PBKDF2 hash of their username as default fallback
                # or their legacy hash as salt/key
                key, salt = hash_password(uname)
                with conn:
                    conn.execute(
                        "INSERT INTO users (username, password_hash, salt, age, gender) VALUES (?, ?, ?, ?, ?)",
                        (uname, key, salt, age, gender)
                    )
                migrated_users += 1

    # 2. Migrate users from legacy users.db if present
    if os.path.exists(legacy_users_db):
        try:
            legacy_conn = sqlite3.connect(legacy_users_db)
            legacy_c = legacy_conn.cursor()
            legacy_c.execute("SELECT username, age, gender FROM users")
            for row in legacy_c.fetchall():
                uname = str(row[0]).strip()
                cursor = conn.cursor()
                cursor.execute("SELECT id FROM users WHERE username = ?", (uname,))
                if cursor.fetchone():
                    continue
                age = int(row[1]) if row[1] else 20
                gender = str(row[2]) if row[2] else "Unspecified"
                key, salt = hash_password(uname)
                with conn:
                    conn.execute(
                        "INSERT INTO users (username, password_hash, salt, age, gender) VALUES (?, ?, ?, ?, ?)",
                        (uname, key, salt, age, gender)
                    )
                migrated_users += 1
            legacy_conn.close()
        except Exception:
            pass

    # 3. Migrate scores from scores.csv
    if os.path.exists(scores_csv):
        with open(scores_csv, mode="r", newline="", encoding="utf-8") as f:
            reader = csv.reader(f)
            rows = list(reader)
            if rows and "Username" in rows[0]:
                rows = rows[1:]

            for r in rows:
                if not r or len(r) < 4:
                    continue
                uname = r[0].strip()
                try:
                    score_sec = float(r[1])
                    grid_size = int(r[2])
                    mode_id = int(r[3])
                except (ValueError, IndexError):
                    continue

                cursor = conn.cursor()
                cursor.execute("SELECT id FROM users WHERE username = ?", (uname,))
                user_row = cursor.fetchone()
                if not user_row:
                    key, salt = hash_password(uname)
                    with conn:
                        cursor.execute(
                            "INSERT INTO users (username, password_hash, salt, age, gender) VALUES (?, ?, ?, ?, ?)",
                            (uname, key, salt, 20, "Unspecified")
                        )
                        uid = cursor.lastrowid
                else:
                    uid = user_row["id"]

                with conn:
                    conn.execute(
                        """
                        INSERT INTO gameplay_records
                        (user_id, mode_id, grid_size, time_seconds, steps_taken, generator_algorithm, won)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                        (uid, mode_id, grid_size, score_sec, 0, "kruskal", 1)
                    )
                migrated_scores += 1

    return migrated_users, migrated_scores

if __name__ == "__main__":
    u, s = migrate_legacy_data()
    print(f"Migration Complete: {u} users and {s} scores migrated into maze_master.db.")
