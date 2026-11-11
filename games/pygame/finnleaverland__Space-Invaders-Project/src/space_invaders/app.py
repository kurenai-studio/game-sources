"""The main window. It shows one screen at a time and starts games."""
from . import game, settings, theme
from .accounts import ClientList
from .login_screen import LoginScreen, RegisterScreen, ResetPasswordScreen, WelcomeScreen
from .menu_screen import DeleteAccountScreen, HowToPlayScreen, LeaderboardScreen, MenuScreen

WINDOW_TITLE = "Space Invaders"
WINDOW_WIDTH = 520  # at 96 DPI; scaled for the real screen
WINDOW_HEIGHT = 700

SCREENS = {
    "welcome": WelcomeScreen,
    "login": LoginScreen,
    "register": RegisterScreen,
    "reset_password": ResetPasswordScreen,
    "menu": MenuScreen,
    "leaderboard": LeaderboardScreen,
    "how_to_play": HowToPlayScreen,
    "delete_account": DeleteAccountScreen,
}


class App:
    """The single window that every screen is shown in."""

    def __init__(self, root=None):
        """Create the window, or reuse an existing themed root window (used by the tests)."""
        self.root = root or theme.new_root(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT)
        self.client = None  # the logged-in player
        self.screen = None
        # Keys are bound once to the window and passed on to whichever screen is showing
        for key in ("<Return>", "<KP_Enter>"):
            self.root.bind(key, lambda event: self.screen.handle_return(event))
        self.root.bind("<Escape>", lambda event: self.screen.handle_escape(event))
        self.show("welcome")

    def run(self):
        """Show the window and wait for the player."""
        self.root.mainloop()

    def quit(self):
        self.root.destroy()

    def show(self, name, **options):
        """Replace the current screen with another one, e.g. show("login")."""
        if self.screen is not None:
            self.screen.destroy()
        self.screen = SCREENS[name](self.root, self, **options)
        self.screen.pack(fill="both", expand=True)
        self.screen.on_show()

    def log_in(self, client):
        self.client = client
        self.show("menu")

    def log_out(self, message=None):
        self.client = None
        self.show("welcome", message=message)

    def play_game(self):
        """Hide the window, play one game, save the score and come back to the menu."""
        self.root.withdraw()
        try:
            score = game.main(high_score=self.client.highest_score,
                              volume=settings.load_volume())
        finally:
            self.root.deiconify()
            self.root.focus_force()
        self.save_score(score)
        self.show("menu")

    def save_score(self, score):
        """Save a finished game's score and reload the logged-in player's details."""
        clients = ClientList()
        found, index = clients.find(self.client)
        if found:
            player = clients.clients[index]
            player.score = score
            clients.update_player_in_list(player)
            self.client = player


def main():
    """Open the game's main window."""
    App().run()
