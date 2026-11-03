"""
Database & Cryptography Package.
Provides relational persistence via SQLite and PBKDF2 password derivation.
"""

from .db_manager import DatabaseManager
from .security import hash_password, verify_password
from .data_migrator import migrate_legacy_data

__all__ = [
    'DatabaseManager',
    'hash_password',
    'verify_password',
    'migrate_legacy_data'
]
