"""Permanent upgrades bought with coins, and the run stats they produce.

To balance an upgrade, edit its row in ``UPGRADES``. To add one, add a row
(and an icon in app.render.icons) and read its bonus in ``RunStats.from_levels``.
"""

from dataclasses import dataclass

from app import config


@dataclass(frozen=True)
class Upgrade:
    """One upgrade line. ``step`` is the effect of a single level.

    ``effect`` formats the *total* effect at a level, e.g. "+{:.0%} move speed"
    with 3 levels of 0.05 -> "+15% move speed".
    """

    id: str
    name: str
    icon: str                           # name of a vector icon in app.render.icons
    color_name: str                     # palette field, read at draw time
    summary: str                        # one short sentence for the shop card
    effect: str
    max_level: int
    base_cost: int
    growth: float                       # each level costs ``growth`` times the previous one
    step: float

    def cost(self, level: int) -> int:
        """Price of going from ``level`` to ``level + 1``."""
        return round(self.base_cost * self.growth ** level)


UPGRADES: tuple[Upgrade, ...] = (
    Upgrade("boots", "Swift Boots", "boots", "player", "Move faster.", "+{:.0%} move speed",
            max_level=5, base_cost=15, growth=1.5, step=0.05),
    Upgrade("haste", "Ability Haste", "haste", "accent", "Abilities recharge faster.", "-{:.0%} ability cooldowns",
            max_level=5, base_cost=20, growth=1.5, step=0.06),
    Upgrade("shield", "Thick Bubble", "shield", "shield", "Your Shield lasts longer.", "+{:g} s Shield",
            max_level=4, base_cost=15, growth=1.5, step=0.3),
    Upgrade("wall", "Long Wall", "wall", "wall", "Your Wall is wider.", "+{:g} px Wall length",
            max_level=4, base_cost=15, growth=1.5, step=25),
    Upgrade("sprint", "Long Sprint", "sprint", "sprint", "Sprint lasts longer.", "+{:g} s Sprint",
            max_level=4, base_cost=15, growth=1.5, step=0.5),
    Upgrade("blink", "Far Blink", "blink", "blink", "Blink goes further.", "+{:g} px Blink range",
            max_level=3, base_cost=25, growth=1.6, step=30),      # maxed: 310 px, still short of Warp
    Upgrade("magnet", "Coin Magnet", "magnet", "coin", "Nearby coins fly to you.", "{:g} px pull radius",
            max_level=4, base_cost=10, growth=1.5, step=40),
    Upgrade("second_wind", "Second Wind", "second_wind", "second_wind", "Survive one fatal hit.",
            "", max_level=3, base_cost=120, growth=1.6, step=30),      # effect text: see effect_text()
)
UPGRADE_BY_ID = {u.id: u for u in UPGRADES}


@dataclass(frozen=True)
class RunStats:
    """Every upgrade-dependent number for one run, worked out once when it starts."""

    player_speed: float = config.PLAYER_SPEED
    cooldown_mult: float = 1.0          # applies to abilities only, not utility spells
    shield_duration: float = config.SHIELD_DURATION
    wall_length: float = config.WALL_LENGTH
    sprint_duration: float = config.SPRINT_DURATION
    blink_range: float = config.BLINK_RANGE
    magnet_radius: float = 0.0          # px; 0 = no magnet
    second_wind_cooldown: float | None = None   # s to recharge; None = not owned

    @classmethod
    def from_levels(cls, levels: dict[str, int]) -> "RunStats":
        def bonus(uid: str) -> float:
            return levels.get(uid, 0) * UPGRADE_BY_ID[uid].step

        return cls(player_speed=config.PLAYER_SPEED * (1 + bonus("boots")),
                   cooldown_mult=max(config.MIN_COOLDOWN_MULT, 1 - bonus("haste")),
                   shield_duration=config.SHIELD_DURATION + bonus("shield"),
                   wall_length=config.WALL_LENGTH + bonus("wall"),
                   sprint_duration=config.SPRINT_DURATION + bonus("sprint"),
                   blink_range=config.BLINK_RANGE + bonus("blink"),
                   magnet_radius=bonus("magnet"),
                   second_wind_cooldown=second_wind_cooldown(levels.get("second_wind", 0)))


def second_wind_cooldown(level: int) -> float | None:
    """Level 1 unlocks Second Wind; each further level shortens the recharge. None = not owned."""
    if level <= 0:
        return None
    return max(config.SECOND_WIND_MIN_COOLDOWN,
               config.SECOND_WIND_COOLDOWN - (level - 1) * UPGRADE_BY_ID["second_wind"].step)


def effect_text(upgrade: Upgrade, level: int) -> str:
    """The total effect at ``level`` for the shop, e.g. "+15% move speed"."""
    if level <= 0:
        return "Not owned"
    if upgrade.id == "second_wind":
        return f"Recharges in {second_wind_cooldown(level):g} s"
    return upgrade.effect.format(level * upgrade.step)
