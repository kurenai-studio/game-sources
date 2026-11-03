import itertools
import random
from tile import DotColor


def create_combination_priority_dict():
    # Get all possible combinations
    all_combinations = list(itertools.product('0ope', repeat=5))
    comb_list = []

    # Make strings from tuples and append them to new list
    for comb in all_combinations:
        comb_list.append(''.join(comb))

    comb_list = list(filter(lambda c: c[0] not in ('0', 'e') and
                                      not c.count('0') == 0 and
                                      not (c.count('e') == 4 and c[1:] == 'eeee') and
                                      not (c.count('e') == 3 and c[2:] == 'eee') and
                                      not (c.count('e') == 2 and c[3:] == 'ee') and
                                      not (c.count('e') == 1 and c[4] == 'e'),
                            comb_list))

    comb_priority_dict = {}
    for i in range(10):
        comb_priority_dict[str(i)] = []

    unused_comb = []
    for c in comb_list:
        if c.count('p') == 4 and c.count('0') == 1:
            comb_priority_dict['0'].append(c)
        elif c.count('o') == 4 and c.count('0') == 1:
            comb_priority_dict['1'].append(c)
        elif c.count('p') == 3 and c.count('0') == 2:
            comb_priority_dict['2'].append(c)
        elif c.count('o') == 3 and c.count('0') == 2:
            comb_priority_dict['4'].append(c)
        elif c.count('p') == 2:
            comb_priority_dict['5'].append(c)
        elif c.count('o') == 2:
            comb_priority_dict['6'].append(c)
        elif c.count('p') == 1 or c.count('o') == 1:
            comb_priority_dict['7'].append(c)
        elif c.count('e') == 1:
            comb_priority_dict['8'].append(c)
        elif c.count('e') >= 2:
            comb_priority_dict['9'].append(c)
        else:
            unused_comb.append(c)

    return comb_priority_dict


class Player:
    def __init__(self, name, dot_num, game_field_map):
        self.game_field_map = game_field_map
        self.name = name

        self.dot_num = dot_num
        if self.dot_num == 1:
            self.dot_color = DotColor.BLACK
        else:
            self.dot_color = DotColor.WHITE

        self.opponent = None
        self.last_move = None

    def assign_opponent(self, opponent):
        self.opponent = opponent

    def select_move(self):
        raise NotImplementedError


class HumanPlayer(Player):
    def __init__(self, name, dot_num, game_field_map):
        super().__init__(name, dot_num, game_field_map)
    
    def select_move(self, tile):
        if not self.game_field_map[tile.map_pos[1]][tile.map_pos[0]]:
            x, y = tile.map_pos[0], tile.map_pos[1]
            self.game_field_map[y][x] = self.dot_num
            self.last_move = (x, y)
            pos = x, y
            return pos


class MachinePlayer(Player):
    combination_priority = create_combination_priority_dict()
    
    def __init__(self, name, dot_num, game_field_map):
        super().__init__(name, dot_num, game_field_map)
        self.playfield_map = game_field_map
        self.last_x_index = len(game_field_map[0]) - 1
        self.last_y_index = len(game_field_map) - 1

        if self.dot_num == 1:
            self.opponent_dot_num = 2
        else:
            self.opponent_dot_num = 1
        self.dots = []

    def select_move(self):
        if not self.opponent.last_move:
            x, y = self.select_random_tile()
        else:
            self.dots.append(self.opponent.last_move)
            self.dots.sort()
            x, y = self.analyze()
        self.last_move = (x, y)
        self.dots.append(self.last_move)
        self.dots.sort()
        self.playfield_map[y][x] = self.dot_num
        return x, y

    def analyze(self):
        # Create dict of best moves with 10 priority levels
        best_moves = {}
        for i in range(10):
            best_moves[str(i)] = []

        for dot in self.dots:
            self.check_neighbours(dot[0], dot[1], best_moves)

        for priority in range(len(best_moves)):
            priority = str(priority)
            if best_moves[priority]:
                return best_moves[priority][random.randrange(len(best_moves[priority]))]

        return self.select_random_tile()

    def check_neighbours(self, x, y, moves_dict):
        orig_x, orig_y = x, y
        for direction_x in -1, 0, 1:
            for direction_y in -1, 0, 1:
                x, y = orig_x, orig_y
                # If they both are 0, then x and y won't change and make combinations
                if direction_x == 0 and direction_y == 0:
                    continue

                combination = ''
                for k in range(5):
                    x += k * direction_x
                    y += k * direction_y
                    combination += self.get_tile_value(x, y)

                # If combination doesn't contain an empty tile, then there's no place for dot
                if '0' not in combination:
                    continue

                for priority in range(len(moves_dict)):
                    priority = str(priority)
                    if combination in self.combination_priority[priority]:
                        empty_tiles_indexes = []
                        while combination.count('0'):
                            empty_tiles_indexes.append(combination.index('0'))
                            combination = combination.replace('0', 'r', 1)
                        for i in empty_tiles_indexes:
                            moves_dict[priority] += [(orig_x + i * direction_x, orig_y + i * direction_y)]

                    # Remove all moves which are out of playfield
                    moves_dict[priority] = list(filter(
                        lambda move: 0 <= move[0] <= self.last_x_index and
                                     0 <= move[1] <= self.last_y_index and
                                     self.playfield_map[move[1]][move[0]] == 0,
                        moves_dict[priority]))

    def get_tile_value(self, x, y):
        if 0 <= x <= self.last_x_index and 0 <= y <= self.last_y_index:
            if self.playfield_map[y][x] == self.opponent_dot_num:
                # 'o' for 'opponent'
                return 'o'
            elif self.playfield_map[y][x] == self.dot_num:
                # 'p' for 'player', meaning this MachinePlayer
                return 'p'
            else:
                # '0' for empty tile
                return '0'
        else:
            # 'e' for 'error', meaning value is out of range
            return 'e'

    def select_random_tile(self):
        while True:
            tiles_all = len(self.playfield_map) * len(self.playfield_map[0])
            if len(self.dots) == tiles_all:
                break

            y = random.randint(0, len(self.playfield_map) - 1)
            x = random.randint(0, len(self.playfield_map[0]) - 1)
            if not self.playfield_map[y][x]:
                return x, y
