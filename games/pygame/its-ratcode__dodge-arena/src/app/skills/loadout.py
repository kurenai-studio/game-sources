"""The loadout: which skill sits in which slot, and which key casts it."""

import pygame

from app import config
from app.skills.abilities import Dash, Shield, WallSkill
from app.skills.base import Skill
from app.skills.utility import Blink, Sprint
from app.util.keys import key_label

# Slot order = order in the ability bar. Each slot is cast by the key bound to its action.
ABILITIES: tuple[tuple[str, type[Skill]], ...] = (("shield", Shield), ("wall", WallSkill), ("dash", Dash))
UTILITY_SPELLS: tuple[tuple[str, type[Skill]], ...] = (("sprint", Sprint), ("blink", Blink))


class SkillSlot:
    """One box in the ability bar: an action, its skill (None = an empty power-up slot),
    and the key bindings to look its key up in.

    The key is looked up every time, so rebinding takes effect immediately.
    """

    def __init__(self, action: str, skill: Skill | None, keybinds: dict[str, str]) -> None:
        self.action = action
        self.skill = skill
        self.keybinds = keybinds

    @property
    def key_name(self) -> str:
        return self.keybinds[self.action]

    @property
    def key(self) -> int:
        return pygame.key.key_code(self.key_name)      # "q" -> pygame.K_q

    @property
    def key_label(self) -> str:
        return key_label(self.key_name)


def build_loadout(keybinds: dict[str, str] | None = None, cooldown_mult: float = 1.0) -> list[SkillSlot]:
    """Fresh skills (all ready) for a new run: abilities first, then utility spells.

    ``cooldown_mult`` (from Ability Haste) shortens ability cooldowns only;
    utility spells keep theirs.
    """
    keybinds = keybinds if keybinds is not None else dict(config.DEFAULT_KEYBINDS)
    slots = []
    for action, cls in ABILITIES:
        skill = cls()
        skill.cooldown *= cooldown_mult                # an instance value, shadowing the class default
        slots.append(SkillSlot(action, skill, keybinds))
    for action, cls in UTILITY_SPELLS:
        slots.append(SkillSlot(action, cls(), keybinds))
    return slots
