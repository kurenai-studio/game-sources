# Releasing

This project does **not** use automated CI/CD. Releases are built and
published **manually** by the maintainer, which keeps the pipeline simple and
gives full control over what is shipped.

## What we ship

Portable, self-contained builds produced by `scripts/build.sh` /
`scripts/build.ps1`:

| Artifact | Description |
|---|---|
| `Breakout.love` | Portable game package (runs on any OS with LÖVE) |
| `Breakout-linux-x86_64.tar.gz` | Linux bundle: LÖVE AppImage + game + launcher |
| `Breakout-win64\Breakout.exe` | Self-contained Windows executable (no install) |
| `Breakout-win64.zip` | Zipped Windows portable build |

## Manual release checklist

1. **Update the changelog** — move the `[Unreleased]` section in
   `CHANGELOG.md` to the new version.
2. **Build the artifacts**:
   ```bash
   ./scripts/build.sh 0.1.0            # Linux/macOS
   ```
   or on Windows:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\build.ps1
   ```
3. **Smoke test** the artifacts before publishing:
   - `love dist/Breakout.love`
   - unpack the Linux tarball and run the launcher
   - run `dist/Breakout-win64/Breakout.exe` (Windows)
4. **Commit and tag**:
   ```bash
   git add CHANGELOG.md
   git commit -m "chore(release): v0.1.0"
   git tag v0.1.0
   git push origin main --tags
   ```
   > Build artifacts (`dist/`) are git-ignored; they are uploaded to the
   > GitHub Release, not committed to the repository.
5. **Create the GitHub Release** (GitHub UI):
   - Tag: `v0.1.0` (already pushed)
   - Title: `v0.1.0`
   - Notes: summary of changes (from `CHANGELOG.md`)
   - Attach the portable artifacts: `Breakout.love`,
     `Breakout-linux-x86_64.tar.gz`, `Breakout-win64.zip`.

## Versioning

Follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.
Breaking changes bump MAJOR, new features bump MINOR, fixes bump PATCH.