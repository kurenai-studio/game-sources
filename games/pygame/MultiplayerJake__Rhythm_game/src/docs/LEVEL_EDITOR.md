# Level Editor

The built-in editor turns any `.mp3` or `.wav` into a playable level. You pick a song,
name it, then tap out the chart in real time while the track plays once.

Open it from the **Main Menu → Create**.

---

## 1. Pick the audio

On the setup screen you can either:

- Click **Browse…** to open a file dialog, **or**
- Paste the full path into the audio field.

If the file dialog is unavailable (some systems), the game tells you and you can paste
the path manually. Supported formats: **`.mp3`** and **`.wav`**.

The audio is copied into `music_levels/music_<name>.<ext>` — your original file is left
untouched.

---

## 2. Name the level

Type a name in the level-name field. It's sanitized for the filesystem. If the name
already exists, the game auto-suffixes it (`_2`, `_3`, …) and **never** overwrites an
existing level.

A `<name>.json` chart file is created alongside the copied audio.

---

## 3. Record the chart

Click **Start Recording**. The song plays from the beginning and you tap the chart as you
hear it:

| You do | You get |
|---|---|
| Quick tap of a lane key (`D` `F` `J` `K`) | A single **note** |
| Hold a lane key for **≥ 400 ms**, then release | A **hold/sustain** note spanning that span |
| Hold **`Ctrl`** while pressing/holding a lane | The note becomes a yellow **boost note** |
| `Backspace` | Remove the last placed note (undo) |

Notes are timestamped from the same music clock used for playback, so what you record is
what plays back.

---

## 4. Save or cancel

- **Stop (`Space`)** — end recording and **save** the level. It now appears in the **Play** list.
- **`Esc`** — cancel and **discard** everything created for this level (chart and copied audio).

---

## Tips

- Do a quick first pass for the main beats, then refine with undo rather than trying to be perfect in one run.
- Sprinkle in `Ctrl` boost notes on the chorus — they're what charge the boost meter.
- Long holds are scored every second you keep the key down, so they're great for sustained sections.
- After saving, jump straight into **Play** and try your chart; the editor and gameplay use identical timing, so it should feel the same.

---

## Where files live

```
music_levels/
├── <level_name>.json          # chart: notes with lane, time, end, boost flag
└── music_<level_name>.mp3     # the copied audio
```

Both must stay together — the Play screen greys out a level whose audio is missing.
