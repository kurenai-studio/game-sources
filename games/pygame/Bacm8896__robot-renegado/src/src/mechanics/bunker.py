"""Búnker de Mando en la Base Central: sitio de obra, ensamblaje y consola (mixin de las escenas con construcción).

La escena aporta: world, res, CC_POS, map_rect, notify() y _register() (ConstructionMixin). Mientras no esté ensamblado hay un
`BunkerSite` (sólido) en la primera posición libre de `U.BUNKER["offsets"]`; al ensamblarlo (400 de chatarra, 2 núcleos y el
Módulo de Mando) el sitio se convierte en la estructura "bunker" (800 HP) y aparece la Consola de Mando Táctico. El estado vive en
`CampaignRun.bunker_built`; la estructura viaja con la base (layout) y, si el estado dice "ensamblado" pero la estructura no
está (p. ej. se perdió el layout de un mapa derrotado), se recrea. Si el Búnker cae, vuelve el sitio de obra."""
import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.audio_manager import audio
from src.entities.building import create_building
from src.entities.bunker import BunkerSite
from src.entities.interactable import Terminal

OP4_REQUIRED = "Requiere planos de Op 4: Complejo Tecnológico"   # Búnker y asedio: Módulo de Mando y planos salen de la Op 4


class BunkerMixin:
    CONSOLE_ACTIVE = False        # solo la Base Central (modo Comandante) inicia el asedio desde la consola del Búnker
    CONSOLE_NOTE = "La consola de mando se usa desde la Base Central (modo Comandante)."
    bunker_site = None
    bunker = None
    bunker_console = None

    # --- preparación ---
    def _bunker_rect(self, pos):
        size = U.BUNKER["cells"] * C.BUILD_GRID
        rect = pygame.Rect(0, 0, size, size)
        rect.center = (round(pos.x), round(pos.y))
        return rect

    def _free_bunker_pos(self):
        blockers = [s.rect for s in self.world.structures] + [d.rect for d in self.world.deposits]
        for off in U.BUNKER["offsets"]:
            pos = Vector2(self.CC_POS) + Vector2(off)
            rect = self._bunker_rect(pos)
            if self.map_rect.contains(rect) and rect.collidelist(blockers) == -1:
                return pos
        return Vector2(self.CC_POS) + Vector2(U.BUNKER["offsets"][0])

    def setup_bunker(self):
        """Llamar tras restaurar la base: deja el sitio de obra, o el Búnker y su consola si ya está ensamblado."""
        self.bunker_site = self.bunker = self.bunker_console = None
        if self.res.bunker_built:
            b = next((s for s in self.world.structures if s.building_type == "bunker"), None)
            self.bunker = b if b is not None else self._place_bunker(self._free_bunker_pos())
            self._make_console(self.bunker)
        else:
            self._make_site(self._free_bunker_pos())

    def _place_bunker(self, pos):
        b = create_building("bunker", pos)
        self._register(b)
        return b

    def _make_site(self, pos):
        site = BunkerSite(pos)
        site.on_interact = self._assemble_bunker
        self.world.all_sprites.add(site)
        self.world.solids.add(site)
        self.bunker_site = site

    def _make_console(self, bunker):
        pos = Vector2(bunker.pos) + Vector2(0, U.BUNKER["cells"] * C.BUILD_GRID / 2 + 28)
        label = U.BUNKER["console_label"] if self.CONSOLE_ACTIVE else U.BUNKER["console_label_remote"]
        console = Terminal(pos, (34, 44), label, color=C.CYAN)
        if self.CONSOLE_ACTIVE:
            console.prompt_key = "Clic / E"                          # aviso: "[Clic / E] Iniciar Asedio Táctico a la Fortaleza..."
        console.on_interact = self._console_used
        self.world.all_sprites.add(console)
        self.bunker_console = console

    # --- ensamblaje y consola ---
    def _assemble_bunker(self, scene, site):
        """E (Operador) o clic (VULCANO) sobre el sitio: cobra 400 de chatarra y 2 núcleos y levanta el Búnker."""
        if not self.res.bunker_built and not self.res.command_module:   # sin la Op 4 no hay nada que montar
            self.notify(OP4_REQUIRED, 6)
            audio.play("error")
            return False
        ok, msg = self.res.build_bunker()
        if not ok:
            self.notify(msg, 6)
            audio.play("error")
            return False
        game = getattr(self, "game", None)
        if game is not None:
            game.autosave_here()                                 # autoguardado: Búnker completado
        pos = Vector2(site.pos)
        self.world.solids.remove(site)
        site.kill()
        self.bunker_site = None
        self.bunker = self._place_bunker(pos)
        self._make_console(self.bunker)
        self.notify("Búnker de Mando ensamblado. Desde la Base Central, su consola inicia el asedio a la Fortaleza enemiga.", 6)
        return True

    def _console_used(self, scene, console):
        """Clic o E sobre la consola: en la Base Central pide confirmar el asedio; en el resto de escenas, solo informa."""
        if self.CONSOLE_ACTIVE:
            self.request_siege()
        else:
            self.notify(self.CONSOLE_NOTE, 5)

    def request_siege(self):
        """Gancho: la Base Central lo implementa (confirmación de despliegue)."""

    def _bunker_lost(self, building):
        """El Búnker cayó: hay que volver a ensamblarlo (el Módulo de Mando se conserva)."""
        self.res.bunker_built = False
        if self.bunker_console is not None:
            self.bunker_console.kill()
            self.bunker_console = None
        self.bunker = None
        self._make_site(Vector2(building.pos))
        self.notify("¡El Búnker de Mando ha caído! Hay que ensamblarlo de nuevo.", 6)

    # --- entrada y dibujo ---
    def update_bunker(self, dt, player=None, cursor=None):
        """Avanza el sitio y la consola y marca cuál está "cerca" (Operador a su alcance o ratón encima): muestra su [E]."""
        for it in (self.bunker_site, self.bunker_console):
            if it is None or not it.alive():
                continue
            it.update(dt)
            it.near = ((player is not None and player.alive() and it.can_interact(player))
                       or (cursor is not None and it.rect.collidepoint(cursor)))

    def bunker_interact(self, player=None, point=None):
        """E del Operador (por cercanía) o clic/E del Comandante (por puntero). True si consumió la acción."""
        for it in (self.bunker_site, self.bunker_console):
            if it is None or not it.alive() or not it.enabled:
                continue
            if (player is not None and player.alive() and it.can_interact(player)) or (point is not None and it.rect.collidepoint(point)):
                it.interact(self)
                return True
        return False

    def bunker_hover_card(self, world_pos):
        from src.ui.tooltips import bunker_console_card, bunker_site_card
        if self.bunker_site is not None and self.bunker_site.alive() and self.bunker_site.rect.collidepoint(world_pos):
            return ("bunker_site",), bunker_site_card(self.res)
        if self.bunker_console is not None and self.bunker_console.alive() and self.bunker_console.rect.collidepoint(world_pos):
            return ("bunker_console",), bunker_console_card(self.CONSOLE_ACTIVE, self.res)
        return None
