"""
Shinrin CS — Merkezi Loglama Sistemi.

Tüm modüller bu fabrika fonksiyonunu kullanarak
tutarlı formatta log üretir.
"""

import logging
import os
from datetime import datetime


def get_logger(name: str) -> logging.Logger:
    """
    İsimlendirilmiş bir logger oluşturur veya var olanı döndürür.

    Args:
        name: Logger adı (genellikle modül adı).

    Returns:
        Yapılandırılmış Logger nesnesi.
    """
    logger = logging.getLogger(f"ShinrinCS.{name}")

    if not logger.handlers:
        logger.setLevel(logging.DEBUG)

        # ── Konsol Handler ──
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        console_fmt = logging.Formatter(
            "[%(levelname)s] %(name)s: %(message)s"
        )
        console_handler.setFormatter(console_fmt)
        logger.addHandler(console_handler)

        # ── Dosya Handler ──
        log_dir = os.path.join(os.path.dirname(__file__), "..", "logs")
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(
            log_dir,
            f"shinrin_cs_{datetime.now().strftime('%Y%m%d')}.log"
        )
        file_handler = logging.FileHandler(log_file, encoding="utf-8")
        file_handler.setLevel(logging.DEBUG)
        file_fmt = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        file_handler.setFormatter(file_fmt)
        logger.addHandler(file_handler)

    return logger
