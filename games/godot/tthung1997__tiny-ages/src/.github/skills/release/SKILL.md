---
name: release
description: Cut and publish a Tiny Ages release (the downloadable Windows build on GitHub Releases). Use when asked to release, publish, ship, tag or cut a version, bump the version, or make a new download available. Covers the version bump, the tag that triggers publishing, verifying the result, and recovering from a failed run.
---

# Releasing Tiny Ages

A release is a git tag. Pushing a tag like `v0.2.0` runs `.github/workflows/release.yml`, which installs
Godot, runs the full check, builds the Windows zip and publishes a GitHub Release with the zip, its
SHA-256 and generated notes. Nothing is built or uploaded by hand.

## Is it time?

`pwsh -File game/tools/release_check.ps1` gives a suggestion from simple rules, run whenever a PR is opened
or merged (the `pull-request` skill does it). It counts changes since the last tag that touch files a player gets (`game/scripts`,
`scenes`, `assets`, `resources`, `project.godot`, the icon): **none** means no release; a **fix** in a small
batch means a patch; **3 or more** changes, or **14 or more days** with any, means a minor release;
otherwise "not yet". It also warns when the saved world (`game/scripts/sim/state/`) changed, because saves
have no migration. The thresholds are constants at the top of the script. It is a heuristic: it cannot see
how big a change is or whether `main` is stable, so judge on top of it (the `pull-request` skill lists
what to consider). Do not release just because the count is reached; release when a theme is done, a fix
matters, or the user wants it.

## Before you start

1. `main` is the commit to release, and its last change is merged. Check `git status` is clean and you are
   on an up-to-date `main`.
2. The last pull request's check (the same workflow run as a dry run) was green. Look at
   `gh run list --workflow release.yml --limit 3`.
3. Decide the version. It is `0.MINOR.PATCH` while the game is early: a new age or a feature players will
   notice bumps MINOR; fixes bump PATCH. Go to 1.0.0 only when the user says so.

## Steps

1. **Bump the version.** `config/version` in `game/project.godot` is the only place. The exe's file and
   product version follow it (the values in `game/export_presets.cfg` stay empty on purpose).
2. **Land it** with the usual flow: branch from `main`, commit, `gh pr create`, wait for the run, then
   squash merge. Use the commit message `Release X.Y.Z`.
3. **Tag the merge commit** on `main` and push the tag:

   ```
   git switch main && git pull
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

   The workflow refuses a tag that does not equal `v` plus `config/version`.
4. **Watch the run**: `gh run watch` (about 4 to 8 minutes; the first run after a cache miss is slower).
5. **Verify the release** before telling the user it is done:
   - `gh release view vX.Y.Z --repo tthung1997/tiny-ages` lists `TinyAges-X.Y.Z-windows.zip` and its
     `.sha256`.
   - Download the zip from the release URL with `curl -L` (no token) and compare its SHA-256 with the
     `.sha256` file.
   - Optionally unzip and run `TinyAges.exe -- --nosave --new --shot=<png>` to see that it starts.
6. **Tell the user** the release URL, the version, and what changed since the last release.

The release notes are `.github/release-notes.md` (install text, SmartScreen, save folder, checksum) followed
by GitHub's generated list of merged PRs. Edit the release afterwards with `gh release edit` if the user
wants hand-written highlights.

## Building by hand (rarely needed)

`pwsh -File game/tools/build_release.ps1` produces `game/build/TinyAges-<version>-windows.zip` and its
`.sha256` locally. It needs the Godot console build in `$env:GODOT` and the Windows export templates;
`pwsh -File game/tools/install_godot.ps1` installs both, verified against Godot's published checksums.
Use it to try a build, not to publish.

## If something goes wrong

- **Tag does not match the version.** Delete the tag (`git push origin :refs/tags/vX.Y.Z`, then
  `git tag -d vX.Y.Z`), fix `config/version` through a PR, and tag again.
- **The run failed after the tag was pushed** (tests, build, download). No release was published, because
  publishing is the last step. Fix the cause through a PR, then move the tag: delete it as above and tag
  the new `main` commit.
- **A release is wrong.** `gh release delete vX.Y.Z --cleanup-tag --yes`, fix, and release again. Prefer a
  new PATCH version over reusing a number that people may already have downloaded.
- **Godot upgrade.** The version `4.7.1` is written in `.github/workflows/release.yml` (the cache path and
  the install step) and as the default in `game/tools/install_godot.ps1`. Change all of them together with
  the project's `config/features`, and run the dry run on a PR before releasing.

## Things not to do

- Do not commit a build, an `.exe` or a zip. `game/build/` is ignored.
- Do not put signing keys or tokens in the repo. The workflow uses only the built-in `GITHUB_TOKEN`.
- Do not push a tag from a commit that is not on `main`.
- New commits use the GitHub noreply address (`19512458+tthung1997@users.noreply.github.com`); check
  `git config user.email` in a fresh clone before committing.
- The build is not code-signed, so Windows SmartScreen warns on first run. Do not claim otherwise.
