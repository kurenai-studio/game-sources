# Free asset sources for Veilfall

Characters, weapons, enemies, projectiles, and attack effects use generated low-poly geometry. The current arena environment uses an open ground plane with scattered biome vegetation, rocks, and shallow pools; prefabricated modular room pieces are not used in the playfield.

The following packs are free and list a CC0 license on the creator's pages:

- [Kenney Mini Dungeon](https://kenney.nl/assets/mini-dungeon) — CC0 human/orc fighter, sword, shield, and dungeon meshes. The OBJ models and shared texture are included under `assets/models/kenney-mini-dungeon/` and drive the player/enemy silhouettes and Warden sword.
- [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) — trees, rocks, and foliage for forest arenas.
- [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) — 2D particle sprites for VFX. The current effects are generated 3D meshes, so this pack needs a billboard/particle rendering path before use.
- [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) — CC0 weapon and RPG foley; selected sounds are included under `assets/audio/combat/`.
- [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) — CC0 impact cues; selected sounds are included under `assets/audio/combat/`.

The current Gradle/libGDX setup does not include a glTF importer or skeletal animation runtime. The Mini Dungeon human/orc and sword OBJ meshes use libGDX's built-in OBJ loader. Archer bows, mage staves, and the Warden maul remain generated meshes because the downloaded character pack does not include those weapon shapes.
