"""
Shinrin CS — Açık Dünya Sahnesi (WorldScene).

Oyuncunun haritada dolaştığı, NPC ve düşmanlarla etkileşime
girdiği ana sahne. Tile-based hareket, kamera takibi,
çarpışma ve etkileşim mekanikleri burada çalışır.
"""

from __future__ import annotations

import random
import pygame
from scenes.base_scene import BaseScene
from entities.player import Player
from entities.enemy import Enemy
from entities.npc import NPC
from entities.interactable import Interactable
from world.world_map import WorldMap
from world.zone import Zone, Portal
from systems.collision_system import CollisionSystem
from systems.dialogue_system import DialogueSystem
from systems.battle_system import BattleSystem
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE,
    COLOR_UI_BG, COLOR_UI_BORDER, COLOR_UI_TEXT,
    COLOR_GOLD, COLOR_HP_BAR, COLOR_HP_BAR_LOW, COLOR_MP_BAR,
    COLOR_WHITE, FONT_SIZE_SMALL, FONT_SIZE_MEDIUM
)
from utils.logger import get_logger

_logger = get_logger("WorldScene")


class WorldScene(BaseScene):
    """
    Açık dünya dolaşma sahnesi.

    Sorumlu olduğu mekanikler:
    - Oyuncu hareketi + tilemap çarpışması
    - NPC/düşman/etkileşilebilir nesne yönetimi
    - Diyalog sistemi (overlay)
    - Rastgele savaş karşılaşması
    - HUD (can, mana, seviye gösterimi)
    - Kamera takibi
    """

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._player: Player | None = None
        self._world_map: WorldMap | None = None
        self._collision: CollisionSystem = CollisionSystem()
        self._dialogue: DialogueSystem | None = None
        self._battle: BattleSystem | None = None
        self._in_battle: bool = False
        self._hud_font = None
        self._hud_small_font = None
        self._encounter_timer: float = 0.0
        self._encounter_interval: float = 5.0  # Saniyede bir karşılaşma kontrolü
        self._zone_name_display: str = ""
        self._zone_name_timer: float = 0.0
        self._interaction_hint: str = ""
        self._pending_load_data: dict | None = None  # Yüklenecek kayıt verisi

    # ══════════════════════════════════════════
    #  Yaşam Döngüsü
    # ══════════════════════════════════════════

    def enter(self) -> None:
        """Sahneye girildiğinde dünyayı hazırlar."""
        _logger.info("Dünya sahnesine girildi.")

        am = self._game_engine.asset_manager

        # Fontlar
        self._hud_font = am.load_font(None, FONT_SIZE_MEDIUM)
        self._hud_small_font = am.load_font(None, FONT_SIZE_SMALL)

        # Sistemler
        self._dialogue = DialogueSystem(am)
        self._battle = BattleSystem(am)

        # Dünyayı oluştur
        self._world_map = WorldMap()
        self._create_shinrin_village()

        # Kayıtlı veri varsa yükle
        if self._pending_load_data:
            self._player.load_save_data(self._pending_load_data.get('player', {}))
            self._pending_load_data = None
            _logger.info("Kayıtlı oyun verisi yüklendi.")

        # Bölge adını göster
        self._zone_name_display = "Shinrin Köyü"
        self._zone_name_timer = 3.0

    def _create_shinrin_village(self) -> None:
        """Başlangıç köyünü oluşturur."""
        zone = Zone("Shinrin Köyü", 40, 30)
        zone.generate(seed=42)

        # Oyuncuyu oluştur
        spawn_x, spawn_y = zone.get_spawn_point()
        self._player = Player("Kaito", spawn_x, spawn_y)

        # NPC'ler ekle
        npc_data = [
            {"name": "Tanaka", "x": 14, "y": 12, "role": "merchant",
             "dialogue": [
                 {"speaker": "Tanaka", "text": "Hoş geldin yolcu! Dükkanıma göz at."},
                 {"speaker": "Tanaka", "text": "Ormanın derinliklerinde tehlike var, dikkatli ol!"},
             ]},
            {"name": "Yuki", "x": 22, "y": 14, "role": "quest_giver",
             "dialogue": [
                 {"speaker": "Yuki", "text": "Merhaba! Ben Yuki, köyün muhafızıyım."},
                 {"speaker": "Yuki", "text": "Ormanda bir tilki ruhu görüldü. Onu bulabilir misin?",
                  "choices": [
                      {"text": "Kabul ediyorum!", "next": 2},
                      {"text": "Şimdi değil...", "next": 3},
                  ]},
                 {"speaker": "Yuki", "text": "Harika! Dikkatli ol, Kitsune güçlü!"},
                 {"speaker": "Yuki", "text": "Anladım, hazır olduğunda gel."},
             ]},
            {"name": "Sakura", "x": 26, "y": 10, "role": "healer",
             "dialogue": [
                 {"speaker": "Sakura", "text": "Yaralarını saracağım. Biraz dinlen..."},
                 {"speaker": "Sakura", "text": "İyileştin! Kendine iyi bak."},
             ]},
        ]

        for data in npc_data:
            npc = NPC(
                data["name"],
                data["x"] * TILE_SIZE,
                data["y"] * TILE_SIZE,
                role=data["role"]
            )
            npc._dialogue_data = data["dialogue"]
            zone.add_entity(npc)

        # Düşmanlar ekle
        enemy_spawns = [
            {"name": "Slime", "x": 8, "y": 8, "type": "slime",
             "hp": 40, "attack": 8, "defense": 2, "speed": 3,
             "exp_reward": 20, "gold_reward": 8},
            {"name": "Orman Slime", "x": 30, "y": 20, "type": "slime",
             "hp": 55, "attack": 10, "defense": 3, "speed": 4,
             "exp_reward": 30, "gold_reward": 12},
            {"name": "Oni", "x": 35, "y": 8, "type": "oni",
             "hp": 80, "attack": 15, "defense": 6, "speed": 5,
             "exp_reward": 60, "gold_reward": 30},
        ]

        for data in enemy_spawns:
            enemy = Enemy.from_data(data)
            zone.add_entity(enemy)

        # Etkileşilebilir nesneler
        chest = Interactable("Hazine Sandığı", 18 * TILE_SIZE, 11 * TILE_SIZE,
                             "chest")
        sign = Interactable("Köy Tabelası", 12 * TILE_SIZE, 15 * TILE_SIZE,
                            "sign")
        sign.set_message("Shinrin Köyü'ne Hoş Geldiniz!")
        save_point = Interactable("Kayıt Kristali", 20 * TILE_SIZE, 15 * TILE_SIZE,
                                  "save_point", reusable=True)

        zone.add_entity(chest)
        zone.add_entity(sign)
        zone.add_entity(save_point)

        # Bölgeyi ekle
        portal = Portal(
            38 * TILE_SIZE, 15 * TILE_SIZE,
            "bamboo_forest", 3 * TILE_SIZE, 15 * TILE_SIZE
        )
        zone.add_portal(portal)

        self._world_map.add_zone("shinrin_village", zone)
        self._world_map.load_zone("shinrin_village")

        # Kamerayı ayarla
        camera = self._game_engine.camera
        camera.set_target(self._player)
        camera.set_map_bounds(
            zone.tilemap.pixel_width, zone.tilemap.pixel_height
        )

    def exit(self) -> None:
        """Sahneden çıkış."""
        _logger.info("Dünya sahnesinden çıkıldı.")

    def save_game(self, slot: int = 1) -> bool:
        """
        Mevcut oyun durumunu kaydeder.

        Args:
            slot: Kayıt slotu (1-3).

        Returns:
            Başarılı ise True.
        """
        if not self._player:
            return False

        game_data = {
            'player': self._player.to_save_data(),
            'zone': self._world_map.current_zone_name if self._world_map else 'shinrin_village',
        }

        result = self._game_engine.save_manager.save_game(slot, game_data)
        if result:
            _logger.info("Oyun kaydedildi: Slot %d", slot)
        return result

    def load_game(self, slot: int = 1) -> bool:
        """
        Kaydedilmiş oyun verisini yükler.

        Args:
            slot: Yüklenecek slot.

        Returns:
            Başarılı ise True.
        """
        data = self._game_engine.save_manager.load_game(slot)
        if data:
            self._pending_load_data = data
            return True
        return False

    # ══════════════════════════════════════════
    #  Girdi İşleme
    # ══════════════════════════════════════════

    def handle_input(self, input_handler) -> None:
        """Oyuncu girdisini işler."""
        # Savaş modunda
        if self._in_battle and self._battle:
            self._battle.handle_input(input_handler)
            if not self._battle.is_active:
                self._in_battle = False
                # Savaş sonrası game over kontrolü
                if self._player and not self._player.is_alive:
                    self._game_engine.scene_manager.switch_scene("game_over")
                    return
            return

        # Diyalog modunda
        if self._dialogue and self._dialogue.is_active:
            if input_handler.is_confirm():
                self._dialogue.advance()
            if input_handler.is_just_pressed(pygame.K_UP):
                self._dialogue.navigate_choice(-1)
            if input_handler.is_just_pressed(pygame.K_DOWN):
                self._dialogue.navigate_choice(1)
            return

        # Normal hareket
        dx, dy = input_handler.get_movement_vector()
        if dx != 0 or dy != 0:
            self._move_player(dx, dy,
                              self._game_engine._clock.get_time() / 1000.0)
        else:
            self._player._state = "idle"
            self._player._is_moving = False

        # Etkileşim (Z veya Enter)
        if input_handler.is_confirm():
            self._try_interact()

        # Pause (P tuşu)
        if input_handler.is_pause():
            self._game_engine.scene_manager.push_scene("pause")

        # Envanter (I tuşu)
        if input_handler.is_just_pressed(pygame.K_i):
            self._game_engine.scene_manager.push_scene("inventory")

    def _move_player(self, dx: int, dy: int, dt: float) -> None:
        """Oyuncuyu çarpışma kontrolü ile hareket ettirir."""
        zone = self._world_map.current_zone
        if not zone:
            return

        tilemap = zone.tilemap

        # Çarpışma çözümleme
        new_x, new_y = CollisionSystem.resolve_tilemap_collision(
            self._player, tilemap, dx, dy, dt
        )
        self._player.set_position(new_x, new_y)
        self._player.move(dx, dy, 0)  # Yön ve state güncelleme (hareket dt=0 çünkü zaten taşıdık)

    def _try_interact(self) -> None:
        """Oyuncunun önündeki entity ile etkileşir."""
        zone = self._world_map.current_zone
        if not zone:
            return

        target = CollisionSystem.find_interactable_in_front(
            self._player, zone.entities, interact_range=TILE_SIZE * 1.2
        )

        if target is None:
            return

        # NPC: Diyalog başlat
        if isinstance(target, NPC):
            if hasattr(target, '_dialogue_data') and target._dialogue_data:
                self._dialogue.start(target._dialogue_data)
            target.interact(self._player)
            return

        # Düşman: Savaş başlat
        if isinstance(target, Enemy) and target.is_alive:
            self._start_battle_with([target])
            return

        # Etkileşilebilir nesne
        if isinstance(target, Interactable):
            target.interact(self._player)
            if target.message:
                self._dialogue.start([
                    {"speaker": "", "text": target.message}
                ])
            return

    def _start_battle_with(self, enemies: list) -> None:
        """Savaşı başlatır."""
        self._battle.start_battle(self._player, enemies)
        self._in_battle = True
        _logger.info("Savaş başlatıldı!")

    # ══════════════════════════════════════════
    #  Güncelleme
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Dünya sahnesini günceller."""
        # Savaş modu
        if self._in_battle and self._battle:
            self._battle.update(dt)
            return

        # Diyalog
        if self._dialogue:
            self._dialogue.update(dt)

        # Dünyayı güncelle
        if self._world_map:
            self._world_map.update(dt)

        # Oyuncuyu güncelle
        if self._player:
            self._player.update(dt)

        # Kamerayı güncelle
        self._game_engine.camera.update(dt)

        # Bölge adı zamanlayıcı
        if self._zone_name_timer > 0:
            self._zone_name_timer -= dt

        # Etkileşim ipucu güncelle
        self._update_interaction_hint()

        # Düşman karşılaşma kontrolü
        self._check_enemy_encounters(dt)

    def _update_interaction_hint(self) -> None:
        """Yakınlardaki etkileşilebilir nesneyi algılayıp ipucu gösterir."""
        self._interaction_hint = ""
        zone = self._world_map.current_zone if self._world_map else None
        if not zone or not self._player:
            return

        nearby = CollisionSystem.find_nearby_entities(
            self._player, zone.entities, TILE_SIZE * 2
        )

        for entity in nearby:
            if isinstance(entity, NPC):
                self._interaction_hint = f"[Z] {entity.name} ile konuş"
                break
            elif isinstance(entity, Interactable) and not entity.is_interacted:
                self._interaction_hint = f"[Z] {entity.name}"
                break
            elif isinstance(entity, Enemy) and entity.is_alive:
                self._interaction_hint = f"[Z] {entity.name} ile savaş"
                break

    def _check_enemy_encounters(self, dt: float) -> None:
        """Düşman temas kontrolü (otomatik savaş)."""
        zone = self._world_map.current_zone if self._world_map else None
        if not zone or not self._player:
            return

        for entity in zone.entities:
            if isinstance(entity, Enemy) and entity.is_alive:
                if self._player.get_rect().colliderect(entity.get_rect()):
                    self._start_battle_with([entity])
                    break

    # ══════════════════════════════════════════
    #  Çizim
    # ══════════════════════════════════════════

    def draw(self, surface: pygame.Surface) -> None:
        """Dünya sahnesini çizer."""
        # Savaş modunda sadece savaş ekranını çiz
        if self._in_battle and self._battle:
            self._battle.draw(surface)
            return

        camera = self._game_engine.camera

        # Arka plan rengi
        surface.fill((15, 20, 15))

        # Dünya (tilemap + entity'ler)
        if self._world_map:
            self._world_map.draw(surface, camera)

        # Oyuncuyu çiz
        if self._player:
            self._player.draw(surface, camera)

        # HUD
        self._draw_hud(surface)

        # Diyalog overlay
        if self._dialogue and self._dialogue.is_active:
            self._dialogue.draw(surface)

        # Bölge adı gösterimi
        if self._zone_name_timer > 0:
            self._draw_zone_name(surface)

        # Etkileşim ipucu
        if self._interaction_hint and not (
                self._dialogue and self._dialogue.is_active):
            self._draw_interaction_hint(surface)

    def _draw_hud(self, surface: pygame.Surface) -> None:
        """HUD (Heads-Up Display) çizer."""
        if not self._player or not self._hud_font:
            return

        # Sol üst panel
        panel_w = 200
        panel_h = 70
        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 150))
        surface.blit(panel, (10, 10))
        pygame.draw.rect(surface, COLOR_UI_BORDER,
                         (10, 10, panel_w, panel_h), 1)

        # İsim ve seviye
        name = f"{self._player.name} Lv.{self._player.level}"
        name_surf = self._hud_small_font.render(name, True, COLOR_GOLD)
        surface.blit(name_surf, (18, 15))

        # HP bar
        hp_ratio = self._player.hp / self._player.max_hp
        bar_color = COLOR_HP_BAR if hp_ratio > 0.3 else COLOR_HP_BAR_LOW
        pygame.draw.rect(surface, (40, 40, 40), (18, 35, 130, 8))
        pygame.draw.rect(surface, bar_color,
                         (18, 35, int(130 * hp_ratio), 8))
        hp_text = f"HP {self._player.hp}/{self._player.max_hp}"
        hp_surf = self._hud_small_font.render(hp_text, True, COLOR_WHITE)
        surface.blit(hp_surf, (152, 32))

        # MP bar
        mp_ratio = self._player.mp / self._player.max_mp if self._player.max_mp > 0 else 0
        pygame.draw.rect(surface, (40, 40, 40), (18, 50, 130, 8))
        pygame.draw.rect(surface, COLOR_MP_BAR,
                         (18, 50, int(130 * mp_ratio), 8))
        mp_text = f"MP {self._player.mp}/{self._player.max_mp}"
        mp_surf = self._hud_small_font.render(mp_text, True, COLOR_WHITE)
        surface.blit(mp_surf, (152, 47))

        # Altın (sağ üst)
        gold_text = f"Gold: {self._player.gold}"
        gold_surf = self._hud_small_font.render(gold_text, True, COLOR_GOLD)
        surface.blit(gold_surf, (SCREEN_WIDTH - 100, 15))

    def _draw_zone_name(self, surface: pygame.Surface) -> None:
        """Bölge adını fade-out ile gösterir."""
        alpha = min(255, int(self._zone_name_timer * 170))
        if alpha <= 0:
            return

        name_surf = self._hud_font.render(
            self._zone_name_display, True, COLOR_GOLD
        )
        name_surf.set_alpha(alpha)
        rect = name_surf.get_rect(center=(SCREEN_WIDTH // 2, 80))
        surface.blit(name_surf, rect)

    def _draw_interaction_hint(self, surface: pygame.Surface) -> None:
        """Etkileşim ipucunu gösterir."""
        hint_surf = self._hud_small_font.render(
            self._interaction_hint, True, COLOR_UI_TEXT
        )
        rect = hint_surf.get_rect(
            center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 30)
        )

        bg = pygame.Surface((rect.width + 20, rect.height + 10), pygame.SRCALPHA)
        bg.fill((0, 0, 0, 150))
        surface.blit(bg, (rect.x - 10, rect.y - 5))
        surface.blit(hint_surf, rect)
