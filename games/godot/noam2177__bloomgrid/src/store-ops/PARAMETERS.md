# פרמטרי חנות — BloomGrid (ספט׳ 2026)

לא ייעוץ משפטי. זהות: `com.bloomgrid.gamec` · BloomGrid · `0.2.0` / build `2`.

**מחקר (רשמי):** Data safety — עיבוד מקומי בלי יציאה מהמכשיר **לא** מדווח כ-collected. עדיין חובה טופס + URL מדיניות + טקסט בתוך האפליקציה. הליסטינג מתאר רק את הבילד הנוכחי.

## Play — ליסטינג

| שדה | תקן | כאן |
|---|---|---|
| שם | ≤30 | BloomGrid |
| Short / Full | ≤80 / ≤4000 | `listing/PLAY.md` |
| אייקון | 512×512 PNG + alpha, ≤1MB, ריבוע מלא | `assets/play/icon-512.png` |
| Feature | 1024×500, בלי alpha | placeholder — חסר טקסט |
| צילומים | 2–8, בלי alpha, 320–3840, יחס ≤2:1 | placeholders, לא צילום חי |
| קטגוריה | Games / Puzzle | Puzzle |
| מדיניות | URL ציבורי, לא PDF | טיוטה בלבד |
| Support URL | אופציונלי | חסר |
| אימייל | חובה בחשבון | אדם |

## Play — מדיניות

| שדה | ערך לבילד הזה |
|---|---|
| Target API | 36 (חובה להעלאה אחרי 31.8.2026) |
| חבילה | AAB + Play App Signing |
| Data safety | לא נאסף (מקומי בלבד) — `forms/DATA_SAFETY.md` |
| מודעות / IAP | No |
| קהל | לא Families; 13+ בקונסול |
| IARC | `forms/CONTENT_RATING.md` |
| Closed test | 12×14 — HUMAN STOP |
| חשבון | $25 + אימות — HUMAN STOP |

## Apple

| שדה | תקן | כאן |
|---|---|---|
| שם / Subtitle / Promo | ≤30 / ≤30 / ≤170 | `listing/APPLE.md` |
| Keywords | ≤100, פסיקים בלי רווח | שם |
| תיאור | ≤4000 | שם |
| Support + Privacy URL | חובה, דפים חיים | חסר |
| אייקון | 1024×1024, בלי שקיפות | `assets/apple/icon-1024.png` |
| צילום 6.9" | 1260×2736 / 1290×2796 / 1320×2868, בלי alpha | placeholders |
| iPad 13" | רק אם רץ על iPad | iPhone-only ב-export |
| SDK | iOS 26 / Xcode 26 מ-28.4.2026 | Mac |
| Privacy labels | Data Not Collected | `forms/APPLE_PRIVACY.md` |
| גיל | שאלון 2026 | `forms/APPLE_AGE_RATING.md` |
| הצפנה | ITSAppUsesNonExemptEncryption=false | ב-preset |
| חשבון | $99/שנה | HUMAN STOP |

## קוד (בילד אופליין)

אין INTERNET. שמירה מקומית: שיא, mute, שם אופציונלי מסונן (בלי `@` / URL). שלב L (מודעות) דורש עדכון כל הטפסים לפני העלאה.
