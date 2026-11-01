"""Base class for all screens (scenes) of the game."""

from __future__ import annotations


class Scene:
    """A single screen. Subclasses override handle_event/update/draw.

    Scenes receive the ``Game`` instance on construction; shared services
    (config, save system, level library, audio) live on ``game``.
    """

    def __init__(self, game):
        self.game = game

    def handle_event(self, event) -> None:
        """Process one pygame event. Mouse positions are already converted
        to the 1280x720 design space."""

    def update(self, dt: float) -> None:
        """Advance the scene by ``dt`` seconds."""

    def draw(self, surface) -> None:
        """Render onto the 1280x720 base surface."""

    def on_enter(self) -> None:
        """Called when this scene becomes the active scene."""

    def on_exit(self) -> None:
        """Called when this scene is replaced or removed."""
