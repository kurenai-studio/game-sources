"""
Shinrin CS — Soyut Karakter Sınıfı.

Entity'den türer. HP, MP, seviye, istatistikler gibi
tüm karakter verilerini kapsüller. Player, Enemy ve NPC
bu sınıftan miras alır.
"""

from __future__ import annotations

from abc import abstractmethod
import pygame
from entities.entity import Entity
from utils.constants import (
    TILE_SIZE, PLAYER_SPEED, DIR_DOWN,
    STATE_IDLE, STATE_WALKING, STATE_ATTACKING,
    STATE_HURT, STATE_DEAD
)
from utils.logger import get_logger

_logger = get_logger("Character")


class Character(Entity):
    """
    Tüm oynanabilir ve oynanamaz karakterlerin soyut sınıfı.

    Kapsülleme Prensibi:
        - HP, MP, seviye, istatistikler __private olarak tanımlanır.
        - Dışarıdan sadece take_damage(), heal(), gain_exp() gibi
          kontrollü metotlar ile değiştirilebilir.
        - Property'ler ile salt-okunur erişim sağlanır.

    Çok Biçimlilik:
        - level_up() her alt sınıfta farklı davranır.
        - update() ve draw() alt sınıflara göre özelleşir.

    Attributes (Private — __):
        __hp, __max_hp: Can puanı.
        __mp, __max_mp: Mana puanı.
        __level: Karakter seviyesi.
        __exp: Mevcut deneyim puanı.
        __attack: Saldırı gücü.
        __defense: Savunma gücü.
        __speed: Hız istatistiği.
        __is_alive: Hayatta mı?

    Attributes (Protected — _):
        _direction: Baktığı yön.
        _state: Mevcut durum (idle, walking, vb.)
        _move_speed: Hareket hızı (piksel/saniye).
    """

    # ── Seviye başına gereken EXP formülü için baz ──
    _BASE_EXP_THRESHOLD = 100

    def __init__(self, name: str, x: float, y: float,
                 stats: dict, width: int = TILE_SIZE,
                 height: int = TILE_SIZE):
        """
        Args:
            name: Karakter adı.
            x, y: Başlangıç pozisyonu.
            stats: İstatistik sözlüğü. Beklenen anahtarlar:
                   'hp', 'mp', 'attack', 'defense', 'speed'.
            width, height: Sprite boyutları.
        """
        super().__init__(name, x, y, width, height)

        # ══════════════════════════════════════
        #  PRIVATE — Sadece getter/setter ile erişim
        # ══════════════════════════════════════
        self.__hp: int = stats.get('hp', 100)
        self.__max_hp: int = stats.get('hp', 100)
        self.__mp: int = stats.get('mp', 50)
        self.__max_mp: int = stats.get('mp', 50)
        self.__level: int = stats.get('level', 1)
        self.__exp: int = 0
        self.__attack: int = stats.get('attack', 10)
        self.__defense: int = stats.get('defense', 5)
        self.__speed: int = stats.get('speed', 5)
        self.__is_alive: bool = True

        # ══════════════════════════════════════
        #  PROTECTED — Alt sınıflar erişebilir
        # ══════════════════════════════════════
        self._direction: str = DIR_DOWN
        self._state: str = STATE_IDLE
        self._move_speed: float = PLAYER_SPEED
        self._invincible: bool = False
        self._invincible_timer: float = 0.0
        self._hurt_timer: float = 0.0

    # ══════════════════════════════════════════
    #  Soyut Metot: Seviye Atlama
    # ══════════════════════════════════════════

    @abstractmethod
    def level_up(self) -> None:
        """
        Seviye atlandığında çağrılır.
        Her alt sınıf kendi stat artışını tanımlar.
        (Polimorfizm)
        """
        pass

    # ══════════════════════════════════════════
    #  Hasar ve İyileşme (Kontrollü Erişim)
    # ══════════════════════════════════════════

    def take_damage(self, amount: int) -> int:
        """
        Karaktere hasar verir. Savunmayı hesaba katar.

        Args:
            amount: Ham hasar miktarı.

        Returns:
            Gerçekte verilen hasar miktarı.
        """
        if not self.__is_alive or self._invincible:
            return 0

        # Savunma azaltması: hasar = max(1, ham_hasar - savunma/2)
        actual_damage = max(1, amount - self.__defense // 2)
        self.__hp = max(0, self.__hp - actual_damage)

        _logger.debug(
            "%s hasar aldı: %d (ham: %d, savunma: %d) → HP: %d/%d",
            self._name, actual_damage, amount, self.__defense,
            self.__hp, self.__max_hp
        )

        if self.__hp == 0:
            self.__is_alive = False
            self._state = STATE_DEAD
            _logger.info("%s yenildi!", self._name)
        else:
            self._state = STATE_HURT
            self._hurt_timer = 0.3
            self._invincible = True
            self._invincible_timer = 0.5

        return actual_damage

    def heal(self, amount: int) -> int:
        """
        Karakterin HP'sini iyileştirir.

        Args:
            amount: İyileşme miktarı.

        Returns:
            Gerçekte iyileşen miktar.
        """
        if not self.__is_alive:
            return 0

        old_hp = self.__hp
        self.__hp = min(self.__max_hp, self.__hp + amount)
        healed = self.__hp - old_hp

        _logger.debug("%s iyileşti: +%d HP → %d/%d",
                      self._name, healed, self.__hp, self.__max_hp)
        return healed

    def restore_mp(self, amount: int) -> int:
        """
        MP'yi yeniler.

        Args:
            amount: Yenilenecek MP miktarı.

        Returns:
            Gerçekte yenilenen miktar.
        """
        old_mp = self.__mp
        self.__mp = min(self.__max_mp, self.__mp + amount)
        return self.__mp - old_mp

    def use_mp(self, amount: int) -> bool:
        """
        MP harcar. Yeterli MP yoksa False döner.

        Args:
            amount: Harcanacak MP miktarı.

        Returns:
            True ise MP harcanabildi.
        """
        if self.__mp >= amount:
            self.__mp -= amount
            return True
        return False

    # ══════════════════════════════════════════
    #  Deneyim ve Seviye Sistemi
    # ══════════════════════════════════════════

    def gain_exp(self, amount: int) -> bool:
        """
        Deneyim puanı ekler. Eşik aşılırsa seviye atlar.

        Args:
            amount: Kazanılan EXP miktarı.

        Returns:
            True ise seviye atlandı.
        """
        if not self.__is_alive:
            return False

        self.__exp += amount
        leveled_up = False

        while self.__exp >= self._exp_threshold():
            self.__exp -= self._exp_threshold()
            self.__level += 1
            self.level_up()  # Polimorfik çağrı
            leveled_up = True
            _logger.info(
                "%s seviye atladı! → Seviye %d",
                self._name, self.__level
            )

        return leveled_up

    def _exp_threshold(self) -> int:
        """
        Mevcut seviye için gereken EXP eşiğini hesaplar.
        Formül: base * seviye^1.5

        Returns:
            Gereken EXP miktarı.
        """
        return int(self._BASE_EXP_THRESHOLD * (self.__level ** 1.5))

    # ══════════════════════════════════════════
    #  Stat Yardımcıları (Alt sınıflar kullanır)
    # ══════════════════════════════════════════

    def _increase_stat(self, stat_name: str, amount: int) -> None:
        """
        Belirtilen stat'ı artırır (seviye atlama sırasında).

        Args:
            stat_name: 'attack', 'defense', 'speed'.
            amount: Artış miktarı.
        """
        if stat_name == 'attack':
            self.__attack += amount
        elif stat_name == 'defense':
            self.__defense += amount
        elif stat_name == 'speed':
            self.__speed += amount

    def _increase_max_hp(self, amount: int) -> None:
        """Max HP'yi artırır ve mevcut HP'yi de aynı kadar artırır."""
        self.__max_hp += amount
        self.__hp += amount

    def _increase_max_mp(self, amount: int) -> None:
        """Max MP'yi artırır ve mevcut MP'yi de aynı kadar artırır."""
        self.__max_mp += amount
        self.__mp += amount

    def full_restore(self) -> None:
        """HP ve MP'yi tamamen yeniler."""
        self.__hp = self.__max_hp
        self.__mp = self.__max_mp
        self.__is_alive = True
        self._state = STATE_IDLE

    # ── Kayıt yükleme için protected setter'lar ──

    def _set_hp(self, value: int) -> None:
        """Kayıt yüklemesi için HP'yi ayarlar."""
        self.__hp = max(0, min(value, self.__max_hp))
        self.__is_alive = self.__hp > 0

    def _set_max_hp(self, value: int) -> None:
        """Kayıt yüklemesi için Max HP'yi ayarlar."""
        self.__max_hp = max(1, value)

    def _set_mp(self, value: int) -> None:
        """Kayıt yüklemesi için MP'yi ayarlar."""
        self.__mp = max(0, min(value, self.__max_mp))

    def _set_max_mp(self, value: int) -> None:
        """Kayıt yüklemesi için Max MP'yi ayarlar."""
        self.__max_mp = max(0, value)

    def _set_stat(self, stat_name: str, value: int) -> None:
        """Kayıt yüklemesi için stat'ı ayarlar."""
        if stat_name == 'attack':
            self.__attack = value
        elif stat_name == 'defense':
            self.__defense = value
        elif stat_name == 'speed':
            self.__speed = value

    # ══════════════════════════════════════════
    #  Properties (Salt Okunur)
    # ══════════════════════════════════════════

    @property
    def hp(self) -> int:
        return self.__hp

    @property
    def max_hp(self) -> int:
        return self.__max_hp

    @property
    def mp(self) -> int:
        return self.__mp

    @property
    def max_mp(self) -> int:
        return self.__max_mp

    @property
    def level(self) -> int:
        return self.__level

    @property
    def exp(self) -> int:
        return self.__exp

    @property
    def exp_to_next(self) -> int:
        """Sonraki seviye için gereken kalan EXP."""
        return self._exp_threshold() - self.__exp

    @property
    def attack(self) -> int:
        return self.__attack

    @property
    def defense(self) -> int:
        return self.__defense

    @property
    def speed(self) -> int:
        return self.__speed

    @property
    def is_alive(self) -> bool:
        return self.__is_alive

    @property
    def direction(self) -> str:
        return self._direction

    @property
    def state(self) -> str:
        return self._state

    def get_stats(self) -> dict:
        """Tüm istatistikleri sözlük olarak döndürür."""
        return {
            'name': self._name,
            'level': self.__level,
            'hp': self.__hp,
            'max_hp': self.__max_hp,
            'mp': self.__mp,
            'max_mp': self.__max_mp,
            'exp': self.__exp,
            'exp_to_next': self.exp_to_next,
            'attack': self.__attack,
            'defense': self.__defense,
            'speed': self.__speed,
            'is_alive': self.__is_alive,
        }

    # ══════════════════════════════════════════
    #  Serileştirme (Kayıt/Yükleme)
    # ══════════════════════════════════════════

    def to_dict(self) -> dict:
        """Karakter verisini serileştirilebilir sözlüğe çevirir."""
        return {
            'name': self._name,
            'x': self._x,
            'y': self._y,
            'stats': self.get_stats(),
            'direction': self._direction,
        }

    def load_from_dict(self, data: dict) -> None:
        """Sözlükten karakter verisini yükler."""
        stats = data.get('stats', {})
        self._x = data.get('x', self._x)
        self._y = data.get('y', self._y)
        self.__hp = stats.get('hp', self.__hp)
        self.__max_hp = stats.get('max_hp', self.__max_hp)
        self.__mp = stats.get('mp', self.__mp)
        self.__max_mp = stats.get('max_mp', self.__max_mp)
        self.__level = stats.get('level', self.__level)
        self.__exp = stats.get('exp', self.__exp)
        self.__attack = stats.get('attack', self.__attack)
        self.__defense = stats.get('defense', self.__defense)
        self.__speed = stats.get('speed', self.__speed)
        self.__is_alive = stats.get('is_alive', self.__is_alive)
        self._direction = data.get('direction', self._direction)

    # ══════════════════════════════════════════
    #  Güncelleme
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Karakter durumunu günceller (zamanlayıcılar + animasyon)."""
        if not self._active:
            return

        # Yenilmezlik zamanlayıcısı
        if self._invincible:
            self._invincible_timer -= dt
            if self._invincible_timer <= 0:
                self._invincible = False

        # Hasar animasyonu zamanlayıcısı
        if self._state == STATE_HURT:
            self._hurt_timer -= dt
            if self._hurt_timer <= 0:
                self._state = STATE_IDLE

        # Animasyonu güncelle
        super().update(dt)

    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """
        Karakteri çizer. Yenilmez iken yanıp söner.
        """
        if not self._visible:
            return

        # Yenilmez iken yanıp sönme efekti
        if self._invincible:
            import time
            if int(time.time() * 10) % 2 == 0:
                return  # Çift saniyelerde görünmez

        super().draw(surface, camera)

    def __repr__(self) -> str:
        return (
            f"<{self.__class__.__name__} '{self._name}' "
            f"Lv.{self.__level} HP:{self.__hp}/{self.__max_hp} "
            f"state={self._state}>"
        )
