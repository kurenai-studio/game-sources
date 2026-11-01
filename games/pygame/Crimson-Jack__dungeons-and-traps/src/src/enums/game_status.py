from enum import IntEnum


class GameStatus(IntEnum):
    UNKNOWN = 0
    STUDIO_PAGE = 1
    LOADING_PAGE = 2
    FIRST_PAGE = 3
    SECRET_CODE = 4
    SECRET_CODE_IS_VALID = 5
    CREDITS = 6
    NEXT_LEVEL = 7
    GAME_IS_RUNNING = 8
    GAME_IS_PAUSED = 9
    LEVEL_COMPLETED = 10
    GAME_OVER = 11
    YOU_WIN = 12
    SUMMARY = 13
