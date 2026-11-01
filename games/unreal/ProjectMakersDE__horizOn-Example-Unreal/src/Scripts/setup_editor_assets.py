"""Optional regeneration via Unreal 5.8 Tools > Execute Python Script.

Imports shared RGBA art, custom-pivot cutout sprites, fallback one-frame
Paper2D flipbooks and an empty boot map. Existing generated assets are reused.
Imported packages are already versioned. Epic API references and native
verification boundaries are recorded in EDITOR_SETUP.md.
"""
from pathlib import Path
import struct
import json
import unreal

ROOT = Path(__file__).resolve().parents[1]
TOOLS = unreal.AssetToolsHelpers.get_asset_tools()
LIB = unreal.EditorAssetLibrary


def import_file(path, destination):
    asset_path = destination + "/" + path.stem
    existing = LIB.load_asset(asset_path) if LIB.does_asset_exist(asset_path) else None
    if existing:
        return existing
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", str(path))
    task.set_editor_property("destination_path", destination)
    task.set_editor_property("automated", True)
    task.set_editor_property("save", True)
    task.set_editor_property("replace_existing", False)
    TOOLS.import_asset_tasks([task])
    imported = LIB.load_asset(asset_path)
    if not imported:
        raise RuntimeError("Import failed: " + str(path))
    return imported


def dimensions(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Expected PNG: " + str(path))
    return struct.unpack(">II", header[16:24])


def sprite(name, filename, world_size, source_rect=None, destination="/Game/Sprites", pivot=None, translucent=False):
    existing = LIB.load_asset(destination + "/" + name) if LIB.does_asset_exist(destination + "/" + name) else None
    if existing:
        return existing
    path = ROOT / "Content" / "Textures" / filename
    texture_destination = "/Game/Textures" + ("/" + str(Path(filename).parent).replace("\\", "/") if Path(filename).parent != Path(".") else "")
    LIB.make_directory(texture_destination)
    texture = import_file(path, texture_destination)
    texture.set_editor_property("compression_settings", unreal.TextureCompressionSettings.TC_EDITOR_ICON)
    texture.set_editor_property("mip_gen_settings", unreal.TextureMipGenSettings.TMGS_NO_MIPMAPS)
    texture.set_editor_property("filter", unreal.TextureFilter.TF_BILINEAR)
    if pivot:
        texture.set_editor_property("address_x", unreal.TextureAddress.TA_CLAMP)
        texture.set_editor_property("address_y", unreal.TextureAddress.TA_CLAMP)
        texture.set_editor_property("compression_no_alpha", False)
    texture.set_editor_property("srgb", True)
    LIB.save_loaded_asset(texture)
    texture_width, texture_height = dimensions(path)
    x, y, width, height = source_rect or (0, 0, texture_width, texture_height)
    asset = TOOLS.create_asset(name, destination, unreal.PaperSprite, unreal.PaperSpriteFactory())
    if not asset:
        raise RuntimeError("Sprite creation failed: " + name)
    # set_editor_property emits editor change notifications to rebuild sprite geometry.
    asset.set_editor_property("source_texture", texture)
    asset.set_editor_property("source_uv", unreal.Vector2D(x, y))
    asset.set_editor_property("source_dimension", unreal.Vector2D(width, height))
    asset.set_editor_property("source_texture_dimension", unreal.Vector2D(texture_width, texture_height))
    asset.set_editor_property("pixels_per_unreal_unit", width / world_size)
    asset.set_editor_property("pivot_mode", unreal.SpritePivotMode.CUSTOM if pivot else unreal.SpritePivotMode.CENTER_CENTER)
    if pivot:
        asset.set_editor_property("custom_pivot_point", unreal.Vector2D(*pivot))
    asset.set_editor_property("sprite_collision_domain", unreal.SpriteCollisionMode.NONE)
    material = unreal.load_asset("/Paper2D/TranslucentUnlitSpriteMaterial" if translucent else "/Paper2D/MaskedUnlitSpriteMaterial")
    if not material:
        raise RuntimeError("Paper2D unlit material missing. Enable Paper2D.")
    asset.set_editor_property("default_material", material)
    LIB.save_loaded_asset(asset)
    return asset


def flipbook(name, image):
    if LIB.does_asset_exist("/Game/Flipbooks/" + name):
        return
    asset = TOOLS.create_asset(name, "/Game/Flipbooks", unreal.PaperFlipbook, unreal.PaperFlipbookFactory())
    if not asset:
        raise RuntimeError("Flipbook creation failed: " + name)
    frame = unreal.PaperFlipbookKeyFrame()
    frame.set_editor_property("sprite", image)
    frame.set_editor_property("frame_run", 1)
    asset.set_editor_property("key_frames", [frame])
    asset.set_editor_property("frames_per_second", 1.0)
    LIB.save_loaded_asset(asset)


def main():
    unreal.AssetRegistryHelpers.get_asset_registry().search_all_assets(synchronous_search=True)
    for folder in ("/Game/Textures", "/Game/Sprites", "/Game/Flipbooks", "/Game/Materials", "/Game/Maps"):
        LIB.make_directory(folder)
    cutout_destination = "/Game/Sprites/Cutout"
    LIB.make_directory(cutout_destination)
    rig = json.loads((ROOT / "Content/Textures/Cutout/rig.json").read_text())
    for family, world_width in (("gull", 44), ("crab", 38)):
        for part in rig["characters"][family]["parts"]:
            sprite("SP_Cutout_" + family + "_" + part["name"], "Cutout/" + part["file"], world_width,
                   destination=cutout_destination, pivot=part["pivot"])
    sprite("SP_Cutout_shadow", "Cutout/" + rig["shadow"]["file"], 1,
           destination=cutout_destination, pivot=rig["shadow"]["pivot"], translucent=True)
    sources = {
        "Seagull": ("seagull_hero.png", 44, ["Seagull_Idle", "Seagull_Walk", "Seagull_Hurt", "Seagull_Death"]),
        "Crab": ("enemy_crab.png", 38, ["Crab_Walk", "Crab_Death"]),
        "Jellyfish": ("enemy_jellyfish.png", 38, ["Jellyfish_Idle", "Jellyfish_Death"]),
        "Pirate": ("enemy_pirate.png", 42, ["Pirate_Walk", "Pirate_Death"]),
        "Boss": ("enemy_octopus.png", 86, ["Boss_Idle", "Boss_Death"]),
        "XPShell": ("pickup_shell.png", 16, ["XPShell"]),
        "Coin": ("pickup_coin.png", 16, ["Coin"]),
        "Health": ("pickup_heart.png", 20, ["Health"]),
        "Feather": ("weapons.png", 16, ["Feather"]),
        "Arena": ("arena_background.png", 1200, []),
    }
    required = [ROOT / "Content" / "Textures" / record[0] for record in sources.values()]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError("Missing shared artwork: " + ", ".join(missing))
    for name, (filename, size, animations) in sources.items():
        image = sprite("SP_" + name, filename, size, (0, 0, 32, 32) if name == "Feather" else None)
        for animation in animations:
            flipbook("FB_" + animation, image)
    for path in sorted((ROOT / "Content" / "Audio").rglob("*.ogg")):
        import_file(path, "/Game/" + str(path.parent.relative_to(ROOT / "Content")).replace("\\", "/"))
    if not LIB.does_asset_exist("/Game/Materials/M_ArenaColor"):
        material = TOOLS.create_asset("M_ArenaColor", "/Game/Materials", unreal.Material, unreal.MaterialFactoryNew())
        material.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
        expression = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionVectorParameter, -300, 0)
        expression.set_editor_property("parameter_name", "Color")
        expression.set_editor_property("default_value", unreal.LinearColor(1, 1, 1, 1))
        unreal.MaterialEditingLibrary.connect_material_property(expression, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
        unreal.MaterialEditingLibrary.recompile_material(material)
        LIB.save_loaded_asset(material)
    if not LIB.does_asset_exist("/Game/Maps/MainMap"):
        level_editor = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if not level_editor.new_level("/Game/Maps/MainMap"):
            raise RuntimeError("Could not create MainMap")
        level_editor.save_current_level()
    LIB.save_directory("/Game", only_if_is_dirty=True, recursive=True)
    unreal.log("Seagull Storm assets prepared. Restart the editor to refresh constructor asset caches; then open MainMap and Play offline practice.")


if __name__ == "__main__":
    main()
