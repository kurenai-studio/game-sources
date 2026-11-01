"""
Shinrin CS — Sistem, Dünya ve Motor Birim Testleri.

Kapsam:
- Savaş sistemi (tur sırası, düşman turu, zafer/yenilgi)
- Diyalog sistemi (ilerleme, seçimler, NPC verisinin korunması)
- Çarpışma sistemi ve karo haritası
- Kayıt/yükleme sistemi
- Kamera ve yardımcı fonksiyonlar
"""

import sys
import os

# Proje kökünü path'e ekle
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Pygame'i headless modda başlat
os.environ['SDL_VIDEODRIVER'] = 'dummy'
os.environ['SDL_AUDIODRIVER'] = 'dummy'

import pygame
pygame.init()
pygame.display.set_mode((1, 1))

import json
import shutil
import tempfile
import unittest
from unittest import mock

from engine import save_manager as save_manager_module
from engine.camera import Camera
from engine.save_manager import SaveManager
from entities.enemy import Enemy
from entities.npc import NPC
from entities.player import Player
from systems.battle_system import BattleSystem
from systems.collision_system import CollisionSystem
from systems.dialogue_system import DialogueSystem
from utils.constants import TILE_SIZE, MAX_SAVE_SLOTS, DIR_RIGHT
from utils.helpers import pixel_to_tile, tile_to_pixel, distance, clamp, lerp
from world.tile import Tile
from world.tilemap import TileMap


class FakeAssetManager:
    """Sistemlerin font yüklemesi için asgari asset manager."""

    def load_font(self, name, size):
        return pygame.font.Font(None, size)


def make_enemy(name="Slime", hp=50, attack=5, defense=0, speed=3,
               exp_reward=None, gold_reward=None):
    data = {'name': name, 'x': 0, 'y': 0, 'hp': hp, 'mp': 0,
            'attack': attack, 'defense': defense, 'speed': speed}
    if exp_reward is not None:
        data['exp_reward'] = exp_reward
    if gold_reward is not None:
        data['gold_reward'] = gold_reward
    return Enemy.from_data(data)


# ══════════════════════════════════════════
#  Savaş Sistemi
# ══════════════════════════════════════════

class TestBattleSystem(unittest.TestCase):
    """Sıra tabanlı savaş akışını test eder."""

    def setUp(self):
        self.battle = BattleSystem(FakeAssetManager())
        self.player = Player("Kaito")

    def _finish_intro(self):
        self.battle.update(2.0)
        self.assertEqual(self.battle.state, BattleSystem.STATE_PLAYER_TURN)

    def _player_attacks(self):
        self.battle._action_index = BattleSystem.ACTIONS.index("Saldır")
        self.battle._execute_player_action()

    def test_turn_order_sorted_by_speed(self):
        slow = make_enemy("Yavaş", speed=1)
        fast = make_enemy("Hızlı", speed=99)
        self.battle.start_battle(self.player, [slow, fast])
        order = self.battle._turn_order
        self.assertIs(order[0], fast)
        self.assertIs(order[-1], slow)

    def test_enemy_gets_turn_after_player_action(self):
        # Regresyon: _next_turn ANIMATING'den çağrıldığı için sıra hep
        # oyuncuya dönüyor, düşmanlar hiç saldırmıyordu.
        oni = make_enemy("Oni", hp=9999, attack=30, speed=1)
        self.battle.start_battle(self.player, [oni])
        self._finish_intro()
        hp_before = self.player.hp

        self._player_attacks()
        self.assertEqual(self.battle.state, BattleSystem.STATE_ANIMATING)
        self.battle.update(1.0)  # animasyon biter
        self.assertEqual(self.battle.state, BattleSystem.STATE_ENEMY_TURN)
        self.battle.update(0.0)  # düşman hamlesi
        self.battle.update(1.5)  # animasyon biter
        self.assertEqual(self.battle.state, BattleSystem.STATE_PLAYER_TURN)
        self.assertLess(self.player.hp, hp_before)

    def test_victory_grants_rewards(self):
        weak = make_enemy("Slime", hp=1, exp_reward=30, gold_reward=12)
        self.battle.start_battle(self.player, [weak])
        self._finish_intro()
        gold_before = self.player.gold

        self._player_attacks()
        self.assertFalse(weak.is_alive)
        self.battle.update(1.0)

        self.assertEqual(self.battle.state, BattleSystem.STATE_VICTORY)
        self.assertEqual(self.battle.rewards['exp'], 30)
        self.assertEqual(self.battle.rewards['gold'], 12)
        self.assertEqual(self.player.gold, gold_before + 12)

    def test_defeat_when_player_dies(self):
        oni = make_enemy("Oni", hp=9999, attack=9999, speed=1)
        self.battle.start_battle(self.player, [oni])
        self._finish_intro()

        self._player_attacks()
        self.battle.update(1.0)   # → düşman turu
        self.battle.update(0.0)   # düşman öldürücü vuruş
        self.battle.update(1.5)   # tur sonu kontrolü
        self.assertFalse(self.player.is_alive)
        self.assertEqual(self.battle.state, BattleSystem.STATE_DEFEAT)

    def test_successful_flee_ends_battle(self):
        self.battle.start_battle(self.player, [make_enemy()])
        self._finish_intro()
        self.battle._action_index = BattleSystem.ACTIONS.index("Kaç")
        with mock.patch("systems.battle_system.random.random", return_value=0.0):
            self.battle._execute_player_action()
        self.assertFalse(self.battle.is_active)


# ══════════════════════════════════════════
#  Diyalog Sistemi
# ══════════════════════════════════════════

class TestDialogueSystem(unittest.TestCase):
    """Diyalog akışını ve seçimleri test eder."""

    LINES = [
        {'speaker': 'Yaşlı', 'text': 'Merhaba gezgin.'},
        {'speaker': 'Yaşlı', 'text': 'Orman tehlikeli.'},
    ]

    def setUp(self):
        self.dialogue = DialogueSystem(FakeAssetManager())

    def test_advance_completes_text_then_moves_on(self):
        self.dialogue.start(self.LINES)
        self.assertTrue(self.dialogue.is_active)
        self.assertFalse(self.dialogue.is_complete)

        self.dialogue.advance()  # yazıyı anında tamamla
        self.assertTrue(self.dialogue.is_complete)
        self.assertEqual(self.dialogue._displayed_text, 'Merhaba gezgin.')

        self.dialogue.advance()  # 2. satır
        self.assertEqual(self.dialogue._current_text, 'Orman tehlikeli.')
        self.dialogue.advance()
        self.dialogue.advance()  # son satırdan sonra kapanır
        self.assertFalse(self.dialogue.is_active)

    def test_typewriter_reveals_text_over_time(self):
        self.dialogue.start([{'speaker': 'A', 'text': 'abcd'}])
        self.dialogue.update(0.065)  # ~2 karakter (0.03 sn/karakter)
        self.assertEqual(self.dialogue._displayed_text, 'ab')
        self.dialogue.update(10.0)
        self.assertTrue(self.dialogue.is_complete)

    def test_close_does_not_wipe_callers_lines(self):
        # Regresyon: close() saklanan listeyi temizliyordu; NPC'nin kendi
        # diyalog listesi boşalıyor ve NPC ikinci kez konuşmuyordu.
        npc_lines = list(self.LINES)
        self.dialogue.start(npc_lines)
        self.dialogue.close()
        self.assertEqual(npc_lines, self.LINES)

        self.dialogue.start(npc_lines)
        self.assertTrue(self.dialogue.is_active)

    def test_choice_navigation_wraps_and_branches(self):
        lines = [
            {'speaker': 'A', 'text': 'Seç',
             'choices': [{'text': 'Evet', 'next': 2}, {'text': 'Hayır', 'next': 1}]},
            {'speaker': 'A', 'text': 'Hayır dedin'},
            {'speaker': 'A', 'text': 'Evet dedin'},
        ]
        self.dialogue.start(lines)
        self.dialogue.navigate_choice(-1)  # 0 → 1 (sarmal)
        self.assertEqual(self.dialogue._choice_index, 1)
        self.dialogue.navigate_choice(1)   # 1 → 0
        self.assertEqual(self.dialogue._choice_index, 0)

        self.dialogue.advance()  # metni tamamla
        self.dialogue.advance()  # "Evet" seçildi → satır 2
        self.assertEqual(self.dialogue._current_text, 'Evet dedin')

    def test_empty_dialogue_is_ignored(self):
        self.dialogue.start([])
        self.assertFalse(self.dialogue.is_active)


# ══════════════════════════════════════════
#  Karo Haritası ve Çarpışma
# ══════════════════════════════════════════

W, G = Tile.WATER, Tile.GRASS


class TestTileMap(unittest.TestCase):
    """TileMap geçilebilirlik ve harita üretimini test eder."""

    def setUp(self):
        self.tilemap = TileMap(0, 0)
        self.tilemap.load_from_data([
            [W, W, W, W],
            [W, G, G, W],
            [W, G, G, W],
            [W, W, W, W],
        ])

    def test_load_from_data_sets_size(self):
        self.assertEqual((self.tilemap.width, self.tilemap.height), (4, 4))
        self.assertEqual(self.tilemap.pixel_width, 4 * TILE_SIZE)

    def test_walkability(self):
        self.assertTrue(self.tilemap.is_walkable(TILE_SIZE * 1.5, TILE_SIZE * 1.5))
        self.assertFalse(self.tilemap.is_walkable(1, 1))             # su
        self.assertFalse(self.tilemap.is_walkable(-5, 10))           # harita dışı
        self.assertFalse(self.tilemap.is_walkable(TILE_SIZE * 10, 0))

    def test_rect_walkable_checks_all_corners(self):
        inside = pygame.Rect(TILE_SIZE, TILE_SIZE, TILE_SIZE * 2, TILE_SIZE * 2)
        self.assertTrue(self.tilemap.is_rect_walkable(inside))
        overlapping_water = inside.move(TILE_SIZE // 2, 0)
        self.assertFalse(self.tilemap.is_rect_walkable(overlapping_water))

    def test_get_tile_at_bounds(self):
        self.assertEqual(self.tilemap.get_tile_at(1, 1).tile_id, G)
        self.assertIsNone(self.tilemap.get_tile_at(4, 0))
        self.assertIsNone(self.tilemap.get_tile_at(-1, 0))

    def test_spawn_point_is_first_walkable_tile_center(self):
        half = TILE_SIZE // 2
        self.assertEqual(self.tilemap.get_spawn_point(),
                         (TILE_SIZE + half, TILE_SIZE + half))

    def test_generated_village_is_deterministic_and_bordered(self):
        a, b = TileMap(20, 15), TileMap(20, 15)
        a.generate_village_map(seed=7)
        b.generate_village_map(seed=7)
        ids = lambda m: [[m.get_tile_at(x, y).tile_id for x in range(m.width)]
                         for y in range(m.height)]
        self.assertEqual(ids(a), ids(b))
        for x in range(a.width):
            self.assertEqual(a.get_tile_at(x, 0).tile_id, W)
            self.assertEqual(a.get_tile_at(x, a.height - 1).tile_id, W)
        for y in range(a.height):
            self.assertEqual(a.get_tile_at(0, y).tile_id, W)
            self.assertEqual(a.get_tile_at(a.width - 1, y).tile_id, W)


class TestCollisionSystem(unittest.TestCase):
    """Çarpışma algılama ve çözümlemeyi test eder."""

    def test_entity_collision(self):
        a = make_enemy("A"); a.set_position(0, 0)
        b = make_enemy("B"); b.set_position(10, 10)
        c = make_enemy("C"); c.set_position(500, 500)
        self.assertTrue(CollisionSystem.check_entity_collision(a, b))
        self.assertFalse(CollisionSystem.check_entity_collision(a, c))

    def test_find_nearby_excludes_self_and_far(self):
        center = make_enemy("Merkez"); center.set_position(0, 0)
        near = make_enemy("Yakın"); near.set_position(30, 40)    # mesafe 50
        far = make_enemy("Uzak"); far.set_position(300, 0)
        result = CollisionSystem.find_nearby_entities(
            center, [center, near, far], radius=50)
        self.assertEqual(result, [near])

    def test_tilemap_blocks_movement_into_water(self):
        tilemap = TileMap(0, 0)
        tilemap.load_from_data([[W] * 6] + [[W, G, G, G, G, W]] * 4 + [[W] * 6])
        player = Player("Kaito", TILE_SIZE * 1, TILE_SIZE * 2)

        # Sola (suya) doğru büyük adım engellenir
        new_x, _ = CollisionSystem.resolve_tilemap_collision(
            player, tilemap, -1, 0, dt=1.0)
        self.assertEqual(new_x, TILE_SIZE * 1)

        # Sağa (çimene) doğru küçük adım serbest
        new_x, _ = CollisionSystem.resolve_tilemap_collision(
            player, tilemap, 1, 0, dt=0.05)
        self.assertGreater(new_x, TILE_SIZE * 1)

    def test_find_interactable_in_front(self):
        player = Player("Kaito", 100, 100)
        player._direction = DIR_RIGHT
        npc_front = NPC("Köylü", 140, 100)
        npc_behind = NPC("Arkada", 60, 100)
        found = CollisionSystem.find_interactable_in_front(
            player, [player, npc_behind, npc_front])
        self.assertIs(found, npc_front)


# ══════════════════════════════════════════
#  Kayıt Sistemi
# ══════════════════════════════════════════

class TestSaveManager(unittest.TestCase):
    """Kayıt/yükleme sistemini geçici dizinde test eder."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        patcher = mock.patch.object(save_manager_module, "SAVE_DIR", self.tmpdir)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.addCleanup(shutil.rmtree, self.tmpdir, ignore_errors=True)
        self.manager = SaveManager()

    def test_save_and_load_roundtrip(self):
        data = {'player': {'name': 'Kaito', 'level': 3}, 'zone': 'köy'}
        self.assertTrue(self.manager.save_game(1, data))
        self.assertEqual(self.manager.load_game(1), data)
        meta = self.manager.get_save_info(1)
        self.assertEqual(meta['slot'], 1)
        self.assertIn('timestamp', meta)

    def test_invalid_slot_rejected(self):
        self.assertFalse(self.manager.save_game(0, {}))
        self.assertFalse(self.manager.save_game(MAX_SAVE_SLOTS + 1, {}))

    def test_missing_and_corrupt_saves_return_none(self):
        self.assertIsNone(self.manager.load_game(2))
        with open(os.path.join(self.tmpdir, "save_2.json"), "w", encoding="utf-8") as f:
            f.write("{bozuk json")
        self.assertIsNone(self.manager.load_game(2))
        self.assertIsNone(self.manager.get_save_info(2))

    def test_delete_and_list(self):
        self.manager.save_game(3, {'x': 1})
        saves = self.manager.get_all_saves()
        self.assertEqual(len(saves), MAX_SAVE_SLOTS)
        self.assertIsNone(saves[0])
        self.assertIsNotNone(saves[2])
        self.assertTrue(self.manager.delete_save(3))
        self.assertFalse(self.manager.delete_save(3))
        self.assertIsNone(self.manager.load_game(3))

    def test_unicode_is_preserved_on_disk(self):
        self.manager.save_game(1, {'isim': 'Şinrin-yoku'})
        with open(os.path.join(self.tmpdir, "save_1.json"), encoding="utf-8") as f:
            self.assertIn('Şinrin-yoku', f.read())
        with open(os.path.join(self.tmpdir, "save_1.json"), encoding="utf-8") as f:
            self.assertEqual(json.load(f)['game']['isim'], 'Şinrin-yoku')


# ══════════════════════════════════════════
#  Kamera ve Yardımcılar
# ══════════════════════════════════════════

class TestCamera(unittest.TestCase):
    """Kamera dönüşümleri ve sınır kontrolünü test eder."""

    def test_apply_and_visible_area(self):
        cam = Camera(320, 240)
        cam._x, cam._y = 100, 50
        self.assertEqual(cam.apply(150, 80), (50, 30))
        self.assertEqual(cam.apply_rect(pygame.Rect(100, 50, 10, 10)),
                         pygame.Rect(0, 0, 10, 10))
        self.assertEqual(cam.get_visible_area(), pygame.Rect(100, 50, 320, 240))

    def test_follow_is_clamped_to_map_bounds(self):
        cam = Camera(320, 240)
        cam.smoothing = 0.0  # anlık takip
        cam.set_map_bounds(1000, 800)
        target = Player("Kaito", 990, 790)  # sağ alt köşe
        cam.set_target(target)
        cam.update(1 / 60)
        self.assertEqual((cam.x, cam.y), (1000 - 320, 800 - 240))

        target.set_position(5, 5)            # sol üst köşe
        cam.update(1 / 60)
        self.assertEqual((cam.x, cam.y), (0, 0))


class TestHelpers(unittest.TestCase):
    """Yardımcı matematik fonksiyonlarını test eder."""

    def test_tile_pixel_conversion(self):
        self.assertEqual(pixel_to_tile(TILE_SIZE * 3 + 5, TILE_SIZE * 2), (3, 2))
        self.assertEqual(tile_to_pixel(3, 2), (TILE_SIZE * 3, TILE_SIZE * 2))
        self.assertEqual(pixel_to_tile(*tile_to_pixel(7, 9)), (7, 9))

    def test_distance(self):
        self.assertEqual(distance(0, 0, 3, 4), 5.0)

    def test_clamp_and_lerp(self):
        self.assertEqual(clamp(15, 0, 10), 10)
        self.assertEqual(clamp(-1, 0, 10), 0)
        self.assertEqual(lerp(0, 10, 0.25), 2.5)
        self.assertEqual(lerp(0, 10, 2.0), 10)   # t sınırlandırılır
        self.assertEqual(lerp(0, 10, -1.0), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
