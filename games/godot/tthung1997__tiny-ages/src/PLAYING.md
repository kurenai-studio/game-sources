# Tiny Ages

A tiny settlement that lives at the edge of your screen, and grows through the ages. A few villagers, a cave and a fire sit on a thin strip above your taskbar, and the world goes on while you work. Nothing is ever demanded of you: no timers, no penalties, nothing that expires. When something needs a decision, a small light bulb appears, and you answer whenever you like.

This is an early version (0.1.0), for Windows 10/11 (64-bit).

## Run it

1. Unzip the folder anywhere.
2. Double-click `TinyAges.exe`.

There is no installer. The first time, Windows SmartScreen may say the app is "unrecognised", because it is not code-signed. Choose **More info**, then **Run anyway**. The checksum is published with each release if you want to verify the download.

## Playing

- The strip sits at the bottom of your screen, always on top. Clicks pass through the empty parts to whatever is behind it.
- **Click a villager** to see who they are and what they are thinking.
- **The light bulb** (top right of the strip) appears when a decision is waiting. Click it to read it and choose. It waits for you indefinitely, and waiting never costs you anything.
- **The book** opens the journal, the story of your settlement so far.
- **Right-click the strip** for the menu: Journal, Stores, Settings, Quit.
  - **Settings** change how the game sits on your desktop: strip, corner or a normal window; the size; always on top; and which screen.
- **Scroll the world** with the arrows at its edges, the mouse wheel or drag, `A`/`D`, or the arrow keys. `Home` returns to camp.
- `Esc` closes the open panel, or saves and quits. `Q` saves and quits.

The game keeps going while it is closed: time passes at about 20 minutes per day, and when you come back, a short summary tells you what happened. Quitting never loses anything. It saves every minute and when you quit.

## Your save

Your save and settings are two small files in `%APPDATA%\TinyAges\` (`tiny_ages_save.tres` and `settings.cfg`). Delete them to start a new settlement.

## Licence

MIT. See `LICENSE`, and `THIRD_PARTY_NOTICES.md` for the engine and font licences. Source: <https://github.com/tthung1997/tiny-ages>.
