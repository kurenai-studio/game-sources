import pygame
import random
from game_field import GameField
from players import HumanPlayer, MachinePlayer


class GameRound:
    def __init__(self):
        self.display_surf = pygame.display.get_surface()
        self.finished = False
        self.winner_name = None
        self.clicked_tile = None

        # test
        self.game_field = GameField()

        self.players = []
        player1 = HumanPlayer('Player', 1, self.game_field.map)

        # player1 = MachinePlayer('Player', 1, self.game_field.map)
        player2 = MachinePlayer('Enemy', 2, self.game_field.map)
        # player1.assign_opponent(player2)
        # test
        # test
        player2.assign_opponent(player1)
        if random.randint(0, 1):
            self.players.extend([player1, player2])
        else:
            self.players.extend([player2, player1])

        self.turn_count = 1

    def get_tile(self, tile):
        self.clicked_tile = tile

    def turn(self):
        turn_owner = self.players[self.turn_count % 2]
        x = y = None

        # If turn owner is human player, then it should wait for user's correct input
        if type(turn_owner).__name__ == 'HumanPlayer':
            if self.clicked_tile:
                pos = turn_owner.select_move(self.clicked_tile)
                if pos:
                    print('\nTurn', self.turn_count)
                    print(turn_owner.name + "'s move is", turn_owner.last_move)
                    x, y = pos[0], pos[1]
                    self.clicked_tile = None
                    self.turn_count += 1

        # If turn owner is bot, then just let it select a tile
        else:
            print('\nTurn', self.turn_count)
            print(turn_owner.name + "'s move is", turn_owner.last_move)
            x, y = turn_owner.select_move()
            self.turn_count += 1

    def game_over(self):
        if self.turn_count > 5:
            str_rows = []
            last_x_index = len(self.game_field.map[0]) - 1
            last_y_index = len(self.game_field.map) - 1

            # Check if 5 in horizontal
            for row in self.game_field.map:
                str_row = ''.join([str(item) for item in row])
                if '11111' in str_row or '22222' in str_row:
                    return True
                str_rows.append(str_row)

            # Check if 5 in increasing diagonal
            # Move diagonal to the right
            for k in range(len(self.game_field.map[0])):
                s = ''
                for i in range(len(self.game_field.map)):
                    x = i + k
                    y = i
                    if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
                        s += str(self.game_field.map[-y][x])
                if '11111' in s or '22222' in s:
                    return True
            # Move diagonal up
            for k in range(1, len(self.game_field.map)):
                s = ''
                for i in range(len(self.game_field.map)):
                    x = i
                    y = i + k
                    if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
                        s += str(self.game_field.map[-y][x])
                if '11111' in s or '22222' in s:
                    return True

            # Check if 5 in decreasing diagonal
            # Move diagonal to the right
            for k in range(len(self.game_field.map[0])):
                s = ''
                for i in range(len(self.game_field.map)):
                    x = i + k
                    y = i
                    if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
                        s += str(self.game_field.map[y][x])
                if '11111' in s or '22222' in s:
                    return True
            # Move diagonal down
            for k in range(1, len(self.game_field.map)):
                s = ''
                for i in range(len(self.game_field.map)):
                    x = i
                    y = i + k
                    if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
                        s += str(self.game_field.map[y][x])
                if '11111' in s or '22222' in s:
                    return True

            # Check if 5 in vertical
            for i in range(len(str_rows[0])):
                str_col = ''
                for str_row in str_rows:
                    str_col += str_row[i]
                if '11111' in str_col or '22222' in str_col:
                    return True
        return False

    def run(self):
        if not self.game_over():
            old = self.turn_count
            self.turn()
            new = self.turn_count
            if old != new:
                return True, None
            return False, None
        else:
            self.winner_name = self.players[self.turn_count % 2 - 1].name
            self.finished = True
            print('\nGame Over!\n' + self.winner_name, 'is winner')
            return False, self.winner_name
