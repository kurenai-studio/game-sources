"""Player settings: key bindings and options, kept in the ``settings`` section of the save file."""

from collections.abc import Callable

from app import config
from app.core.storage import SaveFile
from app.theme.palette import ACCENTS, COLOR_MODES, SWATCHES
from app.util.keys import is_valid_key_name

ACTION_LABELS = {
    "shield": "Shield", "wall": "Wall", "dash": "Dash",
    "sprint": "Sprint", "blink": "Blink",
    "powerup": "Use power-up", "pause": "Pause", "restart": "Play again",
}
MOVE_BUTTONS = {3: "Right click", 1: "Left click"}      # mouse button -> label

ON_OFF = (False, True)
VOLUMES = tuple(range(0, 101, 10))                          # % steps
# Option name -> (default, allowed values). A saved value is used only if it is one of them.
OPTIONS: dict[str, tuple[object, tuple]] = {
    # Gameplay
    "pause_on_focus_loss": (True, ON_OFF),
    "show_fps": (False, ON_OFF),
    "start_danger": (0, (0, 25, 50, 75, 100)),             # % danger a run starts at
    "game_speed": (100, (50, 60, 70, 80, 90, 100)),        # % of normal speed
    "laser_warning": (100, (100, 125, 150, 200)),          # % of the normal laser warning time
    "lasers": (True, ON_OFF),                               # off: bolts only, for practice
    # Audio
    "master_volume": (80, VOLUMES),
    "sfx_volume": (80, VOLUMES),
    "music_volume": (50, VOLUMES),
    "adaptive_music": (True, ON_OFF),                       # music gains layers as danger rises
    "ui_sounds": (True, ON_OFF),                            # hover / click sounds in menus
    "laser_audio_cue": (True, ON_OFF),                      # beeps and a charge-up before lasers fire
    # Display
    "screen_shake": (True, ON_OFF),
    "show_path": (True, ON_OFF),                            # dotted line to where you are walking
    "show_hints": (True, ON_OFF),                           # controls cheat-sheet in the top-left corner
    "accent": ("Cyan", tuple(ACCENTS)),                     # the interface's accent color
    # Accessibility
    "color_mode": ("default", tuple(COLOR_MODES)),
    "color_player": ("Auto", tuple(SWATCHES)),
    "color_bolt": ("Auto", tuple(SWATCHES)),
    "color_laser": ("Auto", tuple(SWATCHES)),
    "threat_outlines": (False, ON_OFF),
    "reduce_flashing": (False, ON_OFF),
    "reduced_motion": (False, ON_OFF),
}


def default_options() -> dict:
    return {name: default for name, (default, _allowed) in OPTIONS.items()}


class Settings:
    """Validated on load, saved after every change.

    ``keybinds`` is one shared dict: the loadout reads keys from it live, so a
    key changed from the pause menu works as soon as you resume. ``on_change``
    (set by the Game) runs after every change, to re-apply colors and flags.
    """

    SECTION = "settings"

    def __init__(self, save_file: SaveFile) -> None:
        self.save_file = save_file
        self.keybinds = dict(config.DEFAULT_KEYBINDS)
        self.move_button = config.DEFAULT_MOVE_BUTTON
        self.options = default_options()
        self.on_change: Callable[[], None] | None = None
        self._load(save_file.section(self.SECTION))

    def _load(self, data: dict) -> None:
        """Take each saved value only if it is valid. Binding through ``bind`` means a
        hand-edited file that uses one key twice still loads with every key unique."""
        binds = data.get("keybinds")
        if isinstance(binds, dict):
            for action in list(self.keybinds):
                if is_valid_key_name(binds.get(action)):
                    self.bind(action, binds[action], save=False)
        if data.get("move_button") in MOVE_BUTTONS:
            self.move_button = data["move_button"]
        options = data.get("options")
        if isinstance(options, dict):
            for name, (default, allowed) in OPTIONS.items():
                value = options.get(name)
                # The type check matters: in Python True == 1, so 1 would pass for an on/off option.
                if type(value) is type(default) and value in allowed:
                    self.options[name] = value

    def to_dict(self) -> dict:
        return {"keybinds": dict(self.keybinds), "move_button": self.move_button, "options": dict(self.options)}

    def save(self) -> bool:
        saved = self.save_file.write(self.SECTION, self.to_dict())
        if self.on_change:
            self.on_change()
        return saved

    # --- Changes -------------------------------------------------------------------------------
    def bind(self, action: str, key_name: str, save: bool = True) -> None:
        """Bind ``key_name`` to ``action``. If another action had that key, the two swap,
        so no key ever does two things and no action is left unbound."""
        for other, name in self.keybinds.items():
            if name == key_name and other != action:
                self.keybinds[other] = self.keybinds[action]
        self.keybinds[action] = key_name
        if save:
            self.save()

    def cycle_move_button(self, step: int = 1) -> None:
        buttons = list(MOVE_BUTTONS)
        self.move_button = buttons[(buttons.index(self.move_button) + step) % len(buttons)]
        self.save()

    def toggle(self, option: str) -> None:
        self.options[option] = not self.options[option]
        self.save()

    def cycle(self, option: str, step: int = 1) -> None:
        """Move a choice option to its next (``step`` = 1) or previous (-1) allowed value."""
        allowed = OPTIONS[option][1]
        index = allowed.index(self.options[option])
        self.options[option] = allowed[(index + step) % len(allowed)]
        self.save()

    def reset(self) -> None:
        """Everything back to the defaults."""
        self.keybinds.clear()
        self.keybinds.update(config.DEFAULT_KEYBINDS)       # same dict object: the loadout keeps it
        self.move_button = config.DEFAULT_MOVE_BUTTON
        self.options = default_options()
        self.save()

    # --- Derived -------------------------------------------------------------------------------
    @property
    def assists_on(self) -> bool:
        """Slower game speed, longer laser warnings or no lasers make runs easier, so they don't count for
        best times."""
        o = self.options
        return o["game_speed"] != 100 or o["laser_warning"] != 100 or not o["lasers"]
