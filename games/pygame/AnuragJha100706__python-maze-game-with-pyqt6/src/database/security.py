"""
Cryptographic Security & Password Derivation Module.
Implements PBKDF2-HMAC-SHA256 with 100,000 iterations and 16-byte cryptographically secure salts.
Mitigates rainbow tables, dictionary attacks, and precomputation hazards.
"""

import os
import hashlib
import hmac
from typing import Tuple

ITERATIONS = 100_000
ALGORITHM = 'sha256'
SALT_LENGTH = 16

def hash_password(password: str, salt: bytes = None) -> Tuple[bytes, bytes]:
    """
    Derives a cryptographic key from plaintext password using PBKDF2-HMAC-SHA256.
    Returns (derived_key, salt).
    """
    if salt is None:
        salt = os.urandom(SALT_LENGTH)
    key = hashlib.pbkdf2_hmac(
        ALGORITHM,
        password.encode('utf-8'),
        salt,
        iterations=ITERATIONS
    )
    return key, salt

def verify_password(password: str, stored_hash: bytes, salt: bytes) -> bool:
    """
    Verifies a plaintext password against a stored derived key and salt using constant-time comparison.
    """
    computed_key, _ = hash_password(password, salt)
    return hmac.compare_digest(computed_key, stored_hash)
