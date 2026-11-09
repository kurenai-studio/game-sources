# BloomGrid — משחק C — Cursor Agent bootstrap (סעיף 12)

מוצר נפרד מקונסול Hub, מהזמנות RSVP, ומווידג'ט משימות.

מנוע: **Godot 4.7.x**. יעד: Android **API 36**. ז'אנר: hybrid-casual block-puzzle (8×8, מגש 3 חלקים, בלי סיבוב). מודל: **retention לפני ads**.

## ארכיטקטורה

- `core/` — `RefCounted` בלבד. אסור: Node, Input, Audio, HTTP, קבצים.
- `game/` — shell: ציור, מגע, placeholders.
- `tests/run_suite.gd` — הרצה headless בלי אדם.
- AdMob (Poing Studios v5 Mock) **רק שלב L**. לא עכשיו.

## לולאה אוטונומית (מותר בלי לשאול)

1. שנה `core/` + טסטים.
2. `godot --headless --path . -s res://tests/run_suite.gd` וגם `python tools/test_core.py`.
3. תקן עד ירוק.
4. עדכן `game/` כדי שישאר playable.

## חובה לעצור ולשאול (HUMAN STOP)

- תשלום ל-Google Play Console
- פרטי כניסה / מפתחות AdMob חיים
- גיוס 12 בודקים אמיתיים / Closed Testing 14 יום
- לחיצת Publish
- הורדת אסטים חיצוניים או plugins (כולל AdMob)
- שינוי שם חבילה אחרי הרשמה ב-Play
- תוכן בתשלום / IAP

## שלבים

| שלב | מצב יעד |
|---|---|
| A | ריפו + Godot 4.7 |
| B | core + טסטים ירוקים |
| C | shell שולחן עבודה — אפשר לשחק |
| D | placeholders מקומיים (בלי הורדות) |
| E | export Android API 36 (קונפיג בלבד) |
| F | Play listing draft — **שאל אדם** |
| L | AdMob plugin — **שאל אדם** |

מחקר 9/2026: הורדות −7% ב-2025; Block Blast מאומת; virality אורגני קשה; Closed Testing 12×14 יציב.
