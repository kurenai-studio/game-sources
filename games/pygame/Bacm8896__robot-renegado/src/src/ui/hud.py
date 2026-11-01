import math

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities.building import Building
from src.ui import fade
from src.ui.combat_feedback import ALERTS, DamageVignette, WaveBanner, _now


class WaveDisplay:
    """Panel de oleadas de los mapas de campaña: número, tipo (pequeña/GRANDE), enemigos pendientes y descanso."""

    def draw(self, hud, surface, pos, wave):
        x, y = pos
        gen = wave.generator
        kind = wave.wave_kind or (gen.entry(max(1, wave.wave))[0] if gen else "small")
        big = kind == "big"
        total = "" if wave.endless else f"/{wave.total_waves}"
        hud.text(surface, f"Oleada {max(1, wave.wave)}{total} · {'GRANDE' if big else 'pequeña'}", (x, y), "s",
                 (255, 100, 100) if big else (100, 200, 100))
        if wave.phase == "break":
            nxt = gen.entry(wave.wave + 1)[0] if gen else "small"
            hud.text(surface, f"Descanso: {int(math.ceil(wave.timer))}s · siguiente: {'GRANDE' if nxt == 'big' else 'pequeña'}",
                     (x, y + 18), "s", (255, 200, 0))
        elif wave.phase == "wave":
            hud.text(surface, f"Enemigos: {wave.remaining}", (x, y + 18), "s", (200, 200, 200))


def reachable_rewards():
    """Ids de las recompensas que hoy se pueden ganar (están en algún mapa de campaña)."""
    return {r["id"] for cfg in U.CAMPAIGN_MAPS.values() for r in cfg.get("rewards", ())}


class OperatorTreeUI:
    """Árbol del Operador de solo lectura (tecla T en el Acto 2): nodos comprados, rewards y lo que falta."""

    COLUMNS = (("OFENSIVA", (0, 255, 200)), ("SUPERVIVENCIA", (120, 200, 255)), ("RECOMPENSAS", (255, 200, 80)))

    def draw(self, hud, surface, manager):
        tree = manager.upgrade_tree
        panel = pygame.Rect(40, 118, C.WINDOW_WIDTH - 80, 380)
        pygame.draw.rect(surface, (6, 12, 18), panel)                       # fondo opaco: se lee sobre cualquier escena
        hud.panel(surface, panel, C.CYAN)
        hud.text(surface, "ÁRBOL DEL OPERADOR · T cierra", (panel.x + 16, panel.y + 8), "m", C.CYAN)
        col_w = (panel.w - 32) // 3
        for ci, (cat, color) in enumerate(self.COLUMNS):
            x, y = panel.x + 16 + ci * col_w, panel.y + 44
            nodes = tree[cat]
            if cat == "RECOMPENSAS":                                       # solo las que dan los mapas de campaña actuales
                reachable = reachable_rewards()
                nodes = {k: v for k, v in nodes.items() if v.get("reward") in reachable}
            done = sum(1 for n in nodes.values() if n["unlocked"])
            hud.text(surface, f"{cat} {done}/{len(nodes)}", (x, y), "m", color)
            y += 28
            for info in nodes.values():
                on = info["unlocked"]
                label = info.get("label", info["name"])
                hud.text(surface, f"{'[x]' if on else '[ ]'} {label}", (x, y), "s", C.GREEN if on else (150, 150, 150))
                hud.text(surface, (info["description"][:38]), (x + 22, y + 15), "s", (120, 190, 130) if on else (95, 95, 95),
                         shadow=False)
                y += 31


class ProgressBar:
    """Progreso de rewards en una línea: AURA x/6 · mejoras del Operador x/6 · mejoras de drones x/4 · total."""

    def text(self, res, short=False):
        pr = res.reward_tracker.get_progress()
        if short:
            return f"AURA {res.chassis_found}/{C.CHASSIS_TOTAL_PARTS} · Mej. {pr['player_upgrades']} · Drones {pr['drone_upgrades']}/4"
        return (f"AURA {res.chassis_found}/{C.CHASSIS_TOTAL_PARTS} · Mejoras {pr['player_upgrades']} · "
                f"Drones {pr['drone_upgrades']}/4 · Rewards {pr['total_rewards']}")

    def draw(self, hud, surface, pos, res, short=False):
        hud.text(surface, self.text(res, short), pos, "s", (0, 255, 200), shadow=False)


class HUD:
    def __init__(self):
        self.wave_display = WaveDisplay()
        self.progress_bar = ProgressBar()
        self.operator_tree = OperatorTreeUI()
        self.wave_banner = WaveBanner()
        self.damage_fx = DamageVignette()
        self._core_hp = None
        self._core_hit = -99.0
        def font(size):
            return pygame.font.SysFont("consolas", size, bold=True)
        self.fonts = {"s": font(15), "m": font(20), "l": font(34), "xl": font(64)}
        self._text_cache = {}

    # --- primitivas ---
    def _render(self, size, msg, color):
        key = (size, msg, tuple(color))
        img = self._text_cache.get(key)
        if img is None:
            if len(self._text_cache) > 800:          # caché acotada: los textos dinámicos no la inflan sin límite
                self._text_cache.clear()
            img = self.fonts[size].render(msg, True, color)
            self._text_cache[key] = img
        return img

    def text(self, surface, msg, pos, size="m", color=C.WHITE, center=False, shadow=True):
        img = self._render(size, msg, color)
        r = img.get_rect(center=pos) if center else img.get_rect(topleft=pos)
        if shadow:
            surface.blit(self._render(size, msg, (0, 0, 0)), r.move(2, 2))
        surface.blit(img, r)
        return r

    def bar(self, surface, rect, frac, color, label=None):
        rect = pygame.Rect(rect)
        pygame.draw.rect(surface, (20, 22, 34), rect)
        pygame.draw.rect(surface, color, (rect.x, rect.y, int(rect.w * max(0.0, min(1.0, frac))), rect.h))
        pygame.draw.rect(surface, C.DARK_GRAY, rect, 1)
        if label:
            self.text(surface, label, rect.center, "s", C.WHITE, center=True)

    def panel(self, surface, rect, border=C.CYAN):
        s = pygame.Surface(rect.size, pygame.SRCALPHA)
        s.fill((*C.PANEL_COLOR, 205))
        surface.blit(s, rect)
        pygame.draw.rect(surface, border, rect, 1)

    def dialogue(self, surface, box):
        box.draw(surface, self)

    def dash_bar(self, surface, rect, player):
        """Una barra por carga de Dash (1, o 2 con el Impulso Doble): cada una se llena con su propia recarga."""
        n = player.dash_charges_max
        gap = 4
        w = (rect[2] - gap * (n - 1)) // n
        waiting = sorted(player.dash_recharge)
        for i in range(n):
            if i < player.dash_charges:
                ready = 1.0
            else:
                ready = 1.0 - waiting[i - player.dash_charges] / C.DASH_COOLDOWN
            self.bar(surface, (rect[0] + i * (w + gap), rect[1], w, rect[3]), ready,
                     C.WHITE if ready >= 1 else C.DARK_GRAY, "DASH" if ready >= 1 and n == 1 else None)

    def health_blocks(self, surface, rect, player, color):
        """Vida segmentada: un bloque por segmento. El dañado se ve parcial (se regenera solo); los perdidos, vacíos y
        tachados (solo vuelven con un botiquín)."""
        n = max(1, player.health_blocks)
        gap = 4
        x, y, w, h = rect
        bw = (w - gap * (n - 1)) / n
        size = player.block_size
        ceiling = player.block_ceiling()
        for i in range(n):
            r = pygame.Rect(round(x + i * (bw + gap)), y, round(bw), h)
            fill = max(0.0, min(1.0, (player.hp - i * size) / size)) if size > 0 else 0.0
            lost = (i + 1) * size > ceiling + 1e-6 and fill <= 0
            pygame.draw.rect(surface, (20, 22, 34), r)
            if fill > 0:
                partial = fill < 0.999
                pygame.draw.rect(surface, C.YELLOW if partial else color, (r.x, r.y, int(r.w * fill), r.h))
            pygame.draw.rect(surface, (90, 30, 34) if lost else C.DARK_GRAY, r, 1)
            if lost:
                pygame.draw.line(surface, (150, 40, 46), r.topleft, (r.right - 1, r.bottom - 1), 1)

    def medkit_counter(self, surface, pos, resources):
        """«+ 2/5 [H]»: botiquines del bolsillo (rojo vacío, blanco con alguno)."""
        n = getattr(resources, "medkits", 0)
        return self.text(surface, f"+ BOTIQUINES {n}/{C.MEDKIT_MAX} [H]", pos, "s", C.WHITE if n else C.DARK_GRAY,
                         shadow=False)

    @staticmethod
    def ammo_color(player):
        """Blanco normal; AMARILLO con menos de 30 balas y ROJO con menos de 10."""
        total = player.ammo
        if total < U.AMMO_SYSTEM["crit_threshold_critical"]:
            return C.RED
        if total < U.AMMO_SYSTEM["crit_threshold_low"]:
            return C.YELLOW
        return C.WHITE

    def ammo_panel(self, surface, pos, player):
        """Acto 1: munición infinita. Acto 2+: "Balas: 47/150" y un rectángulo por cargador (se llenan y vacían)."""
        if player.infinite_ammo:
            self.text(surface, "MUNICIÓN ∞ · " + ("automático" if player.automatic_fire else "semiautomático"), pos, "s", C.CYAN)
            return
        color = self.ammo_color(player)
        label = f"Balas: {player.ammo}/{player.capacity}"
        r = self.text(surface, label, pos, "s", color)
        if player.reload_timer > 0:
            self.text(surface, "RECARGANDO", (r.right + 8, pos[1]), "s", C.RED)
            return
        n = max(1, player.capacity // player.mag_size)
        w = min(18, 150 // n)
        x0 = pos[0] + 150
        for i in range(n):
            held = player.mag_rounds if i == 0 else max(0, min(player.mag_size, player.reserve - (i - 1) * player.mag_size))
            box = pygame.Rect(x0 + i * (w + 3), pos[1] + 2, w, 10)
            pygame.draw.rect(surface, (20, 22, 34), box)
            pygame.draw.rect(surface, color, (box.x, box.y, int(box.w * held / player.mag_size), box.h))
            pygame.draw.rect(surface, C.DARK_GRAY, box, 1)

    def ammo_message(self, surface, player):
        """Mensajes de munición baja / sin munición (junto al HUD, sin pausar nada)."""
        if player.infinite_ammo or not player.equipped:
            return
        if player.ammo <= 0:
            msg = "¡SIN MUNICIÓN! - COMBATE CUERPO A CUERPO"
        elif player.ammo < U.AMMO_SYSTEM["crit_threshold_critical"]:
            msg = "MUNICIÓN CRÍTICA - BUSCA SUMINISTROS"
        else:
            return
        if int(pygame.time.get_ticks() / 400) % 2 == 0:
            self.text(surface, msg, (C.WINDOW_WIDTH // 2, 106), "m", C.RED, center=True)

    # --- iconos procedurales (los glifos ⚙ 🔷 ⚡ no existen en la fuente del juego) ---
    @staticmethod
    def icon(surface, kind, center, r=6):
        """Chatarra (engranaje gris), Núcleo de Plasma (rombo cian) o Energía (rayo amarillo)."""
        x, y = int(center[0]), int(center[1])
        if kind == "scrap":
            for i in range(6):
                a = i * math.pi / 3
                pygame.draw.circle(surface, (150, 156, 170), (round(x + math.cos(a) * r), round(y + math.sin(a) * r)),
                                   max(1, r // 3))
            pygame.draw.circle(surface, (190, 196, 210), (x, y), r - 1)
            pygame.draw.circle(surface, (40, 44, 56), (x, y), max(1, r // 2 - 1))
        elif kind == "cores":
            pts = [(x, y - r - 1), (x + r - 1, y), (x, y + r + 1), (x - r + 1, y)]
            pygame.draw.polygon(surface, (0, 150, 190), pts)
            pygame.draw.polygon(surface, (150, 245, 255), pts, 1)
            pygame.draw.circle(surface, C.WHITE, (x, y), max(1, r // 3))
        elif kind == "alloy":                                                # lingote de aleación (naranja metálico)
            pts = [(x - r, y + r // 2 + 1), (x - r // 2, y - r // 2 - 1), (x + r // 2, y - r // 2 - 1), (x + r, y + r // 2 + 1)]
            pygame.draw.polygon(surface, (196, 120, 60), pts)
            pygame.draw.polygon(surface, (255, 200, 140), pts, 1)
            pygame.draw.line(surface, (255, 230, 190), (x - r // 2 + 1, y - r // 2 + 1), (x + r // 2 - 1, y - r // 2 + 1))
        elif kind == "energy":
            bolt = [(x + 1, y - r - 1), (x - r // 2 - 1, y + 1), (x, y + 1), (x - 1, y + r + 1), (x + r // 2 + 1, y - 1),
                    (x, y - 1)]
            pygame.draw.polygon(surface, C.YELLOW, bolt)
        elif kind == "heart":
            pygame.draw.circle(surface, C.RED, (x - r // 2, y - r // 3), r // 2 + 1)
            pygame.draw.circle(surface, C.RED, (x + r // 2, y - r // 3), r // 2 + 1)
            pygame.draw.polygon(surface, C.RED, [(x - r, y - r // 5), (x + r, y - r // 5), (x, y + r)])
        elif kind == "warning":
            pygame.draw.polygon(surface, C.RED, [(x, y - r), (x + r, y + r - 1), (x - r, y + r - 1)])
            pygame.draw.rect(surface, C.WHITE, (x - 1, y - r // 2, 2, r - 1))
            pygame.draw.rect(surface, C.WHITE, (x - 1, y + r // 2 + 1, 2, 2))

    def cost_row(self, surface, pos, scrap=0, cores=0, energy=0, afford=(True, True, True), size="s", alloy=0):
        """Costo con iconos: chatarra, núcleos, aleación y energía (en rojo lo que no alcanza). Devuelve la x final.
        `afford` = (chatarra, núcleos, energía[, aleación])."""
        x, y = pos
        alloy_ok = afford[3] if len(afford) > 3 else True
        for kind, value, ok in (("scrap", scrap, afford[0]), ("cores", cores, afford[1]), ("alloy", alloy, alloy_ok),
                                ("energy", energy, afford[2])):
            if value:
                self.icon(surface, kind, (x + 5, y + 8), 5)
                txt = str(value)
                self.text(surface, txt, (x + 12, y), size, C.WHITE if ok else C.RED, shadow=False)
                x += 12 + self._render(size, txt, C.WHITE).get_width() + 5
        return x

    def resources_row(self, surface, pos, resources):
        """Fila de recursos del HUD: chatarra, núcleos, aleación y energía (consumo / capacidad)."""
        x, y = pos
        self.icon(surface, "scrap", (x + 8, y + 12), 7)
        r1 = self.text(surface, f"{resources.metal}", (x + 20, y), "m", C.WHITE)
        x = r1.right + 14
        self.icon(surface, "cores", (x + 8, y + 12), 7)
        r2 = self.text(surface, f"{resources.cores}", (x + 20, y), "m", C.CYAN)
        x = r2.right + 14
        self.icon(surface, "alloy", (x + 8, y + 12), 7)
        r3 = self.text(surface, f"{resources.alloy}", (x + 20, y), "m", (255, 190, 120))
        x = r3.right + 14
        self.icon(surface, "energy", (x + 8, y + 12), 7)
        full = resources.energy >= resources.energy_cap
        self.text(surface, f"{resources.energy}/{resources.energy_cap}", (x + 20, y), "m", C.RED if full else C.YELLOW)

    TOP = 30                                  # alto de la barra superior: el resto del HUD arranca debajo

    def top_bar(self, surface, player, resources, wave=None):
        """Barra superior: Chatarra | Núcleos | Energía | Oleada | Vida | Munición."""
        bar = pygame.Rect(0, 0, C.WINDOW_WIDTH, self.TOP - 4)
        self.panel(surface, bar, C.DARK_GRAY)
        x, cy = 14, bar.centery

        def item(kind, label, color):
            nonlocal x
            if kind:
                self.icon(surface, kind, (x + 8, cy), 7)
                x += 20
            r = self.text(surface, label, (x, cy - 10), "m", color, shadow=False)
            x = r.right + 10
            self.text(surface, "|", (x, cy - 10), "m", C.DARK_GRAY, shadow=False)
            x += 22
        item("scrap", f"{resources.metal}", C.WHITE)
        item("cores", f"{resources.cores}", C.CYAN)
        full = resources.energy >= resources.energy_cap
        item("energy", f"{resources.energy}/{resources.energy_cap}", C.RED if full else C.YELLOW)
        if wave is not None:
            item(None, f"Oleada {max(1, wave.wave)}" + ("" if wave.endless else f"/{wave.total_waves}"), C.WHITE)
        if player.equipped:
            item("heart", f"{max(0, int(player.hp))}/{player.max_hp}", C.RED if player.hp < player.max_hp * 0.3 else C.GREEN)
            self.ammo_panel(surface, (x, cy - 8), player)
        else:
            self.text(surface, "SISTEMAS DEL TRAJE APAGADOS", (x, cy - 8), "s", C.DARK_GRAY, shadow=False)

    def resources_line(self, resources):
        return (f"Chatarra: {resources.metal} | Núcleos: {resources.cores} | "
                f"Energía: {resources.energy}/{resources.energy_cap}")

    def energy_warning_message(self, surface):
        """Aviso central cuando falta energía para construir o hay torretas apagadas."""
        r = self.text(surface, "INSUFICIENTE ENERGÍA - Extiende la red con más pilones",
                      (C.WINDOW_WIDTH // 2 + 12, 142), "m", C.RED, center=True)
        self.icon(surface, "warning", (r.left - 14, r.centery), 8)

    # --- tarjetas de tooltip ---
    def draw_card(self, surface, mouse, card):
        """Tarjeta flotante cerca del ratón. card = {"title", "rows": [("text", s, color) | ("sep",) |
        ("cost", scrap, cores, energy, afford) | ("bar", fracción, color, texto)], "color" (opcional: marco y título)}"""
        rows = card["rows"]
        accent = card.get("color", C.YELLOW)
        w = max(220, self._render("m", card["title"], C.WHITE).get_width() + 24)
        for row in rows:
            if row[0] in ("text", "bar"):
                w = max(w, self._render("s", row[1] if row[0] == "text" else row[3], C.WHITE).get_width()
                        + (24 if row[0] == "text" else 110))
        h = 12 + 26 + sum(14 if r[0] == "sep" else 20 for r in rows) + 8
        x = min(mouse[0] + 18, C.WINDOW_WIDTH - w - 8)
        y = mouse[1] - h - 14 if mouse[1] + h + 24 > C.WINDOW_HEIGHT else mouse[1] + 20
        rect = pygame.Rect(max(8, x), max(8, y), w, h)
        self.panel(surface, rect, accent)
        self.text(surface, card["title"], (rect.x + 10, rect.y + 6), "m", accent)
        cy = rect.y + 36
        for row in rows:
            if row[0] == "sep":
                pygame.draw.line(surface, C.DARK_GRAY, (rect.x + 8, cy + 4), (rect.right - 8, cy + 4), 1)
                cy += 14
            elif row[0] == "bar":                                   # mini-barra de vida con su valor
                r = self.text(surface, row[3], (rect.x + 10, cy), "s", C.WHITE, shadow=False)
                bar = pygame.Rect(r.right + 10, cy + 4, rect.right - 10 - (r.right + 10), 9)
                pygame.draw.rect(surface, (30, 24, 28), bar)
                pygame.draw.rect(surface, row[2], (bar.x, bar.y, round(bar.w * max(0.0, min(1.0, row[1]))), bar.h))
                pygame.draw.rect(surface, C.DARK_GRAY, bar, 1)
                cy += 20
            elif row[0] == "cost":
                self.text(surface, "Costo:", (rect.x + 10, cy), "s", C.WHITE, shadow=False)
                self.cost_row(surface, (rect.x + 66, cy), row[1], row[2], row[3], row[4])
                cy += 20
            else:
                self.text(surface, row[1], (rect.x + 10, cy), "s", row[2], shadow=False)
                cy += 20

    def pause_banner(self, surface, title="PAUSA TÁCTICA"):
        """Aviso de la pausa táctica (el mundo está congelado, el HUD sigue activo)."""
        r = pygame.Rect(C.WINDOW_WIDTH // 2 - 330, 108, 660, 34)
        self.panel(surface, r, C.YELLOW)
        self.text(surface, f"{title} · WASD / bordes / clic central: cámara · ESPACIO reanuda", r.center, "s", C.YELLOW,
                  center=True)

    def build_mode_notice(self, surface, menu, active=False):
        """Aviso fijo del tutorial de fortificación: «[ESPACIO] Modo Construcción», a la izquierda del panel de construcción."""
        label = "[ESPACIO] Salir del Modo Construcción" if active else "[ESPACIO] Modo Construcción"
        slots = self.build_slots(menu)
        r = pygame.Rect(0, 0, 330 if active else 250, 28)
        r.bottomright = (slots[0][0].left - 10, slots[0][0].bottom) if slots else (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 128)
        self.panel(surface, r, C.ORANGE)
        self.text(surface, label, r.center, "s", C.ORANGE, center=True)

    @staticmethod
    def build_slots(menu, shift=0):
        """[(rect, tipo)] de las casillas del panel de construcción (dibujo, clic y tooltips usan lo mismo)."""
        if len(menu) > 6:             # 9-10 edificios: panel compacto a la izquierda (el minimapa ocupa la esquina derecha)
            pw, x0 = (118 if len(menu) <= 9 else 107), 12
        else:
            pw = min(150, (C.WINDOW_WIDTH - 24) // len(menu))
            x0 = C.WINDOW_WIDTH // 2 - (pw * len(menu)) // 2 + shift
        return [(pygame.Rect(x0 + i * pw, C.WINDOW_HEIGHT - 62, pw - 6, 52), btype) for i, (key, btype) in enumerate(menu)]

    def build_panel(self, surface, resources, build_choice, menu, cost_fn, shift=0):
        free = resources.energy_free
        for (rect, btype), (key, _) in zip(self.build_slots(menu, shift), menu):
            if not resources.structure_unlocked(btype):                    # bloqueada: candado y qué la desbloquea
                self.panel(surface, rect, C.DARK_GRAY)
                self.text(surface, f"[{pygame.key.name(key)}] {Building.SHORT[btype]}", (rect.x + 5, rect.y + 6), "s", C.DARK_GRAY)
                self.lock_icon(surface, (rect.x + 12, rect.y + 39))
                self.text(surface, resources.structure_requirement(btype, short=True), (rect.x + 26, rect.y + 31), "s", C.ORANGE,
                          shadow=False)
                continue
            stats = Building.STATS[btype]
            scrap, cores, energy = cost_fn(btype), stats["cores"], stats["energy"]
            self.panel(surface, rect, C.YELLOW if build_choice == btype else C.CYAN)
            self.text(surface, f"[{pygame.key.name(key)}] {Building.SHORT[btype]}", (rect.x + 5, rect.y + 6), "s", C.WHITE)
            self.cost_row(surface, (rect.x + 5, rect.y + 28), scrap, cores, energy,
                          (resources.can_afford(scrap), resources.cores >= cores, energy <= free))

    @staticmethod
    def lock_icon(surface, center, color=C.DARK_GRAY):
        """Candado: arco del grillete sobre un cuerpo rectangular."""
        x, y = center
        pygame.draw.arc(surface, color, (x - 5, y - 11, 10, 12), 0, math.pi, 2)
        pygame.draw.rect(surface, color, (x - 7, y - 3, 14, 11), border_radius=2)
        pygame.draw.circle(surface, (30, 34, 44), (x, y + 2), 2)

    # --- radar de AURA ---
    def radar_panel(self):
        w, h = 176, 132
        return pygame.Rect(C.WINDOW_WIDTH - w - 12, C.WINDOW_HEIGHT - h - 12, w, h)

    def radar_offline(self, surface):
        r = self.radar_panel()
        self.panel(surface, r, C.DARK_GRAY)
        self.text(surface, "RADAR", r.center, "m", C.DARK_GRAY, center=True)
        self.text(surface, "sin señal de AURA", (r.centerx, r.centery + 22), "s", C.DARK_GRAY, center=True)

    def radar(self, surface, level, player_pos, player_screen, enemies=(), bosses=(), targets=(), fog=None):
        """Radar táctico de AURA: mapa del nivel, enemigos y balizas hacia los objetivos clave. Con `fog` (incursiones) solo
        muestra, en tono tenue, lo ya explorado; lo no visitado queda en negro."""
        r = self.radar_panel()
        self.panel(surface, r)
        inner = pygame.Rect(r.x + 2, r.y + 2, r.w - 4, r.h - 4)
        cell_w = inner.w / level.size[0]
        cell_h = inner.h / level.size[1]
        surface.blit(level.radar_image(inner.size) if fog is None else fog.minimap(inner.size), inner)

        def pt(p):
            return (inner.x + int(p[0] * cell_w), inner.y + int(p[1] * cell_h))
        for e in enemies:
            pygame.draw.rect(surface, C.RED, (*pt(e.pos), 3, 3))
        for b in bosses:
            pygame.draw.rect(surface, C.ORANGE, (*pt(b.pos), 5, 5))
        for target in targets:
            if len(target) > 2 and target[2] == "energy":                   # extractor de plasma (escaneo de AURA)
                self.icon(surface, "energy", pt(target[0]), 5)
            else:
                pygame.draw.circle(surface, target[1], pt(target[0]), 4, 1)
        pygame.draw.circle(surface, C.YELLOW, pt(player_pos), 3)
        if targets and int(pygame.time.get_ticks() / 350) % 2 == 0:            # objetivo principal: baliza cian parpadeante
            pygame.draw.circle(surface, C.CYAN, pt(targets[0][0]), 6)
            pygame.draw.circle(surface, C.WHITE, pt(targets[0][0]), 6, 1)
        self.text(surface, "RADAR · AURA", (r.x + 6, r.y - 18), "s", C.CYAN)

    # --- HUD de los sub-actos 1.1 a 1.4 ---
    def draw_level(self, surface, player, resources, sub_act, objective, dialogue, radar=None,
                   checklist=None, banner=None, build=None, level_hint=None):
        """`radar`: dict(level, enemies, bosses, targets, player_screen) o None (sin señal)."""
        T = self.TOP
        if player.equipped:
            self.damage_fx.draw(surface, player)                      # viñeta roja bajo el HUD
        self.top_bar(surface, player, resources)
        if player.equipped:
            self.panel(surface, pygame.Rect(10, T + 6, 300, 52))
            self.text(surface, "EXOESQUELETO", (20, T + 10), "s", C.CYAN)
            self.medkit_counter(surface, (150, T + 10), resources)
            self.health_blocks(surface, (20, T + 28, 280, 12), player, C.CYAN)
            self.dash_bar(surface, (20, T + 44, 280, 10), player)
        self.text(surface, "SUB-ACTO " + sub_act, (C.WINDOW_WIDTH // 2, T + 8), "s", C.MAGENTA, center=True)
        self.text(surface, objective, (C.WINDOW_WIDTH // 2, T + 30), "m", C.WHITE, center=True)
        if banner:
            self.text(surface, banner, (C.WINDOW_WIDTH // 2, T + 58), "l", C.YELLOW, center=True)
        if checklist:
            y = T + 70
            for text, done in checklist:
                self.text(surface, ("[x] " if done else "[ ] ") + text, (14, y), "s", C.GREEN if done else C.WHITE)
                y += 20
        if radar is not None:
            self.radar(surface, radar["level"], player.pos, radar["player_screen"],
                       radar.get("enemies", ()), radar.get("bosses", ()), radar.get("targets", ()), radar.get("fog"))
        elif resources.equipped:
            self.radar_offline(surface)
        if build is not None:
            self.build_panel(surface, resources, build["choice"], build["menu"], build["cost_fn"])
        if level_hint:
            self.text(surface, level_hint, (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 84), "s", C.DARK_GRAY, center=True)
        self.ammo_message(surface, player)
        if build is not None and build.get("energy_warning"):
            self.energy_warning_message(surface)
        self.dialogue(surface, dialogue)

    # --- HUD de la Base Central (perspectiva de VULCANO) ---
    @staticmethod
    def base_report_rect(report):
        """Recuadro del REPORTE DE VULCANO (pasar el ratón por encima lo vuelve a mostrar)."""
        return pygame.Rect(10, 70, 620, 34 + 24 * len(report))

    BASE_HELP_RECT = pygame.Rect(0, C.WINDOW_HEIGHT - 114, C.WINDOW_WIDTH, 42)   # las dos líneas de controles de abajo

    def draw_base(self, surface, report, build_choice, menu, cost_fn, resources, buttons, dialogue, report_alpha=255,
                  help_alpha=255):
        """`report_alpha` / `help_alpha`: opacidad (0-255) del reporte y de las ayudas de controles (se desvanecen)."""
        self.text(surface, "BASE CENTRAL · PERSPECTIVA DE VULCANO", (C.WINDOW_WIDTH // 2, 18), "l", C.ORANGE, center=True)
        self.text(surface, U.lore_title("VULCANO"), (C.WINDOW_WIDTH // 2, 44), "s", (190, 120, 40), center=True,
                  shadow=False)                                                  # denominación oficial de VULCANO
        self.text(surface, "Modo Comandante: sin enemigos · VULCANO construye y repara bajo tus órdenes", (C.WINDOW_WIDTH // 2, 60), "s", C.DARK_GRAY,
                  center=True)
        panel = self.base_report_rect(report)
        if report_alpha > 0:
            lay = fade.layer(panel.size)
            local = lay.get_rect()
            self.panel(lay, local, C.ORANGE)
            self.text(lay, "REPORTE DE VULCANO", (12, 8), "s", C.ORANGE)
            for i, line in enumerate(report):
                self.text(lay, line, (12, 32 + i * 24), "s", C.WHITE)
            fade.blit_faded(surface, lay, panel.topleft, report_alpha)
        self.resources_row(surface, (14, panel.bottom + 8), resources)
        for rect, label, enabled, color in buttons:
            self.panel(surface, rect, color if enabled else C.DARK_GRAY)
            self.text(surface, label, rect.center, "s", color if enabled else C.DARK_GRAY, center=True)
        self.build_panel(surface, resources, build_choice, menu, cost_fn, shift=-60)
        if help_alpha > 0:
            hr = self.BASE_HELP_RECT
            lay = fade.layer(hr.size)
            self.text(lay, "WASD mover cámara · 1-8 elegir + clic izq. construir · clic izq. sobre estructura: reparar · H ayuda",
                      (hr.width // 2, C.WINDOW_HEIGHT - 84 - hr.y), "s", C.DARK_GRAY, center=True)
            self.text(lay, "Clic der.: rutas de torreta / mejorar muro / vender (70%) · F reparar todo · C instalar componente · ESPACIO desplegar",
                      (hr.width // 2, C.WINDOW_HEIGHT - 102 - hr.y), "s", C.DARK_GRAY, center=True)
            fade.blit_faded(surface, lay, hr.topleft, help_alpha)
        self.dialogue(surface, dialogue)

    # --- HUD del Acto 2 ---
    @staticmethod
    def is_revealed(pos, revealers):
        """¿Algún revelador (posición, radio) alcanza `pos`? Sin lista, todo se ve."""
        if revealers is None:
            return True
        return any(Vector2(pos).distance_to(c) <= r for c, r in revealers)

    def minimap_act2(self, surface, world_size, player_pos, cc, foundry_core, structures, deposits, drones, enemies,
                     revealers=None, fog=None, enemy_bases=()):
        r = self.radar_panel()
        self.panel(surface, r)
        w, h = r.size
        sx, sy = (w - 4) / world_size[0], (h - 4) / world_size[1]
        seen = (lambda p: fog.is_revealed(p)) if fog is not None else (lambda p: True)

        def pt(p):
            return (r.x + 2 + int(p[0] * sx), r.y + 2 + int(p[1] * sy))
        for d in deposits:
            pygame.draw.circle(surface, C.DARK_GRAY if d.depleted else (170, 160, 30), pt(d.pos), 2)
        for s in structures:
            pygame.draw.rect(surface, C.CYAN if getattr(s, "is_powered", True) else C.RED, (*pt(s.pos), 2, 2))
        for pos, radius in revealers or ():                                  # zona de detección (Foco Vigía)
            pygame.draw.circle(surface, (40, 70, 40), pt(pos), max(2, int(radius * sx)), 1)
        if fog is not None:                                                  # niebla: lo no descubierto, negro
            surface.blit(pygame.transform.scale(fog.small_surface(), (w - 4, h - 4)), (r.x + 2, r.y + 2))
        for e in enemies:
            if seen(e.pos) and (fog is not None or self.is_revealed(e.pos, revealers)):   # solo lo descubierto
                pygame.draw.rect(surface, C.RED, (*pt(e.pos), 2, 2))
        for d in drones:
            pygame.draw.rect(surface, C.GREEN, (*pt(d.pos), 2, 2))
        pygame.draw.rect(surface, C.CYAN, (*pt(cc.pos), 6, 6))
        for base in enemy_bases:                                            # bases enemigas reveladas
            if base.detected:
                x, y = pt(base.pos)
                if base.destroyed:
                    pygame.draw.line(surface, C.DARK_GRAY, (x - 4, y - 4), (x + 4, y + 4), 2)
                    pygame.draw.line(surface, C.DARK_GRAY, (x + 4, y - 4), (x - 4, y + 4), 2)
                else:
                    pygame.draw.rect(surface, (255, 50, 50), (x - 4, y - 4, 8, 8))
        if foundry_core is not None and foundry_core.alive() and seen(foundry_core.pos):
            pygame.draw.rect(surface, C.MAGENTA if foundry_core.shielded else C.ORANGE, (*pt(foundry_core.pos), 7, 7))
        if player_pos is not None:                                       # (en modo Comandante no hay Operador que marcar)
            pygame.draw.circle(surface, C.YELLOW, pt(player_pos), 3)

    # --- HUD del asedio (modo Comandante: sin Operador) ---
    THREAT_COLORS = {1: (255, 210, 60), 2: C.ORANGE, 3: C.RED}

    def siege_top_bar(self, surface, resources):
        """Barra superior del Comandante: Chatarra | Núcleos | Energía (no hay traje del Operador)."""
        bar = pygame.Rect(0, 0, C.WINDOW_WIDTH, self.TOP - 4)
        self.panel(surface, bar, C.DARK_GRAY)
        x, cy = 14, bar.centery
        for kind, label, color in (("scrap", f"{resources.metal}", C.WHITE), ("cores", f"{resources.cores}", C.CYAN),
                                   ("energy", f"{resources.energy}/{resources.energy_cap}", C.YELLOW)):
            self.icon(surface, kind, (x + 8, cy), 7)
            x += 20
            r = self.text(surface, label, (x, cy - 10), "m", color, shadow=False)
            x = r.right + 10
            self.text(surface, "|", (x, cy - 10), "m", C.DARK_GRAY, shadow=False)
            x += 22

    def threat_panel(self, surface, clock, fortress):
        """Nivel de Amenaza Enemiga (I, II, III) con el temporizador regresivo hasta la siguiente evolución y el estado del
        núcleo de la Fortaleza."""
        from src.mechanics.threat_clock import ROMAN
        rect = pygame.Rect(C.WINDOW_WIDTH - 312, self.TOP + 6, 300, 118)
        color = self.THREAT_COLORS[clock.phase]
        self.panel(surface, rect, color)
        self.text(surface, "AMENAZA ENEMIGA", (rect.x + 10, rect.y + 6), "s", color)
        self.text(surface, clock.name, (rect.x + 12, rect.y + 26), "xl", color)
        nxt = clock.time_to_next
        if nxt is None:
            line, sub = "MÁXIMA AMENAZA", "Sin más evolución"
        else:
            secs = math.ceil(nxt)
            line, sub = f"Evolución en {secs // 60:02d}:{secs % 60:02d}", f"Hacia la amenaza {ROMAN[clock.phase + 1]}"
        self.text(surface, line, (rect.x + 124, rect.y + 28), "m", C.WHITE)
        self.text(surface, sub, (rect.x + 124, rect.y + 54), "s", C.DARK_GRAY, shadow=False)
        self.bar(surface, (rect.x + 124, rect.y + 74, 166, 8), clock.phase_progress, color)
        core = fortress.core
        state = "DESTRUIDO" if fortress.destroyed else ("ESCUDO ACTIVO" if fortress.shielded else "EXPUESTO")
        self.text(surface, f"Núcleo enemigo · {state}", (rect.x + 10, rect.y + 90), "s",
                  C.GREEN if fortress.destroyed else (C.CYAN if fortress.shielded else C.ORANGE), shadow=False)
        self.bar(surface, (rect.x + 10, rect.y + 106, 280, 8), max(0, core.hp) / core.max_hp, C.RED)

    def siege_banner(self, surface, banner):
        """Banner grande al subir de nivel la Fortaleza enemiga (aparece y se desvanece)."""
        if not banner:
            return
        k = max(0.0, min(1.0, banner["timer"] / 1.0, (banner["total"] - banner["timer"]) / 0.3))
        surf = pygame.Surface((860, 96), pygame.SRCALPHA)
        pygame.draw.rect(surf, (24, 4, 4, 225), surf.get_rect())
        pygame.draw.rect(surf, banner["color"], surf.get_rect(), 3)
        self.text(surf, banner["title"], (430, 28), "l", banner["color"], center=True)
        self.text(surf, banner["sub"], (430, 66), "s", C.WHITE, center=True)
        surf.set_alpha(int(255 * k))
        surface.blit(surf, (C.WINDOW_WIDTH // 2 - 430, 150))

    def draw_siege(self, surface, s):
        """HUD completo de la escena de asedio (`s` = SiegeState)."""
        T = self.TOP
        self.siege_top_bar(surface, s.res)
        self.panel(surface, pygame.Rect(10, T + 6, 300, 52))
        frac = s.core.hp / s.core.max_hp
        self.text(surface, "CENTRO DE CONTROL", (20, T + 10), "s", C.CYAN)
        self.bar(surface, (20, T + 28, 280, 16), frac, C.CYAN if frac > 0.25 else C.RED, f"{max(0, int(s.core.hp))}/{s.core.max_hp}")
        self.text(surface, s.vulcano_status_text(), (20, T + 66), "s", C.CYAN, shadow=False)
        self.text(surface, s.drone_status(), (20, T + 86), "s", C.CYAN)
        fleet = s.fleet_breakdown()
        if fleet:                                                         # composición de la escuadra en vuelo
            self.text(surface, "Escuadra: " + fleet, (20, T + 106), "s", C.WHITE)
        held = sum(1 for n in s.nodes if n.owner == "player")
        self.text(surface, f"Nodos de plasma: {held}/{len(s.nodes)} capturados", (20, T + (126 if fleet else 106)), "s", C.CYAN)
        self.threat_panel(surface, s.clock, s.fortress)
        q = s.spawn_queue
        self.text(surface, f"Enemigos activos: {s.active_enemies()}/{q.cap}" + (f" · refuerzos en cola: {q.pending}" if q.pending else ""),
                  (C.WINDOW_WIDTH - 312, T + 128), "s", C.ORANGE if q.pending else C.DARK_GRAY, shadow=False)
        self.build_panel(surface, s.res, s.build_choice, s.build_menu, s._cost, shift=-60)
        self.text(surface, "WASD / bordes: cámara · clic izq. / arrastre: seleccionar drones · clic der.: mover / foco (sin selección: ataque global)",
                  (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 102), "s", C.DARK_GRAY, center=True)
        self.text(surface, "1-0 edificio · F1-F4 drones · clic der. sobre una obra: cancelar · ESPACIO pausa",
                  (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 84), "s", C.DARK_GRAY, center=True)
        self.siege_banner(surface, s.phase_banner)
        self.minimap_act2(surface, (s.map_w, s.map_h), s.core.pos, s.core, None, s.world.structures,
                          list(s.world.deposits) + list(s.nodes), s.world.drones, s.minimap_enemies(), s.revealers(), s.fog,
                          [s.fortress])
        ALERTS.draw(surface, self)
        self.dialogue(surface, s.dialogue)

    def draw_act2(self, surface, player, core, resources, wave, build_choice, menu, cost_fn, dialogue, extras):
        """Acto 2 en modo Comandante (`player` = None: no hay Operador; sin vida del piloto, botiquines, balas ni Dash).
        `extras`: dict con el estado de los drones, foundry_pool, foundry_core, sub-acto y mundo para el minimapa."""
        T = self.TOP
        self.siege_top_bar(surface, resources)
        self.panel(surface, pygame.Rect(10, T + 6, 300, 86))
        now = _now()
        if self._core_hp is not None and core.hp < self._core_hp - 0.01:       # el Centro de Control recibe daño
            self._core_hit = now
            ALERTS.push("¡CENTRO DE CONTROL BAJO ATAQUE!", C.RED, key="core")
        self._core_hp = core.hp
        core_frac = core.hp / core.max_hp
        self.text(surface, "CENTRO DE CONTROL", (20, T + 10), "s", C.CYAN)
        self.bar(surface, (20, T + 28, 280, 16), core_frac, C.CYAN if core_frac > 0.25 else C.RED,
                 f"{max(0, int(core.hp))}/{core.max_hp}")
        if now - self._core_hit < 0.5 or (core_frac < 0.25 and int(now * 4) % 2 == 0):
            pygame.draw.rect(surface, C.RED, (18, T + 26, 284, 20), 2)           # destello al recibir daño / parpadeo crítico
        self.text(surface, "MANDO TÁCTICO · VISTA CENITAL", (20, T + 50), "s", C.CYAN)
        self.text(surface, f"Oleada {max(1, wave.wave)}" + ("" if wave.endless else f"/{wave.total_waves}"), (20, T + 68), "s",
                  C.WHITE, shadow=False)

        # Cabecera segun la fase
        fc = extras["foundry_core"]
        if wave.phase == "prep":
            head = f"{math.ceil(wave.timer)}s para preparar · construcción -50%"
            sub, color = "N: saltar preparación", C.GREEN
        elif wave.phase == "wave":
            left = max(0, int(C.WAVE_DURATION - wave.wave_time))
            of = "" if wave.endless else f" / {wave.total_waves}"
            head = f"Oleada {wave.wave}{of} · {left // 60:02d}:{left % 60:02d} restantes · enemigos: {wave.remaining}"
            sub, color = "", C.RED
        elif wave.phase == "break":
            head = f"Oleada {wave.wave} superada · siguiente en {wave.timer:0.1f}s"
            sub, color = "", C.CYAN
        elif fc is None:
            head = "ASALTO: ¡destruye las bases enemigas!"
            sub, color = "Quedan incursiones hasta que caiga la última base", C.ORANGE
        else:
            head = "ASALTO: ¡destruye la Fundición Renegada!"
            state = "BLINDADO: destruye sus torretas" if fc is not None and fc.shielded else "EXPUESTO: ¡demuélelo!"
            sub, color = f"Núcleo de la Fundición {state}", C.ORANGE
        self.text(surface, "SUB-ACTO " + extras["sub_act"], (C.WINDOW_WIDTH // 2, T + 4), "s", C.DARK_GRAY, center=True)
        self.text(surface, head, (C.WINDOW_WIDTH // 2, T + 26), "m", color, center=True)
        if sub:
            self.text(surface, sub, (C.WINDOW_WIDTH // 2, T + 50), "s", C.WHITE, center=True)

        # Esquina superior derecha: alerta, escuadron y Fundicion
        rx = C.WINDOW_WIDTH - 12
        if not extras.get("campaign_title"):
            self.text(surface, f"Alerta {resources.threat_level}", (rx - 130, T + 6), "m",
                      C.RED if resources.threat_bonus_pct else C.DARK_GRAY)
        status = extras.get("drone_status", "")
        self.text(surface, status, (rx - 480, T + 32), "s", C.CYAN)
        fleet = extras.get("fleet", "")
        dy = 0
        if fleet:                                                         # composición de la escuadra en vuelo
            self.text(surface, "Escuadra: " + fleet, (rx - 480, T + 50), "s", C.WHITE)
            dy = 20                                                       # el resto de la columna baja una línea
        title = extras.get("campaign_title")
        if title:                                                         # mapa de campaña: nombre y tiempo restante
            left = int(extras.get("campaign_left") or 0)
            self.text(surface, f"{title} · {left // 60:02d}:{left % 60:02d}", (rx - 300, T + 8), "s",
                      C.RED if left < 60 else C.CYAN)
        self.text(surface, f"{'Fundición' if fc is not None else 'Enemigo'}: {extras['foundry_pool']}/{C.FOUNDRY_SCRAP_STEP} metal robado",
                  (rx - 300, T + 52 + dy), "s", C.ORANGE)
        if fc is not None and fc.alive():
            self.bar(surface, (rx - 300, T + 74 + dy, 280, 10), fc.hp / fc.max_hp, C.ORANGE)
        if extras.get("vulcano"):
            self.text(surface, "VULCANO: en línea (auto-reparación)", (rx - 300, T + 90 + dy), "s", C.ORANGE)
        bases = extras.get("enemy_bases") or ()
        if bases:
            left = sum(1 for b in bases if not b.destroyed)
            found = sum(1 for b in bases if b.detected and not b.destroyed)
            self.text(surface, f"Bases enemigas: {left}/{len(bases)} · {found} vistas", (rx - 300, T + 108 + dy), "s",
                      (255, 90, 90) if left else C.GREEN)
        if title:
            self.wave_display.draw(self, surface, (rx - 300, T + 128 + dy), wave)
        self.progress_bar.draw(self, surface, (rx - 300, T + 168 + dy), resources, short=True)

        self.build_panel(surface, resources, build_choice, menu, cost_fn, shift=-60)
        self.text(surface, "WASD / flechas / bordes: cámara · clic izq. construir · R+clic reparar · E mejorar muro · ESPACIO pausa",
                  (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 102), "s", C.DARK_GRAY, center=True)
        self.text(surface, "1-8 edificio · F1-F4 drones · T árbol · clic izq./arrastre: seleccionar · clic der.: orden / menú · ESC: soltar",
                  (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 84), "s", C.DARK_GRAY, center=True)
        if extras.get("energy_warning"):
            self.energy_warning_message(surface)
        self.minimap_act2(surface, extras["world_size"], None, core, fc, extras["structures"],
                          extras["deposits"], extras["drones"], extras["enemies"], extras.get("revealers"),
                          extras.get("fog"), extras.get("enemy_bases", ()))
        self.wave_banner.draw(surface, self, wave)                    # anuncio de oleada y avisos de pérdidas
        ALERTS.draw(surface, self)
        self.dialogue(surface, dialogue)
