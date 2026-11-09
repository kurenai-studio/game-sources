# Playbook — המרת משחק Godot לנייד (מבוסס BloomGrid)

מסמך זה מתאר **תהליך ההמרה** שבוצע על משחק C (BloomGrid) כדי שתוכלו לחזור עליו ביישומים נוספים. לא ייעוץ משפטי.

## תוצאה ב-BloomGrid

| שכבה | מה עשינו |
|------|-----------|
| מנוע | Godot **4.7.x**, feature `Mobile` |
| מסך בסיס | **720×1280** portrait |
| גרפיקה | `renderer/rendering_method=mobile`, `import_etc2_astc=true` |
| מגע | `InputEventScreenTouch` / `Drag` (+ עכבר לדסקטופ) |
| פריסה | `game/layout_fit.gd` + safe area ב-`main.gd` |
| אחסון | `user://` בלבד, בלי רשת |
| ייצוא | AAB לחנות + **APK debug** להתקנה (`tools/export_android_debug.ps1`) |

---

## שלב 1 — קונפיגורציה (`project.godot`)

```ini
[display]
window/size/viewport_width=720
window/size/viewport_height=1280
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=1

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

**גרפיקה:** ציור פרוצדורלי / placeholders מקומיים — בלי טעינת URL. אם תוסיפו טקסטורות, הפעילו דחיסת VRAM ל-ASTC/ETC2 לפני export אנדרואיד.

---

## שלב 2 — פריסה ו-UX נייד

1. **אל תקבעו `origin.y` קבוע** — חשבו לוח + מגש + שורות כפתורים יחד.
2. העתיקו דפוס **`LayoutFit`** (`game/layout_fit.gd`):
   - HUD עליון (~144px)
   - Chrome תחתון (כפתורים מ-`size.y - 132`)
   - מגש בין לוח לכפתורים
3. **Safe area:** `DisplayServer.get_display_safe_area()` מול `get_viewport().get_visible_rect()` — הזזת HUD, שם שחקן וכפתורים.
4. **מגע:** אותה לוגיקה ל-`_press` / `_release` עבור מגע ועכבר.
5. **רטט (אופציונלי):** `Input.vibrate_handheld` רק כש-`OS.has_feature("mobile")`.

טסטים אוטומטיים (headless):

- `layout_phone_fits` — אין חפיפה tray/כפתורים
- `layout_graphics_scale` — גודל תא קריא ב-720×1280 ובמסך קטן

```powershell
godot --headless --path . -s res://tests/run_suite.gd
```

---

## שלב 3 — אבטחה ופרטיות (offline-first)

| בדיקה | BloomGrid |
|--------|-----------|
| `permissions/internet=false` | כן (בכל preset אנדרואיד) |
| `access_network_state=false` | כן |
| אין `HTTPRequest` / shell בקוד משחק | כן |
| נתונים רגישים | רק שיאים + mute + שם מסונן (`local_save.gd`) |
| סינון שם | בלי `@`, URL, `www.` |
| סודות בריפו | `.env` / `.keystore` ב-`.gitignore` |

סריקה סטטית מקומית:

```powershell
py -3 tools/mobile_gate.py
```

**HUMAN STOP:** מפתח release לחנות, AdMob, Publish, שינוי package אחרי רישום — ראו `HUMAN_STOP.md`.

---

## שלב 4 — ייצוא אנדרואיד

1. Godot 4.7 + Android export templates + JDK 17+ + SDK (API 36).
2. **Preset חנות:** `Android` → `build/bloomgrid.aab` (`export_format=1`).
3. **Preset בדיקה:** `Android Debug APK` → `build/bloomgrid-debug.apk` (`export_format=0`).

```powershell
.\tools\export_android_debug.ps1
```

העתקה לשליחה (מחוץ ל-git): למשל `Desktop\משחקים\נייד\<שם-משחק>\`.

---

## שלב 5 — בדיקות לפני מסירה

| סוג | פקודה / מסמך |
|-----|----------------|
| לוגיקה | `python tools/test_core.py` |
| Godot headless | `tests/run_suite.gd` |
| מובייל + אבטחה | `python tools/mobile_gate.py` |
| העתק חנות | `python tools/check_store_copy.py` |
| מכשיר אמיתי | רשימה ב-`docs/MOBILE_PLAY.md` |

---

## תבנית ליישום חדש (צ'קליסט)

- [ ] `project.godot`: 720×1280, mobile renderer, portrait
- [ ] `core/` בלי Node/רשת; `game/` עם מגע + פריסה
- [ ] `layout_fit` (או מקביל) + טסט `layout_*`
- [ ] `export_presets.cfg`: Android API 36, רשת כבויה
- [ ] `local_save` או מקביל — `user://` בלבד
- [ ] `tools/mobile_gate.py` מותאם (או אותו סקריפט עם ROOT)
- [ ] `docs/MOBILE_PLAY.md` + smoke על מכשיר
- [ ] APK debug לבודקים; AAB רק לפני העלאה (אדם)

---

## מה לא להעתיק מ-Windows Desktop

`BloomGrid.exe` הוא preset **Windows Desktop** — חלון רחב עם `aspect=expand` ≠ חוויית טלפון. לבדיקת UI נייד השתמשו ב-APK או Web/PWA (`tools/export_web.ps1`).

---

## קבצי עוגן בריפו BloomGrid

| קובץ | תפקיד |
|------|--------|
| `game/layout_fit.gd` | מתמטיקת פריסה |
| `game/main.gd` | safe area + מגע |
| `tools/mobile_gate.py` | שער אבטחה/מובייל |
| `tools/export_android_debug.ps1` | APK לבדיקה |
| `docs/MOBILE_PLAY.md` | התקנה + smoke |
| `export_presets.cfg` | AAB + APK presets |

עדכון גרסה: 2026-10-17 · BloomGrid `0.2.0`
