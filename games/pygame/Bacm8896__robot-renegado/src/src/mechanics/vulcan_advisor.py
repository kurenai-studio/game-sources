"""Mentor VULCANO: tutoriales de desbloqueo reactivos en la Base Central.

Cada hito se activa solo cuando el estado de la campaña lo permite (`ready`) y no está ya en `CampaignRun.tutorial_done`:
  1. explicación  VULCANO cuenta qué es la estructura o la mejora y para qué sirve (con el nombre del Operador).
                  [ENTER] siguiente línea · [ESC] salta el hito y vuelve al juego libre (queda marcado, no se repite).
  2. paso guiado  el menú solo deja construir/mejorar lo del hito, en la zona marcada, y SIN coste (subsidio de prueba).
  3. prueba       micro-oleada que demuestra la ventaja de esa tecnología. Ninguna estructura baja de 1 HP durante la prueba.
  4. cierre       VULCANO felicita, repara lo dañado, marca el hito y autoguarda (saves/{nombre}.json).

Hitos: triad (Pilón -> Muro -> Torreta Ligera, 3 Scouts) · economy (Extractor sobre una veta, 2 Carroñeros) ·
heavy (Balista y su perforación, 1 Ariete de prueba) · upgrade (especialización de una torreta, escaramuza rápida)."""
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.entities.building import Building
from src.entities.enemy import Enemy
from src.entities.scavenger import ScavengerDrone
from src.entities.scrap import ScrapItem
from src.mechanics import combat
from src.ui.fade import FadeTimer, blit_faded, layer

ENABLED = True                     # las pruebas automáticas lo apagan para entrar a la Base Central sin tutorial
ORDER = ("triad", "economy", "heavy", "upgrade")
TRIAL_TIMEOUT = 60.0               # s: la simulación se da por terminada aunque quede algún enemigo
SPAWN_DIST = 760                   # px al este del Centro de Control donde entran los enemigos de prueba
ZONE_COLOR = (255, 150, 40)


def _triad_ready(res, scene):
    return True


def _economy_ready(res, scene):
    return res.structure_unlocked("extractor") and scene.free_deposit() is not None


def _heavy_ready(res, scene):
    return res.structure_unlocked("balista")


def _upgrade_ready(res, scene):
    return res.initial_done and any(b.building_type == "tower" and b.route is None for b in scene.world.towers)


MILESTONES = {
    "triad": {
        "title": "Tríada Base", "ready": _triad_ready,
        "intro": ["{name}, soy VULCANO. Antes de salir quiero enseñarte a levantar una defensa que se sostenga sola.",
                  "Todo empieza por la energía: el PILÓN lleva la red del Reactor a lo que construyas cerca.",
                  "El MURO no dispara, pero obliga al enemigo a pararse a morderlo: gana tiempo para tus armas.",
                  "Y la TORRETA LIGERA, conectada a la red, barre a los Scouts rápidos. Pilón, muro, torreta: la tríada."],
        "steps": [("build", "pylon"), ("build", "wall"), ("build", "tower")],
        "zone": "east", "trial": [("scout", 3)],
        "outro": "Tres Scouts, tres chatarras. Así se defiende una base, {name}: energía, contención y fuego.",
    },
    "economy": {
        "title": "Economía", "ready": _economy_ready,
        "intro": ["{name}, la guerra se gana con chatarra. Te enseño a minarla sin moverte de casa.",
                  "El EXTRACTOR se monta SOBRE una veta de chatarra y la va sacando sola, a cambio de energía.",
                  "Ojo: lo que extrae atrae a los Carroñeros. Vienen a saquear y huyen. Que la torreta los vea llegar."],
        "steps": [("build", "extractor")],
        "zone": "deposit", "trial": [("scavenger", 2)],
        "outro": "La veta es tuya, {name}. Un extractor cubierto por una torreta es dinero que nadie te roba.",
    },
    "heavy": {
        "title": "Defensa Pesada", "ready": _heavy_ready,
        "intro": ["{name}, la BALISTA ya está a tu alcance: la torreta pesada de la base.",
                  "Dispara virotes de 160 que PERFORAN: atraviesan al primero y siguen hacia el de detrás.",
                  "Contra un Ariete es la diferencia: su frente blindado deja el fuego ligero en nada, pero un virote "
                  "pesado sigue haciendo daño de verdad. Y si lo pilla de costado o por detrás, el triple.",
                  "Colócala en la zona marcada, junto a la red. Te mando un Ariete de prueba con blindaje de entrenamiento."],
        "steps": [("build", "balista")],
        "zone": "east", "trial": [("ariete", 1)],
        "outro": "Ese Ariete no llegó a tocar el Reactor. La Balista es tu martillo, {name}.",
    },
    "upgrade": {
        "title": "Mejoras In-Situ", "ready": _upgrade_ready,
        "intro": ["{name}, una torreta no se queda como nace: se especializa sobre el terreno.",
                  "Haz clic derecho sobre tu Torreta Ligera y elige una RUTA: Minigun perfora armadura; Lanzallamas, "
                  "daño en área.",
                  "Esta primera especialización corre de mi cuenta: no gasta ni chatarra ni la tecnología del Terminal."],
        "steps": [("upgrade", "tower")],
        "zone": "tower", "trial": [("scout", 4), ("soldier", 1)],
        "outro": "Escaramuza resuelta. Una torreta especializada vale por dos, {name}.",
    },
}


class VulcanAdvisor:
    """Gestor de hitos de una visita a la Base Central (la escena lo crea en `enter`)."""

    def __init__(self, scene):
        self.scene = scene
        self.key = None              # hito en curso
        self.phase = None            # "intro" | "step" | "trial" | "outro"
        self.lines, self.line_i = [], 0
        self.step_i = 0
        self.zone = None             # (centro, radio) donde se permite construir en el paso guiado
        self.target = None           # estructura marcada (la torreta del hito de mejoras)
        self.known = set()           # ids de las estructuras que ya había al empezar el paso
        self.trial_t = 0.0
        self.foes = []
        self.trial_drops = []
        self.pending = []            # [(retardo, tipo)] de la micro-oleada
        self._shown = None           # (capa, posición) del último cuadro de explicación dibujado
        self.ghost = None            # [capa, posición, FadeTimer]: la explicación recién cerrada o saltada, desvaneciéndose
        self.completed = []          # hitos terminados en esta visita (pruebas / reporte)
        self.outro_t = 0.0

    # --- estado ---
    @property
    def res(self):
        return self.scene.res

    @property
    def run(self):
        return self.res.campaign_run

    @property
    def name(self):
        return self.run.player_name

    @property
    def active(self):
        return self.key is not None

    @property
    def modal(self):
        """Explicación en pantalla: el resto de teclas no actúa (solo ENTER y ESC)."""
        return self.phase in ("intro", "outro")

    @property
    def spec(self):
        return MILESTONES[self.key]

    def next_ready(self):
        for key in ORDER:
            if key not in self.run.tutorial_done and MILESTONES[key]["ready"](self.res, self.scene):
                return key
        return None

    def start_next(self):
        """Arranca el siguiente hito disponible (si lo hay y el mentor está activo)."""
        if not ENABLED or self.active:
            return None
        key = self.next_ready()
        if key is not None:
            self.start(key)
        return key

    def start(self, key):
        self.key, self.phase = key, "intro"
        self.lines = [ln.format(name=self.name) for ln in MILESTONES[key]["intro"]]
        self.line_i = 0
        self.step_i = 0
        self.scene.build_choice = None

    # --- entrada ---
    def handle_event(self, event):
        """Devuelve True si el mentor consumió el evento."""
        if not self.active or event.type != pygame.KEYDOWN:
            return False
        if self.phase == "intro":
            if event.key == pygame.K_ESCAPE:
                self.skip()
            elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self.line_i += 1
                if self.line_i >= len(self.lines):
                    self._begin_step()
            return True
        if self.phase == "outro":
            if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_ESCAPE):
                self._close()
            return True
        return False

    def skip(self):
        """[ESC] en la explicación: salta el hito y vuelve al juego libre (queda registrado y no se repite)."""
        key = self.key
        self._cleanup_trial()
        self.run.tutorial_done.add(key)
        self.key = self.phase = None
        self.zone = self.target = None
        self.scene.build_choice = None
        self.scene.notify(f"Tutorial «{MILESTONES[key]['title']}» saltado: juego libre.", 4)
        self.scene.game.autosave_here()

    # --- paso guiado ---
    @property
    def step(self):
        if self.key is None or self.phase != "step":
            return None
        steps = self.spec["steps"]
        return steps[self.step_i] if self.step_i < len(steps) else None

    def _begin_step(self):
        self.phase = "step"
        kind, btype = self.step
        self.known = {id(b) for b in self.scene.world.structures}
        self.zone = self._zone_for(btype)
        if kind == "build":
            self.scene.build_choice = btype if self.res.structure_unlocked(btype) else None
            self.scene.notify(f"VULCANO: construye {Building.LABELS[btype]} en la zona marcada (sin coste).", 6)
        else:
            self.scene.build_choice = None
            self.scene.notify("VULCANO: clic derecho sobre la torreta marcada y elige una ruta (sin coste).", 6)

    def _zone_for(self, btype):
        sc = self.scene
        mode = self.spec["zone"]
        if mode == "deposit":
            dep = sc.free_deposit()
            return (Vector2(dep.pos), 30) if dep is not None else None
        if mode == "tower":
            towers = [b for b in sc.world.towers if b.building_type == "tower" and b.route is None]
            self.target = min(towers, key=lambda b: b.pos.distance_to(sc.CC_POS)) if towers else None
            return (Vector2(self.target.pos), 40) if self.target is not None else None
        return (sc.CC_POS + Vector2(150, 0), 120)           # al alcance de la red del Reactor (160 px)

    def allows(self, btype):
        """¿El paso guiado deja elegir `btype`? (fuera de un hito, todo)."""
        if not self.active:
            return True
        st = self.step
        return st is not None and st[0] == "build" and st[1] == btype

    def guard(self, btype, rect=None):
        """Aviso si el paso guiado no permite `btype` (o fuera de la zona marcada); None si vale."""
        if not self.active:
            return None
        if self.modal:
            return "VULCANO: termina antes la explicación ([ENTER] seguir · [ESC] saltar)."
        if not self.allows(btype):
            st = self.step
            want = Building.LABELS[st[1]] if st is not None and st[0] == "build" else "la mejora de la torreta"
            return f"VULCANO: ahora toca {want}. Lo demás, cuando terminemos la prueba."
        if rect is not None and self.zone is not None:
            center, radius = self.zone
            if Vector2(rect.center).distance_to(center) > radius:
                return "VULCANO: dentro de la zona marcada, por favor."
        return None

    def free(self, btype):
        """Subsidio de prueba: lo que pide el paso guiado sale gratis (nunca deja la cuenta en rojo)."""
        st = self.step
        return st is not None and st[0] == "build" and st[1] == btype

    def free_route(self, building):
        """Paso de mejoras: la torreta marcada puede especializarse gratis aunque la ruta no esté desbloqueada."""
        st = self.step
        return st is not None and st[0] == "upgrade" and building is self.target

    def _step_done(self):
        kind, btype = self.step
        if kind == "build":
            return any(b.building_type == btype and id(b) not in self.known and b.alive() for b in self.scene.world.structures)
        return self.target is not None and self.target.alive() and self.target.route is not None

    # --- prueba (micro-oleada) ---
    def _begin_trial(self):
        self.phase = "trial"
        self.zone = None
        self.scene.build_choice = None
        self.scene.close_menu()
        self.trial_t = 0.0
        self.foes = []
        for b in self.scene.world.structures:
            b.hp_floor = 1                                     # nada cae del todo durante la prueba
        self.pending = []
        delay = 1.5
        for kind, n in self.spec["trial"]:
            for _ in range(n):
                self.pending.append((delay, kind))
                delay += 0.8
        if self.key == "economy":
            self._spill_ore()
        self.scene.notify("VULCANO: simulación en marcha. Mira cómo trabaja tu defensa.", 5)

    def _spill_ore(self):
        """La veta recién abierta deja chatarra a la vista: es lo que vienen a saquear los Carroñeros."""
        ext = next((b for b in self.scene.world.extractors if id(b) not in self.known), None)
        center = ext.pos if ext is not None else self.scene.CC_POS
        for i in range(3):
            pile = ScrapItem(center + Vector2(34, 0).rotate(120 * i), 12)
            pile.lifetime = TRIAL_TIMEOUT + 10
            self.scene.world.scraps.add(pile)
            self.scene.all_sprites.add(pile)
            self.trial_drops.append(pile)

    def _spawn(self, kind):
        sc, w = self.scene, self.scene.world
        y = sc.CC_POS.y + random.uniform(-70, 70)
        start = Vector2(min(sc.map_w - 30, sc.CC_POS.x + SPAWN_DIST), y)
        if kind == "scavenger":
            foe = ScavengerDrone(Vector2(sc.map_w + 30, y))
            foe.on_death = foe.on_escape = self._foe_gone
            w.scavengers.add(foe)
        else:
            foe = Enemy(kind, start, sc.core.pos, w.enemies)
            foe.world, foe.always_active = w, True
            foe.on_death = self._foe_gone
            if kind == "ariete":                                 # Ariete de prueba: entrenamiento, no asalto
                foe.hp = foe.max_hp = foe.max_hp * 0.6
                foe.power = 0.5
                foe.base = dict(foe.base, front_reduction=0.3)   # blindaje de entrenamiento (el real frena un 45%)
            w.enemies.add(foe)
        w.targets.add(foe)
        sc.all_sprites.add(foe)
        self.foes.append(foe)

    def _foe_gone(self, foe):
        pass

    def _trial_tick(self, dt):
        sc, w = self.scene, self.scene.world
        self.trial_t += dt
        due = [p for p in self.pending if p[0] <= self.trial_t]
        self.pending = [p for p in self.pending if p[0] > self.trial_t]
        for _, kind in due:
            self._spawn(kind)
        sc.nav.update(w.structures, sc.core)
        w.enemies.update(dt, w.structures, sc.nav)
        w.scavengers.update(dt, w.scraps, w.core_items, w.pylons)
        w.structures.update(dt, w.targets, w.bullets)
        w.bullets.update(dt)
        w.enemy_bullets.update(dt)
        w.shells.update(dt)
        w.scraps.update(dt, None)
        combat.resolve_projectiles(w.bullets, w.enemies, w.scavengers)
        for bullet, victims in pygame.sprite.groupcollide(w.enemy_bullets, w.structures, True, False).items():
            victims[0].take_damage(bullet.damage)
        alive = [f for f in self.foes if f.alive()]
        if (not self.pending and not alive) or self.trial_t >= TRIAL_TIMEOUT:
            self._end_trial()

    def _cleanup_trial(self):
        """Fin (o cancelación) de la prueba: fuera los enemigos de prueba y su chatarra; VULCANO repara todo gratis."""
        w = self.scene.world
        if self.phase != "trial" and not self.foes:
            return                                              # no había prueba: nada que limpiar ni reparar
        for f in self.foes:
            f.kill()
        for pile in self.trial_drops:
            pile.kill()
        self.foes, self.trial_drops, self.pending = [], [], []
        w.enemy_bullets.empty()
        w.bullets.empty()
        for b in w.structures:
            b.hp_floor = 0
            if b.alive() and b.hp < b.max_hp:
                b.hp = b.max_hp

    def abort(self):
        """La escena se va a mitad de un hito (despliegue, terminal, asedio): sin enemigos de prueba ni vida mínima. El
        hito no se marca: se repite en la próxima visita."""
        self._cleanup_trial()
        self.key = self.phase = None
        self.zone = self.target = None

    def _end_trial(self):
        self._cleanup_trial()
        self.phase = "outro"
        self.lines = [self.spec["outro"].format(name=self.name)]
        self.line_i = 0

    def _close(self):
        """Cierre: felicitación leída, hito registrado y autoguardado; si hay otro listo, empieza."""
        key = self.key
        self.run.tutorial_done.add(key)
        self.completed.append(key)
        self.key = self.phase = None
        self.zone = self.target = None
        self.scene.notify(f"Hito «{MILESTONES[key]['title']}» completado.", 4)
        self.scene.game.autosave_here()
        self.start_next()

    # --- bucle ---
    def update(self, dt):
        if self.ghost is not None:
            self.ghost[2].update(dt)
            if not self.ghost[2].visible:
                self.ghost = None
        if not self.active:
            return
        if self.phase == "step":
            st = self.step
            if st is not None and st[0] == "upgrade" and (self.target is None or not self.target.alive()):
                self.zone = self._zone_for("tower")             # la marcada desapareció: marca otra
            if st is not None and self._step_done():
                self.step_i += 1
                if self.step_i >= len(self.spec["steps"]):
                    self._begin_trial()
                else:
                    self._begin_step()
        elif self.phase == "trial":
            self._trial_tick(dt)

    # --- dibujo ---
    def draw_world(self, surface, offset):
        if self.zone is None:
            return
        center, radius = self.zone
        c = (round(center.x - offset.x), round(center.y - offset.y))
        pulse = 0.5 + 0.5 * math.sin(pygame.time.get_ticks() / 220)
        layer = pygame.Surface((radius * 2 + 8, radius * 2 + 8), pygame.SRCALPHA)
        pygame.draw.circle(layer, (*ZONE_COLOR, int(28 + 30 * pulse)), (radius + 4, radius + 4), radius)
        pygame.draw.circle(layer, (*ZONE_COLOR, 220), (radius + 4, radius + 4), radius, 2)
        surface.blit(layer, (c[0] - radius - 4, c[1] - radius - 4))

    def objective(self):
        if self.phase == "step":
            kind, btype = self.step
            if kind == "build":
                n = len(self.spec["steps"])
                return f"Paso {self.step_i + 1}/{n}: construye {Building.LABELS[btype]} en la zona marcada · gratis"
            return "Clic derecho sobre la torreta marcada y elige una ruta · gratis"
        if self.phase == "trial":
            left = len(self.pending) + sum(1 for f in self.foes if f.alive())
            return f"Prueba en curso: {left} enemigo(s) de práctica · {max(0, int(TRIAL_TIMEOUT - self.trial_t))} s"
        return ""

    def draw_panel(self, surface, hud):
        if self._shown is not None and not self.modal:      # la explicación se cerró o se saltó: se desvanece
            self.ghost = [*self._shown, FadeTimer(hold=0.0)]
            self._shown = None
        if self.ghost is not None:
            blit_faded(surface, self.ghost[0], self.ghost[1], self.ghost[2].alpha)
        if not self.active:
            return
        idx = ORDER.index(self.key) + 1
        rect = pygame.Rect(C.WINDOW_WIDTH // 2 - 360, 244, 720, 132 if self.modal else 64)    # bajo el reporte de VULCANO
        lay = layer(rect.size)                               # se dibuja aparte: así puede desvanecerse al cerrarse
        hud.panel(lay, lay.get_rect(), C.ORANGE)
        hud.text(lay, f"MENTOR VULCANO · Hito {idx}/{len(ORDER)}: {self.spec['title']}", (14, 8), "s", C.ORANGE)
        if self.modal:
            line = self.lines[min(self.line_i, len(self.lines) - 1)]
            for i, chunk in enumerate(_wrap(line, 84)[:3]):
                hud.text(lay, chunk, (14, 32 + i * 22), "s", C.WHITE)
            more = "[ENTER] seguir" if self.phase == "intro" else "[ENTER] cerrar"
            skip = " · [ESC] saltar el tutorial (juego libre)" if self.phase == "intro" else ""
            hud.text(lay, f"{more}{skip}  ({self.line_i + 1}/{len(self.lines)})", (14, rect.height - 26), "s", C.DARK_GRAY)
            self._shown = (lay, rect.topleft)
            self.ghost = None                                # una explicación nueva tapa la que se iba
        else:
            hud.text(lay, self.objective(), (14, 32), "s", C.YELLOW)
        surface.blit(lay, rect.topleft)


def _wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        if len(cur) + len(w) + 1 > width and cur:
            lines.append(cur)
            cur = w
        else:
            cur = f"{cur} {w}".strip()
    if cur:
        lines.append(cur)
    return lines
