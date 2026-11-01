"""Plays the thin slice headlessly by sending real pygame mouse and text events:
Profile -> Zone Map -> Z1 Lesson -> every Z1 Puzzle -> Results -> Progress Report."""
import dataclasses
import json
import os
from functools import partial

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pygame
import pytest

from clicks import button, click, click_at, labels, perform, play, press, settle, target, wheel
from structura.models import Move
from structura.persistence import report
from structura.persistence.store import Store
from structura.puzzles.schema import load_all
from structura.puzzles.session import reference_moves
from structura.ui import theme
from structura.ui.app import SIZE, App
from structura.ui.renderers import RENDERERS
from structura.ui.scenes.lesson import LessonScene
from structura.ui.scenes.profiles import ProfileScene
from structura.ui.scenes.puzzle import BRIEF_SIZE, BRIEF_W, PuzzleScene
from structura.ui.scenes.results import ResultsScene
from structura.ui.scenes.zone import ZoneScene
from structura.ui.scenes.zone_map import ZoneMapScene


def type_into(app, field_label, text):
    field = next(f for f in app.scene.fields if f.label == field_label)
    click_at(app, field.rect.center)
    app.handle(pygame.event.Event(pygame.TEXTINPUT, text=text))


# ---- fixtures -------------------------------------------------------------
@pytest.fixture
def app(tmp_path):
    pygame.init()
    a = App(Store(tmp_path / "t.db"), load_all(), screen=pygame.display.set_mode((1280, 720)),
            report_dir=tmp_path)
    a.draw()
    yield a
    a.store.close()


def new_profile(app, name="Ana Cruz", sid="2024-0001", language="Java"):
    assert isinstance(app.scene, ProfileScene)
    click(app, "New Profile")
    type_into(app, "Name", name)
    type_into(app, "Student ID", sid)
    click(app, language)
    click(app, "Create")


def solve_to_results(app, zone, puzzle_id):
    puzzle = next(p for p in zone.puzzles if p.id == puzzle_id)
    app.open_puzzle(zone, puzzle)
    for move in reference_moves(puzzle):
        play(app, move)
    click(app, "See Results")
    return puzzle


# ---- tests ----------------------------------------------------------------
def test_profile_requires_name_and_id(app):
    click(app, "New Profile")
    type_into(app, "Name", "Ana")
    click(app, "Create")
    assert isinstance(app.scene, ProfileScene)
    assert "required" in app.scene.message


# ---- a long Profile list ----------------------------------------------------
def profiles_on_screen(app, count):
    """A lab PC holding `count` Profiles, back at the Profile screen (as Switch Profile does)."""
    for i in range(1, count + 1):
        app.store.create_profile(f"Student {i:02d}", f"2024-{i:04d}")
    app.go(ProfileScene(app))
    app.draw()


def profile_buttons(app):
    return [b for b in app.scene.buttons if b.label != "New Profile"]


SCREEN = pygame.Rect((0, 0), SIZE)


@pytest.mark.parametrize("count, new_profile_top", [(3, 438), (7, 662)])
def test_a_short_profile_list_looks_as_it_always_has(app, count, new_profile_top):
    profiles_on_screen(app, count)
    assert [b.rect.top for b in profile_buttons(app)] == [250 + 56 * i for i in range(count)]
    assert button(app, "New Profile").rect.top == new_profile_top
    assert (app.scene.more_above, app.scene.more_below) == (0, 0)
    wheel(app, -1)
    press(app, pygame.K_DOWN)
    assert [b.rect.top for b in profile_buttons(app)] == [250 + 56 * i for i in range(count)]


def scroll_until_shown(app, label, scroll):
    for _ in range(len(app.store.profiles())):
        if any(b.label == label for b in profile_buttons(app)):
            return
        scroll(app)
    raise AssertionError(f"never scrolled to {label!r}")


SCROLLING = {
    "mouse wheel": (partial(wheel, y=-1), partial(wheel, y=1)),
    "arrow keys": (partial(press, key=pygame.K_DOWN), partial(press, key=pygame.K_UP)),
}


@pytest.mark.parametrize("scroll_down, scroll_up", SCROLLING.values(), ids=SCROLLING.keys())
def test_a_long_profile_list_scrolls_to_every_profile(app, scroll_down, scroll_up):
    profiles_on_screen(app, 12)
    shown = profile_buttons(app)
    assert all(SCREEN.contains(b.rect) for b in app.scene.buttons)
    assert not any(b.rect.colliderect(button(app, "New Profile").rect) for b in shown)
    assert app.scene.more_above == 0 and app.scene.more_below == 12 - len(shown)

    scroll_until_shown(app, "Student 12  (2024-0012)", scroll_down)
    assert app.scene.more_above == 12 - len(profile_buttons(app)) and app.scene.more_below == 0
    assert all(SCREEN.contains(b.rect) for b in app.scene.buttons)
    scroll_down(app)                                    # already at the end: nothing moves
    assert profile_buttons(app)[-1].label.startswith("Student 12")

    scroll_up(app)
    assert app.scene.more_below == 1
    scroll_down(app)
    click(app, "Student 12  (2024-0012)")
    assert isinstance(app.scene, ZoneMapScene) and app.profile.student_id == "2024-0012"


def test_a_long_name_is_shortened_to_fit_but_keeps_the_student_id(app):
    app.store.create_profile("W" * 40, "2024-0001")
    app.store.create_profile("Ana Cruz", "X" * 40)
    app.go(ProfileScene(app))
    long_name = next(b for b in profile_buttons(app) if "2024-0001" in b.label)
    long_id = next(b for b in profile_buttons(app) if b is not long_name)
    assert long_name.label.endswith("\u2026  (2024-0001)")
    for b in (long_name, long_id):
        assert theme.font(b.size).size(b.label)[0] <= b.rect.w - 20, b.label
    click_at(app, long_name.rect.center)
    assert app.profile.name == "W" * 40


def test_new_profile_still_works_with_a_long_list(app):
    profiles_on_screen(app, 12)
    wheel(app, -1)
    assert SCREEN.contains(button(app, "New Profile").rect)
    new_profile(app, name="Zoe Reyes", sid="2024-0099")
    assert isinstance(app.scene, ZoneMapScene) and app.profile.student_id == "2024-0099"


def test_full_slice(app, tmp_path):
    new_profile(app)
    assert isinstance(app.scene, ZoneMapScene)
    assert app.profile.language == "java"

    click(app, "The Array Plains")
    assert isinstance(app.scene, ZoneScene)
    # Puzzles unlock in order.
    assert not button(app, "Bubbling Up").enabled

    click(app, "Lesson")
    assert isinstance(app.scene, LessonScene)
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    assert app.scene.code_panel.snippet.language == "java"
    click(app, "Finish Lesson")
    assert isinstance(app.scene, ZoneScene)

    zone = app.zones[0]
    for i, puzzle in enumerate(zone.puzzles):
        click(app, puzzle.title)
        scene = app.scene
        assert isinstance(scene, PuzzleScene) and scene.session.puzzle.id == puzzle.id
        for move in reference_moves(puzzle):
            play(app, move)
        assert scene.session.done
        click(app, "See Results")
        assert isinstance(app.scene, ResultsScene)
        assert app.scene.stars == 3
        click(app, "Back to Zone")

    results = app.store.results(app.profile.id)
    assert {p.id for p in zone.puzzles} <= set(results)

    click(app, "Zone Map")
    click(app, "Export Progress Report")
    files = list(tmp_path.glob("structura_2024-0001_*.json"))
    assert len(files) == 1
    data = json.loads(files[0].read_text())
    assert report.verify(data) and data["summary"]["puzzles_completed"] == len(zone.puzzles)
    assert str(files[0]) in app.scene.message


def test_glitch_hint_and_undo(app):
    new_profile(app)
    puzzle = app.zones[0].puzzles[2]           # Bubbling Up: strict bubble sort
    app.open_puzzle(app.zones[0], puzzle)
    scene = app.scene
    play_wrong = Move.of("swap", 0, 4)
    click_at(app, target(app, "node", 0))
    click_at(app, target(app, "node", 4))
    click(app, "Swap")
    assert scene.session.glitches == 1 and "neighbours" in scene.message

    click(app, "Hint")
    click(app, "Hint")
    click(app, "Hint")
    assert scene.session.hint_tier == 3 and scene.message.startswith("Next:")
    assert scene.hint_move == scene.session.expected()

    play(app, scene.session.expected())
    moves_before = scene.session.moves
    click(app, "Undo")
    assert scene.session.moves == moves_before
    assert scene.session.model.values() == puzzle.initial
    assert play_wrong != scene.session.expected()


def test_disruption_is_announced(app):
    new_profile(app)
    boss = app.zones[0].puzzles[-1]
    app.open_puzzle(app.zones[0], boss)
    announced = []
    for move in reference_moves(boss):
        play(app, move)
        announced.append(app.scene.message)
    assert any("Shuffler flips" in m for m in announced)


# ---- exporting a Progress Report -------------------------------------------
def test_a_failed_export_is_explained_and_the_game_carries_on(app, tmp_path):
    blocked = tmp_path / "Structura Reports"
    blocked.write_text("a file where the folder should be", encoding="utf-8")
    app.report_dir = blocked
    new_profile(app)
    click(app, "Export Progress Report")
    assert isinstance(app.scene, ZoneMapScene)
    assert "couldn't be saved" in app.scene.message and str(blocked) in app.scene.message
    assert app.scene.message_colour == theme.BAD
    app.draw()

    blocked.unlink()
    click(app, "Export Progress Report")
    saved = list(blocked.glob("structura_2024-0001_*.json"))
    assert len(saved) == 1
    assert str(saved[0]) in app.scene.message and "Google Classroom" in app.scene.message
    assert app.scene.message_colour == theme.GOOD

    click(app, "The Array Plains")
    assert isinstance(app.scene, ZoneScene)


# ---- animation speed ------------------------------------------------------
def speed(app):
    """The Zone Map's animation speed button label."""
    return next(label for label in labels(app) if label.startswith("Speed:"))


def set_speed(app, label):
    app.open_map()
    while speed(app) != label:
        click(app, speed(app))


def test_animation_speed_cycles_on_the_zone_map_and_is_saved(app, tmp_path):
    new_profile(app)
    assert speed(app) == "Speed: 1x"
    for shown in ("Speed: 2x", "Speed: 0.5x", "Speed: 1x", "Speed: 2x"):
        click(app, speed(app))
        assert speed(app) == shown
    reopened = Store(tmp_path / "t.db")
    assert [p.speed for p in reopened.profiles()] == [2.0]
    reopened.close()


def seconds_until(app, finished, dt=0.005):
    t = 0.0
    while not finished():
        app.update(dt)
        t += dt
        assert t < 10, "the animation never finished"
    return t


def board_at_rest(scene):
    return lambda: all(scene.renderer.at_rest(e) for e in scene.renderer.element_ids())


def swap_animation_times(app, label):
    """(board motion, Step playback) in seconds for the first swap in Bubbling Up."""
    set_speed(app, label)
    z1 = app.zones[0]
    app.open_puzzle(z1, next(p for p in z1.puzzles if p.id == "z1_p3"))     # Bubbling Up
    scene = app.scene
    perform(app, scene.session.expected())
    board = seconds_until(app, board_at_rest(scene))
    steps = board + seconds_until(app, lambda: not scene.player.busy)
    return board, steps


def test_a_puzzle_animates_at_the_profile_speed(app):
    new_profile(app)
    board_1x, steps_1x = swap_animation_times(app, "Speed: 1x")
    board_2x, steps_2x = swap_animation_times(app, "Speed: 2x")
    assert board_2x == pytest.approx(board_1x / 2, rel=0.15)
    assert steps_2x == pytest.approx(steps_1x / 2, rel=0.15)


def first_lesson_motion_time(app, label):
    """Seconds the board moves for after the first Lesson beat that moves anything."""
    set_speed(app, label)
    app.open_lesson(app.zones[0])
    scene = app.scene
    settle(app)
    while board_at_rest(scene)():
        click(app, "Next")
    return seconds_until(app, board_at_rest(scene))


def test_a_lesson_animates_at_the_profile_speed(app):
    new_profile(app)
    at_1x = first_lesson_motion_time(app, "Speed: 1x")
    assert first_lesson_motion_time(app, "Speed: 2x") == pytest.approx(at_1x / 2, rel=0.15)


# ---- Achievements -----------------------------------------------------------------
def earned_titles(app):
    return [a.title for a in app.scene.achievements if a.earned]


def test_achievements_screen_lights_first_repair_after_one_puzzle(app):
    new_profile(app)
    click(app, "Achievements")
    titles = [a.title for a in app.scene.achievements]
    assert earned_titles(app) == []
    assert "First Repair" in titles and {f"Master of {z.name}" for z in app.zones} <= set(titles)
    app.draw()
    click(app, "Back")
    assert isinstance(app.scene, ZoneMapScene)

    solve_to_results(app, app.zones[0], app.zones[0].puzzles[0].id)
    app.open_map()
    click(app, "Achievements")
    assert "First Repair" in earned_titles(app)
    app.draw()


def test_clean_hands_is_earned_by_a_clean_run_that_scores_less_than_a_messy_one(app):
    new_profile(app)
    z1 = app.zones[0]
    puzzle = next(p for p in z1.puzzles if p.stage == "challenge")
    reference = list(reference_moves(puzzle))

    app.open_puzzle(z1, puzzle)
    perform(app, Move.of("swap", 0, 2))
    assert app.scene.session.glitches == 1
    for move in reference:
        play(app, move)
    click(app, "See Results")
    assert app.scene.stars == 2
    app.open_map()
    click(app, "Achievements")
    assert "Clean Hands" not in earned_titles(app)

    app.open_puzzle(z1, puzzle)
    for _ in range(3):                            # Undo doesn't refund the Move
        play(app, reference[0])
        click(app, "Undo")
    for move in reference:
        play(app, move)
    assert (app.scene.session.glitches, app.scene.session.hints_used) == (0, 0)
    click(app, "See Results")
    assert app.scene.stars == 1

    app.open_map()
    click(app, "Achievements")
    assert "Clean Hands" in earned_titles(app)


def test_achievements_fit_on_screen_with_every_planned_zone(app):
    """The spec plans about a dozen Zones, so about sixteen Achievements."""
    new_profile(app)
    planned = app.zones[0]
    app.zones = [dataclasses.replace(planned, id=f"z{i}", name=f"Zone {i}") for i in range(12)]
    click(app, "Achievements")
    cards = [app.scene.card(i) for i in range(len(app.scene.achievements))]
    back = button(app, "Back").rect
    screen = pygame.Rect(0, 0, 1280, 720)
    assert len(cards) == 16
    assert all(screen.contains(c) and not c.colliderect(back) for c in cards)
    assert not any(a.colliderect(b) for i, a in enumerate(cards) for b in cards[i + 1:])


# ---- watching the Reference Solution ------------------------------------------
def watch(app, dt=0.05, limit=60.0):
    """Run the replay until it offers Back to Results. Returns (seconds, every
    (Moves made, message) pair shown along the way)."""
    scene, t, shown = app.scene, 0.0, []
    while "Back to Results" not in labels(app):
        app.update(dt)
        t += dt
        shown.append((scene.session.moves, scene.message))
        assert t < limit, "the replay never finished"
    return t, shown


def test_watching_the_reference_solution_ends_solved_and_records_nothing(app):
    new_profile(app)
    z1 = app.zones[0]
    puzzle = solve_to_results(app, z1, "z1_p3")                             # Bubbling Up
    results = app.scene
    saved = app.store.results(app.profile.id)

    click(app, "Watch Reference Solution")
    scene = app.scene
    assert isinstance(scene, PuzzleScene) and scene.session.moves == 0
    assert scene.session.model.values() == puzzle.initial
    watch(app)
    assert scene.session.model.values() == sorted(puzzle.initial)
    assert scene.session.moves == len(reference_moves(puzzle))

    click(app, "Back to Results")
    assert app.scene is results
    assert app.store.results(app.profile.id) == saved, "a replay never records a result"


def test_the_player_only_watches_a_replay_and_can_leave_partway(app):
    new_profile(app)
    z1 = app.zones[0]
    solve_to_results(app, z1, "z1_p3")                                      # Bubbling Up
    results = app.scene
    click(app, "Watch Reference Solution")
    scene = app.scene
    assert labels(app) == ["Leave Replay"], "no Swap, Undo or Hint while watching"
    for _ in range(3):
        click_at(app, target(app, "node", 0))
    assert scene.selected == [] and scene.session.glitches == 0
    for _ in range(30):
        app.update(0.05)
    assert 0 < scene.session.moves < len(reference_moves(scene.puzzle)), "the replay moves on by itself"
    click(app, "Leave Replay")
    assert app.scene is results


def test_a_replay_announces_each_disruption_after_the_same_move_as_play(app):
    new_profile(app)
    z1 = app.zones[0]
    boss = solve_to_results(app, z1, z1.puzzles[-1].id)                     # the Array Plains Boss
    click(app, "Watch Reference Solution")
    _, shown = watch(app)
    for d in boss.disruptions:
        first = next(moves for moves, message in shown if d.say in message)
        assert first == d.after, f"{d.say!r} fired after Move {first}, not {d.after}"
    assert app.scene.session.done


def test_a_replay_plays_at_the_profile_speed(app):
    new_profile(app)
    z1 = app.zones[0]
    solve_to_results(app, z1, "z1_p3")                                      # Bubbling Up
    click(app, "Watch Reference Solution")
    at_1x, _ = watch(app, dt=0.01)
    set_speed(app, "Speed: 2x")
    solve_to_results(app, z1, "z1_p3")
    click(app, "Watch Reference Solution")
    at_2x, _ = watch(app, dt=0.01)
    assert at_2x == pytest.approx(at_1x / 2, rel=0.15)


def test_a_quiz_replay_shows_the_right_answer(app):
    new_profile(app)
    z3 = app.zones[2]
    solve_to_results(app, z3, "z3_p2")                                      # a stack quiz
    click(app, "Watch Reference Solution")
    scene = app.scene
    options = scene.session.goal.options
    assert all(not button(app, o).enabled for o in options), "answers can't be clicked while watching"
    watch(app)
    assert scene.session.done and button(app, options[scene.session.goal.correct]).selected


# ---- The Linked Marshes ---------------------------------------------------
def clear_zone(app, zone):
    for p in zone.puzzles:
        app.store.record(app.profile.id, p.id, 3, 1, 0, 0)


def test_linked_marshes_play_through(app):
    new_profile(app)
    z1, z2 = app.zones[0], app.zones[1]
    assert z2.name == "The Linked Marshes"
    clear_zone(app, z1)
    app.open_map()
    click(app, "The Linked Marshes")
    assert isinstance(app.scene, ZoneScene)

    click(app, "Lesson")
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    click(app, "Finish Lesson")

    for puzzle in z2.puzzles:
        click(app, puzzle.title)
        scene = app.scene
        assert isinstance(scene, PuzzleScene) and scene.session.puzzle.id == puzzle.id
        for move in reference_moves(puzzle):
            play(app, move)
        assert scene.session.done, puzzle.id
        click(app, "See Results")
        assert app.scene.stars == 3, puzzle.id
        click(app, "Back to Zone")

    assert {p.id for p in z2.puzzles} <= set(app.store.results(app.profile.id))


def test_delete_needs_exactly_one_selected_node(app):
    new_profile(app)
    z2 = app.zones[1]
    app.open_puzzle(z2, next(p for p in z2.puzzles if p.id == "z2_p4"))     # Cut the Rot
    assert not button(app, "Delete").enabled
    click_at(app, target(app, "node", 2))
    assert button(app, "Delete").enabled and app.scene.selected == [2]
    click_at(app, target(app, "node", 3))
    assert app.scene.selected == [3], "selecting another node moves the selection"
    click_at(app, target(app, "node", 3))
    assert not button(app, "Delete").enabled


def test_dead_end_prompts_undo(app):
    new_profile(app)
    z2 = app.zones[1]
    app.open_puzzle(z2, z2.puzzles[-1])                                     # The Marsh Hydra
    scene = app.scene
    play(app, Move.of("delete", 0))                                          # 1 can't come back
    assert scene.session.dead_end
    assert "Undo" in scene.message and "Hydra" in scene.message, "the Disruption is still announced"
    click(app, "Hint")
    click(app, "Hint")
    click(app, "Hint")
    assert scene.message.startswith("Undo") and scene.hint_move is None
    click(app, "Undo")
    assert not scene.session.dead_end


# ---- The Stack Towers -------------------------------------------------------
def test_stack_towers_play_through(app):
    new_profile(app)
    z1, z2, z3 = app.zones[0], app.zones[1], app.zones[2]
    assert z3.name == "The Stack Towers"
    clear_zone(app, z1)
    app.open_map()
    assert not button(app, "The Stack Towers").enabled, "locked until The Linked Marshes is cleared"
    clear_zone(app, z2)
    app.open_map()
    click(app, "The Stack Towers")

    click(app, "Lesson")
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    click(app, "Finish Lesson")

    quizzes = 0
    for puzzle in z3.puzzles:
        click(app, puzzle.title)
        scene = app.scene
        quizzes += scene.session.goal.options is not None
        for move in reference_moves(puzzle):
            play(app, move)
        assert scene.session.done, puzzle.id
        click(app, "See Results")
        assert app.scene.stars == 3, puzzle.id
        click(app, "Back to Zone")
    assert quizzes >= 1
    assert {p.id for p in z3.puzzles} <= set(app.store.results(app.profile.id))


def test_push_and_pop_buttons_follow_the_ops(app):
    new_profile(app)
    z3 = app.zones[2]
    by_id = {p.id: p for p in z3.puzzles}
    app.open_puzzle(z3, by_id["z3_p1"])                # Stack the Blocks: push only
    assert "Push" in labels(app) and "Pop" not in labels(app)

    app.open_puzzle(z3, by_id["z3_p3"])                # Mirror Spell: push and pop
    assert button(app, "Push").enabled and not button(app, "Pop").enabled, "nothing to pop yet"
    click(app, "Push")
    assert button(app, "Pop").enabled
    assert "Swap" not in labels(app) and "Delete" not in labels(app)


def test_quiz_wrong_then_right_answer(app):
    new_profile(app)
    z3 = app.zones[2]
    quiz = next(p for p in z3.puzzles if p.id == "z3_p2")
    app.open_puzzle(z3, quiz)
    scene = app.scene
    options, right = scene.session.goal.options, scene.session.goal.correct
    assert all(o in labels(app) for o in options)
    assert "Push" not in labels(app) and "Pop" not in labels(app)
    wrong = next(o for i, o in enumerate(options) if i != right)
    click(app, wrong)
    assert scene.session.glitches == 1 and "LIFO" in scene.message and not scene.session.done
    click(app, options[right])
    assert scene.session.done


# ---- The Queue Canals -------------------------------------------------------
def test_queue_canals_play_through(app):
    new_profile(app)
    z1, z2, z3, z4 = app.zones[:4]
    assert z4.name == "The Queue Canals"
    for z in (z1, z2):
        clear_zone(app, z)
    app.open_map()
    assert not button(app, "The Queue Canals").enabled, "locked until The Stack Towers is cleared"
    clear_zone(app, z3)
    app.open_map()
    click(app, "The Queue Canals")

    click(app, "Lesson")
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    click(app, "Finish Lesson")

    quizzes = 0
    for puzzle in z4.puzzles:
        click(app, puzzle.title)
        scene = app.scene
        quizzes += scene.session.goal.options is not None
        for move in reference_moves(puzzle):
            play(app, move)
        assert scene.session.done, puzzle.id
        click(app, "See Results")
        assert app.scene.stars == 3, puzzle.id
        click(app, "Back to Zone")
    assert quizzes >= 1
    assert {p.id for p in z4.puzzles} <= set(app.store.results(app.profile.id))


def test_enqueue_and_dequeue_buttons_follow_the_ops(app):
    new_profile(app)
    z4 = app.zones[3]
    by_id = {p.id: p for p in z4.puzzles}
    app.open_puzzle(z4, by_id["z4_p1"])                # Launch the Boats: enqueue only
    assert "Enqueue" in labels(app) and "Dequeue" not in labels(app)

    app.open_puzzle(z4, by_id["z4_p3"])                # Same Order Out: enqueue and dequeue
    assert button(app, "Enqueue").enabled and not button(app, "Dequeue").enabled, "nothing to dequeue yet"
    click(app, "Enqueue")
    assert button(app, "Dequeue").enabled
    assert "Push" not in labels(app) and "Pop" not in labels(app)


def test_queue_quiz_wrong_answer_explains_fifo(app):
    new_profile(app)
    z4 = app.zones[3]
    app.open_puzzle(z4, next(p for p in z4.puzzles if p.id == "z4_p2"))
    scene = app.scene
    options, right = scene.session.goal.options, scene.session.goal.correct
    click(app, next(o for i, o in enumerate(options) if i != right))
    assert scene.session.glitches == 1 and "FIFO" in scene.message and not scene.session.done
    click(app, options[right])
    assert scene.session.done


def test_the_lock_keeper_sweeps_the_front_boat_to_the_output(app):
    new_profile(app)
    z4 = app.zones[3]
    boss = z4.puzzles[-1]
    app.open_puzzle(z4, boss)
    scene = app.scene
    front = scene.session.model.front()
    moves = reference_moves(boss)
    for move in moves[:boss.disruptions[0].after]:
        play(app, move)
    assert "Lock Keeper" in scene.message
    assert front in scene.session.model.out
    assert front in [v for v, _ in scene.renderer.output()], "the swept boat lands on the Output row"


# ---- Nexus Alpha ------------------------------------------------------------
def nexus(app):
    return next(z for z in app.zones if z.id == "nexus_alpha")


def test_nexus_alpha_play_through(app):
    new_profile(app)
    nx = nexus(app)
    for z in app.zones[:3]:
        clear_zone(app, z)
    app.open_map()
    assert not button(app, "Nexus Alpha").enabled, "locked until The Queue Canals is cleared"
    clear_zone(app, app.zones[3])
    app.open_map()
    click(app, "Nexus Alpha")

    click(app, "Lesson")
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    click(app, "Finish Lesson")

    said = []
    for puzzle in nx.puzzles:
        click(app, puzzle.title)
        scene = app.scene
        assert type(scene.renderer) is RENDERERS[puzzle.structure], "each Puzzle's own structure, not the Zone's"
        for move in reference_moves(puzzle):
            play(app, move)
            said.append(scene.message)
        assert scene.session.done, puzzle.id
        click(app, "See Results")
        assert app.scene.stars == 3, puzzle.id
        click(app, "Back to Zone")
    assert all(d.say in said for d in nx.puzzles[-1].disruptions), "both of the Serpent's strikes are shown"
    assert {p.id for p in nx.puzzles} <= set(app.store.results(app.profile.id))


@pytest.mark.parametrize("language", ["Java", "Python"])
def test_select_puzzle_offers_structures_and_shows_their_big_o(app, language):
    new_profile(app, language=language)
    nx = nexus(app)
    puzzle = next(p for p in nx.puzzles if p.id == "nx_p3")          # Seat Numbers
    app.open_puzzle(nx, puzzle)
    scene = app.scene
    options = ["Array", "Linked List", "Stack", "Queue"]
    assert scene.session.goal.options == options and all(o in labels(app) for o in options)
    head, rows = scene.code_panel.table
    assert "read the item at a position" in head
    assert [name for name, _ in rows] == options
    app.draw()

    click(app, "Linked List")
    assert scene.session.glitches == 1 and not scene.session.done
    assert "Linked List takes O(n)" in scene.message and "Array takes O(1)" in scene.message
    assert scene.code_panel.table is not None, "the table stays up after a Glitch"
    click(app, "Array")
    assert scene.session.done


def test_a_regular_puzzle_shows_code_not_a_table(app):
    new_profile(app)
    nx = nexus(app)
    app.open_puzzle(nx, nx.puzzles[-1])
    assert app.scene.code_panel.table is None and app.scene.code_panel.snippet is not None


def test_nexus_lesson_shows_each_structure_and_their_big_o(app):
    """The comparison Lesson puts every structure on the board in turn, and
    the Code Mirror shows the Big-O table to compare them."""
    new_profile(app)
    nx = nexus(app)
    app.open_zone(nx)
    click(app, "Lesson")
    shown, tables = [], 0
    while True:
        settle(app)
        scene = app.scene
        assert scene.renderer.element_ids(), f"beat {scene.index + 1} has nothing on the board"
        shown.append(type(scene.renderer))
        tables += scene.code_panel.table is not None
        if "Finish Lesson" in labels(app):
            break
        click(app, "Next")
    assert set(shown) == {RENDERERS[s] for s in ("array", "linked_list", "stack", "queue")}
    assert tables >= 1


@pytest.mark.parametrize("puzzle", [p for z in load_all() for p in z.puzzles], ids=lambda p: p.id)
def test_every_brief_fits_on_its_one_line(puzzle):
    pygame.init()
    assert theme.font(BRIEF_SIZE).size(puzzle.brief)[0] <= BRIEF_W


# ---- The Binary Forest ---------------------------------------------------------------
def forest(app):
    return next(z for z in app.zones if z.id == "z5")


def test_binary_forest_play_through(app):
    new_profile(app)
    z5 = forest(app)
    for z in app.zones[:4]:
        clear_zone(app, z)
    app.open_map()
    assert not button(app, "The Binary Forest").enabled, "locked until Nexus Alpha is cleared"
    clear_zone(app, nexus(app))
    app.open_map()
    click(app, "The Binary Forest")

    click(app, "Lesson")
    while not any(b.label == "Finish Lesson" for b in app.scene.buttons):
        click(app, "Next")
        settle(app)
    click(app, "Finish Lesson")

    for puzzle in z5.puzzles:
        click(app, puzzle.title)
        scene = app.scene
        for move in reference_moves(puzzle):
            play(app, move)
        assert scene.session.done, puzzle.id
        click(app, "See Results")
        assert app.scene.stars == 3, puzzle.id
        click(app, "Back to Zone")
    assert {p.id for p in z5.puzzles} <= set(app.store.results(app.profile.id))


def test_the_forest_lesson_deletes_on_the_board_only_after_the_comparisons(app):
    new_profile(app)
    app.open_zone(forest(app))
    click(app, "Lesson")
    while "delete 10" not in app.scene.lesson.beats[app.scene.index].do:
        settle(app)
        click(app, "Next")
    assert 10 in app.scene.renderer.keys(), "the old tree stays while 10 is compared and replaced"
    settle(app)
    assert app.scene.renderer.keys() == [3, 6, 8, 9, 14]


@pytest.mark.parametrize("puzzle_id, wrong, rule", [
    ("z5_p2", 3, "go left if the value is smaller"),
    ("z5_p5", 50, "In-order visits the left subtree"),
    ("z5_p6", 30, "Pre-order visits a node first"),
])
def test_a_wrong_click_on_a_tree_trace_explains_the_rule(app, puzzle_id, wrong, rule):
    new_profile(app)
    z5 = forest(app)
    app.open_puzzle(z5, next(p for p in z5.puzzles if p.id == puzzle_id))
    click_at(app, target(app, "node", wrong))
    assert app.scene.session.glitches == 1 and rule in app.scene.message


def test_rotate_buttons_need_one_node_with_the_child_it_lifts(app):
    new_profile(app)
    z5 = forest(app)
    app.open_puzzle(z5, next(p for p in z5.puzzles if p.id == "z5_p7"))    # 1 -> 2 -> 3, leaning right
    assert not button(app, "Rotate Left").enabled and not button(app, "Rotate Right").enabled
    click_at(app, target(app, "node", 1))
    assert button(app, "Rotate Left").enabled, "1 has a right child to lift"
    assert not button(app, "Rotate Right").enabled, "1 has no left child"
    click_at(app, target(app, "node", 3))
    assert app.scene.selected == [3], "one node at a time"
    assert not button(app, "Rotate Left").enabled and not button(app, "Rotate Right").enabled
    click_at(app, target(app, "node", 1))
    click(app, "Rotate Left")
    settle(app)
    assert app.scene.session.done and app.scene.renderer.keys() == [1, 2, 3]


def open_heart_of_the_tree(app):
    new_profile(app)
    z5 = forest(app)
    app.open_puzzle(z5, next(p for p in z5.puzzles if p.id == "z5_p4"))
    return app.scene


def test_deleting_a_node_with_two_children_asks_for_its_replacement(app):
    scene = open_heart_of_the_tree(app)
    click_at(app, target(app, "node", 3))
    click(app, "Delete")
    assert scene.session.moves == 0, "Delete alone makes no Move yet"
    assert "takes its place" in scene.message
    assert not button(app, "Delete").enabled

    click_at(app, target(app, "node", 7))
    assert scene.session.glitches == 1 and "in-order successor" in scene.message
    assert 3 in scene.renderer.keys(), "the tree is unchanged"

    click_at(app, target(app, "node", 3))
    click(app, "Delete")
    click_at(app, target(app, "node", 4))
    settle(app)
    assert scene.session.done and scene.renderer.keys() == [1, 4, 6, 7, 8, 10, 13, 14]


def test_clicking_the_same_node_again_cancels_the_delete(app):
    scene = open_heart_of_the_tree(app)
    click_at(app, target(app, "node", 3))
    click(app, "Delete")
    click_at(app, target(app, "node", 3))
    assert scene.session.moves == 0 and scene.session.glitches == 0
    assert scene.selected == [] and not button(app, "Delete").enabled
    click_at(app, target(app, "node", 3))
    assert button(app, "Delete").enabled


def test_a_hint_for_a_different_delete_cancels_the_pending_one(app):
    scene = open_heart_of_the_tree(app)
    click_at(app, target(app, "node", 6))
    click(app, "Delete")
    for _ in range(3):
        click(app, "Hint")
    assert scene.hinted() == (3,) and scene.selected == []
    click_at(app, target(app, "node", 3))
    assert scene.session.glitches == 0 and scene.selected == [3]


def test_undo_drops_the_steps_of_the_undone_move(app):
    new_profile(app)
    z5 = forest(app)
    app.open_puzzle(z5, next(p for p in z5.puzzles if p.id == "z5_p1"))
    scene = app.scene
    perform(app, Move.of("insert", 8, None, ""))
    click(app, "Undo")
    assert not scene.player.busy
    settle(app)
    assert scene.renderer.keys() == [] and not scene.renderer.leaving()


def test_the_hint_points_at_the_replacement_while_one_is_being_chosen(app):
    scene = open_heart_of_the_tree(app)
    click_at(app, target(app, "node", 3))
    click(app, "Delete")
    for _ in range(3):
        click(app, "Hint")
    assert scene.hinted() == (4,)
