"""Cola de obras de la Base Central (modo Comandante): el jugador ordena y VULCANO construye.

La escena aporta: world, res, vulcano, deposit_list, ConstructionMixin (`_register`, `_cost`, `_deposit_at`, `_sync_energy`...)
y `sites` (lista en orden de pedido). Elegir una estructura y hacer clic en el mapa coloca un sitio de obra (sólido: nada se
construye encima); no se cobra al ordenarlo sino a medida que VULCANO ensambla. Se cancela con clic derecho (reembolsa lo
gastado)."""
import pygame
from pygame.math import Vector2

from src.core.audio_manager import audio
from src.entities.building import Building, create_building
from src.entities.construction_site import ConstructionSite
from src.ui.tooltips import site_card

STATUS_TEXT = {
    "repairing": "VULCANO: reparando estructuras críticas (las obras esperan)",
    "waiting_repair": "VULCANO: reparación crítica pendiente, falta chatarra (las obras esperan)",
    "moving": "VULCANO: de camino al sitio de obra",
    "building": "VULCANO: construyendo",
    "waiting_scrap": "VULCANO: obra en espera, falta chatarra",
    "idle": "VULCANO: sin órdenes",
}


class SiteQueueMixin:
    sites = ()
    vulcano_status = "idle"

    def _queue_site(self, btype, rect):
        """Coloca el sitio de obra de `btype` en `rect` (ya validado). Los núcleos, si los pide, se pagan ahora."""
        stats = Building.STATS[btype]
        scrap, cores = self._cost(btype), stats["cores"]
        queued_energy = sum(s.energy for s in self.sites)
        if stats["energy"] > self.energy_free() - queued_energy:
            self.notify(f"Energía insuficiente: {Building.LABELS[btype]} necesita {stats['energy']} y quedan "
                        f"{self.energy_free() - queued_energy}. Extiende la red con más pilones.", 3)
            self.build_cd = 0.5
            return None
        if cores and not self.res.spend_cores(cores):
            self.notify("Núcleos de plasma insuficientes.", 2)
            self.build_cd = 0.5
            return None
        deposit = self._deposit_at(Vector2(rect.center)) if btype == "extractor" else None
        ghost = self._ghost_image(btype, rect.center, deposit)
        site = ConstructionSite(btype, rect.center, ghost, scrap, cores, stats["energy"], stats["hp"], deposit)
        self.sites.append(site)
        audio.play("place")                                         # sitio de obra colocado
        self.world.all_sprites.add(site)
        self.world.solids.add(site)
        self.vulcano_status = "moving"                              # VULCANO toma la obra al instante (no "sin órdenes")
        self.notify(f"VULCANO tiene la orden: {Building.LABELS[btype]} ({scrap} de chatarra a medida que construye).", 3)
        return site

    @staticmethod
    def _ghost_image(btype, center, deposit):
        """Aspecto del andamio: la propia estructura, translúcida."""
        try:
            img = create_building(btype, center, deposit=deposit).image.copy()
        except Exception:                                                  # estructura sin arte propio: caja genérica
            img = pygame.Surface(Building.SIZES[btype], pygame.SRCALPHA)
            pygame.draw.rect(img, (120, 200, 255), img.get_rect(), 2)
        img.set_alpha(120)
        return img

    def site_under(self, world_pos):
        for s in self.sites:
            if s.rect.collidepoint(world_pos):
                return s
        return None

    def _remove_site(self, site):
        if site in self.sites:
            self.sites.remove(site)
        self.world.solids.remove(site)
        site.kill()

    def cancel_site(self, site, quiet=False):
        """Cancela la obra y reembolsa la chatarra ya consumida (y los núcleos)."""
        self.res.add_metal(site.paid)
        self.res.add_cores(site.core_cost)
        self._remove_site(site)
        if not quiet:
            self.notify(f"Obra cancelada: {Building.LABELS[site.btype]} (reembolso {site.paid} de chatarra).", 3)

    def cancel_all_sites(self):
        """Antes de desplegar: lo que no se ha terminado no viaja con la base; se reembolsa. Devuelve cuántas canceló."""
        n = len(self.sites)
        for site in list(self.sites):
            self.cancel_site(site, quiet=True)
        return n

    def _finish_site(self, site):
        """La obra llegó al 100%: la estructura real, con toda su vida."""
        pos, deposit = Vector2(site.pos), site.deposit
        self._remove_site(site)
        b = create_building(site.btype, pos, deposit=deposit)
        if hasattr(b, "build_left"):                                # la Fábrica ya la ensambló VULCANO: operativa al instante
            b.build_left = 0.0
        self._register(b)
        self.grid.update()
        self._sync_energy()
        self.placed_sound(b)                                        # VULCANO terminó (y el pilón se engancha a la red)
        self.on_built(b)
        self.notify(f"VULCANO terminó: {Building.LABELS[site.btype]}.", 3)
        return b

    def work_sites(self, dt):
        """Un paso de VULCANO constructor: reparar lo crítico, ensamblar la cola de obras o flotar junto al Núcleo."""
        status, finished = self.vulcano.command_update(dt, self.world, self.res, self.sites)
        self.vulcano_status = status
        if finished is not None:
            self._finish_site(finished)

    def vulcano_status_text(self):
        text = STATUS_TEXT[self.vulcano_status]
        if self.sites:
            text += f" · {len(self.sites)} obra(s) en cola"
        return text

    def hover_card(self, mouse):
        if getattr(self, "menu", None) is None:
            site = self.site_under(self.camera.to_world(mouse))
            if site is not None:
                return ("site", id(site)), site_card(site, self.res)
        return super().hover_card(mouse)
