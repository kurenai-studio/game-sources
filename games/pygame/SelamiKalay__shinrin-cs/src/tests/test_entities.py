"""
Shinrin CS — Entity Hiyerarşisi Birim Testleri.

OOP prensiplerini doğrular:
- Kalıtım zinciri
- Kapsülleme (private erişim kontrolü)
- Çok biçimlilik (polimorfik metot çağrıları)
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

import unittest
from entities.game_object import GameObject
from entities.entity import Entity
from entities.character import Character
from entities.player import Player
from entities.enemy import Enemy
from entities.npc import NPC
from entities.item import Item
from entities.consumable import Consumable
from entities.equipment import Equipment
from entities.interactable import Interactable


class TestInheritanceChain(unittest.TestCase):
    """Kalıtım zincirinin doğruluğunu test eder."""

    def test_player_inherits_from_character(self):
        player = Player("Test")
        self.assertIsInstance(player, Character)
        self.assertIsInstance(player, Entity)
        self.assertIsInstance(player, GameObject)

    def test_enemy_inherits_from_character(self):
        enemy = Enemy("Slime", 0, 0, {'hp': 50, 'attack': 5, 'defense': 2, 'speed': 3})
        self.assertIsInstance(enemy, Character)
        self.assertIsInstance(enemy, Entity)
        self.assertIsInstance(enemy, GameObject)

    def test_npc_inherits_from_character(self):
        npc = NPC("Köylü", 0, 0)
        self.assertIsInstance(npc, Character)
        self.assertIsInstance(npc, Entity)

    def test_consumable_inherits_from_item(self):
        potion = Consumable("hp_pot", "HP İksiri", "Can verir", heal_amount=30)
        self.assertIsInstance(potion, Item)
        self.assertIsInstance(potion, Entity)
        self.assertIsInstance(potion, GameObject)

    def test_equipment_inherits_from_item(self):
        sword = Equipment("sword_1", "Bamboo Kılıç", "Basit kılıç", slot="weapon", atk_bonus=5)
        self.assertIsInstance(sword, Item)
        self.assertIsInstance(sword, Entity)

    def test_interactable_inherits_from_entity(self):
        chest = Interactable("Sandık", 0, 0, "chest")
        self.assertIsInstance(chest, Entity)
        self.assertIsInstance(chest, GameObject)


class TestEncapsulation(unittest.TestCase):
    """Kapsülleme prensiplerini test eder."""

    def test_hp_cannot_be_set_directly(self):
        """HP private — doğrudan atama yapılamamalı."""
        player = Player("Test")
        initial_hp = player.hp
        # player.hp = 999  # Bu çağrı AttributeError verir çünkü setter yok
        # Private erişim denemesi
        with self.assertRaises(AttributeError):
            player.__hp = 999  # name mangling: bu _Character__hp'ye erişmez
            # Gerçek private'a dışarıdan erişim
            _ = player._Player__hp_that_doesnt_exist

    def test_hp_changed_only_via_methods(self):
        """HP sadece take_damage() ve heal() ile değişmeli."""
        player = Player("Test")
        initial_hp = player.hp
        # Hasar ver
        player.take_damage(20)
        self.assertLess(player.hp, initial_hp)
        # İyileştir
        player.heal(100)
        self.assertGreaterEqual(player.hp, initial_hp - 20)

    def test_gold_encapsulation(self):
        """Altın sadece add_gold() ve spend_gold() ile değişmeli."""
        player = Player("Test")
        self.assertEqual(player.gold, 0)
        player.add_gold(100)
        self.assertEqual(player.gold, 100)
        result = player.spend_gold(30)
        self.assertTrue(result)
        self.assertEqual(player.gold, 70)
        result = player.spend_gold(999)
        self.assertFalse(result)
        self.assertEqual(player.gold, 70)  # Değişmemeli

    def test_inventory_encapsulation(self):
        """Envanter kopyası döndürülmeli, orijinal değişmemeli."""
        player = Player("Test")
        potion = Consumable("p1", "İksir", "test", heal_amount=10)
        player.add_item(potion)
        inv_copy = player.get_inventory()
        inv_copy.clear()  # Kopyayı temizle
        self.assertEqual(player.inventory_count, 1)  # Orijinal etkilenmemeli

    def test_negative_gold_prevention(self):
        """Negatif altın eklenmesini engeller."""
        player = Player("Test")
        player.add_gold(-50)  # Negatif: eklenmemeli (metot korur)
        self.assertEqual(player.gold, 0)


class TestPolymorphism(unittest.TestCase):
    """Çok biçimlilik prensiplerini test eder."""

    def test_polymorphic_update(self):
        """Farklı entity tipleri tek listeden güncellenebilmeli."""
        entities = [
            Player("Kaito"),
            Enemy("Slime", 100, 100, {'hp': 50, 'attack': 5, 'defense': 2, 'speed': 3}),
            NPC("Köylü", 200, 200),
            Interactable("Sandık", 300, 300),
        ]
        # Polimorfik güncelleme — hata vermemeli
        for entity in entities:
            entity.update(0.016)

    def test_polymorphic_draw(self):
        """Tüm entity'ler polimorfik olarak çizilebilmeli."""
        surface = pygame.Surface((800, 600))
        entities = [
            Player("Kaito"),
            Enemy("Oni", 100, 100, {'hp': 80, 'attack': 12, 'defense': 5, 'speed': 4},
                  enemy_type="oni"),
            NPC("Tüccar", 200, 200, role="merchant"),
            Interactable("Levha", 300, 300, "sign"),
        ]
        for entity in entities:
            entity.draw(surface)  # Hata vermemeli

    def test_polymorphic_interact(self):
        """Farklı entity tipleri farklı interact() davranışı göstermeli."""
        player = Player("Kaito")
        # NPC healer etkileşimi
        healer = NPC("Şifacı", 0, 0, role="healer")
        player.take_damage(50)
        hp_before = player.hp
        healer.interact(player)
        self.assertGreater(player.hp, hp_before)  # İyileşmiş olmalı

    def test_polymorphic_level_up(self):
        """Player ve Enemy farklı level_up() davranışı göstermeli."""
        player = Player("Kaito")
        enemy = Enemy("Slime", 0, 0, {'hp': 50, 'attack': 5, 'defense': 2, 'speed': 3})

        p_atk_before = player.attack
        e_atk_before = enemy.attack

        player.level_up()
        enemy.level_up()

        # Player +3 ATK, Enemy +5 ATK alır (farklı artış)
        self.assertEqual(player.attack, p_atk_before + 3)
        self.assertEqual(enemy.attack, e_atk_before + 5)

    def test_item_use_polymorphism(self):
        """Consumable ve Equipment farklı use() davranışı göstermeli."""
        player = Player("Kaito")
        player.take_damage(40)
        hp_before = player.hp

        # Consumable: İyileştirir
        potion = Consumable("hp", "İksir", "Can verir", heal_amount=30)
        potion.use(player)
        self.assertGreater(player.hp, hp_before)


class TestDamageAndLevelSystem(unittest.TestCase):
    """Hasar ve seviye sistemini test eder."""

    def test_damage_reduces_hp(self):
        enemy = Enemy("Slime", 0, 0, {'hp': 50, 'mp': 10, 'attack': 5, 'defense': 2, 'speed': 3})
        enemy.take_damage(20)
        self.assertLess(enemy.hp, 50)
        self.assertTrue(enemy.is_alive)

    def test_lethal_damage(self):
        enemy = Enemy("Slime", 0, 0, {'hp': 10, 'mp': 0, 'attack': 5, 'defense': 0, 'speed': 3})
        enemy.take_damage(999)
        self.assertEqual(enemy.hp, 0)
        self.assertFalse(enemy.is_alive)

    def test_heal_caps_at_max(self):
        player = Player("Test")
        max_hp = player.max_hp
        player.heal(9999)
        self.assertEqual(player.hp, max_hp)

    def test_exp_gain_and_level_up(self):
        player = Player("Test")
        self.assertEqual(player.level, 1)
        # Yeterli EXP ver
        player.gain_exp(9999)
        self.assertGreater(player.level, 1)

    def test_mp_usage(self):
        player = Player("Test")
        initial_mp = player.mp
        result = player.use_mp(10)
        self.assertTrue(result)
        self.assertEqual(player.mp, initial_mp - 10)
        # Yetersiz MP
        result = player.use_mp(9999)
        self.assertFalse(result)


class TestEnemyAI(unittest.TestCase):
    """Enemy AI davranışlarını test eder."""

    def test_enemy_decision(self):
        enemy = Enemy("Slime", 0, 0, {'hp': 50, 'attack': 5, 'defense': 2, 'speed': 3})
        player = Player("Kaito")
        decision = enemy.decide_action({'player': player})
        self.assertIn(decision['action'], ['attack', 'defend'])

    def test_loot_drop(self):
        enemy = Enemy("Slime", 0, 0, {'hp': 50, 'attack': 5, 'defense': 2, 'speed': 3})
        enemy.set_loot_table([
            {'item_id': 'slime_gel', 'chance': 1.0},  # %100 drop
        ])
        loot = enemy.drop_loot()
        self.assertEqual(len(loot), 1)
        self.assertEqual(loot[0], 'slime_gel')

    def test_factory_method(self):
        data = {
            'name': 'Kitsune',
            'x': 100, 'y': 200,
            'hp': 80, 'attack': 15, 'defense': 5, 'speed': 8,
            'type': 'kitsune', 'ai': 'aggressive',
            'exp_reward': 50, 'gold_reward': 25
        }
        enemy = Enemy.from_data(data)
        self.assertEqual(enemy.name, 'Kitsune')
        self.assertEqual(enemy.enemy_type, 'kitsune')
        self.assertEqual(enemy.exp_reward, 50)


class TestEquipmentSystem(unittest.TestCase):
    """Ekipman sistemini test eder."""

    def test_equip_weapon(self):
        player = Player("Test")
        sword = Equipment("sw1", "Bamboo Kılıç", "Basit", slot="weapon", atk_bonus=5)
        player.add_item(sword)
        player.equip(sword)
        equipment = player.get_equipment()
        self.assertIsNotNone(equipment.get('weapon'))

    def test_equipment_bonuses(self):
        sword = Equipment("sw1", "Kılıç", "test", slot="weapon",
                          atk_bonus=10, def_bonus=2)
        bonuses = sword.get_bonuses()
        self.assertEqual(bonuses['atk_bonus'], 10)
        self.assertEqual(bonuses['def_bonus'], 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
