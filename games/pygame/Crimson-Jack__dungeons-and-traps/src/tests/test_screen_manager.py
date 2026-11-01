from unittest.mock import Mock, call

import pytest

from src.enums.game_status import GameStatus
from src.screen_manager import ScreenManager


SCREEN_COMPONENT_NAMES = ('level', 'studio_page', 'loading_page', 'first_page','menu_dialog', 'message_dialog', 'summary_panel')


RUN_CURRENT_SCREEN_CASES = [
    (GameStatus.UNKNOWN, {}),
    (GameStatus.GAME_IS_RUNNING, {'level': [call.run()]}),
    (GameStatus.STUDIO_PAGE, {'studio_page': [call.draw()]}),
    (GameStatus.LOADING_PAGE, {'loading_page': [call.draw()]}),
    (GameStatus.FIRST_PAGE, {'first_page': [call.draw()], 'menu_dialog': [call.draw()]}),
    (GameStatus.GAME_IS_PAUSED, {'menu_dialog': [call.draw()]}),
    (GameStatus.SUMMARY, {'summary_panel': [call.draw()]}),
    (GameStatus.CREDITS, {'message_dialog': [call.draw()]}),
    (GameStatus.SECRET_CODE, {'message_dialog': [call.draw()]}),
    (GameStatus.SECRET_CODE_IS_VALID, {'message_dialog': [call.draw()]}),
    (GameStatus.NEXT_LEVEL, {'message_dialog': [call.draw()]}),
    (GameStatus.LEVEL_COMPLETED, {'message_dialog': [call.draw()]}),
    (GameStatus.GAME_OVER, {'message_dialog': [call.draw()]}),
    (GameStatus.YOU_WIN, {'message_dialog': [call.draw()]}),
]


@pytest.mark.refactoring
class TestRunCurrentScreen:
    @pytest.mark.parametrize('game_status, expected_component_calls', RUN_CURRENT_SCREEN_CASES,
                             ids=[game_status.name for game_status, expected_component_calls in RUN_CURRENT_SCREEN_CASES])
    def test_runs_only_components_of_current_status(self, game, game_status, expected_component_calls):
        for component_name in SCREEN_COMPONENT_NAMES:
            setattr(game.screen_manager.wrapped_screen_manager, f'_{component_name}', Mock())
        game.game_manager._game_status = game_status

        game.screen_manager.run_current_screen()

        for component_name in SCREEN_COMPONENT_NAMES:
            assert getattr(game.screen_manager, component_name).method_calls == \
                expected_component_calls.get(component_name, []), component_name

    def test_message_dialog_statuses(self):
        assert ScreenManager.MESSAGE_DIALOG_STATUSES == {
            GameStatus.CREDITS, GameStatus.SECRET_CODE, GameStatus.SECRET_CODE_IS_VALID,
            GameStatus.NEXT_LEVEL, GameStatus.LEVEL_COMPLETED, GameStatus.GAME_OVER, GameStatus.YOU_WIN,
        }
