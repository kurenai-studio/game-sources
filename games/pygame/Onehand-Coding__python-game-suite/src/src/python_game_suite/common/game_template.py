from abc import ABC, abstractmethod


class Game(ABC):
    """A template for all games in the suite."""

    @staticmethod
    @abstractmethod
    def get_name() -> str:
        """Return the display name of the game."""
        pass

    @abstractmethod
    def run(self):
        """Run the main game loop."""
        pass
