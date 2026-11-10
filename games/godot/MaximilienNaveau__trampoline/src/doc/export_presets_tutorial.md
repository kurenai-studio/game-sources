# Rebuilding/validating `export_presets.cfg` through the editor

`export_presets.cfg` (at the repository root) was hand-authored
because there's no local Android/iOS/macOS toolchain here to generate it the
normal way. This tutorial uses the *editor's own Export dialog* to validate
(and fix) that file — Godot parses whatever's on disk, so anything it
misunderstood will show up as a missing preset or an empty field, not a
crash. Do this once, save, and the file becomes the real, editor-verified
source of truth going forward — no more guessing at field names.

Do this from a normal `nix develop` shell at the repository root, running
`godot4 --editor --path .` — the `--editor` flag matters: `godot4 --path .`
alone runs the game itself (same as pressing Play), it's `--editor` that
opens the editor UI instead.

## 1. Open the Export dialog

**Project menu → Export...**

The left column lists presets. Because `export_presets.cfg` already exists,
you should see **5 presets already there**: `Linux`, `Android`, `macOS`,
`Web`, `iOS`.

- **If all 5 are there** → good, continue to step 2, reviewing each.
- **If the list is empty, or fewer than 5 show up** → stop here and tell me
  exactly what you *do* see. That means Godot rejected the structure of one
  of my `[preset.N]` sections outright (not just an unrecognized option
  inside it), which is worth me looking at directly rather than
  re-guessing blind.

Ignore any small red/yellow warning icon next to a preset's name — that
just means the export *template* for that platform isn't downloaded here,
which is expected and fine. We're not exporting locally, only editing the
preset's settings.

## 2. How to check/set a field

Each preset's settings live in a scrollable panel on the right, organized
into collapsible categories (Version, Package, Screen, Keystore, ...).
Rather than hunting through categories, use the **filter/search box** at
the top of that options panel — type part of a field's name (e.g. `unique
name`) and it'll jump straight to it regardless of which category it's
filed under.

The **Export Path** field is the one exception — it's not inside that
options panel, it's its own text field near the top of the preset's panel,
right below the preset's name. You can type directly into it; the folder
doesn't need to exist yet.

## 3. Linux

Select the **Linux** preset.

- **Export Path** should read `build/linux/trampoline.x86_64`.
- Search `architecture` → should be `x86_64`.
- Search `embed pck` → **leave unchecked** (a separate `.pck` file next to
  the executable is fine; the release workflow zips them together anyway).

Nothing else on this one needs touching.

## 4. Android

Select the **Android** preset.

- **Export Path** should read `build/android/trampoline.apk`.
- Search `use gradle build` → should be **checked (on)**. Godot 4 can only
  export Android through a Gradle build, which is exactly why the release
  workflow uses the `barichello/godot-ci` Docker image (it bundles the
  Android SDK/NDK/JDK/Gradle this needs).
- Search `export format` → should be **APK** (not AAB).
- Search `unique name` (under Package) → should be `com.magamajo.trampoline`
  — reused from the Unity build (`../trampoline`) so a signed Godot build
  could eventually replace it as an update to the same install, not a
  separate app.
- Search `code` (under Version) → **Version/Code** should be `4000000`.
  This is deliberately far above the Unity build's last shipped versionCode
  (`3002000`, using the same `MAJOR*1_000_000 + MINOR*1_000 + PATCH`
  scheme) so this reads as an *upgrade*, not a downgrade, to anyone who
  already has the Unity APK installed. Bump by the same formula, offset by
  `+4_000_000`, for each future Godot release.
- Search `version` (under Version) → **Version/Name** should be `0.1.0`.
- Search `immersive` → should be **checked**.
- Search `keystore` → **leave every field here blank**. Godot automatically
  falls back to its own bundled debug keystore when these are empty —
  that's the "debug-signed for now" choice from the release plan. Real
  release signing is a deliberate later step, not something to set up here.

## 5. macOS

Select the **macOS** preset.

- **Export Path** should read `build/macos/trampoline.zip`.
- Search `bundle identifier` → should be `com.magamajo.trampoline`.
- Search `version` (under Application) → both **Short Version** and
  **Version** should read `0.1.0`.
- Search `codesign` → the **Codesign** dropdown should be **Disabled**.
  This one matters: the release workflow cross-exports macOS from a *Linux*
  container (Godot ships a prebuilt macOS app template, so no compilation
  needed), which has no `codesign` tool at all — "Ad-Hoc" here would make
  that export step fail outright. Disabled means a genuinely unsigned
  `.app`; Gatekeeper will need a manual right-click-open the first time
  it's launched. Real notarization is out of scope for now.

## 6. Web

Select the **Web** preset.

- **Export Path** should read `build/web/index.html`.
- Nothing else needs changing — the project already targets the GL
  Compatibility renderer, which the default Web export options already
  match.

## 7. iOS

Select the **iOS** preset.

- **Export Path** should read `build/ios/trampoline.ipa`.
- Search `bundle identifier` → should be `com.magamajo.trampoline`.
- Search `version` (under Application) → both **Short Version** and
  **Version** should read `0.1.0`.
- Search `export project only` → should be **checked**. This is the
  important one: with no Apple Developer account/signing identity
  available yet, this makes Godot stop right after writing out the Xcode
  project instead of attempting to sign and archive a real `.ipa` (which
  would otherwise just fail with no identity configured). The release
  workflow zips this project directory directly — opening it in Xcode and
  signing it locally is left to whoever actually ships to a device.
- Search `orientation` → **Portrait** checked, **Landscape Left**,
  **Landscape Right**, and **Portrait Upside Down** all unchecked (matches
  the project's own portrait-first design, see `project.godot`).

## 8. Save and verify

Godot writes `export_presets.cfg` back to disk as you edit these fields —
there's no separate "Save" button to hunt for. As a safety net, click
**Close** at the bottom of the dialog when you're done with all 5 presets.

Then, from a shell:

```
git diff export_presets.cfg
```

Whatever shows up there is the real, ground-truth correction to whatever I
hand-wrote — bring that back so the two release/CI workflow files can be
updated if anything (especially a preset *name*, which both workflows
reference literally) changed.

One more side effect to know about: opening the full editor UI (as opposed
to `--headless`) on this project will likely also rewrite `project.godot`
itself — Godot tends to strip out hand-written comments there the same way
it did once already this session. Run `git diff project.godot`
too, and if it just shows lost comments with no real setting changes,
`git restore` it before committing anything.
