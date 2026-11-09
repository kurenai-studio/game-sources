# משחק מהטלפון — BloomGrid

BloomGrid בנוי לנייד ב-Godot: viewport **720×1280**, אוריינטציה אנכית, מגע (`InputEventScreenTouch`), רנדרר `mobile`, ופריסה דינמית (`game/layout_fit.gd`) עם safe area ומגש מעל שורות הכפתורים.

תהליך המרה לשימוש חוזר בפרויקטים אחרים: [`MOBILE_CONVERSION_PLAYBOOK.md`](MOBILE_CONVERSION_PLAYBOOK.md). שער אבטחה/מובייל: `py -3 tools/mobile_gate.py`.

## אנדרואיד (מומלץ לשחקנים)

1. התקן [Godot 4.7](https://godotengine.org/) ו־Android build template (Editor → Manage Export Templates).
2. התקן JDK 17+ ו־Android SDK; ב־Godot: Editor → Editor Settings → Export → Android.
3. **APK לבדיקה מקומית** (preset `Android Debug APK`):

```powershell
cd C:\Users\noam1\Documents\game-c-bloomgrid
.\tools\export_android_debug.ps1
```

הקובץ: `build\bloomgrid-debug.apk` — העבר לטלפון והתקן (מקור לא ידוע מותר).

4. **AAB לחנות** (לא Publish בלי HUMAN_STOP):

```powershell
godot --headless --export-release "Android" build\bloomgrid.aab
```

## בדיקה על מכשיר (smoke)

אחרי התקנת APK:

- [ ] מסך פתיחה: HUD, לוח, מגש שלושה חלקים — בלי חיתוך מתחת ל-notch או מעל כפתורי מערכת
- [ ] גרירת חלק ללוח, שחרור, ניקוי שורה/עמודה
- [ ] Spin (עד 2), Classic / Race, Restart
- [ ] Scores, Privacy (סגירה במגע), Mute
- [ ] Game over + Play again
- [ ] Race: שעון וסיום TIME UP

## דפדפן (בלי חנות)

1. הוסף Web export template ב־Godot.
2. הרץ:

```powershell
.\tools\export_web.ps1
```

3. העלה תיקיית `build/web/` ל-GitHub Pages או לכל שרת סטטי.
4. פתח בכרום/ספארי בנייד; הוסף למסך הבית (PWA) אם תרצה.

## בדיקה מהירה על אותו Wi‑Fi

```powershell
python -m http.server 8792 --directory build\web
```

בטלפון: `http://<כתובת-IP-של-המחשב>:8792`
