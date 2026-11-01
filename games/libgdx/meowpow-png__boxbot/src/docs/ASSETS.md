# Assets

This document covers where art, content, and config assets live,
how sprites get packed into an atlas, and how both assets and
config get loaded and reloaded at runtime.

## Directory Layout

All source assets live under `assets/` at the repo root:

- `sprites/`: source PNGs for every entity sprite
- `overlays/`: lighting textures
- `fonts/`: font source
- `maps/`: the Tiled map and its tileset
- `atlas/`: the packed sprite sheet
- `config/`: runtime tuning values

Sprites and atlases hold the same art but serve different purposes. 
Sprite files are source of truth and are committed to the repository.
The generated atlas is a build output regenerated from it,
so it is gitignored rather than committed.

Editor source files, such as `.xcf` and Tiled's project files, are gitignored
for the same reason: nothing at runtime reads them, so there is no reason to ship them.

## Sprites

Every entity sprite is a loose PNG in `assets/sprites/`.  
Before it can be drawn, it has to be packed into the atlas alongside every other sprite.

The filename is the only link between source and atlas. 

For example, `package-inbound-red.png` becomes the region 
name`package-inbound-red`, looked up directly in code. 
There is no manifest and no separate registration step.

Packing runs automatically as part of a full build via `packTextures` 
Gradle task, so a packaged build always has a current atlas. The only
time it needs a manual run is iterating on a sprite mid-development, 
since editing the PNG has no effect until it is repacked. 

See [Reloading](#Reloading) for more information.

## Overlays

Overlay textures skip the atlas by design. They are full-screen draws for lighting 
rather than individual sprites drawn per entity, so packing them in would not save any binds. 

They are loaded and used as-is from `assets/overlays/`.

## Fonts

`assets/fonts/` holds a single TrueType source rather than pre-rendered glyphs. 
The game rasterizes it into a bitmap font at whatever pixel size is requested.

## Maps

`assets/maps/` holds the warehouse layout as a Tiled map, along with its
tileset image and tile definitions. It is authored externally in Tiled
and loaded like any other asset, with no special-casing at runtime.

## Config

`assets/config/boxbot.json` holds runtime tuning values. Gameplay and
presentation tuning share one file rather than being split by category:

- Level generation: the `seed`
- Shipment failures: the `backlogLimit`
- Robot: battery capacity
- Job arrival pacing: preseeding, retrieval interval, delivery timer, truck cadence
- Presentation: tick durations, label sizes

Every value is validated on load, and an invalid value fails 
to load rather than being silently clamped or defaulted.

The same file is used in development and in a packaged build. There is
no separate hardcoded fallback. What differs between the two is where
the file is read from, and whether it can be reloaded without restarting.

See [Reloading](#Reloading) for more information.

## Loading

`AssetLoader` and `ConfigLoader` are each the only thing allowed to touch disk 
for their resource type. Everything downstream works from what they already
loaded, so nothing needs to know how or when something was read from disk.

Loading fails fast. Violated constraint all throw
immediately, in both development and a packaged build.

## Reloading

Two hotkeys reload things while the game is running, without restarting the process:

**F5** reloads every asset and `config/boxbot.json` from disk, then rebuilds the 
renderers. Simulation state is untouched. Presentation config values, like label sizes, 
take effect immediately, since the renderers that use them are rebuilt as part of the reload.

Gameplay config values do not, since they are already 
baked into objects that were constructed before the reload

**F6** restarts the level, discarding the current run, and rebuilds the simulation 
from whatever config is currently loaded. It does not touch disk itself, so pair it 
with F5 first if the config file changed on disk and those changes need to take effect

What needs to happen before pressing F5 depends on what changed:

- Sprites: repack first, since F5 reloads the atlas, not the loose PNGs
- Overlays, fonts, the map, and config: no repack step, just edit the file and reload

Both hotkeys only exist in development mode, enabled with `-Dboxbot.dev=true` 
or `BOXBOT_DEV` environment variable. Outside development mode, neither key does anything.

What actually matters for reloading is having a live `assets/` folder to 
read from, not development mode itself. A packaged build reads assets and 
config from inside the jar, where there is nothing to edit and reload.
