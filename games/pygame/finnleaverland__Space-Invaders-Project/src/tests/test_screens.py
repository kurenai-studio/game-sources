"""Tests for the tkinter screens, driven through their real buttons and text boxes.

They need a display, so they are skipped automatically where tkinter can't open a window.
"""
import tkinter as tk
from tkinter import ttk
from types import SimpleNamespace

import pytest

from space_invaders import accounts, game, settings, theme
from space_invaders import app as app_module
from space_invaders.accounts import Client, ClientList
from space_invaders.validation import SECURITY_QUESTIONS


@pytest.fixture(scope="session")
def root():
    """One main window shared by every test (Tk is slow and flaky to recreate).

    It stays mapped, so keyboard focus and Tab order work as they do for a player,
    but it is fully transparent and off-screen so nothing flashes up.
    """
    try:
        window = theme.new_root("test", app_module.WINDOW_WIDTH, app_module.WINDOW_HEIGHT)
    except tk.TclError as error:
        pytest.skip(f"tkinter can't open a window here: {error}")
    window.attributes("-alpha", 0.0)
    window.geometry("+-4000+-4000")
    window.update()
    # Tk loads its keyboard-traversal commands from library files the first time they're
    # used. On some Windows machines that read occasionally fails, so load them up front.
    for _attempt in range(3):
        try:
            window.tk.call("auto_load", "tk_focusNext")
            break
        except tk.TclError:
            pass
    yield window
    window.destroy()


@pytest.fixture
def accounts_file(tmp_path, monkeypatch):
    path = tmp_path / "Clientfile.txt"
    monkeypatch.setattr(accounts, "CLIENT_FILE", str(path))
    monkeypatch.setattr(settings, "SETTINGS_FILE", str(tmp_path / "settings.json"))
    monkeypatch.setattr(accounts, "HASH_ITERATIONS", 1_000)
    clients = ClientList()
    alice = Client.new("alice", "alice-pass", "First pet?", "Rex")
    alice.highest_score = 50
    clients.add_client(alice)
    clients.add_client(Client.new("carol", "carol-pass", "Home town?", "Leeds"))
    clients.add_client(Client.new("dan", "abc", "Old free-text question?", "yes"))  # pre-1c account
    return path


@pytest.fixture
def app(root, accounts_file):
    application = app_module.App(root)
    yield application
    application.screen.destroy()


def widgets(parent, kind):
    """Every widget of a type inside parent, in creation order."""
    found = []
    for child in parent.winfo_children():
        if isinstance(child, kind):
            found.append(child)
        found.extend(widgets(child, kind))
    return found


def click(app, text):
    """Press the button with this text on the current screen."""
    for button in widgets(app.screen, ttk.Button):
        if button.cget("text") == text:
            button.invoke()
            app.root.update()
            return
    raise AssertionError(f"no {text!r} button on {type(app.screen).__name__}")


def type_into(entry, text):
    entry.delete(0, "end")
    entry.insert(0, text)


def message(app):
    return app.screen.message.cget("text")


def screen_name(app):
    return type(app.screen).__name__


# --- Navigation -------------------------------------------------------------------

def test_starts_on_welcome_screen(app):
    assert screen_name(app) == "WelcomeScreen"


@pytest.mark.parametrize("button, screen", [
    ("Log in", "LoginScreen"),
    ("Register", "RegisterScreen"),
    ("Reset password", "ResetPasswordScreen"),
])
def test_every_form_has_a_back_button(app, button, screen):
    click(app, button)
    assert screen_name(app) == screen
    click(app, "← Back")
    assert screen_name(app) == "WelcomeScreen"


def test_everything_happens_in_one_window(app):
    click(app, "Log in")
    click(app, "← Back")
    click(app, "Register")
    assert not [w for w in app.root.winfo_children() if isinstance(w, tk.Toplevel)]


# --- Keyboard and usability ----------------------------------------------------------

def press(app, widget, key, char=""):
    """Send a key press on a widget to the same handlers the window's key bindings call.

    Real key events only arrive while the window has keyboard focus, which Windows won't
    give a background test window, so the bindings themselves are checked separately.
    """
    event = SimpleNamespace(widget=widget, keysym=key, char=char)
    if key == "Return":
        app.screen.handle_return(event)
    elif key == "Escape":
        app.screen.handle_escape(event)
    else:
        app.screen.on_typing(event)
    app.root.update()


def test_keys_are_bound_to_the_screen_handlers(app):
    bound = app.root.bind()
    assert {"<Key-Return>", "<Key-KP_Enter>", "<Key-Escape>"} <= set(bound)
    click(app, "Register")
    for field in app.screen.fields:
        # typing clears errors; the read-only question list clears them when a choice is made
        expected = "<<ComboboxSelected>>" if isinstance(field, ttk.Combobox) else "<Key>"
        assert expected in field.bind()


def test_cursor_starts_in_the_first_box(app):
    click(app, "Log in")
    assert app.root.focus_lastfor() == app.screen.username_entry


def test_tab_goes_from_box_to_box_then_to_the_button(app):
    click(app, "Log in")
    screen = app.screen
    assert screen.username_entry.tk_focusNext() == screen.password_entry
    next_widget = screen.password_entry.tk_focusNext()
    assert isinstance(next_widget, ttk.Button) and next_widget.cget("text") == "Log in"


def test_return_submits_the_form(app):
    click(app, "Log in")
    type_into(app.screen.username_entry, "alice")
    type_into(app.screen.password_entry, "alice-pass")
    press(app, app.screen.password_entry, "Return")
    assert screen_name(app) == "MenuScreen"


def test_return_presses_the_focused_button(app):
    register_button = [b for b in app.screen.buttons if b.cget("text") == "Register"][0]
    press(app, register_button, "Return")
    assert screen_name(app) == "RegisterScreen"


def test_escape_goes_back(app):
    click(app, "Register")
    press(app, app.screen.username_entry, "Escape")
    assert screen_name(app) == "WelcomeScreen"


def test_escape_does_not_quit_from_the_welcome_screen(app):
    press(app, app.screen.buttons[0], "Escape")
    assert screen_name(app) == "WelcomeScreen"


def test_show_password_toggle(app):
    click(app, "Log in")
    toggle = widgets(app.screen, ttk.Checkbutton)[0]
    assert app.screen.password_entry.cget("show") != ""
    toggle.invoke()
    assert app.screen.password_entry.cget("show") == ""
    toggle.invoke()
    assert app.screen.password_entry.cget("show") != ""


def test_error_clears_when_the_player_edits_a_box(app):
    log_in(app, password="wrong")
    assert message(app) == "Incorrect password"
    press(app, app.screen.username_entry, "Tab")  # moving between boxes keeps the message
    assert message(app) == "Incorrect password"
    press(app, app.screen.username_entry, "BackSpace")
    assert message(app) == ""


def test_typing_a_letter_clears_the_error(app):
    log_in(app, username="nobody")
    assert message(app) == "Incorrect username"
    press(app, app.screen.username_entry, "a", char="a")
    assert message(app) == ""


# --- Logging in -------------------------------------------------------------------

def log_in(app, username="alice", password="alice-pass"):
    click(app, "Log in")
    type_into(app.screen.username_entry, username)
    type_into(app.screen.password_entry, password)
    click(app, "Log in")


def test_log_in(app):
    log_in(app)
    assert screen_name(app) == "MenuScreen"
    assert app.client.username == "alice"


def test_log_in_with_unknown_username(app):
    log_in(app, username="nobody")
    assert screen_name(app) == "LoginScreen"
    assert message(app) == "Incorrect username"


def test_log_in_with_wrong_password(app):
    log_in(app, password="wrong")
    assert message(app) == "Incorrect password"
    assert app.screen.password_entry.get() == ""


# --- Registering ------------------------------------------------------------------

def register(app, username="bob", password="bob-pass", confirm=None,
             question=SECURITY_QUESTIONS[0], answer="blue"):
    click(app, "Register")
    type_into(app.screen.username_entry, username)
    type_into(app.screen.password_entry, password)
    type_into(app.screen.confirm_entry, password if confirm is None else confirm)
    if question is not None:
        app.screen.question_choice.set(question)
    type_into(app.screen.answer_entry, answer)
    click(app, "Create account")


def test_register_logs_the_new_player_in(app):
    register(app)
    assert screen_name(app) == "MenuScreen"
    assert ClientList().find(Client("bob"))[0]


def test_register_rejects_taken_username(app):
    register(app, username="alice")
    assert message(app) == "That username is already taken"


def test_register_checks_the_passwords_match(app):
    register(app, confirm="bob-pas")
    assert message(app) == "The passwords don't match"


def test_register_needs_a_long_enough_password(app):
    register(app, password="short")
    assert message(app) == "Password must be at least 8 characters"


def test_register_needs_a_question_from_the_list(app):
    register(app, question=None)
    assert message(app) == "Choose a security question"
    assert list(app.screen.question_choice.cget("values")) == list(SECURITY_QUESTIONS)
    assert str(app.screen.question_choice.cget("state")) == "readonly"


def test_old_accounts_with_short_passwords_can_still_log_in(app):
    log_in(app, username="dan", password="abc")
    assert screen_name(app) == "MenuScreen"


# --- Resetting a password -----------------------------------------------------------

def test_reset_password(app):
    click(app, "Reset password")
    type_into(app.screen.username_entry, "alice")
    click(app, "Next")
    assert app.screen.question_label.cget("text") == "First pet?"
    type_into(app.screen.answer_entry, "  REX ")
    type_into(app.screen.password_entry, "new-password")
    type_into(app.screen.confirm_entry, "new-password")
    click(app, "Save new password")

    assert screen_name(app) == "LoginScreen"
    assert "Password changed" in message(app)
    type_into(app.screen.username_entry, "alice")
    type_into(app.screen.password_entry, "new-password")
    click(app, "Log in")
    assert screen_name(app) == "MenuScreen"


def test_reset_password_unknown_user_and_wrong_answer(app):
    click(app, "Reset password")
    type_into(app.screen.username_entry, "nobody")
    click(app, "Next")
    assert message(app) == "That username doesn't exist"
    type_into(app.screen.username_entry, "alice")
    click(app, "Next")
    type_into(app.screen.answer_entry, "Max")
    type_into(app.screen.password_entry, "new-password")
    type_into(app.screen.confirm_entry, "new-password")
    click(app, "Save new password")
    assert message(app) == "Wrong answer, try again"


def test_reset_password_uses_the_new_password_rules(app):
    click(app, "Reset password")
    type_into(app.screen.username_entry, "alice")
    click(app, "Next")
    type_into(app.screen.answer_entry, "rex")
    type_into(app.screen.password_entry, "short")
    type_into(app.screen.confirm_entry, "short")
    click(app, "Save new password")
    assert message(app) == "Password must be at least 8 characters"
    type_into(app.screen.password_entry, "new-password")
    type_into(app.screen.confirm_entry, "new-passwrd")
    click(app, "Save new password")
    assert message(app) == "The passwords don't match"


# --- The menu -----------------------------------------------------------------------

def test_play_saves_the_score(app, monkeypatch):
    monkeypatch.setattr(game, "main", lambda *args, **kwargs: 120)
    log_in(app)
    click(app, "Play")
    assert screen_name(app) == "MenuScreen"
    alice = ClientList().clients[0]
    assert (alice.score, alice.highest_score) == (120, 120)


def test_leaderboard_and_how_to_play_have_back_buttons(app):
    log_in(app)
    for button in ("Leaderboard", "How to play"):
        click(app, button)
        assert screen_name(app) != "MenuScreen"
        click(app, "← Back")
        assert screen_name(app) == "MenuScreen"


def test_delete_account(app):
    log_in(app)
    click(app, "Delete account")
    type_into(app.screen.password_entry, "wrong")
    click(app, "Delete my account")
    assert message(app) == "Wrong password"

    type_into(app.screen.password_entry, "alice-pass")
    click(app, "Delete my account")
    assert screen_name(app) == "WelcomeScreen"
    assert "deleted" in message(app)
    assert not ClientList().find(Client("alice"))[0]


# --- Leaderboard and menu ---------------------------------------------------------------

def table_rows(app):
    table = app.screen.table
    return [(table.item(row, "values"), table.item(row, "tags")) for row in table.get_children()]


def test_menu_shows_the_players_high_score(app):
    log_in(app)
    assert app.screen.high_score_label.cget("text") == "Your high score: 50"


def test_high_score_on_the_menu_updates_after_a_game(app, monkeypatch):
    monkeypatch.setattr(game, "main", lambda *args, **kwargs: 75)
    log_in(app)
    click(app, "Play")
    assert app.screen.high_score_label.cget("text") == "Your high score: 75"


def test_log_out_returns_to_the_welcome_screen(app):
    log_in(app)
    click(app, "Log out")
    assert screen_name(app) == "WelcomeScreen"
    assert app.client is None


def test_leaderboard_table_highlights_the_logged_in_player(app):
    log_in(app)
    click(app, "Leaderboard")
    rows = table_rows(app)
    assert [values for values, _ in rows] == [
        ("1", "alice (you)", "50"), ("2", "carol", "0"), ("2", "dan", "0")]
    assert rows[0][1] == ("you",)
    assert rows[1][1] == ""


def test_leaderboard_adds_your_row_when_you_are_outside_the_top_ten(app):
    clients = ClientList()
    for i in range(12):
        player = Client.new(f"p{i:02}", "password1", "Q?", "a")
        player.highest_score = 100 + i
        clients.add_client(player)
    log_in(app, username="dan", password="abc")
    click(app, "Leaderboard")
    rows = table_rows(app)
    assert len(rows) == 12  # top ten, a gap row, then you
    assert rows[10][0][0] == "…"
    assert rows[11] == (("14", "dan (you)", "0"), ("you",))


def test_volume_slider_saves_the_volume(app):
    log_in(app)
    assert app.screen.volume_label.cget("text") == "60%"  # the default
    app.screen.volume.set(25)
    app.screen.on_volume_change()
    assert settings.load_volume() == 0.25
    assert app.screen.volume_label.cget("text") == "25%"
    app.screen.volume.set(0)
    app.screen.on_volume_change()
    assert app.screen.volume_label.cget("text") == "Off"


def test_play_passes_the_high_score_and_volume_to_the_game(app, monkeypatch):
    received = {}

    def fake_game(**kwargs):
        received.update(kwargs)
        return 0
    monkeypatch.setattr(game, "main", fake_game)
    settings.save_volume(0.4)
    log_in(app)
    click(app, "Play")
    assert received == {"high_score": 50, "volume": 0.4}
