# Release and build notes

Forkline is built with Godot 4.7.2 (standard build). Run everything from Git Bash unless a step says PowerShell.

## Build the debug APK

From the repo root, in a fresh clone or a fresh `git worktree`, one command does it all:

```bash
bash scripts/build.sh
```

PowerShell does the same:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1
```

The script:

1. Checks that Godot is version 4.7.2.stable. It uses `godot` on PATH, or the GODOT environment variable.
2. Checks that the working tree is clean (see "Build from a clean tree" below) and prints the commit it builds.
3. Imports the project. The first import of a fresh project can crash or stop early, so the script reruns it (up to 3 tries) until `.godot/global_script_class_cache.cfg` exists. You do not run the import yourself.
4. Exports `build/forkline-debug.apk` with a private temp folder (`build/tmp.*`, removed afterwards). It retries a failed export up to 3 times.
5. Counts the build as good only when Godot exited 0 and the APK is new, over 1 MB and a valid zip.

On any failure it prints `BUILD FAILED: ...` and exits 1. It never reports success without an APK. If you pipe the output (for example to `tail`), check the exit code too: use `set -o pipefail`, or look for the `Built` line.

Each Godot import and export is limited by a timeout (300 s and 600 s).

## Build from a clean tree

`build.sh`, `build.ps1` and `build_release.sh` export the files in the folder they are in. If that folder holds uncommitted work, the APK would contain code that no commit has, and `check_apk.sh` would still pass it, because it compares the APK with the same folder. So the scripts refuse to build when `git status --porcelain` shows a changed tracked file or an untracked file that git does not ignore (`build/`, `.godot/` and `android/` are ignored). The message says to commit, or to build from a clean clone. The commit being built is printed at the start, for the release notes. `bash scripts/check_clean.sh` runs just this check.

- Local test on your own phone: `bash scripts/build.sh --allow-dirty` (PowerShell: `-AllowDirty`). It prints a warning. Never publish such a build.
- `build_release.sh` has no such option and rejects every option. It also refuses a folder that has no `.git`, because it cannot check one.
- `build.sh` accepts a folder with no `.git`, such as a copy made with `git archive`, and says so. That copy holds only what the commit holds.

`bash scripts/test_check_clean.sh` tests all of this in a scratch git repo with a stand in for Godot. It never touches the real repo.

## Why the private temp folder

Godot writes its temporary export files to the shared temp folder, named with the clock in whole seconds (`tmpexport-unaligned.<unix seconds>.apk`). Two exports that start in the same second overwrite each other, and one fails with "Could not unzip temporary unaligned APK". Other Godot projects on this machine, or two builds of Forkline at once, can hit this. Pointing TEMP and TMP at a folder inside `build/` for the export step avoids it. The retry covers any other one-off failure.

## Build in a fresh worktree

This is the way to build while other work is uncommitted in the main folder.

```bash
git worktree add --detach "$TEMP/fl_try" HEAD
cd "$TEMP/fl_try"
bash scripts/build.sh
```

Then clean up:

```bash
cd /path/to/forkline
git worktree remove --force "$TEMP/fl_try"
git worktree prune
```

A worktree has only what is committed. Commit script changes first, or the build uses the old script.

## Check and install

```bash
bash scripts/check_apk.sh     # bundled parts, credits, no permissions
bash scripts/install.sh       # needs exactly one ready phone on USB
```

PowerShell has `scripts\install.ps1`.

## Check a release APK

```bash
bash scripts/check_apk.sh --release path/to/forkline-release.apk
```

`--release` adds two checks. First, `android:debuggable` must be absent or an explicit false (`=false` or `(type 0x12)0x0`). True, `0x1`, a reference or any other value fails. Second, the APK must not be signed with the Android debug certificate (`CN=Android Debug`). The signer is read with `apksigner` (SDK build-tools, or on PATH), or else `keytool` (on PATH or in `JAVA_HOME`). If neither is found, the check fails instead of passing. The debug APK is debuggable and debug-signed on purpose, so the default mode only prints notes. Play also refuses debuggable uploads. The release build below is signed with the upload key.

## The release build (signed AAB and APK)

Bart approved Play App Signing on 2026-10-27. Google holds the app signing key. We hold only an upload key, and Play checks every upload against it.

```bash
bash scripts/build_release.sh     # build/forkline-release.aab and build/forkline-release.apk
bash scripts/check_aab.sh         # the checks for the bundle
bash scripts/check_apk.sh --release build/forkline-release.apk
bash scripts/check_secrets.sh     # no key or password in the repo
```

The script does what `build.sh` does (version check, import with retries, a private temp folder), then installs Godot's Android build template into `android/` the first time, and exports two files with Godot's Gradle build:

| File | What it is |
|---|---|
| build/forkline-release.aab | The app bundle that Play Console takes. Signed with the upload key. |
| build/forkline-release.apk | A release APK for checking the release build on a phone. Same key, native code compressed. It is not attached to GitHub test builds (see below). |

Publish only a build made from a clean checkout of the tagged commit. A clean clone is the simplest way: `git clone <repo> <folder>`, `git checkout <tag or sha>`, then run the script there. The script prints the commit.

Both have package `io.github.bartbasi.forkline`, version code and name from `export_presets.cfg` (now 1 and 0.1), arm64-v8a only, no permissions, and the same immersive and portrait settings as the debug APK. The bundle keeps the game files in an install time asset pack (`assetPackInstallTime/assets/`), which is how Godot lays out a Gradle bundle.

Raise `version/code` in all three presets of `export_presets.cfg` for every upload. Play refuses a code it has seen. The version name is what players read.

What you need on the machine: Godot 4.7.2 with its export templates (the Android source template `android_source.zip` is part of them), the Android SDK with build tools 36.1.0 and platform 36, and JDK 17, set in Godot's Editor Settings. Gradle downloads its own tools and libraries the first time (about a minute, into your Gradle cache, outside the repo). That is build tooling only. The app has no network code and requests no permissions.

`android/` (about 1 GB with the Gradle output) is ignored by git, as is `build/`. Delete `android/` any time to get a fresh template. The script reinstalls it when the Godot version changes.

### Where the upload key lives

The key is not in the repo and never goes in it.

| Item | Place |
|---|---|
| Keystore | `%APPDATA%\Forkline\release\forkline-upload.keystore` |
| Password | `%APPDATA%\Forkline\release\forkline-upload.password` (one line, readable only by the current Windows user) |
| Key alias | `forkline-upload` (not a secret, it is in `build_release.sh`) |
| Certificate | CN=Play Inc, O=Play Inc. RSA 4096, valid 30 years from 2026-10-27. |
| SHA-256 fingerprint | AF:29:63:CB:E5:D2:D6:6E:82:69:E2:17:68:0B:A9:AA:71:80:38:81:56:8A:A1:32:38:FE:19:AD:47:20:9B:36 |

The fingerprint is public. Play Console shows it after the first upload, and it must be the same. `check_aab.sh` and `check_apk.sh --release` print the fingerprint of the signed file, and `check_aab.sh` fails if it differs from the key in the folder.

`build_release.sh` hands the key to Godot through the environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, only for the export commands. It never prints the password. `export_presets.cfg` holds no keystore path, user or password for release. Godot 4.7.2 gives the password to its Gradle process on the Gradle command line, so for the minutes of a release export it can be read by other programs the same Windows user runs. So: never run the release export with `--verbose` (`build_release.sh` does not, and must not get that flag), do not share build logs, and run no process listing or screen recording during it. The password is never printed or written anywhere by the script. `scripts/check_secrets.sh` fails if a tracked file (or a file git would add) has one, a key file name, or the real password. The build script runs it first. Godot's own editor can write credentials to `.godot/export_credentials.cfg`, which git ignores. Do not type the release key into the export dialog.

### What Bart must back up

Copy the whole folder `%APPDATA%\Forkline\release\` (both files) to storage of your own, such as a password manager attachment or an encrypted drive. Keep two copies in different places. Do not put it in the repo, in a public or shared cloud folder, or in an email. Anyone with both files can upload updates as Play, Inc.

### If the upload key is lost or leaked

Because Play App Signing is on, Google still holds the app signing key, so the app is not lost and players keep getting updates. Do this:

1. In Play Console, open the app, then Test and release, App integrity, App signing, and choose Request upload key reset. (The menu names change now and then. Search the Play Console help for "reset upload key".)
2. Make a new keystore with the same steps as below, with a new file name, so the old one is not overwritten.
3. Upload the new certificate (the .pem export of the public certificate, not the keystore) when Play asks. Google confirms by email, and the new key works after a short wait (a few days at most).
4. Point the build at the new files (change the file names in `build_release.sh`, or move the old ones aside and use the standard names), build, check and upload.

For a leaked key, request the reset at once. Never delete the old keystore until the reset is done.

### Make a new upload key

Only if the old one is lost. This writes the password to a file and never to the screen.

```bash
dir="$(cygpath -u "$APPDATA")/Forkline/release"
mkdir -p "$dir" && cd "$dir"
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40 > forkline-upload.password
keytool -genkeypair -keystore forkline-upload.keystore -storetype PKCS12 -alias forkline-upload \
  -keyalg RSA -keysize 4096 -validity 10950 -dname "CN=Play Inc, O=Play Inc" \
  -storepass:file forkline-upload.password -keypass:file forkline-upload.password
icacls "$(cygpath -w "$dir")" /inheritance:r /grant:r "$USERNAME:(OI)(CI)F"
```

The `icacls` line limits the folder to the current Windows user. Then show only the public fingerprint:

```bash
keytool -list -v -keystore forkline-upload.keystore -storepass:file forkline-upload.password | grep SHA256
```

### Upload to Play (ask first)

Play Console work waits for Play, Inc.'s DUNS number and Bart's go ahead. When it starts: create the app, turn on Play App Signing when asked, upload `build/forkline-release.aab` to a testing track first, and check that Play Console lists no permissions for it. Agents never do this step.

## Wording for the privacy policy and store listing (phase 9)

The export sets `allowBackup` to false, so there is no cloud or adb backup of saves. Android's documentation says some manufacturers' devices can still move app files in a device to device transfer on API 31 and higher. So write that the app never sends saves anywhere. Do not write that saves can never leave the phone.

## Store material (phase 9)

Everything for the Play listing is in `docs/store/`. Nothing has been entered in Play Console. The listing and the privacy policy are drafts for Bart to review.

| File | What it is |
|---|---|
| docs/store/listing.md | Every field to paste into Play Console, with limits and counts |
| docs/store/privacy-policy.md | The privacy policy |
| docs/store/graphics/ | The icon (512 x 512), feature graphic (1024 x 500) and five phone screenshots (1080 x 2160) |

### Make the graphics

Both tools need a rendering display, so run them without `--headless`, from the repo root. Each opens a window for a short time.

```bash
godot --path . --script res://tools/store/make_graphics.gd       # icon and feature graphic, a few seconds
godot --path . --script res://tools/store/make_screenshots.gd    # five real screens, about a minute
```

`make_graphics.gd` draws the icon with `IconArt` and the feature graphic with `Wordmark`, `MapArt`, `Silhouettes` and the palette. `make_screenshots.gd` runs the real app in a SubViewport at 1080 x 2160 with the bundled data, a throwaway save folder (`user://store_shots/`, removed afterwards) and the sound off. It plays three waves of The Fork out of sight and tops up the gold, so the pictures show a full defense. Add `-- --only=wave` (or `front_door`, `modes`, `levels`, `build`) for one picture. Rerun after any change to the look, then run the check.

### Check the store material

```bash
bash tools/store/check_store.sh
```

It checks the character counts in listing.md (the stated count must match the real one, and stay under Google's limit), plain ASCII only (no em dashes or curly quotes), no double hyphens in prose, the required wording in the listing and the policy, the size of every PNG, and the Pages site (see below). Exit 0 means it all passed. When you change a text field, change its `Characters: N of L.` line to match. The site check runs Godot, so `godot` must be on PATH or GODOT must be set.

## The privacy policy site (GitHub Pages)

docs/store/privacy-policy.md is the one source of the policy text. `tools/store/make_site.gd` turns it into plain HTML in `docs/store/site/`, and the generated files are committed:

| File | What it is |
|---|---|
| docs/store/site/index.html | Short home page: title, one line about the game, links to the source code, the test builds and the policy, the copyright line and "Made by Bart Basi" |
| docs/store/site/privacy-policy/index.html | The policy, at https://bartbasi.github.io/forkline/privacy-policy/ |
| docs/store/site/.nojekyll | Empty. Tells GitHub to serve the files as they are |

The pages use inline CSS only, with a system font stack and light and dark colors from `prefers-color-scheme`. They have no script, cookie, external font, image or stylesheet, so nothing loads from any other address. The only outbound addresses are the two plain links to the source code and the test builds. The home page line about the game is the short description from listing.md.

Regenerate after any change to the policy or the short description, from the repo root (no window needed):

```bash
godot --headless --path . --script res://tools/store/make_site.gd
bash tools/store/check_store.sh
```

`check_store.sh` fails if `docs/store/site/` differs from what the generator writes now, if a page has `src=`, `@import`, `url(`, a script, a `<link>` or any address other than the two allowed links, or if a page has a non ASCII character or a double hyphen. To write the site somewhere else, add `-- --out=<folder>` to the Godot command.

### Publish the site (the DM does this, after Bart's go ahead)

Bart approved the policy on Pages on 2026-10-26. Agents never run these steps.

1. Run the store check and the full test suite on the commit to publish.
2. Make the `gh-pages` branch hold exactly the contents of `docs/store/site/`, including `.nojekyll`, and nothing else. A throwaway worktree keeps main untouched:

   ```bash
   scratch="$(mktemp -d)"
   cp -r docs/store/site/. "$scratch"
   git worktree add --detach "$TEMP/fl_pages" HEAD
   cd "$TEMP/fl_pages"
   git checkout --orphan gh-pages
   git rm -rf --quiet .
   cp -r "$scratch"/. .
   git add -A
   git ls-files        # must list only .nojekyll, index.html, privacy-policy/index.html
   ```

   Later runs: start from `git worktree add "$TEMP/fl_pages" gh-pages` (after fetching it), replace the files the same way, and `git add -A` so removed files go too.
3. Commit as the bartbasi account and push `gh-pages` with the same gh credential helper used for main.
4. Turn Pages on from that branch's root:

   ```bash
   gh api -X POST repos/bartbasi/forkline/pages -f "source[branch]=gh-pages" -f "source[path]=/"
   ```

   (If Pages is already on, use `-X PUT` to change the source.) Then remove the worktree (`git worktree remove --force "$TEMP/fl_pages"`, `git worktree prune`).
5. After a minute, open https://bartbasi.github.io/forkline/ and https://bartbasi.github.io/forkline/privacy-policy/ and confirm both load. That second address is the one in the Play listing.
6. To update later: regenerate, run the check, commit on main, and repeat steps 2 and 3 (a new commit on `gh-pages` with the same exact contents rule).

## GitHub test builds (the DM does this)

Each verified milestone gets a public pre-release with the APK attached. The full suite must pass on a clean copy and `bash scripts/check_apk.sh` must pass first. Agents never run these steps.

1. Build from a clean clone of the tagged commit (`git clone`, then `git checkout <the commit>`), never from the main working tree, which other work uses. `bash scripts/build.sh` refuses a dirty tree. Do not use `--allow-dirty` here. Then write the checksum next to the APK:

   ```bash
   cd build
   sha256sum forkline-debug.apk > forkline-debug.apk.sha256
   ```
2. Tag name: `v0.1-testN`, where N counts the test builds (`v0.1-test1`, `v0.1-test2`, ...). The tag points at the verified commit.
3. Write the release notes to a file: what changed, and that this is a debug signed test build, not a store release. GitHub test builds stay debug signed, with the Android debug key, for now. That way testers can keep installing over earlier test builds and keep their progress, because a build signed with a different key would not install over them. Whether GitHub ever carries release signed builds is a later decision for Bart.
4. Create the release. Use the full 40 character sha of the verified commit for `--target`:

   ```bash
   gh release create v0.1-testN -R bartbasi/forkline --target <full 40 character sha> --prerelease \
     --notes-file <notes> build/forkline-debug.apk build/forkline-debug.apk.sha256
   ```
5. Open the release page and check that both files are attached and the tag shows the right commit.

### Screenshots from the Fold5

The tool's pictures are enough for the phone slots. If Play Console asks for large screen screenshots, take them on the Fold5's inner screen:

1. Install the build (`bash scripts/install.sh`), unfold the phone, and open Forkline.
2. Capture these four screens with the phone's own screenshot (power and volume down): the front door, the campaign list, a level in its build phase with a gate placed, and a wave in progress.
3. Copy them off with `adb pull` and put them in docs/store/graphics/. Play wants JPEG or 24 bit PNG, each side from 320 to 3840 px, and no side more than twice the other.

### What is still missing for a Play submission

The upload key, the signed bundle and the privacy policy on a public address are done (see above). What is left is Play Console itself, which waits for Play, Inc.'s DUNS number, and the answers recorded in docs/store/listing.md.
