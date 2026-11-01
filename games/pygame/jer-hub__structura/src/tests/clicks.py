"""The click contract: how each Move becomes the clicks a player makes.

Shared by every test that plays the game through real mouse events. Each
structure registers two things:

  * a player, turning one Move into clicks on renderer targets and buttons;
  * the targets its renderer promises for a model, as (kind, key) pairs.

A new Zone adds its structure here instead of copying the helper.
"""
import pygame

from structura.models import Move

PLAYERS = {}
PROMISED_TARGETS = {}


def player(structure):
    def register(fn):
        PLAYERS[structure] = fn
        return fn
    return register


def promised_targets(structure):
    def register(fn):
        PROMISED_TARGETS[structure] = fn
        return fn
    return register


# ---- acting like a player ---------------------------------------------------
def click_at(app, pos):
    app.handle(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=pos))
    app.handle(pygame.event.Event(pygame.MOUSEBUTTONUP, button=1, pos=pos))
    app.update(0.01)
    app.draw()


def wheel(app, y):
    """Turn the mouse wheel: y > 0 is away from the player (up)."""
    app.handle(pygame.event.Event(pygame.MOUSEWHEEL, x=0, y=y, flipped=False, precise_x=0.0, precise_y=float(y)))
    app.draw()


def press(app, key):
    app.handle(pygame.event.Event(pygame.KEYDOWN, key=key, mod=0, unicode="", scancode=0))
    app.draw()


def button(app, label):
    matches = [b for b in app.scene.buttons if b.label == label]
    assert matches, f"no button {label!r} on {type(app.scene).__name__}: {[b.label for b in app.scene.buttons]}"
    return matches[0]


def labels(app):
    return [b.label for b in app.scene.buttons]


def click(app, label):
    b = button(app, label)
    assert b.enabled, f"button {label!r} is disabled"
    click_at(app, b.rect.center)


def settle(app):
    for _ in range(40):
        app.update(0.25)
    app.draw()


def target(app, kind, key):
    for t in app.scene.renderer.targets():
        if t.kind == kind and t.key == key:
            return t.rect.center
    raise AssertionError(f"no {kind} target {key!r}")


def perform(app, move: Move):
    """Make one Move the way a player would, without waiting for its animation."""
    if move.op == "answer":                       # any structure: click the option's button
        click(app, app.scene.session.goal.options[move.args[0]])
        return
    structure = app.scene.session.puzzle.structure
    assert structure in PLAYERS, f"no click contract for {structure!r}"
    PLAYERS[structure](app, move)


def play(app, move: Move):
    """Perform one Move the way a player would, then let the animation finish."""
    perform(app, move)
    settle(app)


# ---- array ---------------------------------------------------------------------
@player("array")
def play_array(app, move: Move):
    if move.op == "visit":
        click_at(app, target(app, "node", move.args[0]))
    elif move.op == "insert":
        click_at(app, target(app, "slot", move.args[0]))
    elif move.op == "swap":
        click_at(app, target(app, "node", move.args[0]))
        click_at(app, target(app, "node", move.args[1]))
        click(app, "Swap")
    else:
        raise AssertionError(move)


@promised_targets("array")
def array_targets(model, show_slots):
    n = len(model.values())
    nodes = {("node", i) for i in range(n)}
    slots = {("slot", i) for i in range(n + 1)} if show_slots else set()
    return nodes | slots


# ---- linked list -----------------------------------------------------------------
@player("linked_list")
def play_linked_list(app, move: Move):
    if move.op == "visit":
        click_at(app, target(app, "node", move.args[0]))
    elif move.op == "insert_head":
        click_at(app, target(app, "slot", "head"))
    elif move.op == "insert_after":
        click_at(app, target(app, "slot", move.args[0]))
    elif move.op == "delete":
        click_at(app, target(app, "node", move.args[0]))
        click(app, "Delete")
    else:
        raise AssertionError(move)


@promised_targets("linked_list")
def linked_list_targets(model, show_slots):
    """Nodes keyed by position; slots keyed "head" and i for "after position i"."""
    n = len(model.values())
    nodes = {("node", i) for i in range(n)}
    slots = {("slot", "head")} | {("slot", i) for i in range(n)} if show_slots else set()
    return nodes | slots


# ---- stack -----------------------------------------------------------------------
@player("stack")
def play_stack(app, move: Move):
    assert move.op in ("push", "pop"), move
    click(app, move.op.capitalize())


@promised_targets("stack")
def stack_targets(model, show_slots):
    return set()                                  # Moves come from the Push and Pop buttons


# ---- queue -----------------------------------------------------------------------
@player("queue")
def play_queue(app, move: Move):
    assert move.op in ("enqueue", "dequeue"), move
    click(app, move.op.capitalize())


@promised_targets("queue")
def queue_targets(model, show_slots):
    return set()                                  # Moves come from the Enqueue and Dequeue buttons


# ---- binary search tree -------------------------------------------------------------
@player("bst")
def play_bst(app, move: Move):
    if move.op == "visit":
        click_at(app, target(app, "node", move.args[0]))
    elif move.op == "insert":
        _, parent, side = move.args
        click_at(app, target(app, "slot", (parent, side)))
    elif move.op == "delete":
        value, replacement = move.args
        click_at(app, target(app, "node", value))
        click(app, "Delete")
        if replacement is not None:
            click_at(app, target(app, "node", replacement))
    elif move.op in ("rotate_left", "rotate_right"):
        click_at(app, target(app, "node", move.args[0]))
        click(app, "Rotate Left" if move.op == "rotate_left" else "Rotate Right")
    else:
        raise AssertionError(move)


@promised_targets("bst")
def bst_targets(model, show_slots):
    """Nodes keyed by value; slots keyed (parent value, side), the root's as (None, "")."""
    nodes = {("node", v) for v in model.values()}
    slots = {("slot", s) for s in model.empty_slots()} if show_slots else set()
    return nodes | slots
