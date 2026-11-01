# NEON COURIER

A small neon-noir courier game made with LÖVE 11.5. Pick District 07 or
Waterfront, carry dangerous cargo, make deliveries, choose upgrades and dodge
traffic and police during a five-minute shift. A shift ends at the timer or
when your vehicle is wrecked; Run Again keeps the district you just played.

This is a completed proof of concept, with no ongoing update schedule promised.
Code and documentation use MIT; original art/audio owned by ninefournine
uses CC BY 4.0. See [licensing and attribution](LICENSING.md).

## Play

Install [LÖVE 11.5](https://github.com/love2d/love/releases/tag/11.5), extract the
download ZIP, and open `neon-courier.love` with LÖVE. On macOS, drag the file
onto the LÖVE application. If the installed runtime is on your PATH:

```sh
love neon-courier.love
```

The download is a portable LÖVE archive, not a standalone application or
Windows executable. It contains no bundled runtime or installer. No signed or
notarized standalone macOS application is supplied.

On the title screen, select DISTRICT and use left/right or confirm to choose
WATERFRONT or DISTRICT 07, then select START SHIFT. Pickups and deliveries happen
automatically inside their marked zones; no interaction button is needed.

| Action | Keyboard | Controller mapping |
| --- | --- | --- |
| Steer / navigate menus | WASD or arrow keys | Left stick / D-pad |
| Boost | Space / Left Shift | A / right shoulder |
| EMP | X | B / X / left shoulder |
| Pause / resume | Esc / P | Start |
| Confirm | Enter | A |
| Menu back | Esc | B |
| Mute / fullscreen | M / F11 | Settings menu |

These are implemented controller mappings; physical-controller testing of this
release is not claimed. Release boost to rearm it after its energy runs out.
Settings include music/SFX levels, mute, shake, atmosphere, fullscreen and
integer pixel scaling subject to screen fit. Settings and best scores use
LÖVE's platform save storage under `neon-courier-v1`; district selection resets
to District 07 on a fresh launch and is not stored in the shared settings.

## What's in the shift

- Stolen prototypes pay well and add temporary police attention.
- Medical supplies lose integrity on discrete impacts; the third loses the cargo.
- Batteries have a delivery timer and damage the vehicle when they expire.
- Every three deliveries offers upgrades from six bounded upgrade types.
- A named destination, dotted route, edge arrow and minimap guide the courier.

## Support and limitations

| Target / evidence | Current release status |
| --- | --- |
| macOS, LÖVE 11.5 | Direct native launch verified; creator reported a positive Waterfront playtest |
| Lua logic, input, saves, renderer stubs | Automated suites verified separately from native rendering |
| Windows / current Linux native build | Not verified for this Waterfront release |
| Browser / mobile / PortMaster / handheld | No supported release artifact provided |
| Physical controller, listening review, sustained native timing | Not separately verified |

Software supports the intended controls, but a platform or device is not called
tested merely because LÖVE supports it. Automated driving audits record outcomes;
raised-hull soak fixtures establish stability, not human balance or survival.
The map-definition validator does not fully validate custom theme metadata;
the two shipped definitions are valid. There is no multiplayer or online service.

## Source, build and tests

The game runs from a source folder with `love .`. Packaging needs Python 3.9+
and its standard library; no Node, browser tooling or downloads are required.
The tracked runtime assets are already generated. From the source root:

```sh
python3 scripts/build.py
```

Output: `dist/neon-courier.love` and `dist/BUILD_MANIFEST.json`. The builder uses
an explicit runtime allowlist, sorted ZIP paths, fixed timestamps and permissions.
Repeated builds with the same Python/zlib toolchain are byte reproducible;
compression bytes may differ between toolchain versions. See the manifest for
runtime source and artifact hashes.

With LuaJIT installed, run the existing automated suites:

```sh
luajit tests/logic.lua
luajit tests/districts.lua
luajit tests/render_maps.lua
luajit tests/district_flow.lua
luajit tests/input.lua
luajit scripts/test_audio.lua
luajit tests/drive.lua
luajit tests/district_soak.lua
luajit tests/fullscreen.lua
luajit tests/save.lua
```

For a fresh packaging baseline and reproducibility check:

```sh
python3 scripts/build.py
python3 tests/package.py --remember
python3 scripts/build.py
python3 tests/package.py
```

The renderer/audio/input preference suites use stubs and are not native visual,
listening or hardware evidence. Tests keep saves in memory or their isolated
test fixtures, rather than modifying the normal play profile.

## Assets and credits

Vehicle sprites and the score/SFX have included project generator sources.
Art generation needs only Python. Optional audio regeneration needs an existing
FFmpeg with libvorbis; nothing installs it automatically:

```sh
python3 scripts/generate_art.py
python3 scripts/generate_audio.py
```

Audio regeneration may vary with encoder versions. Normal game packaging uses
the tracked assets. See [credits](CREDITS.md), [provenance](ASSET_PROVENANCE.md)
and [licensing](LICENSING.md). The project was built with AI-assisted
programming and written documentation; the sprites and audio were produced by
included deterministic project scripts. External runtimes keep their own licenses.
