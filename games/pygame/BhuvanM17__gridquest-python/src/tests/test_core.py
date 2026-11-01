"""Behavior tests for deterministic maps, shortest routes, and game rules."""

import pytest

from gridquest.core import Game, Maze, generate_maze, shortest_path


@pytest.mark.parametrize("seed", range(20))
def test_generated_maze_is_connected_and_bounded(seed):
    maze = generate_maze(25, 19, seed)
    assert maze.start == (1, 1)
    assert maze.exit != maze.start
    assert all(0 < x < 24 and 0 < y < 18 for x, y in maze.floor)
    reached = {maze.start}
    pending = [maze.start]
    while pending:
        x, y = pending.pop()
        for neighbor in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if neighbor in maze.floor and neighbor not in reached:
                reached.add(neighbor)
                pending.append(neighbor)
    assert reached == maze.floor
    assert maze.exit in reached


def test_generation_reproduces_seed_without_global_random_state():
    assert generate_maze(25, 19, 42) == generate_maze(25, 19, 42)
    assert generate_maze(25, 19, 42).floor != generate_maze(25, 19, 43).floor


@pytest.mark.parametrize("width,height", [(2, 3), (4, 5), (5, 2), (5, 6)])
def test_invalid_dimensions_rejected(width, height):
    with pytest.raises(ValueError):
        generate_maze(width, height, 0)


def test_smallest_maze_has_separate_exit():
    maze = generate_maze(5, 5, 1)
    assert maze.exit != maze.start
    assert shortest_path(maze, maze.start, maze.exit)


def corridor():
    return Maze(7, 5, frozenset({(1, 1), (2, 1), (3, 1), (4, 1), (5, 1)}), (1, 1), (5, 1))


def test_path_is_shortest_and_includes_endpoints():
    maze = corridor()
    assert shortest_path(maze, (1, 1), (4, 1)) == [(1, 1), (2, 1), (3, 1), (4, 1)]
    assert shortest_path(maze, (2, 1), (2, 1)) == [(2, 1)]


def test_no_path_for_walls_or_disconnected_cells():
    maze = Maze(5, 5, frozenset({(1, 1), (3, 3)}), (1, 1), (3, 3))
    assert shortest_path(maze, (1, 1), (3, 3)) == []
    assert shortest_path(maze, (0, 0), (0, 0)) == []


def test_player_rejects_walls_diagonals_and_jumps():
    game = Game(corridor(), enemy=(4, 1))
    for delta in ((0, 1), (1, 1), (2, 0), (0, 0)):
        assert not game.move(*delta)
        assert game.player == (1, 1)
    assert game.move(1, 0)
    assert game.player == (2, 1)
    assert game.moves == 1


def test_enemy_takes_one_shortest_path_step_and_catches_player():
    game = Game(corridor(), enemy=(3, 1))
    game.advance_enemy()
    assert game.enemy == (2, 1)
    assert game.status == "playing"
    game.advance_enemy()
    assert game.enemy == (1, 1)
    assert game.status == "lost"
    assert not game.move(1, 0)


def test_entering_enemy_loses_immediately():
    game = Game(corridor(), enemy=(2, 1))
    assert game.move(1, 0)
    assert game.status == "lost"


def test_reaching_exit_wins_and_freezes_enemy():
    game = Game(corridor(), enemy=(1, 1), player=(4, 1))
    assert game.move(1, 0)
    assert game.status == "won"
    game.advance_enemy()
    assert game.enemy == (1, 1)
    assert not game.move(-1, 0)


def test_collision_has_priority_over_exit():
    game = Game(corridor(), enemy=(5, 1), player=(4, 1))
    game.move(1, 0)
    assert game.status == "lost"


def test_enemy_launches_from_entrance_with_solvable_escape_route():
    game = Game.new(42)
    assert game.enemy == game.maze.start
    assert game.enemy != game.maze.exit
    assert shortest_path(game.maze, game.player, game.maze.exit)
