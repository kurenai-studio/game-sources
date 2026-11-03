"""
SQLite Relational Database Manager.
Manages connections, migrations, transactional queries, and thread safety.
Database file: maze_master.db
"""

import sqlite3
import os
import threading
import sys
import shutil
from typing import Dict, List, Optional, Tuple, Any
from .security import hash_password, verify_password

if getattr(sys, 'frozen', False):
    # Running in a PyInstaller standalone executable bundle
    BASE_DIR = os.path.dirname(sys.executable)
    DB_PATH = os.path.join(BASE_DIR, "maze_master.db")
    if not os.path.exists(DB_PATH) and hasattr(sys, '_MEIPASS'):
        seed_db = os.path.join(sys._MEIPASS, "maze_master.db")
        if os.path.exists(seed_db):
            try:
                shutil.copyfile(seed_db, DB_PATH)
            except Exception:
                pass
else:
    DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "maze_master.db"))

class DatabaseManager:
    """Thread-safe SQLite Database Manager for the Algorithmic Maze Platform."""
    _instances: Dict[str, Any] = {}
    _lock = threading.Lock()

    def __new__(cls, db_path: str = DB_PATH):
        with cls._lock:
            if db_path not in cls._instances:
                instance = super(DatabaseManager, cls).__new__(cls)
                instance._init_db(db_path)
                cls._instances[db_path] = instance
            return cls._instances[db_path]

    def _init_db(self, db_path: str):
        self.db_path = db_path
        self._local = threading.local()
        self.create_tables()

    def get_connection(self) -> sqlite3.Connection:
        """Returns a thread-local SQLite connection with foreign keys enabled."""
        if not hasattr(self._local, "conn") or self._local.conn is None:
            self._local.conn = sqlite3.connect(self.db_path, timeout=10.0)
            self._local.conn.row_factory = sqlite3.Row
            self._local.conn.execute("PRAGMA foreign_keys = ON;")
        return self._local.conn

    def close(self):
        """Closes the thread-local SQLite connection if open."""
        if hasattr(self._local, "conn") and self._local.conn is not None:
            self._local.conn.close()
            self._local.conn = None

    def create_tables(self):
        """Initializes database tables, constraints, and indexes."""
        conn = self.get_connection()
        with conn:
            conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL COLLATE NOCASE,
                password_hash BLOB NOT NULL,
                salt BLOB NOT NULL,
                age INTEGER CHECK(age > 0),
                gender TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS gameplay_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                mode_id INTEGER NOT NULL CHECK(mode_id BETWEEN 0 AND 4),
                grid_size INTEGER NOT NULL,
                time_seconds REAL NOT NULL,
                steps_taken INTEGER NOT NULL,
                generator_algorithm TEXT NOT NULL,
                won BOOLEAN NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS benchmark_runs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                algorithm_name TEXT NOT NULL,
                grid_size INTEGER NOT NULL,
                execution_time_us REAL NOT NULL,
                peak_memory_kb REAL NOT NULL,
                nodes_expanded INTEGER NOT NULL,
                path_length INTEGER NOT NULL,
                optimality_ratio REAL NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS system_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_records_mode ON gameplay_records(mode_id, grid_size, time_seconds);
            CREATE INDEX IF NOT EXISTS idx_bench_algo ON benchmark_runs(algorithm_name, grid_size);
            """)

    # --- User Management ---

    def register_user(self, username: str, password: str, age: int, gender: str = "Unspecified") -> Tuple[bool, str]:
        """Registers a new user with salted PBKDF2 hash. Returns (success, message)."""
        username = username.strip()
        if not username or len(username) < 3:
            return False, "Username must be at least 3 characters long."
        if not password or len(password) < 4:
            return False, "Password must be at least 4 characters long."
        if age < 1 or age > 130:
            return False, "Please enter a valid age."

        key, salt = hash_password(password)
        conn = self.get_connection()
        try:
            with conn:
                conn.execute(
                    "INSERT INTO users (username, password_hash, salt, age, gender) VALUES (?, ?, ?, ?, ?)",
                    (username, key, salt, age, gender)
                )
            return True, "Registration successful."
        except sqlite3.IntegrityError:
            return False, f"Username '{username}' is already taken."
        except Exception as e:
            return False, f"Database error: {str(e)}"

    def authenticate_user(self, username: str, password: str) -> Tuple[bool, Optional[Dict[str, Any]], str]:
        """Authenticates a user. Returns (success, user_dict, message)."""
        username = username.strip()
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()

        if row is None:
            return False, None, "User not found."

        stored_hash = row["password_hash"]
        salt = row["salt"]

        if verify_password(password, stored_hash, salt):
            user_data = {
                "id": row["id"],
                "username": row["username"],
                "age": row["age"],
                "gender": row["gender"]
            }
            return True, user_data, "Login successful."
        else:
            return False, None, "Incorrect password."

    def get_user_by_name(self, username: str) -> Optional[Dict[str, Any]]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, age, gender FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()
        return dict(row) if row else None

    # --- Gameplay Records ---

    def save_gameplay_record(
        self,
        user_id: int,
        mode_id: int,
        grid_size: int,
        time_seconds: float,
        steps_taken: int = 0,
        generator_algorithm: str = "kruskal",
        won: bool = True
    ) -> int:
        """Saves a completed gameplay record. Returns the new record ID."""
        conn = self.get_connection()
        with conn:
            cursor = conn.execute(
                """
                INSERT INTO gameplay_records 
                (user_id, mode_id, grid_size, time_seconds, steps_taken, generator_algorithm, won)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (user_id, mode_id, grid_size, time_seconds, steps_taken, generator_algorithm, won)
            )
            return cursor.lastrowid

    def get_leaderboard(
        self,
        mode_id: Optional[int] = None,
        grid_size: Optional[int] = None,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Retrieves sorted leaderboard records with player usernames."""
        conn = self.get_connection()
        cursor = conn.cursor()

        query = """
            SELECT 
                r.id,
                u.username,
                r.mode_id,
                r.grid_size,
                r.time_seconds,
                r.steps_taken,
                r.generator_algorithm,
                r.won,
                r.created_at
            FROM gameplay_records r
            JOIN users u ON r.user_id = u.id
            WHERE r.won = 1
        """
        params = []
        if mode_id is not None:
            query += " AND r.mode_id = ?"
            params.append(mode_id)
        if grid_size is not None:
            query += " AND r.grid_size = ?"
            params.append(grid_size)

        query += " ORDER BY r.time_seconds ASC, r.steps_taken ASC LIMIT ?"
        params.append(limit)

        cursor.execute(query, tuple(params))
        rows = cursor.fetchall()
        return [dict(row) for row in rows]

    # --- Benchmark Records ---

    def save_benchmark_run(
        self,
        algorithm_name: str,
        grid_size: int,
        execution_time_us: float,
        peak_memory_kb: float,
        nodes_expanded: int,
        path_length: int,
        optimality_ratio: float
    ) -> int:
        conn = self.get_connection()
        with conn:
            cursor = conn.execute(
                """
                INSERT INTO benchmark_runs
                (algorithm_name, grid_size, execution_time_us, peak_memory_kb, nodes_expanded, path_length, optimality_ratio)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (algorithm_name, grid_size, execution_time_us, peak_memory_kb, nodes_expanded, path_length, optimality_ratio)
            )
            return cursor.lastrowid

    def get_benchmark_history(self, limit: int = 200) -> List[Dict[str, Any]]:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT * FROM benchmark_runs 
            ORDER BY created_at DESC LIMIT ?
            """,
            (limit,)
        )
        return [dict(r) for r in cursor.fetchall()]

    # --- System Settings Store ---

    def set_setting(self, key: str, value: str):
        conn = self.get_connection()
        with conn:
            conn.execute("INSERT OR REPLACE INTO system_settings (key, value) VALUES (?, ?)", (key, str(value)))

    def get_setting(self, key: str, default: str = "") -> str:
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM system_settings WHERE key = ?", (key,))
        row = cursor.fetchone()
        return row["value"] if row else default
