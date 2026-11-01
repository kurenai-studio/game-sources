import pygame

from settings import Settings
from src.level_stats import LevelStats
from src.panels.input_message import InputMessage
from src.panels.menu_box import MenuBox
from src.panels.message import Message
from src.panels.message_box import MessageBox


class DialogFactory:
    @staticmethod
    def create_first_page_menu(screen: pygame.Surface) -> MenuBox:
        return MenuBox(screen, 500, 0, 0,
                       Settings.MESSAGE_BACKGROUND_COLOR, Settings.MESSAGE_BORDER_COLOR,
                       Settings.HIGHLIGHTED_TEXT_COLOR,
                       None, [
                           Message('New Game', Settings.TEXT_COLOR, 35),
                           Message('Secret Code', Settings.TEXT_COLOR, 25),
                           Message('Credits', Settings.TEXT_COLOR, 25),
                           Message('Quit', Settings.TEXT_COLOR, 25),
                       ],
                       show_border=False)

    @staticmethod
    def create_game_paused_menu(screen: pygame.Surface) -> MenuBox:
        return MenuBox(screen, 740, 200, 20,
                       Settings.MESSAGE_BACKGROUND_COLOR, Settings.MESSAGE_BORDER_COLOR,
                       Settings.HIGHLIGHTED_TEXT_COLOR,
                       Message('PAUSED', Settings.HIGHLIGHTED_TEXT_COLOR, 40), [
                           Message('Resume', Settings.TEXT_COLOR, 20),
                           Message('Restart level', Settings.TEXT_COLOR, 20),
                           Message('Quit game', Settings.TEXT_COLOR, 20),
                       ])

    @staticmethod
    def create_level_completed_dialog(screen: pygame.Surface, current_stats: LevelStats) -> MessageBox:
        messages = [
            Message('CONGRATULATIONS', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            Message('Level completed', Settings.TEXT_COLOR, 20),
            Message('', Settings.TEXT_COLOR, 15),
        ]

        enemy_groups = (
            ('Spiders', current_stats.get_enemy_spider_total_kills(),
             current_stats.get_enemy_spider_total_count(), current_stats.get_enemy_spider_total_score()),
            ('Goblins', current_stats.get_enemy_monster_total_kills(),
             current_stats.get_enemy_monster_total_count(), current_stats.get_enemy_monster_total_score()),
            ('Bats', current_stats.get_enemy_bat_total_kills(),
             current_stats.get_enemy_bat_total_count(), current_stats.get_enemy_bat_total_score()),
        )

        kill_lines = [Message(f'{label}: {kills} / {count} ({score} pts)', Settings.TEXT_COLOR, 16)
                      for label, kills, count, score in enemy_groups if kills > 0]

        if kill_lines:
            messages.append(Message('Defeated enemies:', Settings.TEXT_COLOR, 16))
            messages.extend(kill_lines)

        # The 'Defeated enemies:' header counts as a line whenever any kill line is shown.
        kill_lines_count = len(kill_lines) + 1 if kill_lines else 0
        dialog_height = 196 + kill_lines_count * 20

        if current_stats.all_enemies_defeated():
            messages.append(Message(f'EXTRA BONUS +{Settings.LEVEL_COMPLETION_BONUS} pts', Settings.HIGHLIGHTED_TEXT_COLOR, 20))
            dialog_height += 20

        messages.append(Message('', Settings.TEXT_COLOR, 15))
        messages.append(Message('Press the SPACE button to go to the next level', Settings.TEXT_COLOR, 20))

        return MessageBox(screen, 740, dialog_height, 20, Settings.MESSAGE_BACKGROUND_COLOR,
                          Settings.MESSAGE_BORDER_COLOR, messages)

    @staticmethod
    def create_next_level_dialog(screen: pygame.Surface, level_number: int, level_name: str | None,
                                 level_description: str | None, secret_code: str | None) -> MessageBox:
        messages = [Message(f'LEVEL {level_number}', Settings.HIGHLIGHTED_TEXT_COLOR, 80)]

        if level_name is not None:
            messages.append(Message('', Settings.TEXT_COLOR, 20))
            messages.append(Message(level_name, Settings.HIGHLIGHTED_TEXT_COLOR, 20))

        if level_description is not None:
            sentences = level_description.split('. ')
            messages.append(Message('', Settings.TEXT_COLOR, 20))
            for sentence in sentences:
                if not sentence.endswith(('.', '!', '?')):
                    sentence += '.'
                messages.append(Message(sentence, Settings.TEXT_COLOR, 16))

        if secret_code is not None and len(secret_code) > 0:
            messages.append(Message('', Settings.TEXT_COLOR, 80))
            messages.append(Message('The secret code for this level is', Settings.TEXT_COLOR, 16))
            messages.append(Message(secret_code, Settings.HIGHLIGHTED_TEXT_COLOR, 20))

        messages.append(Message('', Settings.TEXT_COLOR, 80))
        messages.append(Message('Press the SPACE button to start', Settings.TEXT_COLOR, 20))

        top_margin = 40
        if level_name is None:
            top_margin += 40
        if level_description is None:
            top_margin += 36

        return MessageBox(screen, screen.get_width(), screen.get_height(), top_margin,
                          Settings.MESSAGE_BACKGROUND_COLOR, Settings.MESSAGE_BORDER_COLOR, messages)

    @staticmethod
    def create_game_over_dialog(screen: pygame.Surface) -> MessageBox:
        messages = [
            Message('GAME OVER', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            Message('Press the SPACE button to open summary page', Settings.TEXT_COLOR, 20),
        ]
        return MessageBox(screen, 740, 130, 20, Settings.MESSAGE_BACKGROUND_COLOR,
                          Settings.MESSAGE_BORDER_COLOR, messages)

    @staticmethod
    def create_you_win_dialog(screen: pygame.Surface) -> MessageBox:
        messages = [
            Message('YOU WIN', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            Message('Press the SPACE button to open summary page', Settings.TEXT_COLOR, 20),
        ]
        return MessageBox(screen, 740, 130, 20, Settings.MESSAGE_BACKGROUND_COLOR,
                          Settings.MESSAGE_BORDER_COLOR, messages)

    @staticmethod
    def create_secret_code_dialog(screen: pygame.Surface, secret_code_text: str,
                                  dialog_response_messages: list[Message] | None = None) -> MessageBox:
        messages = [
            Message('SECRET CODE', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            Message('to jump to a specific level', Settings.TEXT_COLOR, 16),
            InputMessage(secret_code_text, Settings.TEXT_COLOR, 40, 610, 50, -5, 10, 20),
        ]
        if dialog_response_messages is not None:
            messages.extend(dialog_response_messages)
        else:
            messages.append(Message('', Settings.TEXT_COLOR, 20))
            messages.append(Message('Press ESC to cancel', Settings.TEXT_COLOR, 20))
        return MessageBox(screen, 740, 270, 20, Settings.MESSAGE_BACKGROUND_COLOR,
                          Settings.MESSAGE_BORDER_COLOR, messages)

    @staticmethod
    def create_secret_code_valid_messages() -> list[Message]:
        return [
            Message('The code is valid!', Settings.HIGHLIGHTED_TEXT_COLOR, 20),
            Message('Press any button to start the game', Settings.TEXT_COLOR, 20),
        ]

    @staticmethod
    def create_secret_code_invalid_messages() -> list[Message]:
        return [
            Message('', Settings.TEXT_COLOR, 20),
            Message('The code is not valid - please try again!', Settings.TEXT_COLOR, 20),
        ]

    @staticmethod
    def create_credits_dialog(screen: pygame.Surface) -> MessageBox:
        messages = [
            Message('CREDITS', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            Message('', Settings.TEXT_COLOR, 15),
            Message('A game by Crimson-Jack', Settings.TEXT_COLOR, 20),
            Message('', Settings.TEXT_COLOR, 15),
            Message('Graphics:', Settings.TEXT_COLOR, 16),
            Message('Original graphics by Crimson-Jack,', Settings.TEXT_COLOR, 12),
            Message('inspired by Tiny Dungeon tileset by Kenney - CC0', Settings.TEXT_COLOR, 12),
            Message('', Settings.TEXT_COLOR, 15),
            Message('Sound:', Settings.TEXT_COLOR, 16),
            Message('Effects by Crimson-Jack,', Settings.TEXT_COLOR, 12),
            Message('created with ChipTone by SFBGames', Settings.TEXT_COLOR, 12),
            Message('', Settings.TEXT_COLOR, 15),
            Message('Fonts:', Settings.TEXT_COLOR, 16),
            Message('Silkscreen font by Jason Kottke', Settings.TEXT_COLOR, 12),
            Message('Trade Winds font by Sideshow (Font Diner, Inc)', Settings.TEXT_COLOR, 12),
            Message('', Settings.TEXT_COLOR, 15),
            Message('Thanks to:', Settings.TEXT_COLOR, 16),
            Message('My wife and kids, who are always so eager', Settings.TEXT_COLOR, 12),
            Message('to help me pursue my indie game-making passion :-)', Settings.TEXT_COLOR, 12),
            Message('My friend MAK and all my mates from CF', Settings.TEXT_COLOR, 12),
            Message('The whole Polish retro YouTube community,', Settings.TEXT_COLOR, 12),
            Message('especially fans of 8-bit computers from the 80s and 90s,', Settings.TEXT_COLOR, 12),
            Message('in particular: ARF, Retrobajtel and more ... ', Settings.TEXT_COLOR, 12),
            Message('', Settings.TEXT_COLOR, 15),
            Message('Press ESC to return', Settings.TEXT_COLOR, 20),
        ]
        return MessageBox(screen, 740, 560, 20, Settings.MESSAGE_BACKGROUND_COLOR,
                          Settings.MESSAGE_BORDER_COLOR, messages)
