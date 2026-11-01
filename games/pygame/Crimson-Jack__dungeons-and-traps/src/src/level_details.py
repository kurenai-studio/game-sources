class LevelDetails:
    """Fixed description of one level: map file, secret code, name, description and flags."""

    def __init__(self, source_file: str, secret_code: str | None = None, name: str | None = None,
                 description: str | None = None, exit_point_enabled: bool = True,
                 is_final_level: bool = False) -> None:
        """
        Store the details of one level.

        :param source_file: name of the TMX map file in data/tmx/
        :param secret_code: code that starts the game from this level, or None
        :param name: name shown in the level intro dialog, or None
        :param description: description shown in the level intro dialog, or None
        :param exit_point_enabled: True when collecting all diamonds opens the exit point,
                                   False when it removes the obstacles and creates the boss
        :param is_final_level: True for the last level of the campaign
        """
        self._source_file = source_file
        self._secret_code = secret_code
        self._name = name
        self._description = description
        self._exit_point_enabled = exit_point_enabled
        self._is_final_level = is_final_level

    @property
    def source_file(self) -> str:
        """Name of the TMX map file in data/tmx/."""
        return self._source_file

    @property
    def secret_code(self) -> str | None:
        """Code that starts the game from this level, or None."""
        return self._secret_code

    @property
    def name(self) -> str | None:
        """Name shown in the level intro dialog, or None."""
        return self._name

    @property
    def description(self) -> str | None:
        """Description shown in the level intro dialog, or None."""
        return self._description

    @property
    def exit_point_enabled(self) -> bool:
        """
        True when collecting all diamonds opens the exit point;
        False when it removes the obstacles and creates the boss.
        """
        return self._exit_point_enabled

    @property
    def is_final_level(self) -> bool:
        """True for the last level of the campaign."""
        return self._is_final_level
