# Contributing

How Felterra: Tall Order is versioned and released. For how the code is written and tested, see
[`AGENTS.md`](AGENTS.md); the conventions every Itrium project follows live in the handbook it
links to.

## Versioning

Tall Order follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`, tagged
`v0.0.1`. It's a game, not a library, so "compatible" means what players rely on between
versions:

- their settings and their records (`settings.cfg` and `records.cfg`), and saves once there are
  any
- the systems it runs on: Windows, macOS and Linux, on the processors it's built for

| Bump | When | Example |
| --- | --- | --- |
| **MAJOR** | Something players rely on stops working: older settings, records or saves no longer load, or a system is no longer supported | `1.4.2` → `2.0.0` |
| **MINOR** | Anything new or improved, still compatible | `1.4.2` → `1.5.0` |
| **PATCH** | Bug fixes only | `1.4.2` → `1.4.3` |

The pull request labels since the last release decide it: any `type: feature` or
`type: enhancement` means at least a minor bump, and only `type: bug` means a patch. A breaking
change says so in its pull request description.

While Tall Order is `0.x`, the major number stays at 0: a breaking change bumps **minor**
instead, and everything else bumps **patch**. `1.0.0` is the first version with a promise of
stability.

## Releasing

1. Pick the version (see **Versioning** above) and set `config/version` in `project.godot`, in a
   pull request of its own (`chore/version-0-0-1`). The release checks the tag against it.
2. Once it's merged, tag `main` with an annotated, signed tag, and push it:

   ```sh
   git checkout main && git pull
   git tag -s v0.0.1 -m "Felterra: Tall Order 0.0.1"
   git push origin v0.0.1
   ```

3. The **Release** workflow exports every platform with `tools/export.sh`, attaches the builds
   and their checksums to a **draft** release, and checks every build is there. The builds are
   named without the version, so a link always means the latest:
   `https://github.com/itriumid/felterra-tall-order/releases/latest/download/FelterraTallOrder_macos_universal.zip`.
   The version is in the release, in each app's own metadata, and on the game's title screen.
4. Read the draft. Trim the generated notes to what players would notice (drop changes only to
   Continuous Integration or tooling, and the contributor lists), then **publish it by hand**.

Releases are **immutable** once published: nothing can be attached, replaced or removed. Check
the draft before publishing; a mistake after that means a new version.

A dry run: run the Release workflow by hand (Actions → Release → Run workflow). It exports the
same builds and keeps them as workflow artifacts, without making a release. The **Export** check
does the same on every pull request.

### Builds aren't signed by a publisher

Windows and macOS warn about apps from publishers they don't know, and we're not one they know
yet. The Mac build is signed ad hoc, which lets it run on Apple Silicon, but it isn't notarized.
The README says how to open it on each system.
