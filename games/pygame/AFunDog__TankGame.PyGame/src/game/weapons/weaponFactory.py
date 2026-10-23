from enum import Enum
from game.gameObject import GameObject
from game.weapons.weapon import Weapon


class WEAPON_TYPE(Enum):
    COMMON_WEAPON = 0
    GHOST_WEAPON = 1
    MISSILE_WEAPON = 2
    EXPLOSIVEBOMB_WEAPON = 3


class WeaponFactory:

    def __init__(self):
        raise NotImplementedError("WeaponFactory类不允许初始化")

    @staticmethod
    def createWeapon(owner: GameObject, weaponType: WEAPON_TYPE) -> Weapon:
        from game.weapons.commonWeapon import CommonWeapon
        from game.weapons.ghostWeapon import GhostWeapon
        from game.weapons.remoteControlMissileWeapon import RemoteControlMissileWeapon
        from game.weapons.explosiveBombWeapon import ExplosiveBombWeapon

        weaponList: list[type[Weapon]] = [CommonWeapon, GhostWeapon, RemoteControlMissileWeapon,ExplosiveBombWeapon]
        return weaponList[weaponType.value](owner)

    @staticmethod
    def getWeaponType(weapon: Weapon) -> WEAPON_TYPE:
        from game.weapons.commonWeapon import CommonWeapon
        from game.weapons.ghostWeapon import GhostWeapon
        from game.weapons.remoteControlMissileWeapon import RemoteControlMissileWeapon
        from game.weapons.explosiveBombWeapon import ExplosiveBombWeapon

        weaponList: list[type[Weapon]] = [CommonWeapon, GhostWeapon, RemoteControlMissileWeapon,ExplosiveBombWeapon]
        return WEAPON_TYPE(weaponList.index(type(weapon)))