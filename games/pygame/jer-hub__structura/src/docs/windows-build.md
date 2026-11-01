# Building and distributing the Windows build

Structura ships to students as one file, `Structura.exe`. It runs without installing anything and without admin rights.

## Building it

You need Python 3.11 or newer and the Structura source folder. One-time setup, in PowerShell from inside that folder:

```powershell
py -m venv .venv
.venv\Scripts\pip install -e ".[build]"
```

Then, every time you want a new build (for example after changing a Zone file in `src/structura/content/zones/`):

```powershell
.venv\Scripts\pyinstaller --noconfirm structura.spec
```

The result is `dist\Structura.exe`. It contains the game, every Zone and the Code Mirror snippets. Double-click it once to check it opens before handing it out.

## Giving it to students

Copy `Structura.exe` to the lab PCs, a shared drive or the class's Google Classroom. Students double-click it; there is no installer.

- **Windows SmartScreen** may say it "protected your PC" the first time, because the file isn't signed. Click **More info → Run anyway**. Lab administrators can allow it permanently.
- **Antivirus** software sometimes flags programs built this way. If it does, ask your lab administrator to allow `Structura.exe`.
- Each launch takes a few seconds while the game unpacks itself to a temporary folder (antivirus scanning can add more).

## Where student data lives

Nothing is written next to `Structura.exe`, so it can sit in a read-only folder.

- **Profiles and results:** `%APPDATA%\Structura\structura.db`, one per Windows account. Students who share a Windows account on a lab PC each pick their own Profile in the game.
- **Progress Reports:** `Documents\Structura Reports`, where the game tells the student it saved them.

Replacing `Structura.exe` with a newer build keeps everyone's Profiles and results. If your lab PCs wipe user folders when they restart, progress is lost at restart too; students should export a Progress Report before they leave.

To combine the reports students hand in, see [Combining a class's Progress Reports](combining-progress-reports.md).
