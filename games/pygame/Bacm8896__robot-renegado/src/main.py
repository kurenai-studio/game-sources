"""Robot Renegado - Tower Defense activo + RTS táctico + ARPG ciberpunk (Python / Pygame).

Ejecutar:  python main.py
"""
import logging
import math
import random
import sys

import pygame
from pygame.math import Vector2

import config as C
from src.core.audio_manager import audio
from src.entities import WorldRefs
from src.entities.ai_ally import AIAlly
from src.entities.chassis import ChassisPart
from src.entities.drones import AuraDrone
from src.entities.enemy_base import EnemyBase, base_positions, bases_for_alert
from src.entities.core_item import CoreItem
from src.entities.enemy import Enemy, roll_core_drop, roll_drop
from src.entities.building import BUILD_MENU, create_building
from src.entities.foundry import build_foundry
from src.entities.power import PowerGrid
from src.entities.projectile import Projectile
from src.entities.resource_node import ScrapDeposit
from src.entities.scavenger import ScavengerDrone
from src.entities.scrap import ScrapItem
from src.entities.vulcano import Vulcano
from src.entities.factory import explorer_cap, explorer_count, fleet_capacity
from src.managers.resource_manager import CampaignRun, ResourceManager
from src.managers.state_machine import FIRST_STATE_OF, GameState, State, StateMachine, SubAct
from src.map.game_map import Camera, GameMap
from src.mechanics import combat
from src.mechanics.base_layout import capture_base, restore_base
from src.mechanics import save_manager as saves
from src.mechanics.commander import Absent, NoOperator
from src.mechanics.construction import ConstructionMixin
from src.mechanics.fog import MapFog
from src.mechanics.scenario import scenario_of
from src.mechanics.selection import DroneSelectionMixin
from src.mechanics.upgrades import UpgradeManager
from src.scenes.main_menu import MainMenuState
from src.scenes.campaign_menu import CampaignMenuState
from src.mechanics.pathing import FlowField
from src.mechanics.wave import RenegadeFoundry, WaveManager
from src.scenes.base_management import BaseManagementState
from src.scenes.campaign_victory import CampaignVictoryState
from src.scenes.incursion_scene import IncursionScene
from src.scenes.act1 import Sub11State, Sub12State, Sub13State, Sub14State
from src.ui.dialogue_box import DialogueBox
from src.ui.hints import HintManager
from src.ui.tooltips import TooltipManager, node_card
from src.ui.hud import HUD
from src.config import UNITS as U


# =============================================================================
# Menu
# =============================================================================
# =============================================================================
# Base Central: terminal tactico (ACT_2_BASE)
# =============================================================================
# Sub-actos del Acto 1 que, al empezar, autoguardan el perfil y son su punto de reanudación
ACT1_RESUME = {SubAct.S1_1: GameState.SUB_ACT_1_1, SubAct.S1_2: GameState.SUB_ACT_1_2,
               SubAct.S1_3: GameState.SUB_ACT_1_3, SubAct.S1_4: GameState.SUB_ACT_1_4}

TREE_COLUMNS = {"offensive": (640, "RAMA OFENSIVA · Balística"), "survival": (950, "RAMA DE SUPERVIVENCIA · Exotraje")}
NODE_W, NODE_H, NODE_STEP, NODE_TOP = 300, 62, 70, 268
OPS_TOP, OPS_STEP, OPS_H = 244, 62, 58          # tablero de incursiones del Terminal: 5 tarjetas de operación


def tree_layout():
    """Posición de cada nodo del árbol de mejoras: por rama, una cadena (cada nodo cuelga del anterior). Nodos de 62 px:
    nombre en una línea y efecto en hasta dos, sin recortar."""
    rects = {}
    for branch, (x, _) in TREE_COLUMNS.items():
        for i, node in enumerate(U.UPGRADES_TREE[branch]):
            rects[node] = pygame.Rect(x + 6 * i, NODE_TOP + i * NODE_STEP, NODE_W - 6 * i, NODE_H)
    return rects


def wrap_px(hud, text, width, size="s"):
    """Parte `text` en líneas que caben en `width` píxeles con la fuente `size` del HUD."""
    lines, cur = [], ""
    for word in text.split():
        cand = f"{cur} {word}".strip()
        if cur and hud._render(size, cand, C.WHITE).get_width() > width:
            lines.append(cur)
            cur = word
        else:
            cur = cand
    if cur:
        lines.append(cur)
    return lines


def _clip(text, n):
    return text if len(text) <= n else text[:n - 1] + "…"


class InterludeState(State):
    def enter(self):
        self.game.begin_sub_act(SubAct.S2_0)
        self.game.autosave("ACT_2_BASE")                   # autoguardado al entrar a la Base Central tras una misión
        r = self.game.resources
        self.op_rects = {op: pygame.Rect(60, OPS_TOP + i * OPS_STEP, 560, OPS_H) for i, op in enumerate(U.OPS_ORDER)}
        self.proceed_rect = pygame.Rect(60, OPS_TOP + len(U.OPS_ORDER) * OPS_STEP + 2, 560, 38)
        pending = [op for op in U.OPS_ORDER if r.op_unlocked(op) and not r.op_cleared(op)]
        self.selected = U.OPS_ORDER.index(pending[0]) if pending else len(U.OPS_ORDER) - 1   # la siguiente por superar
        self.board_msg = ""
        self.node_rects = tree_layout()
        self.drone_rects = {name: pygame.Rect(640 + i * 153, 576, 148, 40)
                            for i, name in enumerate(U.DRONE_UPGRADES)}   # mejoras permanentes de la Fábrica
        self.tech_rects = {key: pygame.Rect(640 + i * 153, 684, 148, 32)
                           for i, key in enumerate(U.TURRET_TECH)}        # especializaciones de torreta (Tech-Tree)
        self.upgrade_msg = ""

    # --- árbol de mejoras del Operador (persistente entre actos) ---
    def _buy_node(self, node):
        res, spec = self.game.resources, U.OPERATOR_TREE[node]
        state = res.node_state(node)
        if state == "owned":
            self.upgrade_msg = f"{spec['label']}: ya la tienes."
        elif state == "locked":
            self.upgrade_msg = f"Bloqueada: requiere {U.OPERATOR_TREE[spec['requires']]['label']}."
        elif res.buy_node(node):
            self.upgrade_msg = f"{spec['label']} comprada (-{spec['cores']} núcleos de plasma)."
        else:
            self.upgrade_msg = f"Faltan núcleos de plasma para {spec['label']} ({spec['cores']})."

    def _buy_drone_upgrade(self, name):
        res, spec = self.game.resources, U.DRONE_UPGRADES[name]
        dt = U.DRONE_TYPES[spec["type"]]
        if name in res.drone_upgrades:
            self.upgrade_msg = f"{dt['name']}: mejora ya instalada."
        elif res.buy_drone_upgrade(name):
            self.upgrade_msg = f"{dt['name']}: {dt['upgrade_description']} (permanente)."
        else:
            self.upgrade_msg = f"Falta aleación militar ({spec['alloy']}) para la mejora del {dt['name']}."

    def _buy_turret_tech(self, key):
        res, spec = self.game.resources, U.TURRET_TECH[key]
        kind = "Torreta Ligera" if spec["turret"] == "tower" else "Balista"
        if key in res.unlocked_tech:
            self.upgrade_msg = f"{spec['label']}: ya desbloqueada."
        elif res.unlock_route(key):
            self.upgrade_msg = f"{spec['label']} desbloqueada para la {kind} (permanente): especialízala con clic der."
        else:
            self.upgrade_msg = f"Falta aleación militar ({spec['alloy']}) para desbloquear {spec['label']}."

    def _draw_turret_tech(self, screen, mouse):
        hud, r = self.game.hud, self.game.resources
        hud.text(screen, "ESPECIALIZACIONES DE TORRETA · se desbloquean aquí, se pagan en la base", (640, 664), "s", C.CYAN)
        for key, rect in self.tech_rects.items():
            spec = U.TURRET_TECH[key]
            owned = key in r.unlocked_tech
            afford = r.alloy >= spec["alloy"]
            border = C.GREEN if owned else (C.YELLOW if afford else C.ORANGE)
            hud.panel(screen, rect, border)
            if rect.collidepoint(mouse) and not owned:
                pygame.draw.rect(screen, border, rect, 3)
            hud.text(screen, spec["label"], (rect.x + 6, rect.y + 7), "s", C.GREEN if owned else C.WHITE, shadow=False)
            if owned:
                hud.text(screen, "LISTA", (rect.right - 48, rect.y + 7), "s", C.GREEN, shadow=False)
            else:
                hud.cost_row(screen, (rect.right - 44, rect.y + 7), alloy=spec["alloy"],
                             afford=(True, True, True, afford))

    def _draw_drone_upgrades(self, screen, mouse):
        hud, r = self.game.hud, self.game.resources
        for name, rect in self.drone_rects.items():
            spec = U.DRONE_UPGRADES[name]
            dt = U.DRONE_TYPES[spec["type"]]
            owned = name in r.drone_upgrades
            afford = r.alloy >= spec["alloy"]
            border = C.GREEN if owned else (C.YELLOW if afford else C.ORANGE)
            hud.panel(screen, rect, border)
            if rect.collidepoint(mouse) and not owned:
                pygame.draw.rect(screen, border, rect, 3)
            hud.text(screen, _clip(dt["name"].replace("Dron ", "Dron "), 18), (rect.x + 6, rect.y + 3), "s",
                     C.GREEN if owned else C.WHITE, shadow=False)
            if owned:
                hud.text(screen, _clip(dt["upgrade_description"], 18), (rect.x + 6, rect.y + 21), "s", C.GREEN, shadow=False)
            else:
                hud.cost_row(screen, (rect.x + 6, rect.y + 21), alloy=spec["alloy"],
                             afford=(True, True, True, r.alloy >= spec["alloy"]))

    # --- acciones ---
    def launch_op(self, op):
        """Despliega al Operador en la operación `op` del tablero si está desbloqueada (las superadas se pueden repetir)."""
        r = self.game.resources
        i = U.OPS_ORDER.index(op)
        if not r.op_unlocked(op):
            prev = U.INCURSION_OPS[U.OPS_ORDER[i - 1]]
            self.board_msg = f"Bloqueada: supera antes la Op {prev['index']} ({prev['name']})."
            audio.play("error")
            return False
        self.selected = i
        self.game.machine.transition(GameState.INCURSION, op=op)
        return True

    def _proceed(self):
        if self.game.resources.initial_done:
            self.game.machine.transition(GameState.CAMPAIGN_MENU)     # elegir mapa de campaña antes del Acto 2
        else:
            self.board_msg = "Supera antes la Op 1 (Reconocimiento de Perímetro) para proceder al Acto 2."

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            digits = (pygame.K_1, pygame.K_2, pygame.K_3, pygame.K_4, pygame.K_5)
            if event.key in digits[:len(U.OPS_ORDER)]:
                self.launch_op(U.OPS_ORDER[digits.index(event.key)])
            elif event.key in (pygame.K_UP, pygame.K_DOWN):
                step = -1 if event.key == pygame.K_UP else 1
                self.selected = (self.selected + step) % len(U.OPS_ORDER)
                self.board_msg = ""
            elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self.launch_op(U.OPS_ORDER[self.selected])
            elif event.key == pygame.K_6:
                self._proceed()
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for op, rect in self.op_rects.items():
                if rect.collidepoint(event.pos):
                    self.launch_op(op)
                    return
            if self.proceed_rect.collidepoint(event.pos):
                self._proceed()
                return
            for node, rect in self.node_rects.items():
                if rect.collidepoint(event.pos):
                    self._buy_node(node)
            for name, rect in self.drone_rects.items():
                if rect.collidepoint(event.pos):
                    self._buy_drone_upgrade(name)
            for key, rect in self.tech_rects.items():
                if rect.collidepoint(event.pos):
                    self._buy_turret_tech(key)

    def _draw_board(self, screen, mouse):
        """Tablero de incursiones: una tarjeta por operación (título, dificultad, objetivo y botín estimado) y el paso al
        Acto 2. Verde = superada (repetible), amarillo = disponible, gris = bloqueada; la seleccionada lleva marco grueso."""
        hud, r = self.game.hud, self.game.resources
        for i, (op, rect) in enumerate(self.op_rects.items()):
            spec = U.INCURSION_OPS[op]
            cleared, unlocked = r.op_cleared(op), r.op_unlocked(op)
            color = C.GREEN if cleared else (C.YELLOW if unlocked else C.DARK_GRAY)
            hud.panel(screen, rect, color)
            if i == self.selected or (unlocked and rect.collidepoint(mouse)):
                pygame.draw.rect(screen, color if unlocked else C.ORANGE, rect, 3)
            state = "SUPERADA" if cleared else ("DISPONIBLE" if unlocked else "BLOQUEADA")
            fg = C.WHITE if unlocked else C.DARK_GRAY
            hud.text(screen, f"[{spec['index']}] {spec['name'].upper()}", (rect.x + 10, rect.y + 4), "s", color)
            tag = f"Nivel {r.op_level(op)} · {state}"
            hud.text(screen, tag, (rect.right - 10 - hud._render("s", tag, color).get_width(), rect.y + 4), "s", color)
            hud.text(screen, _clip(spec["summary"], 68), (rect.x + 10, rect.y + 22), "s", fg, shadow=False)
            first = "" if cleared else f" · +{spec['first_bonus']} 1ª vez"
            hud.text(screen, _clip(spec["loot_text"] + first, 68), (rect.x + 10, rect.y + 39), "s",
                     C.YELLOW if unlocked else C.DARK_GRAY, shadow=False)
        rect, ready = self.proceed_rect, r.initial_done
        hud.panel(screen, rect, C.CYAN if ready else C.DARK_GRAY)
        if ready and rect.collidepoint(mouse):
            pygame.draw.rect(screen, C.CYAN, rect, 3)
        hud.text(screen, "[6] PROCEDER AL ACTO 2 · ELEGIR MAPA" if ready else "[6] ACTO 2: supera antes la Op 1",
                 (rect.x + 10, rect.y + 10), "s", C.CYAN if ready else C.DARK_GRAY)

    def _draw_node(self, screen, node, rect, mouse):
        hud, r = self.game.hud, self.game.resources
        spec, state = U.OPERATOR_TREE[node], r.node_state(node)
        scrap, cores = spec["cost"], spec["cores"]
        border = {"owned": C.GREEN, "available": C.YELLOW if r.can_pay(scrap, cores) else C.ORANGE,
                  "locked": C.DARK_GRAY}[state]
        hud.panel(screen, rect, border)
        if state == "available" and rect.collidepoint(mouse):
            pygame.draw.rect(screen, border, rect, 3)
        if spec["tier"] >= 2:                                                 # conector con su prerrequisito
            pygame.draw.line(screen, border, (rect.x - 8, rect.y - (NODE_STEP - NODE_H) - 2), (rect.x - 8, rect.centery), 1)
            pygame.draw.line(screen, border, (rect.x - 8, rect.centery), (rect.x, rect.centery), 1)
        fg = C.GREEN if state == "owned" else (C.WHITE if state == "available" else C.DARK_GRAY)
        hud.text(screen, spec["label"], (rect.x + 8, rect.y + 5), "s", fg)       # el nombre entero (cabe en la fila)
        if state == "owned":
            hud.text(screen, "COMPRADO", (rect.right - 86, rect.y + 5), "s", C.GREEN)
            sub, sub_color = spec["effect"], C.GREEN
        elif state == "locked":
            sub, sub_color = f"Requiere: {U.OPERATOR_TREE[spec['requires']]['label']} · {cores} núcleos", C.DARK_GRAY
        else:
            hud.cost_row(screen, (rect.right - 54, rect.y + 5), scrap, cores, 0,
                         (r.can_afford(scrap), r.cores >= cores, True))
            sub, sub_color = spec["effect"], (190, 195, 210)
        for i, line in enumerate(wrap_px(hud, sub, rect.w - 16)[:2]):            # efecto en hasta dos líneas, sin recortar
            hud.text(screen, line, (rect.x + 8, rect.y + 23 + i * 18), "s", sub_color, shadow=False)

    def draw(self, screen):
        hud, r = self.game.hud, self.game.resources
        screen.fill((4, 10, 12))
        for y in range(0, C.WINDOW_HEIGHT, 4):
            pygame.draw.line(screen, (6, 16, 18), (0, y), (C.WINDOW_WIDTH, y))
        hud.text(screen, "TERMINAL TÁCTICO // BASE CENTRAL", (60, 22), "l", C.CYAN)
        hud.text(screen, U.lore_title("AURA"), (62, 64), "s", (0, 150, 150), shadow=False)     # denominación oficial de AURA
        hud.resources_row(screen, (60, 90), r)
        hud.text(screen, f"Nivel de Alerta: {r.threat_level}  (asedio +{r.threat_bonus_pct}% enemigos)", (60, 120), "m",
                 C.RED if r.threat_bonus_pct else C.DARK_GRAY)
        hud.text(screen, f"Ensamblaje del chasis de AURA: {r.assembly_pct}% ({r.chassis_installed}/{C.CHASSIS_TOTAL_PARTS})", (60, 155), "s", C.WHITE)
        hud.bar(screen, (60, 178, 360, 12), r.assembly_pct / 100, C.CYAN)
        status = []
        if r.aura_linked:
            status.append("AURA: copiloto en el traje")
        if r.vulcano_online:
            status.append("VULCANO: en línea")
        if r.initial_done:
            status.append("BÚNKER: " + ("ensamblado" if r.bunker_built else
                                        "listo para montar" if r.command_module else "sin Módulo de Mando"))
        if status:
            hud.text(screen, " · ".join(status), (60, 205), "s", C.ORANGE)
        hint = self.board_msg or "TABLERO DE INCURSIONES · [1-5] desplegar · ↑/↓ + ENTER · repetibles"
        hud.text(screen, _clip(hint, 70), (60, 222), "s", C.ORANGE if self.board_msg else C.YELLOW)

        mouse = pygame.mouse.get_pos()
        self._draw_board(screen, mouse)

        hud.progress_bar.draw(hud, screen, (640, 196), r)
        hud.text(screen, "MEJORAS DEL OPERADOR · clic para comprar", (640, 224), "m", C.CYAN)
        hud.text(screen, "DRONES DE LA FÁBRICA · mejoras permanentes", (640, 558), "s", C.CYAN)
        for branch, (x, title) in TREE_COLUMNS.items():
            hud.text(screen, title, (x, 250), "s", C.MAGENTA if branch == "offensive" else C.CYAN)
        for node, rect in self.node_rects.items():
            self._draw_node(screen, node, rect, mouse)
        self._draw_drone_upgrades(screen, mouse)
        self._draw_turret_tech(screen, mouse)
        if self.upgrade_msg:
            hud.text(screen, _clip(self.upgrade_msg, 70), (640, 622), "s", C.MAGENTA)
        elif not r.owns("gatillo_automatico"):
            hud.text(screen, "Mejora: Gatillo Automático para fuego continuo", (640, 622), "s", C.CYAN)
        hist_y = self.proceed_rect.bottom + 8
        hud.text(screen, "HISTORIAL DE OPERACIONES", (60, hist_y), "s", C.CYAN)
        for i, entry in enumerate(r.history[-3:] or ["(sin registros)"]):              # las 3 últimas
            hud.text(screen, _clip("> " + entry, 70), (60, hist_y + 20 + i * 20), "s", C.WHITE)
        for i, line in enumerate(self.game.report):
            hud.text(screen, _clip(line, 62), (640, 644 + i * 20), "s", C.MAGENTA)
        # tooltip de la mejora bajo el ratón (0,5 s de retardo)
        tt = self.game.tooltips
        hovered = next((n for n, rc in self.node_rects.items() if rc.collidepoint(mouse)), None)
        if hovered is None:
            tt.clear()
        elif tt.hover(("node", hovered)):
            hud.draw_card(screen, mouse, node_card(hovered, r))


# =============================================================================
# Sub-acto 2.1: asedio inicial y fundicion (ACT_2_SETUP -> ACT_2_PLAY)
# =============================================================================
REWARD_POPUP_TIME = 3.0                     # segundos que se ve el cartel de reward


COMBAT_DRONES = ("attack", "bomber", "trooper")


class Act2State(DroneSelectionMixin, ConstructionMixin, State):
    FREE_CAMERA = True                                     # modo Comandante: cámara RTS libre (WASD, bordes, clic central)
    # Valores del escenario clásico; enter() los sustituye por los del mapa de campaña elegido (si lo hay)
    CC_POS = Vector2(C.ACT2_CC_POS)
    FOUNDRY_POS = Vector2(C.ACT2_FOUNDRY_POS)
    SPAWN_ZONE = pygame.Rect(C.ACT2_SPAWN_ZONE)            # puertas de la Fundicion

    def enter(self):
        self.assault = self.game.machine.current_state is GameState.ACT_2_ASSAULT     # sub-acto 2.2
        self.sub_act = SubAct.S2_2 if self.assault else SubAct.S2_1
        retried = self.game.begin_sub_act(self.sub_act)
        self.res = self.game.resources
        run = self.res.campaign_run
        if retried and not self.assault:                   # reintento del mapa: base, drones y AURA como al empezarlo
            run.start_map(self.res.campaign_map, res=self.res)
        elif retried:                                      # reintento del 2.2: AURA vuelve, la base es la del final del 2.1
            run.restart_attempt()
        self.scenario = sc = scenario_of(self.res)         # mapa de campaña (o el clásico)
        self.CC_POS, self.map_w, self.map_h = Vector2(sc.cc_pos), sc.w, sc.h
        self.FOUNDRY_POS = Vector2(sc.foundry_pos) if sc.foundry_pos is not None else None
        self.SPAWN_ZONE = sc.spawn_zone
        if retried:
            self.res.metal = C.RESCUE_METAL               # presupuesto de rescate
        elif not self.assault:                            # despliegue del 2.1: mínimo garantizado + bono de despliegue
            self.res.metal = max(self.res.metal, C.STARTING_METAL_ACT2) + C.ACT2_DEPLOY_BONUS
        elif self.res.metal < C.STARTING_METAL_ACT2:      # 2.2: mínimo garantizado
            self.res.metal = C.STARTING_METAL_ACT2
        combat.FX.clear()
        map_rect = pygame.Rect(0, 0, self.map_w, self.map_h)
        Projectile.world_rect = map_rect
        ScavengerDrone.arena = map_rect
        self.map_rect = map_rect
        self.game_map = GameMap.arena(self.map_w, self.map_h, self.CC_POS, self.FOUNDRY_POS)
        self.camera = Camera(C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
        self.all_sprites = pygame.sprite.Group()
        self.world = WorldRefs(all_sprites=self.all_sprites, bounds=map_rect)
        w = self.world
        self._init_construction()
        self.build_menu = BUILD_MENU
        self.dialogue = DialogueBox()
        self.grid = PowerGrid(w)
        self.nav = FlowField(self.map_w, self.map_h)
        self.foundry = RenegadeFoundry()

        self.core = create_building("core", self.CC_POS)
        self.core.use_reactor_art()                         # Reactor Central (como en el 1.3)
        self.core.self_defense = True                       # sin piloto: el núcleo se defiende de lo que se cuela
        w.core = self.core
        self._register(self.core)
        self.deposit_list = []
        for off in sc.deposit_offsets:
            dep = ScrapDeposit(self.CC_POS + Vector2(off))
            self.deposit_list.append(dep)
            w.deposits.add(dep)
            self.all_sprites.add(dep)
        restore_base(self, self.res)                      # base guardada en la Base Central (con su vida)
        self.setup_bunker()                               # sitio de obra del Búnker de Mando (o el Búnker ya ensamblado)
        self.foundry_core = build_foundry(self.FOUNDRY_POS, w) if self.FOUNDRY_POS is not None else None
        # Modo Comandante: el Operador no está en el mapa (vista cenital RTS). Construcción, drones y órdenes con el ratón.
        self.player = NoOperator()
        self.absent = Absent()
        self.order_marker = None                          # marca de la última orden Attack-Move de los drones
        self.auto_collect_delay = C.AUTO_COLLECT_DELAY    # s en el suelo antes de que la base recoja lo caído
        self.ally = AIAlly(self.CC_POS)
        self.ally.mode = "guard"
        self.ally.dialogue = self.dialogue
        w.player = None
        self.all_sprites.add(self.ally)
        self.aura_drone = None                            # AURA en combate (chasis 6/6): aparece con la primera oleada
        self._low_energy_cd = 0.0                         # diálogos contextuales AURA/VULCANO (con enfriamiento)
        self._low_energy_armed = True
        self._wall_line_cd = 0.0
        self.paused = False                               # pausa táctica (ESPACIO): dt = 0
        self.hints = self.game.hints
        self.hints.clear_active()
        self._damaged_check = 0.0
        self._sync_energy()
        self.vulcano = None
        if self.res.vulcano_online:                       # VULCANO vinculado al Centro de Control
            self.vulcano = Vulcano(self.CC_POS + Vector2(0, -70))
            self.all_sprites.add(self.vulcano)
        w.vulcano = self.vulcano                           # las Compuertas lo reconocen como aliado
        self.camera.update(self.CC_POS, (self.map_w, self.map_h))
        # niebla de guerra persistente: la base y lo construido se conocen; el resto, a explorar
        self.fog = MapFog(self.map_w, self.map_h, U.FOG["cell"])
        self.fog.load(self.res.act2_fog)
        self.fog.reveal_fog(self.CC_POS.x, self.CC_POS.y, U.FOG["core_radius"])
        for s in w.structures:
            self.fog.reveal_fog(s.pos.x, s.pos.y, U.FOG["structure_radius"])
        self._spawn_enemy_bases()
        facs = self.factories                              # drones y cola: del mapa anterior (2.1) o del final del 2.1 (2.2)
        drones_data = self.res.base_drones if self.assault else None
        queue_data = self.res.base_factory_queue if self.assault else None
        run.deserialize_drones(w, factories=facs, upgrades=self.res.drone_upgrades, rewards=self.res.reward_tracker,
                               on_collect=self._on_scrap_collected, on_drop=self._on_drone_drop, data=drones_data, origin=self.CC_POS if self.assault else None)
        run.deserialize_factory_queue(facs, self.res, data=queue_data)
        run.bind(self)                                     # referencias vivas del mapa (se sueltan al terminarlo)

        self._tank_alloy_given = False
        self.wave = WaveManager(w, self.res.threat_level, self.CC_POS, self._on_enemy_death,
                                self.SPAWN_ZONE if sc.classic or sc.has_foundry else self._base_zones, self.foundry,
                                plan=sc.plan, break_time=sc.break_time, generator=sc.generator, endless=sc.endless)
        if self.assault:                                   # 2.2: sin oleadas, solo incursiones de la Fundicion
            self.wave.wave = self.wave.total_waves
            self.wave.phase = "assault"
            self.wave.raid_timer = 5.0
            self._deploy_aura()
        self.end_timer = None
        self.victory = False
        self.fail_reason = ""
        self.campaign_failed = False
        self.reward_popup = None       # cartel del reward recién obtenido
        self.upgrade_manager = UpgradeManager(self.res)     # vista del árbol del Operador y de los rewards
        self.show_tree = False                              # T: árbol del Operador a pantalla
        self.pending_scavs = []       # [segundos, scrap]
        self.stolen = 0
        self.stolen_cores = 0
        self.recovered = 0
        intro = [("AURA", f"Asalto a la Fundición, {self.res.player_name}: lidera al escuadrón, destruye sus torretas y "
                          "demuele el núcleo.")
                 if self.assault else
                 ("AURA", "Núcleo en línea. Extiende pilones (3) desde la base: torretas y extractores los necesitan.")]
        if self.vulcano is not None:
            intro.append(("VULCANO", "Repararé las estructuras que caigan por debajo del 50%, a cambio de metal."))
        if retried:                                        # al reintentar no se repite la historia: solo un aviso
            self.ally.say(f"Reintento: presupuesto de rescate de {C.RESCUE_METAL} metal.", 6, sender="SISTEMA")
        else:
            for sender, text in intro:                     # historia clave: pausa el juego hasta avanzarla
                self.dialogue.say(sender, text, blocking=True)
        if self.res.threat_bonus_pct:
            self.ally.say(f"Alerta {self.res.threat_level}: espera +{self.res.threat_bonus_pct}% de enemigos.", 8)
        if not self.assault:                              # tutorial intradiegético de la fase de preparación
            self.hints.show("build", "Clic izq. para construir", "click_left",
                            anchor=lambda: self.core.pos + Vector2(0, -100))
            self.hints.show("pause", "Barra espaciadora: pausa táctica", "space")

    # --- ganchos del mixin de construccion ---
    def build_discount(self):
        """Balance P1: el -50% de la preparación solo vale en tiempo real. En pausa táctica se construye a precio
        completo (si no, pausar en la preparación daba descuento ilimitado: el temporizador no corre)."""
        if self.paused:
            return 0.0
        return self.wave.build_discount

    def notify(self, text, ttl=3.0):
        self.ally.say(text, ttl)

    # --- utilidades ---
    def _drop_scrap(self, pos, value=C.SCRAP_VALUE):
        s = ScrapItem(pos, value)
        self.world.scraps.add(s)
        self.all_sprites.add(s)
        return s

    def _on_scrap_collected(self, value):
        """Chatarra al inventario (recogida a pie, con E o aspirada por el Magneto)."""
        self.res.add_metal(value)
        self.recovered += value
        self.foundry.intercept(value)                       # chatarra interceptada: oleadas mas debiles

    # --- callbacks de muerte / fuga ---
    def _on_enemy_death(self, enemy):
        self.res.add_metal(C.KILL_METAL)
        if enemy.enemy_type == "tank" and self._tank_alloy_due():
            self._tank_alloy_given = True
            self.res.add_alloy(U.ALLOY_BONUS["tank_drop"])
            self.ally.say(f"¡Tanque pesado destruido! +{U.ALLOY_BONUS['tank_drop']} aleación militar.", 4)
        cores = roll_core_drop(enemy.enemy_type)                        # Núcleos de Plasma: Ariete 1, Tanque 2 (50%)
        if enemy.enemy_type == "ariete":                   # los Arietes de la Fundicion llevan piezas del chasis
            if self.res.chassis_part_due(len(self.world.parts)):
                part = ChassisPart(enemy.pos, self.res.chassis_found + len(self.world.parts))
                self.world.parts.add(part)
                self.all_sprites.add(part)
            else:                                          # chasis completo (6/6): la pieza sobrante vale chatarra y núcleos
                self._drop_scrap(enemy.pos + Vector2(-14, 10), U.CHASSIS_SURPLUS["scrap"])
                cores += U.CHASSIS_SURPLUS["cores"]
        if cores:
            item = CoreItem(enemy.pos + Vector2(14, 10), cores)
            self.world.core_items.add(item)
            self.all_sprites.add(item)
            if random.random() < C.SCAVENGER_DISPATCH_CHANCE:             # los núcleos también atraen carroñeros
                self.pending_scavs.append([random.uniform(*C.SCAVENGER_DELAY), item])
        value = roll_drop(enemy.enemy_type)                 # probabilidad y cantidad según el tipo (UNITS)
        if value:
            scrap = self._drop_scrap(enemy.pos, value)
            if random.random() < C.SCAVENGER_DISPATCH_CHANCE:
                self.pending_scavs.append([random.uniform(*C.SCAVENGER_DELAY), scrap])

    def _tank_alloy_due(self):
        """+1 Aleación garantizada por el primer Tanque de oleada avanzada del mapa (solo si el mapa no estaba ya ganado)."""
        if getattr(self, "_tank_alloy_given", False) or self.wave.wave < U.ALLOY_BONUS["tank_min_wave"]:
            return False
        run = self.res.campaign_run
        return run.current_map_key is None or run.current_map_key not in run.completed_maps

    def _on_scavenger_death(self, drone):
        loot = drone.death_loot()                       # lo robado + su drop base
        if loot:
            self._drop_scrap(drone.pos, loot)
        if drone.stolen_scrap:
            self.ally.say("¡El carroñero soltó la chatarra! Recógela antes de que se pierda.", 3)
        if drone.cores_value:
            item = CoreItem(drone.pos, drone.cores_value)
            self.world.core_items.add(item)
            self.all_sprites.add(item)
            self.ally.say("¡El carroñero soltó los núcleos de plasma! Recógelos.", 3)

    def _on_sabotage(self, drone, pylon):
        self.ally.say(f"¡Un carroñero saboteó un pilón! Apagado {C.SCAVENGER_SABOTAGE_TIME:.0f} s: las torretas pueden quedarse sin energía.", 5)

    def _on_scavenger_escape(self, drone):
        self.stolen += drone.scrap_value
        upgrades = self.foundry.add_scrap(drone.scrap_value) if drone.scrap_value else []
        if drone.cores_value:
            self.stolen_cores += drone.cores_value
            self.ally.say(f"¡Un carroñero escapó con {drone.cores_value} núcleo(s) de plasma!", 4)
        if drone.scrap_value:
            self.ally.say(f"Un carroñero escapó con {drone.scrap_value} de metal hacia la Fundición.", 4)
        for up in upgrades:
            self.ally.say("¡La Fundición forja un Ariete blindado!" if up == "ram"
                          else "¡La Fundición acelera el asedio!", 5)

    def _spawn_scavenger(self, scrap):
        """Un carroñero entra por un borde atraído por el botín que cayó; a partir de ahí decide solo (ver ScavengerDrone):
        chatarra primero, si no queda va a por un pilón, y huye por el borde más cercano."""
        a = self.map_rect
        side = random.choice("lrtb")
        start = {"l": Vector2(a.left - 30, random.uniform(a.top, a.bottom)),
                 "r": Vector2(a.right + 30, random.uniform(a.top, a.bottom)),
                 "t": Vector2(random.uniform(a.left, a.right), a.top - 30),
                 "b": Vector2(random.uniform(a.left, a.right), a.bottom + 30)}[side]
        drone = ScavengerDrone(start, scrap.pos)
        drone.on_death = self._on_scavenger_death
        drone.on_escape = self._on_scavenger_escape
        drone.on_sabotage = self._on_sabotage
        w = self.world
        w.scavengers.add(drone)
        w.targets.add(drone)
        self.all_sprites.add(drone)

    # --- Fábrica de Drones (F1-F4) ---
    DRONE_KEYS = {pygame.K_F1: "recon", pygame.K_F2: "attack", pygame.K_F3: "bomber", pygame.K_F4: "trooper"}

    @property
    def factories(self):
        """Fábricas de Drones en pie, de la más antigua a la más nueva (se pueden construir varias)."""
        return sorted((f for f in self.world.factories if f.alive()), key=lambda f: f.build_order)

    @property
    def factory(self):
        """La primera Fábrica en pie (o None): atajo para quien solo necesita una."""
        return next(iter(self.factories), None)

    def configure_building(self, building):
        """La Fábrica recibe las mejoras permanentes y a quién entregar la chatarra recogida."""
        fog = getattr(self, "fog", None)
        if fog is not None:                                 # lo que construyes ilumina su entorno
            fog.reveal_fog(building.pos.x, building.pos.y, U.FOG["structure_radius"])
        if building.building_type == "fabrica":
            building.upgrades = self.res.drone_upgrades
            building.rewards = self.res.reward_tracker
            building.on_collect = self._on_scrap_collected
            building.on_drop = self._on_drone_drop
            building.on_spawn = self._on_drone_spawn

    def factory_drones(self):
        return [d for d in self.world.drones if d.alive() and hasattr(d, "home")]

    def queue_drone(self, drone_type):
        """F1-F4: encarga un dron a la fábrica con menos carga (cada una tiene su cola de 10 s por dron). Devuelve True si
        entró en una cola."""
        spec = U.DRONE_TYPES[drone_type]
        facs = self.factories
        if not facs:
            self.ally.say("Construye primero una Fábrica de Drones (tecla 7).", 3, sender="SISTEMA")
            return False
        ready = [f for f in facs if f.can_queue(drone_type)[0]]
        if not ready:
            self.ally.say(facs[0].can_queue(drone_type)[1], 3, sender="SISTEMA")
            return False
        if not self.res.can_afford(spec["cost"]):
            self.ally.say(f"Chatarra insuficiente para el {spec['name']}.", 3, sender="SISTEMA")
            return False
        fac = min(ready, key=lambda f: (f.load(), f.build_order))
        fac.produce_drone(drone_type, self.res)
        self.ally.say(f"{spec['name']} en cola (-{spec['cost']} chatarra).", 3, sender="SISTEMA")
        return True

    def _on_drone_spawn(self, drone):
        """Gancho al nacer un dron (reservado para avisos)."""

    def _on_drone_drop(self, value, pos):
        """Derribaron a un Explorador con carga: la chatarra cae al suelo donde murió (se recupera sola si nadie la roba)."""
        self._drop_scrap(Vector2(pos), value)
        self.ally.say(f"¡Explorador derribado! Soltó {value} de chatarra: defiéndela de los carroñeros.", 4)

    FLEET_LABELS = (("attack", "Asalto"), ("bomber", "Bombardero"), ("recon", "Recon"), ("trooper", "Soldado"))

    def fleet_breakdown(self):
        """Composición de la escuadra en vuelo por tipo ("Asalto: 2 · Bombardero: 1 · Recon: 1 · Soldado: 0")."""
        if not self.factories:
            return ""
        kinds = [d.kind for d in self.factory_drones()]
        return " · ".join(f"{label}: {kinds.count(k)}" for k, label in self.FLEET_LABELS)

    def drone_status(self):
        """Flota / capacidad (8 por fábrica operativa) y qué hace la producción."""
        facs = self.factories
        n = len(self.factory_drones())
        if not facs:
            return ""                                       # sin Fábrica no hay flota que mostrar (no se exige nada)
        cap = fleet_capacity(self.world)
        building = [f for f in facs if not f.built]
        queued = sum(len(f.production_queue) for f in facs)
        if cap == 0:
            first = min(building, key=lambda f: f.build_left) if building else None
            reason = f"Fábrica {first.build_left:.0f}s" if first is not None else "Fábrica sin red"
            return f"Drones {n}/0 · {reason}"
        full = n >= cap
        producing = [f for f in facs if f.current_production and f.production_time_left > 0]
        if full and (queued or any(f.waiting for f in facs)):
            making = "en espera: flota completa (otra Fábrica da +8)"
        elif producing:
            f = min(producing, key=lambda g: g.production_time_left)
            making = f"{U.DRONE_TYPES[f.current_production]['name'].split()[-1]} {f.production_time_left:.0f}s"
        else:
            making = "lista"
        extra = f" · {len(building)} desplegando" if building else ""
        ecap = explorer_cap(self.world)
        expl = f" · Expl. {explorer_count(self.world)}/{ecap}" + (" TOPE" if explorer_count(self.world) >= ecap else "")
        return f"Drones {n}/{cap} · {making} · cola {queued} · {len(facs)} fábr.{extra}{expl}"

    # --- bases enemigas con IA y niebla de guerra (Prioridad 3.A) ---
    def _spawn_enemy_bases(self):
        """Restaura las bases de 2.1 al entrar en 2.2; si no hay, crea las que marca el Nivel de Alerta."""
        w = self.world
        sc = self.scenario
        self.foundry_note = False
        if self.res.enemy_bases_state:
            self.enemy_bases = [EnemyBase.restore(d, w) for d in self.res.enemy_bases_state]
        elif sc.classic:
            n, difficulty = bases_for_alert(self.res.threat_level)
            self.enemy_bases = [EnemyBase(p, difficulty, w) for p in base_positions(n)]
        else:                                             # mapa de campaña: posiciones, dificultad e ids de CAMPAIGN_MAPS
            self.enemy_bases = []
            for pos, base_id in sc.base_slots:
                b = EnemyBase(pos, sc.difficulty, w)
                b.base_id = base_id
                self.enemy_bases.append(b)
        for i, b in enumerate(self.enemy_bases):
            b.index = i                                   # índice del premio de CAMPAIGN_MAPS[...]["rewards"]
        for base in self.enemy_bases:
            base.on_counterattack = self._enemy_counterattack
            base.on_evacuate = self._enemy_evacuation
            base.on_destroyed = self._on_enemy_base_destroyed
            base.detected = self.fog.is_revealed(base.pos)

    def spawn_enemy_bases(self, num_bases, difficulty):
        """Añade `num_bases` bases con IA de la dificultad dada (escalable: 1, 2, 3 o más)."""
        start = len(self.enemy_bases)
        for pos in base_positions(start + num_bases)[start:]:
            base = EnemyBase(pos, difficulty, self.world)
            base.on_counterattack = self._enemy_counterattack
            base.on_evacuate = self._enemy_evacuation
            base.on_destroyed = self._on_enemy_base_destroyed
            base.index = len(self.enemy_bases)
            self.enemy_bases.append(base)
        return self.enemy_bases[start:]

    def bases_left(self):
        return [b for b in self.enemy_bases if not b.destroyed]

    def _base_zones(self):
        """Puertas de aparición de las oleadas en los mapas sin Fundición: bajo cada base enemiga viva."""
        zones = self.scenario.base_zones(self.enemy_bases)
        return zones or [pygame.Rect(int(self.CC_POS.x) - 200, 60, 400, 60)]

    def _enemy_counterattack(self, base, roster):
        """Le destruyeron un edificio: la base envía un contraataque contra el Centro de Control."""
        w = self.world
        for i, kind in enumerate(roster):
            e = Enemy(kind, base.pos + Vector2(-80 - 20 * (i % 4), 30 * (i // 4) - 30), self.CC_POS, w.enemies)
            e.on_death = self._on_enemy_death
            e.world = w
            e.always_active = True
            w.enemies.add(e)
            w.all_sprites.add(e)
            w.targets.add(e)
        if base.detected:
            self.ally.say(f"¡La base enemiga contraataca con {len(roster)} unidades!", 4)

    def _enemy_evacuation(self, base, roster):
        """El núcleo de una base cayó: su dotación aparece a 200 px y huye al borde del mapa más cercano. No es una oleada
        (no retiene el fin de la oleada) y quien sale del mapa desaparece sin botín."""
        w, b, p = self.world, self.map_rect, Vector2(base.pos)
        gap = {"l": p.x - b.left, "r": b.right - p.x, "t": p.y - b.top, "b": b.bottom - p.y}
        side = min(gap, key=gap.get)
        exit_point = {"l": Vector2(b.left - 40, p.y), "r": Vector2(b.right + 40, p.y),
                      "t": Vector2(p.x, b.top - 40), "b": Vector2(p.x, b.bottom + 40)}[side]
        radius = U.ENEMY_BASES["evacuation"]["spawn_radius"]
        for i, kind in enumerate(roster):
            ang = math.tau * i / len(roster)
            pos = p + Vector2(math.cos(ang), math.sin(ang)) * radius
            pos.x = max(b.left + 20, min(pos.x, b.right - 20))
            pos.y = max(b.top + 20, min(pos.y, b.bottom - 20))
            e = Enemy(kind, pos, exit_point, w.enemies)
            e.is_evacuation = True
            e.on_death = self._on_enemy_death
            e.world = w
            e.always_active = True
            w.enemies.add(e)
            w.all_sprites.add(e)
            w.targets.add(e)
        if base.detected:
            self.ally.say(f"¡El núcleo detona! {len(roster)} unidades evacúan la base: cázalas antes de que escapen.", 4)

    def _on_enemy_base_destroyed(self, base):
        if self.res.campaign_run.is_repeat:               # anti-farmeo: en un mapa ya ganado las bases no pagan
            left = len(self.bases_left())
            self.ally.say("Base enemiga destruida (mapa repetido: sin recursos). "
                          + (f"Quedan {left}." if left else "No quedan bases enemigas."), 5)
            return
        reward = U.ENEMY_BASES["destroy_reward"]
        self.res.add_metal(reward["scrap"])
        self.res.add_cores(reward["cores"])
        self.res.add_alloy(reward["alloy"])
        left = len(self.bases_left())
        self.ally.say(f"¡Base enemiga destruida! +{reward['scrap']} chatarra, +{reward['cores']} núcleo, "
                      f"+{reward['alloy']} aleación. "
                      + (f"Quedan {left}." if left else "No quedan bases enemigas."), 5)
        rewards = self.scenario.rewards
        idx = getattr(base, "index", None)
        if idx is not None and idx < len(rewards):
            self._apply_reward(rewards[idx])

    def _apply_reward(self, reward):
        """Reward de la base destruida (UNITS.REWARD_DEFINITIONS): lo registra en el tracker permanente, aplica su efecto
        y muestra el popup. Si ya lo tenías (o el chasis ya está completo) se convierte en núcleos de plasma.
        Devuelve el texto mostrado ("" si el id no existe)."""
        res, rid = self.res, reward["id"]
        spec = U.REWARD_DEFINITIONS.get(rid)
        if spec is None:
            return ""
        fallback = U.CAMPAIGN_REWARD_FALLBACK["cores"]
        if res.reward_tracker.is_unlocked(rid) or (spec["type"] == "aura_part" and res.chassis_found >= C.CHASSIS_TOTAL_PARTS):
            res.add_cores(fallback)
            text = f"{spec['name']}: ya lo tenías (+{fallback} núcleos)"
            self.ally.say("OBTENIDO: " + text, 6, sender="SISTEMA")
            return text
        res.reward_tracker.add_reward(rid)
        res.campaign_rewards.append(rid)
        self._apply_reward_upgrade(rid)
        self._show_reward_popup(spec)
        text = f"{spec['name']}: {spec['description']}"
        self.ally.say("OBTENIDO: " + text, 6, sender="SISTEMA")
        return text

    def _apply_reward_upgrade(self, reward_id):
        """Aplica el efecto del reward ya registrado: pieza del chasis, mejora del Operador (en caliente) o del dron."""
        spec, res = U.REWARD_DEFINITIONS[reward_id], self.res
        self.upgrade_manager.on_reward_unlocked(reward_id)          # el nodo del reward figura en el árbol
        if spec["type"] == "aura_part":
            res.chassis_found += 1                        # se instala en la Base Central
        elif spec["type"] == "player_upgrade" and hasattr(self.player, "refresh_rewards"):
            self.player.refresh_rewards(res)                 # (en modo Comandante se aplica al volver a pilotar)
        elif spec["type"] == "drone_upgrade":
            res.drone_upgrades.add(spec["operator_tree_node"])        # aparece como instalada en el Terminal
            for factory in self.factories:
                factory.rewards = res.reward_tracker

    def _show_reward_popup(self, reward):
        self.reward_popup = {"reward": reward, "timer": REWARD_POPUP_TIME}

    def draw_reward_popup(self, screen):
        """Cartel de 3 s con el reward obtenido (aparece y se desvanece)."""
        pop = self.reward_popup
        if not pop:
            return
        t_left, hud = pop["timer"], self.game.hud
        alpha = int(255 * max(0.0, min(1.0, (REWARD_POPUP_TIME - t_left) / 0.3, t_left / 0.5)))
        surf = pygame.Surface((440, 104), pygame.SRCALPHA)
        pygame.draw.rect(surf, (14, 46, 38, 235), surf.get_rect())
        pygame.draw.rect(surf, (0, 255, 150), surf.get_rect(), 3)
        reward = pop["reward"]
        hud.text(surf, "¡REWARD DESBLOQUEADO!", (16, 8), "m", (0, 255, 150))
        hud.text(surf, _clip(reward["name"], 44), (16, 40), "m", (200, 255, 200))
        hud.text(surf, _clip(reward["description"], 48), (16, 72), "s", (150, 210, 170), shadow=False)
        surf.set_alpha(alpha)
        screen.blit(surf, (C.WINDOW_WIDTH // 2 - 220, 96))

    def check_victory_condition(self):
        """Victoria: todas las bases enemigas destruidas (y la Fundición, si el mapa la incluye)."""
        if self.bases_left():
            return False
        return self.foundry_core is None or not self.foundry_core.alive()

    def campaign_time_left(self):
        """Segundos que quedan en un mapa de campaña (None en el clásico)."""
        total = self.scenario.total_duration
        return None if total is None else max(0.0, total - self.res.campaign_time)

    def _update_fog(self):
        """Los drones (Exploradores 400 px) y los Focos descubren el mapa; las bases reveladas se marcan."""
        for d in self.world.drones:
            if d.alive() and hasattr(d, "reveal_radius"):
                self.fog.reveal_fog(d.pos.x, d.pos.y, d.reveal_radius)
        for f in self.world.focos:                          # Foco Vigía operativo: revela 320 px de niebla
            if f.alive() and f.active:
                if not getattr(f, "fog_done", False):
                    self.fog.reveal_fog(f.pos.x, f.pos.y, f.stats["reveal_radius"])
                    f.fog_done = True
            else:
                f.fog_done = False
        for base in self.enemy_bases:
            if not base.detected and self.fog.is_revealed(base.pos):
                base.detected = True
                if not base.destroyed:
                    self.ally.say("Base enemiga localizada: extrae chatarra y construye defensas.", 4)

    def visible_sprites(self):
        """Lo que se dibuja: lo hostil y los enemigos solo si su celda está descubierta."""
        w, fog = self.world, self.fog
        hidden = set(w.hostile) | set(w.enemies) | set(w.scavengers)
        return [s for s in self.all_sprites
                if s not in hidden or fog.is_revealed(s.pos) or getattr(s, "detected", False)]

    def capture_enemy_state(self):
        self.res.enemy_bases_state = [b.dump() for b in self.enemy_bases]
        self.res.act2_fog = self.fog.dump()

    # --- AURA en combate (chasis 6/6) ---
    def _deploy_aura(self):
        """Los enemigos detectan el búnker: AURA se despliega como dron autónomo (una sola vez; si cae no vuelve)."""
        if self.aura_drone is not None or not self.res.aura_drone or self.res.aura_drone_lost:
            return
        self.aura_drone = AuraDrone(self.CC_POS + Vector2(0, -90),
                                    energy_ok=lambda cost: self.energy_free() >= cost)
        self.world.drones.add(self.aura_drone)
        self.all_sprites.add(self.aura_drone)
        self.ally.say("Chasis completo: salgo a combatir. Disparo a lo que se acerque y lanzo un pulso EMP cada 5 s.", 5)

    def _check_aura(self):
        if self.aura_drone is not None and not self.aura_drone.alive() and not self.res.aura_drone_lost:
            self.res.aura_drone_lost = True
            self.ally.say("AURA fuera de combate: el dron no volverá en este acto.", 5, sender="SISTEMA")

    # --- diálogos contextuales AURA <-> VULCANO ---
    LOW_ENERGY = 10

    def _contextual_lines(self, dt):
        """Déficit de energía (menos de 10 libres): AURA analiza y VULCANO estalla. Con enfriamiento e histéresis."""
        self._low_energy_cd = max(0.0, self._low_energy_cd - dt)
        self._wall_line_cd = max(0.0, self._wall_line_cd - dt)
        free = self.energy_free()
        if free >= self.LOW_ENERGY + 5:
            self._low_energy_armed = True
        if free < self.LOW_ENERGY and self._low_energy_armed and self._low_energy_cd <= 0:
            self._low_energy_armed = False
            self._low_energy_cd = 45.0
            self.ally.say("Alerta. Fallo de red detectado. Capacidad insuficiente.", 3)
            if self.res.vulcano_online:
                self.ally.say("¡Maldita sea! Circuitos sobrecargados... ¡Desactiva algo!", 3, sender="VULCANO")

    def on_structure_lost(self, building):
        """Cae un muro Reforzado o Electrificado: reacción de VULCANO (AURA no comenta)."""
        if building.building_type == "wall" and building.level >= 2 and self.res.vulcano_online and self._wall_line_cd <= 0:
            self._wall_line_cd = 8.0
            self.ally.say("Ese blindaje... el metal desperdiciado... mierda.", 3, sender="VULCANO")

    # --- órdenes: Attack-Move de los drones (clic derecho en el suelo) ---
    def combat_drones(self):
        return [d for d in self.world.drones if d.alive() and getattr(d, "kind", "") in COMBAT_DRONES]

    def issue_attack_move(self, point):
        """Clic derecho: los drones de combate marchan al punto atacando lo hostil que encuentren. Los terrestres siguen una
        ruta por los pasos de las barreras (si el mapa las tiene)."""
        point = Vector2(point)
        drones = self.combat_drones()
        level = getattr(self, "level", None)
        for d in drones:
            route = level.waypoints(d.pos, point) if d.kind == "trooper" and level is not None else ()
            d.give_order(point, route)
        self.order_marker = [point, 2.0]
        if drones:
            self.ally.say(f"Orden de ataque: {len(drones)} dron(es) marchan al punto marcado.", 3, sender="SISTEMA")
        else:
            self.ally.say("No hay drones de combate (F2 Asalto, F3 Bombardero, F4 Soldado) a los que dar la orden.", 3,
                          sender="SISTEMA")
        return len(drones)

    def on_air_right_click(self):
        """Clic derecho en el suelo (sin estructura debajo): con un edificio elegido lo suelta; si no, orden de ataque."""
        if self.build_choice is not None:
            self.build_choice = None
            return
        self.issue_attack_move(self.camera.to_world(pygame.mouse.get_pos()))

    # --- entrada ---
    def _press_e(self):
        """E: sitio de obra o consola del Búnker bajo el cursor; si no, mejora el muro bajo el cursor."""
        if self.bunker_interact(point=self.camera.to_world(pygame.mouse.get_pos())):
            return
        self.upgrade_under_cursor()

    def repair_at(self, world_pos):
        """R + clic izquierdo: el Comandante ordena reparar la estructura bajo el cursor (sin distancia), pagando chatarra."""
        b = self.structure_under(Vector2(world_pos))
        if b is None or not getattr(b, "repairable", False) or b.hp >= b.max_hp:
            return False
        if not self._pay_repair(b):
            return False
        b.repair(b.max_hp * C.REPAIR_FRACTION)
        self.hints.done("repair")
        return True

    def _auto_collect(self, dt):
        """Sin Operador que la recoja, lo que cae (chatarra, núcleos, piezas del chasis) llega solo a la base tras
        C.AUTO_COLLECT_DELAY s en el suelo: hasta entonces los carroñeros pueden robarlo."""
        w = self.world
        for group in (w.scraps, w.core_items, w.parts):
            for item in list(group):
                item.ground_t = getattr(item, "ground_t", 0.0) + dt
                if item.ground_t < self.auto_collect_delay:
                    continue
                item.kill()
                if group is w.scraps:
                    self._on_scrap_collected(item.value)
                    combat.FX.floater(item.pos, f"+{item.value}")
                elif group is w.core_items:
                    self.res.add_cores(item.value)
                else:
                    self.res.chassis_found += 1
                    self.ally.say("Componente del chasis de AURA recuperado: se instala en la Base Central.", 5)

    def handle_event(self, event):
        if self.dialogue.blocking_active:                  # diálogo narrativo: solo avanza (ESPACIO/ENTER/E/clic)
            if ((event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_e))
                    or (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1)):
                self.dialogue.advance()
            return
        if self.tactical_camera_event(event, (self.map_w, self.map_h)):   # clic central arrastrado (pausa)
            return
        if (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and self.build_choice is None and self.menu is None
                and pygame.key.get_pressed()[pygame.K_r]):
            self.repair_at(self.camera.to_world(event.pos))           # R + clic: reparar (sin distancia)
            return
        if (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and self.build_choice is None and self.menu is None
                and self.panel_hit(event.pos) is None and self.bunker_interact(point=self.camera.to_world(event.pos))):
            return                                                   # clic sobre el sitio o la consola del Búnker
        if self.selection_event(event):                    # selección RTS (clic / caja) y órdenes a los seleccionados
            return
        if self.handle_construction_event(event):          # menú de estructura (clic der.) y Attack-Move en el aire
            return
        if event.type != pygame.KEYDOWN:
            return
        if event.key == pygame.K_SPACE:
            if self.end_timer is None:
                self.toggle_tactical_pause()               # pausa táctica: dt = 0, el HUD sigue visible
            return
        if self.handle_build_key(event):
            return
        if event.key in self.DRONE_KEYS:
            self.queue_drone(self.DRONE_KEYS[event.key])
        elif event.key == pygame.K_n:
            self.wave.skip_prep()
        elif event.key == pygame.K_t:
            self.show_tree = not self.show_tree
        elif event.key == pygame.K_e:
            self._press_e()

    # --- bucle ---
    def update(self, dt):
        w = self.world
        self.camera.tick(dt)
        combat.FX.update(dt)
        self.dialogue.update(dt)
        self.update_bunker(dt, None, self.camera.to_world(pygame.mouse.get_pos()))
        if combat.FX.consume_shake():
            self.camera.shake()
        if self.order_marker is not None:
            self.order_marker[1] -= dt
            if self.order_marker[1] <= 0:
                self.order_marker = None
        self.tick_selection(dt)
        if self.reward_popup and not self.paused:          # el cartel sigue contando aunque la partida esté acabando
            self.reward_popup["timer"] -= dt
            if self.reward_popup["timer"] <= 0:
                self.reward_popup = None
        if self.end_timer is not None:
            self.end_timer -= dt
            if self.end_timer <= 0:
                self._finish()
            return
        if self.dialogue.blocking_active:                  # historia en pantalla: enemigos, proyectiles y timers congelados
            return
        keys = pygame.key.get_pressed()
        mouse = pygame.mouse.get_pressed()
        mouse_pos = self.camera.to_world(pygame.mouse.get_pos())
        self.camera.tactical_update(dt, keys, pygame.mouse.get_pos(), (self.map_w, self.map_h))   # cámara RTS siempre libre
        if self.paused:                                    # pausa táctica: nada se mueve, pero se puede construir/mejorar/vender
            self.process_build_input(dt, keys, mouse, mouse_pos)
            self.grid.update()
            self.energy_tick()
            self._refresh_menu()
            return
        self.hints.update(dt)
        if keys[pygame.K_r]:
            self.hints.done("repair")                       # [R] ya conocida: R + clic izq. repara
        self._contextual_lines(dt)
        if self.scenario.total_duration is not None:        # reloj del mapa de campaña (solo corre sin pausa)
            self.res.campaign_time += dt

        self.wave.update(dt)
        for name, n in self.wave.pop_events():
            if name == "wave_start":
                if n == 1:
                    self._deploy_aura()
                    self.game.machine.transition(GameState.ACT_2_PLAY)
                self.ally.say(f"Oleada {n} de {self.wave.total_waves} en camino.", 4)
            elif name == "prep_end":
                self.ally.say("Fin de la preparación: los precios vuelven a la normalidad.", 4)
            elif name == "wave_clear" and n < self.wave.total_waves:
                self.ally.say(f"Oleada {n} contenida. Repara y reconstruye.", 4)
            elif name == "assault_start":
                if self.res.vulcano_online and not self.assault and (self.scenario.classic or self.scenario.has_foundry):
                    capture_base(self, self.res)                         # fin del sub-acto 2.1: VULCANO gestiona la base
                    self.capture_enemy_state()
                    self.res.base_drones = CampaignRun.serialize_drones(self.world.drones)       # los drones pasan al 2.2
                    self.res.base_factory_queue = CampaignRun.serialize_factory_queue(self.factories)
                    self.game.advance(GameState.ACT_2_ASSAULT)
                    return
                if self.foundry_core is None:
                    self.dialogue.say("AURA", "Oleadas contenidas. Ahora sal a por las bases enemigas: destrúyelas todas.",
                                      blocking=True)
                else:
                    self.dialogue.say("AURA", "Oleadas contenidas. Ahora lidera al escuadrón y destruye la Fundición.",
                                      blocking=True)
            elif name == "foundry_ram":
                self.ally.say(f"La Fundición envía {n} Ariete(s) blindado(s).", 4)

        # Clic derecho + edificio elegido: construir (sin edificio elegido, el clic derecho ordena al escuadron)
        self.process_build_input(dt, keys, mouse, mouse_pos)

        # Actualizacion con las firmas de cada clase
        self.grid.update()
        self.energy_tick()                                  # reparte la energía entre las torretas (apagones en cascada)
        self.nav.update(w.structures, self.core)
        for base in self.enemy_bases:                       # IA de las bases enemigas
            base.update(dt)
        self._update_fog()
        w.enemies.update(dt, w.structures, self.nav)
        w.scavengers.update(dt, w.scraps, w.core_items, w.pylons)
        w.structures.update(dt, w.targets, w.bullets)
        w.hostile.update(dt, w)
        w.drones.update(dt, w)
        self._check_aura()
        w.bombs.update(dt, w)                                # bombas de los Bombarderos en caída libre
        w.bullets.update(dt)
        w.enemy_bullets.update(dt)
        w.shells.update(dt)
        w.scraps.update(dt, None)
        w.core_items.update(dt, None)
        w.parts.update(dt, None)
        self._auto_collect(dt)                              # lo caído llega solo a la base (si no lo roban antes)
        self.ally.update(dt, w)
        if self.vulcano is not None:
            self.vulcano.update(dt, w, self.res)

        for entry in self.pending_scavs:
            entry[0] -= dt
        due = [e for e in self.pending_scavs if e[0] <= 0]
        self.pending_scavs = [e for e in self.pending_scavs if e[0] > 0]
        for _, scrap in due:
            if scrap.alive():
                self._spawn_scavenger(scrap)

        combat.resolve_projectiles(w.bullets, w.enemies, w.scavengers, None, w.hostile)
        combat.resolve_enemy_bullets(w.enemy_bullets, self.absent, w.drones, w.structures)
        combat.resolve_enemy_allies(w.enemies, w.drones, dt)
        for extractor in w.extractors:
            self.res.add_metal(extractor.collect_income())

        self._update_hints(dt)
        if not self.victory and self.check_victory_condition():
            self.victory = True                             # victoria: todas las bases enemigas (y la Fundición, si hay)
            self.ally.say("¡Bases enemigas arrasadas!" if self.foundry_core is None
                          else "¡Núcleo de la Fundición demolido y bases enemigas arrasadas!", 6)
            self.end_timer = 3.0
        elif (self.foundry_core is not None and not self.foundry_core.alive() and not self.foundry_note
              and not self.victory):
            self.foundry_note = True
            self.ally.say(f"Fundición demolida, pero quedan {len(self.bases_left())} base(s) enemiga(s). ¡Destrúyelas!", 6)
        elif (not self.victory and self.scenario.total_duration is not None
              and self.res.campaign_time >= self.scenario.total_duration):
            self.fail_reason = "TIEMPO AGOTADO: las bases enemigas siguen en pie."
            self.ally.say("Se acabó el tiempo de la misión...", 3)
            self.end_timer = 1.5
        elif not self.victory and not self.core.alive():
            self.fail_reason = "El Centro de Control fue destruido."
            self.ally.say("Conexión perdida...", 3)
            self.end_timer = 1.5

    def draw_order_marker(self, screen):
        """Marca de la última orden Attack-Move (aro rojo que se cierra)."""
        if self.order_marker is None:
            return
        p, left = self.order_marker
        s = self.camera.to_screen(p)
        r = int(14 + 22 * (1 - left / 2.0))
        pygame.draw.circle(screen, C.RED, (round(s.x), round(s.y)), r, 2)
        pygame.draw.line(screen, C.RED, (round(s.x) - 9, round(s.y)), (round(s.x) + 9, round(s.y)), 2)
        pygame.draw.line(screen, C.RED, (round(s.x), round(s.y) - 9), (round(s.x), round(s.y) + 9), 2)

    def revealers(self):
        """Quién detecta enemigos en el minimapa: el Centro de Control, cada Foco Vigía energizado y los drones."""
        out = [(Vector2(self.core.pos), C.INCURSION_VISION)]
        out += [(Vector2(f.pos), f.stats["reveal_radius"]) for f in self.world.focos if f.alive() and f.is_powered]
        out += [(Vector2(d.pos), d.reveal_radius) for d in self.world.drones if d.alive() and hasattr(d, "reveal_radius")]
        return out

    def _update_hints(self, dt):
        """Hint de reparación (aparece una sola vez)."""
        h, w = self.hints, self.world
        self._damaged_check -= dt
        if self._damaged_check <= 0:
            self._damaged_check = 0.5
            for wall in w.walls:
                if wall.hp < wall.max_hp and not wall.breaking:
                    h.show("repair", "R + clic izq. para reparar", "r_click",
                           anchor=lambda s=wall: s.pos if s.alive() else None, blink=True)
                    break

    def _stats(self):
        cleared = self.wave.wave if self.wave.phase == "assault" else max(0, self.wave.wave - 1)
        lines = [self.fail_reason] if self.fail_reason else []
        lines += [f"Oleadas superadas: {cleared}/{self.wave.total_waves}",
                  f"Chatarra recuperada: {self.recovered}    Robada por carroñeros: {self.stolen}",
                  f"Drones de la Fábrica en pie: {len(self.factory_drones())}    Nivel de Alerta: {self.res.threat_level}"]
        if not self.scenario.classic:
            sc = self.scenario
            lines += [f"Mapa: {sc.name} · dificultad {sc.difficulty.upper()}",
                      f"Bases enemigas destruidas: {len(self.enemy_bases) - len(self.bases_left())}/{len(self.enemy_bases)}",
                      f"Partes AURA recolectadas: {self.res.chassis_found}/{C.CHASSIS_TOTAL_PARTS}",
                      "Premios: " + (", ".join(self.res.campaign_rewards) if self.res.campaign_rewards else "ninguno")]
        return lines

    def _finish(self):
        if not self.scenario.classic:                      # CampaignRun: una victoria registra el mapa y guarda base y drones
            self.res.campaign_run.on_map_complete(self.victory, self, self.res)
        if self.victory:
            self.game.end_stats = self._stats()
            self.game.machine.transition(GameState.VICTORY)
        else:
            self.game.machine.transition(GameState.RETRY_SUB_ACT, reason=self.fail_reason, stats=self._stats())

    def draw(self, screen):
        cam = self.camera
        self.game_map.draw_background(screen, cam)
        self.grid.draw(screen, cam.offset)
        w = self.world
        self.draw_units(screen)                             # sprites, FX, niebla y, encima, los drones aliados
        self.draw_build_preview(screen)
        self.draw_order_marker(screen)
        self.draw_selection_overlay(screen)                 # caja de selección y marcador del foco de ataque
        cam.apply_shake(screen)
        extras = {"drone_status": self.drone_status(), "fleet": self.fleet_breakdown(),
                  "fog": self.fog, "enemy_bases": self.enemy_bases,
                  "foundry_pool": self.foundry.enemy_scrap_pool, "foundry_core": self.foundry_core,
                  "sub_act": self.sub_act.value, "world_size": (self.map_w, self.map_h),
                  "campaign_title": None if self.scenario.classic else self.scenario.name,
                  "campaign_left": self.campaign_time_left(),
                  "structures": w.structures, "deposits": w.deposits, "drones": w.drones,
                  "enemies": list(w.enemies) + [s for s in w.scavengers if s.detected], "vulcano": self.vulcano is not None, "revealers": self.revealers(),
                  "energy_warning": self.energy_warning > 0}
        self.game.hud.draw_act2(screen, None, self.core, self.res, self.wave, self.build_choice,
                                BUILD_MENU, self._cost, self.dialogue, extras)
        self.hints.draw(screen, self.game.hud, cam)
        self.draw_reward_popup(screen)
        if self.show_tree:
            self.game.hud.operator_tree.draw(self.game.hud, screen, self.upgrade_manager)
        self.draw_structure_menu(screen)
        self.draw_tooltips(screen)
        if self.paused:
            self.game.hud.pause_banner(screen)


# =============================================================================
# Reintento de sub-acto y victoria
# =============================================================================
class RetryState(State):
    def enter(self, reason="", stats=()):
        self.reason = reason
        self.stats = list(stats)
        self.sub_act = self.game.machine.sub_act

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                self.game.retry_sub_act()
            elif event.key in (pygame.K_RETURN, pygame.K_ESCAPE):
                self.game.machine.transition(GameState.MENU)

    def draw(self, screen):
        hud = self.game.hud
        screen.fill(C.BG_COLOR)
        hud.text(screen, "CONEXIÓN PERDIDA", (C.WINDOW_WIDTH // 2, 190), "xl", C.RED, center=True)
        hud.text(screen, f"SUB-ACTO {self.sub_act.value}", (C.WINDOW_WIDTH // 2, 262), "m", C.MAGENTA, center=True)
        lines = ([self.reason] if self.reason else []) + self.stats
        for i, ln in enumerate(lines):
            hud.text(screen, ln, (C.WINDOW_WIDTH // 2, 320 + i * 28), "m", C.WHITE, center=True)
        note = (f"  (presupuesto de rescate: {C.RESCUE_METAL} metal)" if self.sub_act in (SubAct.S2_1, SubAct.S2_2)
                else "  (reaparecerás al inicio con tus suministros)")
        hud.text(screen, "[R] Reintentar sub-acto" + note, (C.WINDOW_WIDTH // 2, 520), "l", C.YELLOW, center=True)
        hud.text(screen, "[ENTER/ESC] Menú principal", (C.WINDOW_WIDTH // 2, 570), "m", C.DARK_GRAY, center=True)


def victory_texts(res):
    """(título, subtítulo, color) de la pantalla de victoria según el chasis de AURA (6/6 o incompleto)."""
    sc = scenario_of(res)
    parts = f"{res.chassis_installed}/{C.CHASSIS_TOTAL_PARTS}"
    if sc.classic:
        fell = "La Fundición Renegada cayó"
    elif sc.has_foundry:
        fell = f"{sc.name}: bases y Fundición arrasadas"
    else:
        fell = f"{sc.name} ({sc.difficulty.upper()}): todas las bases enemigas cayeron"
    if res.chassis_installed >= C.CHASSIS_TOTAL_PARTS:
        return ("CHASIS DE AURA COMPLETADO. AURA ESTÁ LIBRE.",
                f"{fell} y AURA camina de nuevo con el Robot Renegado. Partes de AURA: {parts}", C.GREEN)
    return ("CHASIS INCOMPLETO. AURA PERMANECE ATRAPADA EN EL BÚNKER.",
            f"{fell}, pero solo se instalaron {parts} componentes del chasis.", C.ORANGE)


class VictoryState(State):
    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RETURN:
                if scenario_of(self.game.resources).classic:
                    self.game.machine.transition(GameState.MENU)
                else:                                              # mapas de campaña: elegir el siguiente
                    self.game.machine.transition(GameState.CAMPAIGN_MENU)
            elif event.key == pygame.K_ESCAPE:
                self.game.running = False

    def draw(self, screen):
        hud, res = self.game.hud, self.game.resources
        classic = scenario_of(res).classic
        screen.fill(C.BG_COLOR)
        title, line, color = victory_texts(res)
        hud.text(screen, "¡VICTORIA!", (C.WINDOW_WIDTH // 2, 120), "xl", C.CYAN, center=True)
        hud.text(screen, title, (C.WINDOW_WIDTH // 2, 190), "l", color, center=True)
        hud.text(screen, _clip(line, 130), (C.WINDOW_WIDTH // 2, 232), "s", C.MAGENTA, center=True)
        result = self.game.campaign_run.last_result_message if not classic else ""
        if result:                                                             # premio del mapa (solo el primer viaje)
            hud.text(screen, result, (C.WINDOW_WIDTH // 2, 256), "m",
                     (0, 255, 150) if result.startswith("Primer") else C.DARK_GRAY, center=True)
        for i, ln in enumerate(self.game.end_stats):                          # columna izquierda: estadísticas
            hud.text(screen, _clip(ln, 78), (50, 290 + i * 26), "s", C.WHITE)
        x, y = 790, 290                                                        # columna derecha: rewards y progreso
        hud.text(screen, "REWARDS OBTENIDOS" if not classic else "PROGRESO", (x, y), "m", (0, 255, 150))
        y += 32
        if not classic:
            for rid in res.campaign_rewards or []:
                spec = U.REWARD_DEFINITIONS[rid]
                hud.text(screen, _clip("> " + spec["name"], 44), (x, y), "s", (100, 255, 150))
                hud.text(screen, _clip(spec["description"], 50), (x + 14, y + 17), "s", (140, 180, 150), shadow=False)
                y += 40
            if not res.campaign_rewards:
                hud.text(screen, "(ninguno nuevo: ya los tenías)", (x, y), "s", C.DARK_GRAY)
                y += 30
        y += 8
        pr = res.reward_tracker.get_progress()
        hud.text(screen, "Progreso general", (x, y), "m", C.WHITE)
        for j, (txt, col) in enumerate(((f"AURA: {res.chassis_found}/{C.CHASSIS_TOTAL_PARTS}", (0, 255, 255)),
                                        (f"Mejoras Operador: {pr['player_upgrades']}", (100, 200, 255)),
                                        (f"Mejoras Drones: {pr['drone_upgrades']}/4", (100, 255, 150)))):
            hud.text(screen, txt, (x + 14, y + 28 + j * 22), "s", col)
        hud.text(screen, "[ENTER] " + ("Menú" if classic else "Siguiente mapa") + "    [ESC] Salir",
                 (C.WINDOW_WIDTH // 2, 640), "l", C.YELLOW, center=True)


# =============================================================================
# Juego
# =============================================================================
class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption(C.TITLE)
        self.screen = pygame.display.set_mode((C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
        self.clock = pygame.time.Clock()
        self.hud = HUD()
        self.hints = HintManager()        # tutorial intradiegético (una sola vez por campaña)
        self.tooltips = TooltipManager()  # tarjetas al pasar el ratón (0,5 s de retardo)
        self.resources = ResourceManager()
        self.report = []
        self.end_stats = []
        self.checkpoints = {}         # sub-acto -> snapshot de recursos al empezarlo
        self.retry_pending = False
        self.last_save = None         # ruta del último autoguardado del perfil
        self.running = True
        self.machine = StateMachine()
        act2 = Act2State(self)
        from src.scenes.siege_scene import make_siege_state           # import local: la escena hereda de Act2State (vive aquí)
        SiegeState = make_siege_state(Act2State)
        for gs, screen in ((GameState.MENU, MainMenuState(self)),
                           (GameState.SUB_ACT_1_1, Sub11State(self)),
                           (GameState.SUB_ACT_1_2, Sub12State(self)),
                           (GameState.SUB_ACT_1_3, Sub13State(self)),
                           (GameState.SUB_ACT_1_4, Sub14State(self)),
                           (GameState.ACT_2_BASE, InterludeState(self)),
                           (GameState.CAMPAIGN_MENU, CampaignMenuState(self)),
                           (GameState.INCURSION, IncursionScene(self)),
                           (GameState.ACT_2_SETUP, act2),
                           (GameState.ACT_2_PLAY, act2),
                           (GameState.ACT_2_ASSAULT, act2),
                           (GameState.BASE_MANAGEMENT, BaseManagementState(self)),
                           (GameState.SIEGE, SiegeState(self)),
                           (GameState.CAMPAIGN_VICTORY, CampaignVictoryState(self)),
                           (GameState.RETRY_SUB_ACT, RetryState(self)),
                           (GameState.VICTORY, VictoryState(self))):
            self.machine.register(gs, screen)
        self.machine.start()

    def new_campaign(self):
        self.resources.reset()
        self.hints.reset()
        self.report = []
        self.checkpoints.clear()
        self.retry_pending = False

    @property
    def campaign_run(self):
        """Estado de la campaña del Acto 2 (mapa en curso, mapas ganados, base y drones entre mapas)."""
        return self.resources.campaign_run

    def begin_sub_act(self, sub_act):
        """Guarda el checkpoint al empezar un sub-acto; si es un reintento, lo restaura.
        Devuelve True cuando se está reintentando. Al empezar un sub-acto del Acto 1 (misión anterior terminada) autoguarda
        el perfil para reanudarlo desde aquí."""
        if self.retry_pending and sub_act in self.checkpoints:
            self.resources.restore(self.checkpoints[sub_act])
            self.retry_pending = False
            return True
        self.checkpoints[sub_act] = self.resources.snapshot()
        if sub_act in ACT1_RESUME:
            self.autosave(ACT1_RESUME[sub_act].name)
        return False

    # --- perfiles de guardado (src/mechanics/save_manager.py) ---
    def autosave(self, resume_state, **resume_kwargs):
        """Guarda el perfil del Operador (saves/{nombre}.json) para reanudar en `resume_state`. Sin nombre todavía (antes
        de presentarse a AURA) no guarda. Nunca interrumpe la partida: un error de disco solo se registra."""
        if not self.resources.campaign_run.named:
            return None
        try:
            self.last_save = saves.save_game(self.resources, resume_state, resume_kwargs)
        except (OSError, TypeError, ValueError) as exc:
            logging.getLogger(__name__).warning("autoguardado fallido: %s", exc)
            self.last_save = None
        return self.last_save

    def autosave_here(self):
        """Autoguardado en mitad de la gestión de la base (p. ej. Búnker completado): se reanuda en esa misma pantalla."""
        if self.machine.current_state is GameState.BASE_MANAGEMENT:
            nxt = getattr(self.machine.active, "next_state", GameState.ACT_2_BASE)
            return self.autosave("BASE_MANAGEMENT", next_state=nxt.name)
        return self.autosave("ACT_2_BASE")

    def continue_profile(self, path):
        """Carga el perfil y reanuda la campaña en su punto de guardado. Devuelve el GameState de destino."""
        data = saves.read(path)
        self.new_campaign()
        state, kwargs = saves.apply_save(self.resources, data)
        target = GameState[state] if state in GameState.__members__ else self._infer_resume()
        if "next_state" in kwargs:
            kwargs["next_state"] = GameState[kwargs["next_state"]]
        self.machine.transition(target, **kwargs)
        return target

    def _infer_resume(self):
        """Partidas heredadas sin punto de reanudación: el último lugar seguro según el progreso."""
        r = self.resources
        if r.vulcano_online or r.initial_done:
            return GameState.ACT_2_BASE
        if r.aura_linked:
            return GameState.SUB_ACT_1_3
        return GameState.SUB_ACT_1_1

    def advance(self, next_state):
        """Pasa al siguiente sub-acto: con VULCANO en línea antes se entra en la Base Central (fase estratégica)."""
        if self.resources.vulcano_online:
            self.machine.transition(GameState.BASE_MANAGEMENT, next_state=next_state)
        else:
            self.machine.transition(next_state)

    def retry_sub_act(self):
        """R en la pantalla de reintento: reinicia únicamente el sub-acto actual."""
        self.retry_pending = True
        self.machine.transition(FIRST_STATE_OF[self.machine.sub_act])

    def run(self, max_frames=None):
        frames = 0
        while self.running:
            dt = self.clock.tick(C.FPS) / 1000.0
            dt = min(dt, 0.05)       # evita saltos enormes tras una pausa de ventana
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                else:
                    self.machine.handle_event(event)
            self.machine.update(dt)
            self.machine.draw(self.screen)
            pygame.display.flip()
            frames += 1
            if max_frames is not None and frames >= max_frames:
                break
        pygame.quit()


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING, format="[aviso] %(message)s")
    Game().run()
    sys.exit(0)
