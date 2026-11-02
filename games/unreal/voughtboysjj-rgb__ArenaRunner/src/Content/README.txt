This folder holds the game content (maps, meshes, materials, sounds).

The sample intentionally ships empty: the arena, the player character and the
pickups are all built from engine primitives at runtime, so the project is
playable without any .uasset files.

Create your own maps here, e.g. Content/Maps/Arena.umap, and point
Config/DefaultEngine.ini at them:

  EditorStartupMap=/Game/Maps/Arena
  GameDefaultMap=/Game/Maps/Arena
