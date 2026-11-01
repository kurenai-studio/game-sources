"""Simulación de balance del Acto 2 (sin ventana, modo Comandante: sin Operador): un bot construye una defensa (y drones
en la Fábrica) y juega las 5 oleadas con TODO mortal (a diferencia de smoke_test, que hace inmortales las defensas).

Uso:  python tools/balance_sim.py <perfil> <alerta> <semilla> [segundos_max]
      perfiles: none | small | medium | large      alerta: 1..5     semilla: entero
Imprime una línea JSON con el resultado (oleadas superadas, vida mínima del núcleo, estructuras perdidas...).
Sirve para ajustar UNITS.py (composición de oleadas, drops, costos) con datos y no a ojo."""
import json
import os
import random
import sys

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)

import pygame
from pygame.math import Vector2

import main
from src.managers.state_machine import GameState


class _Keys(dict):
    def __getitem__(self, k):
        return self.get(k, False)


held, mouse, mpos = _Keys(), [False, False, False], [640, 300]
pygame.key.get_pressed = lambda: held
pygame.mouse.get_pressed = lambda *a, **k: tuple(mouse)
pygame.mouse.get_pos = lambda: tuple(mpos)

# Defensas por perfil (todas al este del núcleo, que está en (420, 600); los enemigos llegan por el este).
# Tercer elemento opcional: "A"/"B" = ruta de la torreta; 2/3 = nivel del muro (Reforzado / Electrificado).
PROFILES = {
    "none": [],
    "small": [("pylon", (540, 620)), ("pylon", (660, 620)), ("tower", (700, 580)), ("tower", (700, 660)),
              ("wall", (780, 560)), ("wall", (780, 600)), ("wall", (780, 640)), ("wall", (780, 680))],
    "medium": [("pylon", (540, 620)), ("pylon", (660, 620)), ("pylon", (780, 620)),
               ("balista", (740, 540), "A"), ("balista", (740, 700)), ("tower", (740, 580), "A"), ("tower", (740, 660)),
               ("wall", (860, 540), 2), ("wall", (860, 580), 2), ("wall", (860, 620), 2), ("wall", (860, 660), 2),
               ("wall", (860, 700), 2)],
    "large": [("pylon", (540, 620)), ("pylon", (660, 620)), ("pylon", (780, 620)),
              ("pylon", (540, 540)), ("pylon", (540, 700)),          # antes 2 Generadores (retirados)
              # +9 pilones: Tesla, Lanzallamas y los muros Electrificados dejaban sin energía a la torreta B, al Foco y
              # a la Fábrica (no se construían y el perfil jugaba sin drones)
              ("pylon", (660, 540)), ("pylon", (540, 460)), ("pylon", (660, 460)), ("pylon", (540, 780)),
              ("pylon", (780, 460)), ("pylon", (420, 460)), ("pylon", (420, 780)), ("pylon", (300, 460)), ("pylon", (300, 780)),
              ("balista", (820, 540), "A"), ("balista", (820, 700), "B"), ("balista", (860, 620)),
              ("balista", (820, 580), "B"),
              ("tower", (780, 540), "A"), ("tower", (780, 700), "B"),
              ("foco", (700, 540)),
              ("wall", (900, 540), 2), ("wall", (900, 580), 3), ("wall", (900, 620), 3), ("wall", (900, 660), 3),
              ("wall", (900, 700), 2)],
}
# Fábrica de Drones por perfil: posición y drones que encarga en cuanto termina de ensamblarse
FACTORY = {"medium": ((640, 720), ["attack", "attack", "trooper"]),
           "large": ((640, 720), ["attack", "attack", "bomber", "trooper"])}


def play(profile, threat, seed, max_seconds=420):
    random.seed(seed)
    game = main.Game()
    game.new_campaign()
    game.resources.unlock_all_structures()                # la simulación usa todo el catálogo de estructuras
    res = game.resources
    res.unlock_all_tech()                                 # los perfiles usan las especializaciones de torreta
    res.initial_done = True
    res.threat_level = threat
    res.metal = 6000
    res.cores = 30                                        # holgura para poder levantar cualquier perfil
    game.machine.transition(GameState.ACT_2_BASE)
    game.machine.transition(GameState.ACT_2_SETUP)
    a2 = game.machine.screens[GameState.ACT_2_SETUP]
    for _ in range(80):                                   # intro narrativa
        if not a2.dialogue.blocking_active:
            break
        game.machine.handle_event(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_SPACE))
        game.machine.update(1 / 60)
    a2.wave.timer = 20.0
    w = a2.world
    base_metal, base_cores = res.metal, res.cores         # al entrar al Acto 2 se suma chatarra: no es coste de defensa
    built = 0
    for entry in PROFILES[profile]:
        kind, pos = entry[0], entry[1]
        a2.build_choice = kind
        n = len(w.structures)
        a2._try_build(Vector2(pos))
        a2.build_choice = None
        built += len(w.structures) > n
        if len(entry) > 2 and len(w.structures) > n:          # especialización / mejora del muro recién construido
            b = max(w.structures, key=lambda s: s.build_order)
            a2.open_menu(b)
            want = ("route", entry[2]) if isinstance(entry[2], str) else ("wall_up", entry[2])
            while b.alive() and a2.menu is not None and (b.level < entry[2] if want[0] == "wall_up" else b.route is None):
                idx = next((i for i, o in enumerate(a2.menu.options) if o["action"][0] == want[0]
                           and (want[0] == "wall_up" or o["action"][1] == want[1])), None)
                if idx is None or not a2.menu_choose(idx):
                    break
                a2.open_menu(b)
            a2.menu = None
    orders = []
    if profile in FACTORY:
        a2.build_choice = "fabrica"
        a2._try_build(Vector2(FACTORY[profile][0]))
        a2.build_choice = None
        orders = list(FACTORY[profile][1])
    spent = base_metal - res.metal
    cores_spent = base_cores - res.cores
    planned = len(PROFILES[profile]) + (profile in FACTORY)
    built += a2.factory is not None and a2.factory.alive()
    res.metal = 0
    res.cores = 0                                         # a partir de aquí, solo los núcleos que suelten Arietes y Tanques
    lost = 0
    start_structs = len(w.structures)
    cores_found = 0
    peak_energy = 0
    core_min = a2.core.hp
    drones_made, drones_peak, drone_ids = 0, 0, set()
    wave_start = []
    frames = 0
    result, wave_reached = "tiempo", 0
    while frames < 60 * max_seconds:
        # Modo Comandante (sin Operador): la defensa son las estructuras y los drones; lo caído llega solo a la base
        cores_before = res.cores
        fac = a2.factory
        while orders and fac is not None and fac.built and len(fac.production_queue) < fac.stats["production_queue_size"]:
            spec = main.U.DRONE_TYPES[orders[0]]           # el presupuesto de los drones se aparta al planificar
            res.add_metal(spec["cost"]); res.add_cores(spec["cores"])
            spent += spec["cost"]; cores_spent += spec["cores"]
            if not a2.queue_drone(orders.pop(0)):
                break
        game.machine.update(1 / 60)
        frames += 1
        cores_found += max(0, res.cores - cores_before)
        core_min = min(core_min, a2.core.hp)
        peak_energy = max(peak_energy, res.energy)
        squad = a2.combat_drones()
        drones_made += sum(1 for d in squad if id(d) not in drone_ids)
        drone_ids.update(id(d) for d in squad)
        if a2.wave.phase == "wave":
            drones_peak = max(drones_peak, len(squad))       # drones de combate en el campo durante una oleada
        if a2.wave.wave > wave_reached:                    # vida del núcleo y estructuras en pie al empezar cada oleada
            wave_start.append(f"{round(a2.core.hp)}/{len(w.structures)}")
        wave_reached = max(wave_reached, a2.wave.wave)
        state = game.machine.current_state
        if state is GameState.RETRY_SUB_ACT:
            result = "derrota"
            break
        if a2.wave.phase == "assault":
            result = "oleadas superadas"
            break
        if a2.dialogue.blocking_active:
            a2.dialogue.advance()
    lost = start_structs - len(w.structures)
    out = {"perfil": profile, "alerta": threat, "semilla": seed, "resultado": result, "oleada": wave_reached,
           "inicio_oleadas": wave_start,
           "segundos": round(frames / 60), "nucleo_min": round(core_min), "perdidas": lost, "construidas": f"{built}/{planned}", "drones": drones_made, "drones_en_oleada": drones_peak,
           "coste_defensa": round(spent), "nucleos_gastados": cores_spent, "nucleos_hallados": cores_found,
           "energia_pico": peak_energy,
           "chatarra_final": res.metal, "robada": a2.stolen, "recuperada": a2.recovered}
    return out


if __name__ == "__main__":
    prof = sys.argv[1] if len(sys.argv) > 1 else "medium"
    thr = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    sd = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    secs = int(sys.argv[4]) if len(sys.argv) > 4 else 420
    print(json.dumps(play(prof, thr, sd, secs), ensure_ascii=False))
