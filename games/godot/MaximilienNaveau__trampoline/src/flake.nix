{
  description = "Godot dev shell, audio, tests and exports for the trampoline game";

  # CI pushes what it builds (audio, tests, exports) to this binary cache,
  # so a machine that trusts it downloads them instead of rebuilding.
  # (Nix asks before using a flake's cache; `--accept-flake-config` says yes.)
  nixConfig = {
    extra-substituters = [ "https://baxter.cachix.org" ];
    extra-trusted-public-keys = [ "baxter.cachix.org-1:BJW9FafkmcXVDJVK2xL/b0J3bQkn+wdJPNgmHDRfzoQ=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        version = "4.1.0";

        # Building for Android needs Google's Android SDK, whose licence
        # must be accepted (and which nixpkgs marks unfree): only this
        # second package set opts in, the dev shell and `nix run` don't.
        androidPkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        # Just what Godot's APK export uses: `apksigner` (build-tools)
        # and `adb` (platform-tools). No NDK or Gradle: the APK is made
        # from Godot's prebuilt Android template, not compiled.
        androidSdk = (androidPkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "36.0.0" ];
          platformVersions = [ "36" ];
        }).androidsdk;

        # The tools to make the game's music and sound effects from
        # scripts, all open source:
        # - python3 with mido (writes MIDI) and numpy/scipy (synthesises
        #   sound effects sample by sample, mixes, writes .wav),
        # - sfizz: plays MIDI through sampled instruments (SFZ) -> .wav,
        # - sox and ffmpeg: trim, normalise, encode to .ogg.
        audioTools = [
          (pkgs.python3.withPackages (ps: [ ps.mido ps.numpy ps.scipy ]))
          pkgs.sfizz
          pkgs.sox
          pkgs.ffmpeg
        ];

        # Only some files out of a zip archive on the web, read in slices
        # (HTTP range requests, see tools/audio/fetch_zip.py) rather than
        # downloading the whole archive. A fixed-output derivation: like
        # fetchurl, it may use the network because `hash` pins its result
        # (the files, unpacked under their paths in the archive).
        fetchZipMembers = { name, url, members, hash }:
          pkgs.runCommand name {
            nativeBuildInputs = [ pkgs.python3 ];
            NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            outputHashMode = "recursive";
            outputHash = hash;
          } ''
            python3 ${./tools/audio/fetch_zip.py} "${url}" "$out" ${pkgs.lib.escapeShellArgs members}
          '';

        # The band's sampled instruments, all free (see tools/audio/README.md),
        # laid out as tools/audio/arrange.py expects: guitar/, bass/, vsco/
        # (clarinet and flute), accordion/, piano/, room/ (the hall), each with its
        # .sfz files. About 1 GB to download: only the build needs them, the game
        # ships the rendered music.
        samples = pkgs.stdenvNoCC.mkDerivation {
          pname = "trampoline-samples";
          version = "6";
          dontUnpack = true;
          nativeBuildInputs = [
            pkgs.p7zip
            pkgs.unzip
            pkgs.sox
            (pkgs.python3.withPackages (ps: [ ps.numpy ps.scipy ]))
          ];
          # The University of Iowa's classical guitar, stereo: chromatic
          # runs, cut into notes by slice_guitar.py.
          guitar = pkgs.fetchurl {
            url = "https://theremin.music.uiowa.edu/sound%20files/MIS/Piano_Other/guitar/Guitar.stereo.1644.1.zip";
            hash = "sha256-Og6Lbl+7XQMSxpf3woB87r6Ic8jIUKegbBb6pJAbv0I=";
          };
          sliceGuitar = ./tools/audio/slice_guitar.py;
          accordion = pkgs.fetchurl {
            url = "https://github.com/freepats/button-accordion-HN/releases/download/2024-03-29/ButtonAccordionHN-SFZ+FLAC-20240329.7z";
            hash = "sha256-5TJqiDDwNY+qGVYJ/SHQwduriZ45vX9EsVkOvyzlA14=";
          };
          # Karoryfer's Meatbass: a double bass, its pizzicato played at 4
          # strengths with 4 takes of each (CC0). Only the pizzicato: 127 MB
          # of the 255 MB archive.
          bass = fetchZipMembers {
            name = "meatbass-pizz";
            url = "https://github.com/sfzinstruments/karoryfer.meatbass/releases/download/v1.001/Karoryfer.Meatbass.v1.001.zip";
            members = [ "Meatbass/Programs/pizz_basic.sfz" "Meatbass/Samples/pizz/*" "Meatbass/LICENSE" "Meatbass/readme.txt" ];
            hash = "sha256-Sq3mCoI1ScygPSWginOtqichkVkADMkdS1po54ZRKuc=";
          };
          # Only the clarinet and the flute out of the 3 GB VSCO 2
          # Community Edition.
          vsco = pkgs.fetchgit {
            url = "https://github.com/sgossner/VSCO-2-CE.git";
            rev = "1.1.0";
            sparseCheckout = [ "Woodwinds/Clarinet" "ClarinetSus.sfz" "Woodwinds/Flute" "FluteSusVib.sfz" ];
            nonConeMode = true;
            hash = "sha256-68ryCgFoxTW3+GP1A9ZiyWLBHTyi4rv9nGV64urdu04=";
          };
          # Salamander Grand Piano V3 (Alexander Holm, CC-BY 3.0).
          piano = pkgs.fetchurl {
            url = "https://freepats.zenvoid.org/Piano/SalamanderGrandPiano/SalamanderGrandPiano-SFZ+FLAC-V3+20200602.tar.gz";
            hash = "sha256-t3YOFoSUzwlTROIXsK8BP8RJrQM6u73xxlIRzxHcA4s=";
          };
          # The Brahmssaal (a small concert hall) of the Detmold University
          # of Music, its impulse response recorded by a dummy head: the
          # band's room (CC BY 4.0). Only its one file used: 2 MB of this
          # 1 GB archive.
          room = fetchZipMembers {
            name = "detmold-brahmssaal";
            url = "https://zenodo.org/api/records/4116247/files/DetmoldSRIR_v01.zip/content";
            members = [ "SetA_SingleSources/Data/Brahmssaal/DummyHead/C1S1R3.wav" ];
            hash = "sha256-elveLYg4QrLKQkP7nsNuNJfngYeAsDTqlLxfu5u9CnI=";
          };
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            unzip -q "$guitar" -d "$TMPDIR/guitar" -x "__MACOSX/*"
            python3 "$sliceGuitar" "$TMPDIR/guitar/1644stereo" "$out/guitar"
            7z x -o"$TMPDIR/accordion" "$accordion" >/dev/null
            mv "$TMPDIR"/accordion/"Button Accordion HN SFZ+FLAC-20240329" "$out/accordion"
            cp -r "$bass/Meatbass" "$out/bass"
            cp -r "$vsco" "$out/vsco"
            tar xzf "$piano" -C "$TMPDIR"
            mv "$TMPDIR"/SalamanderGrandPiano-SFZ+FLAC-V3+20200602 "$out/piano"
            mkdir "$out/room"
            cp "$room"/SetA_SingleSources/Data/Brahmssaal/DummyHead/C1S1R3.wav "$out/room/brahmssaal.wav"
            runHook postInstall
          '';
        };
        # Where the scripts find the samples.
        sampleEnv = { TRAMPOLINE_SAMPLES = "${samples}"; };

        # The music and sound effects the game plays, made from
        # tools/audio/ (they aren't committed: only their .import files
        # are). Its source is that folder alone, so it's only rebuilt
        # when the scripts change. Lays out like assets/audio/.
        audio = pkgs.stdenvNoCC.mkDerivation ({
          pname = "trampoline-audio";
          inherit version;
          src = ./tools/audio;
          nativeBuildInputs = audioTools;
          buildPhase = ''
            runHook preBuild
            export HOME="$TMPDIR"
            python3 make_music.py --out "$out/music"
            python3 make_sfx.py --out "$out/sfx"
            runHook postBuild
          '';
          dontInstall = true;
        } // sampleEnv);

        # The project as the exports and tests see it: the committed
        # files plus the generated audio dropped into assets/audio/.
        #
        # Without doc/ and .github/: the game doesn't use them, and leaving
        # them out means a new screenshot or workflow edit rebuilds nothing.
        gameSource = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.difference ./. (
            lib.fileset.unions [
              ./doc
              ./.github
              ./fastlane
            ]
          );
        };
        project = pkgs.runCommand "trampoline-project-${version}" { } ''
          cp -r --no-preserve=mode ${gameSource} "$out"
          cp -r --no-preserve=mode ${audio}/. "$out/assets/audio/"
        '';

        # Godot runs inside the Nix build sandbox, like a compiler: a fresh
        # copy of the project, a throwaway home folder, and only the tools
        # listed here — your own editor settings play no part.
        godotEnv = ''
          export HOME="$TMPDIR/home"
          export XDG_DATA_HOME="$HOME/data"
          export XDG_CONFIG_HOME="$HOME/config"
          export XDG_CACHE_HOME="$HOME/cache"
          # Godot looks for its export templates here, by version.
          mkdir -p "$XDG_DATA_HOME/godot/export_templates"
          ln -s ${pkgs.godot_4-export-templates-bin}/share/godot/export_templates/* \
            "$XDG_DATA_HOME/godot/export_templates/"
          # The source has no import cache (.godot/ isn't committed); this
          # also builds the class_name cache that tests and exports need.
          godot4 --headless --import --path .
        '';

        # `nix build .#<name>` exports one preset of export_presets.cfg
        # into result/<file>. `mode` is "release" or "debug". `setup` runs
        # before Godot's first start, which is when it reads the
        # environment into its editor settings (e.g. the Android SDK path).
        godotExport = { name, preset, file, mode ? "release", extraInputs ? [ ], setup ? "" }:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "trampoline-${name}";
            inherit version;
            src = project;
            nativeBuildInputs = [ pkgs.godot_4 ] ++ extraInputs;
            buildPhase = ''
              runHook preBuild
              ${setup}
              ${godotEnv}
              mkdir -p "$out"
              godot4 --headless --path . --export-${mode} "${preset}" "$out/${file}"
              runHook postBuild
            '';
            dontInstall = true;
          };

        exports = {
          linux = godotExport { name = "linux"; preset = "Linux"; file = "trampoline.x86_64"; };
          windows = godotExport { name = "windows"; preset = "Windows Desktop"; file = "trampoline.exe"; };
          macos = godotExport { name = "macos"; preset = "macOS"; file = "trampoline.zip"; };
          web = godotExport { name = "web"; preset = "Web"; file = "index.html"; };
          # No iOS: Godot refuses to export even the unsigned Xcode project
          # without an App Store Team ID, which needs an Apple account.

          # result/trampoline.apk: a release build (not debuggable, as it
          # ships), signed with the project's own debug key
          # (keys/debug.keystore) so each build installs over the previous
          # one: adb install -r result/trampoline.apk
          # The real key never enters a Nix build (the store is pushed to a
          # public cache): release.yml re-signs this APK with
          # `nix run .#apksigner`, outside Nix, for the GitHub Release and
          # F-Droid.
          android = godotExport {
            name = "android";
            preset = "Android";
            file = "trampoline.apk";
            extraInputs = [ pkgs.jdk17_headless ];
            setup = ''
              # Read by Godot as the default Android SDK and Java paths.
              export ANDROID_HOME=${androidSdk}/libexec/android-sdk
              export JAVA_HOME=${pkgs.jdk17_headless.home}
              # A flake only sees files git tracks: an uncommitted key isn't here.
              if [ ! -f keys/debug.keystore ]; then
                echo "keys/debug.keystore is missing: is it tracked by git?" >&2
                exit 1
              fi
              # A release export reads the RELEASE key variables: point them
              # at the debug key too.
              for kind in DEBUG RELEASE; do
                export GODOT_ANDROID_KEYSTORE_''${kind}_PATH="$PWD/keys/debug.keystore"
                export GODOT_ANDROID_KEYSTORE_''${kind}_USER=androiddebugkey
                export GODOT_ANDROID_KEYSTORE_''${kind}_PASSWORD=android
              done
            '';
          };
        };

        # A check that runs a command over the committed sources and
        # passes if it exits 0 (its output is an empty marker file).
        sourceCheck = name: inputs: command:
          pkgs.runCommand "trampoline-${name}" { nativeBuildInputs = inputs; } ''
            # gdtoolkit caches its parser in the home folder: give it one.
            export HOME="$TMPDIR"
            cd ${./.}
            ${command}
            touch "$out"
          '';
      in
      {
        # `nix develop` drops you into a shell with a `godot4` binary on
        # PATH (GDScript needs nothing else — no separate compiler/SDK),
        # plus `gdlint`/`gdformat` (gdtoolkit) — the closest thing GDScript
        # has to `flutter analyze`, since Godot itself ships no linter.
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.godot_4 pkgs.gdtoolkit_4 ];
        };

        # `nix develop .#audio`: the tools to edit and rerun
        # tools/audio/*.py by hand (see tools/audio/README.md).
        devShells.audio = pkgs.mkShell ({ buildInputs = audioTools; } // sampleEnv);

        packages = exports // {
          inherit audio;
          default = exports.linux;
        };

        # `nix flake check -L` runs everything CI runs: formatting, lint,
        # the audio pipeline, the unit tests on Linux, and every export.
        checks = exports // {
          inherit audio;
          format = sourceCheck "format" [ pkgs.gdtoolkit_4 ] "gdformat --check scripts/*.gd";
          lint = sourceCheck "lint" [ pkgs.gdtoolkit_4 ] "gdlint scripts/*.gd";
          # Each tests/*.gd is a standalone script Godot runs headless; all
          # of them run, then the check fails if any one did.
          tests = pkgs.stdenvNoCC.mkDerivation {
            pname = "trampoline-tests";
            inherit version;
            src = project;
            nativeBuildInputs = [ pkgs.godot_4 ];
            buildPhase = ''
              runHook preBuild
              ${godotEnv}
              status=0
              for test_file in tests/*.gd; do
                echo "=== $test_file"
                godot4 --headless --path . --script "$test_file" || status=1
              done
              [ "$status" = 0 ]
              touch "$out"
              runHook postBuild
            '';
            dontInstall = true;
          };
        };

        apps = {
          # `nix run` launches the game. Godot writes its import cache
          # (.godot/) into the project folder, so it can't run straight
          # from the read-only Nix store: use the checkout you're in when
          # there is one (fast, reuses its cache), otherwise a writable copy
          # of the project in a temporary folder (slower first start, while
          # Godot imports the assets).
          default = {
            type = "app";
            meta.description = "Play Trampoline";
            program = "${pkgs.writeShellApplication {
              name = "trampoline";
              runtimeInputs = [ pkgs.godot_4 ];
              text = ''
                if [ -f project.godot ]; then
                  project="$PWD"
                  # A fresh checkout has no audio yet: bring in the built one.
                  if [ ! -f assets/audio/sfx/bounce.wav ]; then
                    cp -r --no-preserve=mode ${audio}/. assets/audio/
                  fi
                else
                  project="$(mktemp -d)"
                  cp -r --no-preserve=mode ${project}/. "$project"
                fi
                # Brings the import cache (.godot/) up to date first: new or
                # changed assets, and the list of `class_name`s — without it,
                # a script using a class added since the last import fails to
                # load ("Could not find type"). Quick when nothing changed.
                # An import also re-saves project.godot, stripping its
                # comments: keep the file as it was.
                cp "$project/project.godot" "$project/.project.godot.keep"
                godot4 --headless --import --path "$project" > /dev/null 2>&1 || true
                mv "$project/.project.godot.keep" "$project/project.godot"
                # Runs the game, passing on any extra arguments, e.g.
                # `nix run . -- --resolution 480x854` for a phone-sized window.
                exec godot4 --path "$project" "$@"
              '';
            }}/bin/trampoline";
          };

          # `nix run .#apksigner -- <args>`: Android's APK signing tool
          # (from the same SDK the build uses), to re-sign an APK with the
          # release key outside of Nix.
          apksigner = {
            type = "app";
            meta.description = "Android's apksigner";
            program = "${pkgs.writeShellScript "apksigner" ''
              export JAVA_HOME=${pkgs.jdk17_headless.home}
              exec ${androidSdk}/libexec/android-sdk/build-tools/36.0.0/apksigner "$@"
            ''}";
          };

          # `nix run .#screenshots` (from the repository root): pictures of the game
          # for the F-Droid page and the readme, drawn by the game itself
          # (tools/capture_media.gd) in a virtual screen (Xvfb) with
          # software OpenGL (Mesa's llvmpipe), so no GPU or display needed:
          # - fastlane/metadata/android/en-US/images/phoneScreenshots/NN_*.jpg:
          #   the start card, then a still of
          #   each "Comment jouer" card (F-Droid's phone screenshots, in its
          #   fastlane layout; magamajo takes any picture with "screenshot"
          #   in its path);
          # - doc/how_to_play.gif: every card's animation, one after the
          #   other.
          # A few minutes: software drawing is slow, the pictures aren't (the
          # game steps exactly 1/15 s per frame, see capture_media.gd).
          screenshots = {
            type = "app";
            meta.description = "Make the F-Droid screenshots and the how-to-play GIF";
            program = "${pkgs.writeShellApplication {
              name = "trampoline-screenshots";
              runtimeInputs = [ pkgs.godot_4 pkgs.xvfb-run pkgs.imagemagick pkgs.ffmpeg ];
              text = ''
                if [ ! -f project.godot ]; then
                  echo "run this from the repository root" >&2
                  exit 1
                fi
                doc="$PWD/doc"
                work="$(mktemp -d)"
                trap 'rm -rf "$work"' EXIT
                # The project as the exports see it (generated audio
                # included), drawn at a phone's 1080 x 1920.
                cp -r --no-preserve=mode ${project}/. "$work/proj"
                printf '[display]\nwindow/size/window_width_override=1080\nwindow/size/window_height_override=1920\n' \
                  > "$work/proj/override.cfg"
                # Godot's OpenGL goes through libglvnd: point it at Mesa.
                export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
                export __GLX_VENDOR_LIBRARY_NAME=mesa
                export LD_LIBRARY_PATH=${pkgs.mesa}/lib
                export LIBGL_ALWAYS_SOFTWARE=1
                # Silent: the "Dummy" audio driver plays nothing (else the
                # game's music comes out of the speakers while it records).
                export HOME="$work/home"
                godot4 --headless --import --path "$work/proj" > /dev/null 2>&1
                shot() {
                  xvfb-run -a -s "-screen 0 1080x1920x24" \
                    godot4 --path "$work/proj" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 15 \
                    --script res://tools/capture_media.gd -- "$@" 2>&1 \
                    | { grep -E "SCRIPT ERROR|^ERROR: [^0-9]" || true; }
                }
                shots="$PWD/fastlane/metadata/android/en-US/images/phoneScreenshots"
                mkdir -p "$shots"
                rm -f "$shots"/*.jpg
                echo "start card"
                shot start "$work/start"
                magick "$work/start/still.png" -strip -quality 85 "$shots/01_start.jpg"
                # Every card's frames, numbered on, make the GIF's.
                mkdir "$work/gif"
                frame=0
                cards=$(grep -c '^\s*"caption": "' "$work/proj/scripts/how_to_play_cards.gd")
                for card in $(seq 0 $((cards - 1))); do
                  echo "card $((card + 1))/$cards"
                  shot howto "$card" "$work/card$card"
                  magick "$work/card$card/still.png" -strip -quality 85 \
                    "$shots/$(printf '%02d' $((card + 2)))_comment_jouer.jpg"
                  for f in "$work/card$card"/[0-9]*.png; do
                    mv "$f" "$work/gif/$(printf '%05d' "$frame").png"
                    frame=$((frame + 1))
                  done
                done
                echo "GIF ($frame frames)"
                ffmpeg -loglevel error -y -framerate 15 -i "$work/gif/%05d.png" -vf \
                  "fps=10,scale=360:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer" \
                  "$doc/how_to_play.gif"
                ls -l "$shots" "$doc/how_to_play.gif"
              '';
            }}/bin/trampoline-screenshots";
          };

          # `nix run .#audio` (from the repository root): copies the built music and
          # sound effects into assets/audio/, for the Godot editor.
          audio = {
            type = "app";
            meta.description = "Put the generated audio into assets/audio/";
            program = "${pkgs.writeShellScript "trampoline-audio" ''
              set -e
              if [ ! -f project.godot ]; then
                echo "run this from the repository root" >&2
                exit 1
              fi
              cp -r --no-preserve=mode ${audio}/. assets/audio/
              echo "assets/audio/ updated from ${audio}"
            ''}";
          };
        };
      });
}
