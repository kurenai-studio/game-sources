"""Scene stack with simple transitions."""

from __future__ import annotations


class SceneManager:
    def __init__(self):
        self._stack = []

    @property
    def current(self):
        return self._stack[-1] if self._stack else None

    def change(self, scene) -> None:
        """Replace the entire stack with ``scene``."""
        while self._stack:
            self._stack.pop().on_exit()
        self._stack.append(scene)
        scene.on_enter()

    def push(self, scene) -> None:
        """Stack ``scene`` on top of the current one."""
        self._stack.append(scene)
        scene.on_enter()

    def pop(self) -> None:
        """Remove the top scene, returning to the one below."""
        if self._stack:
            self._stack.pop().on_exit()

    def handle_event(self, event) -> None:
        if self.current:
            self.current.handle_event(event)

    def update(self, dt: float) -> None:
        if self.current:
            self.current.update(dt)

    def draw(self, surface) -> None:
        if self.current:
            self.current.draw(surface)
