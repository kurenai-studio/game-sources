"""
Automated Unit Test Suite for Phase 2: Relational Database & Security.
Validates:
1. PBKDF2-HMAC-SHA256 salted password hashing & verification.
2. SQLite transactional queries, table creation, and constraints.
3. User registration, authentication, and duplicate handling.
4. Gameplay record saving, leaderboard sorting, and filtering.
5. Migration of legacy users.csv and scores.csv.
"""

import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from database.security import hash_password, verify_password
from database.db_manager import DatabaseManager
from database.data_migrator import migrate_legacy_data

def test_security():
    print("[TEST] Running Cryptographic Security verification...")
    password = "MasterPassword2026!"
    key1, salt1 = hash_password(password)
    key2, salt2 = hash_password(password)

    # Different salts must yield different derived keys
    assert salt1 != salt2, "Salts must be randomly generated"
    assert key1 != key2, "Keys with different salts must differ"

    # Verification checks
    assert verify_password(password, key1, salt1), "Password verification failed with correct password"
    assert not verify_password("WrongPassword", key1, salt1), "Password verification falsely succeeded on bad password"
    print("  -> PBKDF2 Cryptography: PASSED")

def test_database_operations():
    print("[TEST] Running Database Manager verification...")
    test_db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "test_maze.db"))
    if os.path.exists(test_db_path):
        os.remove(test_db_path)

    db = DatabaseManager(test_db_path)
    
    # User Registration
    success, msg = db.register_user("Alice_Test", "Pass1234", 22, "Female")
    assert success, f"Registration failed: {msg}"

    # Duplicate Prevention
    success_dup, msg_dup = db.register_user("alice_test", "Pass1234", 22, "Female")
    assert not success_dup, "Duplicate registration should fail"

    # Authentication
    auth_ok, user_data, _ = db.authenticate_user("Alice_Test", "Pass1234")
    assert auth_ok and user_data is not None, "Authentication failed for valid user"
    assert user_data["username"] == "Alice_Test"

    auth_fail, _, _ = db.authenticate_user("Alice_Test", "WrongPass")
    assert not auth_fail, "Authentication should fail for invalid password"

    # Gameplay Records
    user_id = user_data["id"]
    r1 = db.save_gameplay_record(user_id, mode_id=0, grid_size=20, time_seconds=18.5, steps_taken=45, won=True)
    r2 = db.save_gameplay_record(user_id, mode_id=0, grid_size=20, time_seconds=12.2, steps_taken=38, won=True)
    r3 = db.save_gameplay_record(user_id, mode_id=1, grid_size=25, time_seconds=25.0, steps_taken=60, won=True)

    assert r1 > 0 and r2 > 0 and r3 > 0

    # Leaderboard Retrieval & Sorting
    leaders_mode0 = db.get_leaderboard(mode_id=0)
    assert len(leaders_mode0) == 2, f"Expected 2 records for mode 0, got {len(leaders_mode0)}"
    assert leaders_mode0[0]["time_seconds"] == 12.2, "Leaderboard must be sorted ascending by time"
    assert leaders_mode0[1]["time_seconds"] == 18.5

    # System Settings
    db.set_setting("theme", "cyberpunk_dark")
    assert db.get_setting("theme") == "cyberpunk_dark"
    assert db.get_setting("volume", "80") == "80"

    print("  -> Database Manager Operations: PASSED")

    # Clean up test db
    db.close()
    if os.path.exists(test_db_path):
        os.remove(test_db_path)

def test_migration():
    print("[TEST] Running Legacy Data Migration verification...")
    u, s = migrate_legacy_data()
    print(f"  -> Migrated {u} users and {s} gameplay records into maze_master.db")
    
    # Verify records in maze_master.db
    db = DatabaseManager()
    leaders = db.get_leaderboard()
    assert len(leaders) > 0, "Migrated scores should appear in leaderboard"
    print("  -> Legacy Migration: PASSED")

if __name__ == "__main__":
    test_security()
    test_database_operations()
    test_migration()
    print("\n==========================================")
    print(">>> ALL PHASE 2 DATABASE TESTS PASSED! <<<")
    print("==========================================")
