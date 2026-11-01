"""Atajo de pruebas: salta el Acto 1 y arranca directamente en la Base Central (terminal donde se elige qué hacer).

Uso (desde la raíz del repo):
    python tools/start_base_central.py                 campaña nueva en la Base Central
    python tools/start_base_central.py --nivel 3       con el nivel de incursión 3
    python tools/start_base_central.py --inicial-hecha incursión inicial ya completada (abre expediciones y campaña)
    python tools/start_base_central.py --modulo        con el Módulo de Mando y recursos para ensamblar el Búnker
    python tools/start_base_central.py --asedio        directo a la Guerra de Asedio (modo Comandante, 1500 de chatarra y 3 núcleos)
"""
import argparse
import logging
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import config as C                                           # noqa: E402
from main import Game                                        # noqa: E402
from src.managers.state_machine import GameState             # noqa: E402


def start(level=C.INCURSION_LEVEL_START, initial_done=False, module=False, siege=False):
    game = Game()
    game.new_campaign()
    r = game.resources
    r.equipped = r.aura_linked = r.vulcano_online = True      # lo que el Acto 1 deja ya hecho: exotraje, AURA y VULCANO
    r.incursion_level = level
    r.initial_done = initial_done or module
    if module:                                                # prueba del Búnker de Mando: módulo y recursos para ensamblarlo
        r.command_module = True
        r.metal, r.cores = max(r.metal, 600), max(r.cores, 3)
        r.incursion_level = max(r.incursion_level, 2)
    if siege:                                                 # prueba del Paso D: directo al asedio con recursos para construir
        r.initial_done, r.command_module = True, True
        r.metal, r.cores = max(r.metal, 1500), max(r.cores, 3)
        game.machine.transition(GameState.SIEGE)
        return game
    game.machine.transition(GameState.ACT_2_BASE)
    return game


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--nivel", type=int, default=C.INCURSION_LEVEL_START, help="nivel de incursión inicial (1 por defecto)")
    ap.add_argument("--inicial-hecha", action="store_true", help="marca la incursión inicial como completada")
    ap.add_argument("--asedio", action="store_true", help="arranca directamente en la Guerra de Asedio (modo Comandante)")
    ap.add_argument("--modulo", action="store_true", help="con el Módulo de Mando y 600 de chatarra y 3 núcleos para ensamblar el Búnker")
    args = ap.parse_args()
    logging.basicConfig(level=logging.WARNING, format="[aviso] %(message)s")
    start(max(1, args.nivel), args.inicial_hecha, args.modulo, args.asedio).run()
    sys.exit(0)
