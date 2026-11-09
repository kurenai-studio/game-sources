"""Validate store listing character limits."""
from __future__ import annotations

LIMITS = {
    "play_name": 30,
    "play_short": 80,
    "play_full": 4000,
    "apple_name": 30,
    "apple_subtitle": 30,
    "apple_promo": 170,
    "apple_keywords": 100,
    "apple_desc": 4000,
}

COPY = {
    "play_name": "BloomGrid",
    "play_short_en": "Place 3 pieces on an 8x8 grid. Clear lines. Combos and supernovas.",
    "play_short_he": "פאזל חלל: גרור 3 חלקים, נקה שורות ועמודות, צבור קומבו.",
    "apple_subtitle_en": "Space block puzzle",
    "apple_subtitle_he": "פאזל בלוקים בחלל",
    "apple_promo_en": (
        "Offline 8x8 block puzzle. Place three pieces, clear rows and columns, "
        "chain combos, hit a supernova. No account."
    ),
    "apple_keywords": "block,puzzle,casual,offline,space,grid,combo,relaxing",
}


def main() -> None:
    checks = [
        ("play_name", COPY["play_name"], LIMITS["play_name"]),
        ("play_short_en", COPY["play_short_en"], LIMITS["play_short"]),
        ("play_short_he", COPY["play_short_he"], LIMITS["play_short"]),
        ("apple_subtitle_en", COPY["apple_subtitle_en"], LIMITS["apple_subtitle"]),
        ("apple_subtitle_he", COPY["apple_subtitle_he"], LIMITS["apple_subtitle"]),
        ("apple_promo_en", COPY["apple_promo_en"], LIMITS["apple_promo"]),
        ("apple_keywords", COPY["apple_keywords"], LIMITS["apple_keywords"]),
    ]
    bad = 0
    for name, text, lim in checks:
        n = len(text)
        ok = n <= lim
        print(f"{'OK' if ok else 'FAIL'} {name}: {n}/{lim}")
        if not ok:
            bad += 1
    raise SystemExit(bad)


if __name__ == "__main__":
    main()
