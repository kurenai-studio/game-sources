"""Screens shown after logging in: the menu, leaderboard, how to play and delete account."""
import tkinter as tk
from tkinter import ttk

from . import game, settings, theme
from .accounts import ClientList
from .widgets import Screen

LEADERBOARD_SIZE = 10  # top players shown (plus your own row if you're further down)
NOT_RANKED = "-"

_POINT_REWARDS = [reward for reward in game.MYSTERY_REWARDS if reward != game.EXTRA_LIFE]
HOW_TO_PLAY = (
    "Move with the LEFT and RIGHT arrow keys and shoot with SPACE",
    "Do NOT get hit by the enemies' bullets",
    f"You have {game.PLAYER_LIVES} lives. After losing one, your ship blinks and can't be hit for a moment",
    "You have infinite bullets (it works best if you hold down SPACE)",
    "Aim: destroy all the enemies",
    f"{game.ALIEN_POINTS} points for every enemy destroyed",
    f"The SPECIAL enemy gives either an extra life or {min(_POINT_REWARDS)}-{max(_POINT_REWARDS)} points",
    "The invaders drop closer each time they reach the edge. Don't let them land!",
    "The game is endless: each new wave moves and shoots a bit faster",
    "Press P to pause, M to turn the sound on or off, and ESC to stop playing",
    "The most points wins",
)


class MenuScreen(Screen):
    """The main menu for a logged-in player."""

    def build(self):
        client = self.app.client
        self.add_title("SPACE INVADERS")
        ttk.Label(self.body, text=f"Welcome, {client.username}!", style="Heading.TLabel").pack()
        self.high_score_label = ttk.Label(self.body, text=f"Your high score: {client.highest_score}",
                                          style="Muted.TLabel")
        self.high_score_label.pack(pady=(theme.px(2), theme.px(theme.GAP)))
        self.add_button("Play", self.app.play_game, primary=True)
        self.add_button("Leaderboard", lambda: self.app.show("leaderboard"))
        self.add_button("How to play", lambda: self.app.show("how_to_play"))
        self.add_button("Delete account", lambda: self.app.show("delete_account"))
        self.add_volume_slider()
        self.add_message_line()
        self.add_back_button(self.app.log_out, text="Log out")
        self.back_command = None  # Escape shouldn't log the player out


    def add_volume_slider(self):
        """A slider for the game's volume, saved as soon as it changes."""
        row = ttk.Frame(self.body)
        row.pack(fill="x", pady=(theme.px(theme.GAP * 2), 0))
        ttk.Label(row, text="Volume", style="Muted.TLabel").pack(side="left")
        self.volume_label = ttk.Label(row, text="", style="Muted.TLabel")
        self.volume_label.pack(side="right")
        self.volume = tk.DoubleVar(value=round(settings.load_volume() * 100))
        self.volume_slider = ttk.Scale(self.body, from_=0, to=100, variable=self.volume,
                                       command=self.on_volume_change)
        self.volume_slider.pack(fill="x", pady=(theme.px(theme.FIELD_GAP), 0))
        self.on_volume_change()

    def on_volume_change(self, value=None):
        percent = round(self.volume.get())
        self.volume_label.configure(text="Off" if percent == 0 else f"{percent}%")
        settings.save_volume(percent / 100)


class LeaderboardScreen(Screen):
    """The top players in a table, with the logged-in player's row highlighted."""

    COLUMNS = (("rank", "Rank", 60, "center"), ("player", "Player", 220, "w"),
               ("score", "High score", 120, "e"))

    def build(self):
        self.add_title("Leaderboard")
        you = self.app.client.username
        rows = ClientList().leaderboard(LEADERBOARD_SIZE, username=you)

        self.table = ttk.Treeview(self.body, columns=[c[0] for c in self.COLUMNS], show="headings",
                                  height=max(len(rows) + 1, 1), selectmode="none", takefocus=False)
        for column, heading, width, anchor in self.COLUMNS:
            self.table.heading(column, text=heading, anchor=anchor)
            self.table.column(column, width=theme.px(width), anchor=anchor, stretch=column == "player")
        self.table.tag_configure("you", background=theme.HIGHLIGHT, foreground=theme.TEXT)
        self.table.tag_configure("gap", foreground=theme.MUTED)

        for position, (rank, player) in enumerate(rows):
            if position == LEADERBOARD_SIZE:  # the player's own row, further down the table
                self.table.insert("", "end", values=("…", "", ""), tags=("gap",))
            tags = ("you",) if player.username == you else ()
            label = f"{player.username} (you)" if player.username == you else player.username
            self.table.insert("", "end", values=(rank, label, player.highest_score), tags=tags)
        if not rows:
            self.table.insert("", "end", values=(NOT_RANKED, "No scores yet", ""))
        self.table.pack(fill="x", pady=(theme.px(theme.GAP), 0))
        self.add_back_button(lambda: self.app.show("menu"))


class HowToPlayScreen(Screen):
    """The rules of the game."""

    def build(self):
        self.add_title("How to play")
        for line in HOW_TO_PLAY:
            ttk.Label(self.body, text="•  " + line, wraplength=theme.px(theme.TEXT_WIDTH)).pack(
                fill="x", pady=theme.px(3))
        self.add_back_button(lambda: self.app.show("menu"))


class DeleteAccountScreen(Screen):
    """Permanently delete the logged-in player's account (asks for their password)."""

    def build(self):
        self.add_title("Delete account")
        ttk.Label(self.body, text="This permanently deletes your account and your scores.",
                  style="Muted.TLabel", wraplength=theme.px(theme.TEXT_WIDTH),
                  justify="center").pack(pady=(0, theme.px(theme.GAP)))
        self.password_entry = self.add_field("Enter your password to confirm", hidden=True)
        self.add_password_toggle()
        self.add_button("Delete my account", self.submit, primary=True)
        self.add_message_line()
        self.add_back_button(lambda: self.app.show("menu"))
        self.submit_command = self.submit

    def submit(self):
        clients = ClientList()
        found, index = clients.find(self.app.client)
        if not found or not clients.clients[index].check_password(self.password_entry.get()):
            self.password_entry.delete(0, "end")
            self.show_error("Wrong password")
            return
        clients.delete_client(clients.clients[index])
        self.app.log_out(message="Your account has been deleted.")
