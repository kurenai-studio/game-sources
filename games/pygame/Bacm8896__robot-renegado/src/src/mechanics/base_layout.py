"""Captura y restauración del estado de la base (estructuras, depósitos y Centro de Control).

La base viaja en `ResourceManager`, así que los checkpoints de sub-acto la conservan. La escena debe
aportar: world, core, deposit_list, grid, _deposit_at() y _register() (ConstructionMixin)."""
from pygame.math import Vector2

from src.entities.building import LEGACY_STRUCTURES, Building, create_building


def layout_entries(scene):
    """Estructuras de la base (todas menos el Centro de Control) como datos: tipo, posición, vida, ruta y nivel
    (y, en la Fábrica, el ensamblaje que le falta: una Fábrica ya montada no vuelve a ensamblarse al restaurarla)."""
    out = []
    for b in scene.world.structures:
        if b.building_type == "core":
            continue
        entry = {"type": b.building_type, "pos": (b.pos.x, b.pos.y), "hp": b.hp, "route": b.route, "level": b.level}
        if hasattr(b, "build_left"):
            entry["build_left"] = float(b.build_left)
            if getattr(scene, "PRODUCTION_ON_DEPLOY", False):     # encargos pagados en la Base Central sin terminar (entre
                current = [b.current_production] if b.current_production else []   # mapas la cola viaja en factory_queue_data)
                entry["queue"] = current + list(b.production_queue)
        out.append(entry)
    return out


def capture_base(scene, res):
    """Guarda en `res` las estructuras (con su vida), el metal de los depósitos y la vida del núcleo."""
    res.base_layout = layout_entries(scene)
    res.base_core_hp = scene.core.hp
    res.base_deposits = [d.total_metal for d in scene.deposit_list]


def restore_base(scene, res):
    """Reconstruye la base guardada: estructuras con su vida, depósitos y núcleo."""
    for deposit, left in zip(scene.deposit_list, res.base_deposits or []):
        deposit.total_metal = left
    if res.base_core_hp is not None:
        scene.core.hp = min(scene.core.max_hp, res.base_core_hp)
    for entry in res.base_layout:
        pos, deposit = Vector2(entry["pos"]), None
        entry["type"] = LEGACY_STRUCTURES.get(entry["type"], entry["type"])    # Generador retirado -> Pilón
        if entry["type"] not in Building.STATS:               # partidas de versiones anteriores (Baluarte, Tesla, Lanzallamas)
            continue
        if entry["type"] == "extractor":
            deposit = scene._deposit_at(pos)
            if deposit is None:
                continue
        b = create_building(entry["type"], pos, deposit=deposit)
        if entry.get("route"):
            b.choose_route(entry["route"])                 # dual-build: la ruta A/B elegida (sin volver a cobrar)
        for level in range(2, entry.get("level", 1) + 1):    # muro Reforzado / Electrificado (sin volver a cobrar)
            b.apply_wall_level(level)
        b.hp = min(b.max_hp, entry["hp"])
        if "build_left" in entry and hasattr(b, "build_left"):
            b.build_left = entry["build_left"]
            b.production_queue = list(entry.get("queue", ()))   # encargos pagados (p. ej. en la Base Central)
        scene._register(b)
    scene.grid.update()
