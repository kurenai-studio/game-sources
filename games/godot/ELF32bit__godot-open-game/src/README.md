# 🎮 [Third-person point-and-click game](https://elf32bit.github.io/godot-open-game-web)
Let's see how far human ingenuity can get us in the AI era.
1. All assets must be made by hand using free software.
2. No stealing, cheating or AI generation is allowed.
3. Prefer elegant solutions to complex problems.

## Project directories
* **`addons`** is a directory for modular code (plugins, tools).
* **`application`** should contain application files and global settings.
* **`characters`** contains [special maps](https://github.com/ELF32bit/godot-mapper-characters) with animated layers for prototyping.
* **`interfaces`** should contain all kinds of buttons, progress bars, etc...
* **`mapping`** is the main directory for game levels with map resources.
* **`sources`** should contain all game logic and the game state.

> Project configuration can be changed in **`addons/mapper.gd`** games file.

## Compiling Godot editor
CSG merge support for **`func_liquid`** entity.
```C++
// modules/csg/csg_shape.cpp#L736
Ref<ArrayMesh> CSGShape3D::bake_static_mesh() {
	Ref<ArrayMesh> baked_mesh;
	// -> update_shape();
	if (is_root_shape() && root_mesh.is_valid()) {
		baked_mesh = root_mesh;
	}
	return baked_mesh;
}
```
Stability fix for **`lightmap_unwrap`** function.
```C++
// thirdparty/xatlas/xatlas.cpp#L72
#define XA_MULTITHREADED 1 // -> 0
```

## How to contribute
1. Download **TrenchBroom** map editor.<br>
2. Use **`Quake2`** map format supporting face flags.<br>
3. Set **`Generic`** game path to the **`mapping`** directory.<br>
4. Or set **`Generic`** game path to the **`characters`** directory.<br>
5. Attach automatically generated **`entities.fgd`** definitions.<br>
6. Tweak **`func_connector+.gd`** for [procedural generation](https://github.com/ELF32bit/godot-mapper-mazes).<br>
7. Explore the infinite possibilities of mapping.<br>
