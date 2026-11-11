# Attribution

- **Name:** rts-mobile (working title)
- **Upstream:** https://github.com/WackeySSL/rts-mobile
- **License:** MIT
- **Commit:** d35f1b40614f1fbbd808e88355c5dae4e107ad0d
- **Collected by:** a
- **Engine:** Godot 4.7 (Compatibility)

An original mobile real-time strategy game: build a base, harvest, and command tank battles in short matches against the computer. Upstream `LICENSE` (MIT) is copied next to this file and also kept under `src/`. Phase 0–4 development gates are complete and a full match against the AI is playable; Phase 4b (air and ground support) is still in progress, and the upstream README still describes the project as pre-alpha.

The game's name and logo are not covered by the MIT licence and remain the property of AppCode ApS (see the upstream README licence section). Code and the assets listed below are MIT or SIL OFL 1.1 as stated.

## Icon

`src/assets/art/svg/icon/app_icon.svg` (md5 `e6c0c570d9dd65a82ac19c7daee76a06`) is a custom tank-and-radar mark by AppCode ApS that shipped upstream; it is not the default Godot icon. It is used as `application/config/icon`.

## Third-party assets

Asset provenance is recorded upstream in `src/assets/CREDITS.md`. In summary:

- SVG art under `src/assets/art/` drawn in this repository is MIT, same as the code (AppCode ApS).
- **Chakra Petch** (SIL OFL 1.1) by Cadson Demak (The Chakra Petch Project Authors), in `src/assets/art/fonts/chakra-petch/` with `OFL.txt`.
- **Big Shoulders Display** ExtraBold (SIL OFL 1.1) by Patric King (The Big Shoulders Project Authors), in `src/assets/art/fonts/big-shoulders/` with `OFL.txt`.
- Godot Engine (MIT) and godot-cpp (MIT) licence texts are vendored under `src/docs/licenses/` for export builds. LLVM libc++ (Apache-2.0 WITH LLVM-exception) licence text is also vendored there for Android export templates; this snapshot does not include a compiled `libc++_shared.so`.

## Engine

Godot Engine (MIT), https://godotengine.org/license/
