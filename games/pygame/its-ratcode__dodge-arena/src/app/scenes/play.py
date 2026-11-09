"""The play scene: input for a run in progress, and the feedback (sound, shake, freeze) for what happens."""

import pygame

from app import config
from app.scenes.base import Scene

LASER_CUES = ("laser_warn", "laser_charge")       # sounds that only warn; the "laser cue" option mutes them
# Event -> (screen shake in px, freeze in s). Big moments shake the arena and stop the action
# for a few frames so they land with weight.
IMPACTS = {
    "block": (config.SHAKE_BLOCK, config.HITSTOP_BLOCK),
    "second_wind": (config.SHAKE_SECOND_WIND, config.HITSTOP_SECOND_WIND),
    "nova": (config.SHAKE_NOVA, 0.0),
    "death": (config.SHAKE_DEATH, 0.0),
}


def is_free_escape(event: pygame.event.Event, settings) -> bool:
    """Esc pauses and resumes even when pause is bound to another key, unless Esc was given to an action."""
    return event.key == pygame.K_ESCAPE and "escape" not in settings.keybinds.values()


class PlayScene(Scene):
    """Moves, casts and pauses. The run itself lives in ``game.world``.
    Keys and the move button come from the settings, read on every event."""

    music = "run"

    def __init__(self, game) -> None:
        super().__init__(game)
        self.hitstop = 0.0                  # s of frozen action left

    def handle_event(self, event: pygame.event.Event) -> None:
        world, settings = self.game.world, self.game.settings
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.key.key_code(settings.keybinds["pause"]) or is_free_escape(event, settings):
                self.game.pause()
            elif event.key == world.powerup_slot.key:
                world.use_powerup(pygame.mouse.get_pos())
            else:
                for index, slot in enumerate(world.loadout):
                    if event.key == slot.key:
                        world.cast(index, pygame.mouse.get_pos())
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == settings.move_button:
            world.command_move(event.pos, new_click=True)

    def on_focus_lost(self) -> None:
        if self.game.settings.options["pause_on_focus_loss"]:
            self.game.pause()               # never keep playing in a window you can't see

    def update(self, dt: float) -> None:
        world = self.game.world
        # Holding the move button keeps updating the destination.
        if pygame.mouse.get_pressed()[self.game.settings.move_button - 1]:
            world.command_move(pygame.mouse.get_pos(), new_click=False)
        if self.hitstop > 0:
            self.hitstop -= dt                             # frozen for a moment after a big hit
        else:
            world.update(dt * world.rules.game_speed)      # the Game speed assist slows the whole run
        self.play_feedback()
        if world.over:
            self.game.audio.silence(config.DEATH_SEQUENCE_TIME + 0.5)     # the music cuts out for the death beat
            self.game.end_run()

    def play_feedback(self) -> None:
        """Play everything the World reported this frame (sound, shake, freeze), then forget it."""
        world, audio = self.game.world, self.game.audio
        cues_on = self.game.settings.options["laser_audio_cue"]
        for name in world.events:
            if name.startswith(LASER_CUES) and not cues_on:
                continue                                   # warning beeps and charge-up are optional
            audio.play(name)
            if name in IMPACTS:
                shake, freeze = IMPACTS[name]
                self.game.add_shake(shake)
                self.hitstop = max(self.hitstop, freeze)
        world.events.clear()

    def draw(self, surface: pygame.Surface) -> None:
        self.game.draw_world(surface)
