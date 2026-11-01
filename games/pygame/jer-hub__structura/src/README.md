# Structura

A faculty-built [pygame](https://pyga.me/) game that teaches data structures and algorithms to BSIT students. Learners change the structures directly—insert, delete, swap, rotate, trace—across themed Zones with Lessons, Guided and Challenge Puzzles, and a Boss.

Domain vocabulary lives in [`CONTEXT.md`](CONTEXT.md). Agent and contribution conventions are in [`AGENTS.md`](AGENTS.md).

## Requirements

- Python 3.11+
- Windows is the primary target (lab PCs and a one-file `.exe` build)

## Quick start

```powershell
py -m venv .venv
.venv\Scripts\pip install -e ".[dev]"
.venv\Scripts\python main.py
```

On macOS or Linux, use `python3` / `.venv/bin/` instead of `py` / `.venv\Scripts\`.

## Tests

```powershell
.venv\Scripts\python -m pytest -q
```

## Windows executable

Students can run a single `Structura.exe` with no install. See [docs/windows-build.md](docs/windows-build.md).

```powershell
.venv\Scripts\pip install -e ".[build]"
.venv\Scripts\pyinstaller --noconfirm structura.spec
```

The build lands at `dist\Structura.exe`.

## Project layout

| Path | Purpose |
|------|---------|
| `src/structura/` | Game package (models, puzzles, UI, content) |
| `src/structura/content/zones/` | Zone TOML shipped inside the package |
| `tests/` | pytest suite (UI under `SDL_VIDEODRIVER=dummy`) |
| `docs/` | Syllabus notes, ADRs, Windows build, Progress Reports |
| `.scratch/` | Local issue tracker and drafts for agents |

## Instructor docs

- [Recommended syllabus](docs/recommended-syllabus.md)
- [Combining Progress Reports](docs/combining-progress-reports.md)
- [Windows build and lab distribution](docs/windows-build.md)

## License

[MIT](LICENSE)
