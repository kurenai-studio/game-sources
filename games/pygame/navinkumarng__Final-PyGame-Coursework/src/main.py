from core.game import Game
from core.player import Player
from ui.screen import GameUI
from ui.menu import MenuUI

def main():
    while True:
        menu = MenuUI()
        config = menu.run()

        if config is None:
            return

        num_players = config["num_players"]
        cpu_ai = config["cpu_ai"]

        while True:
            players = []
            players.append(Player("You", is_human=True))

            if num_players >= 2:
                players.append(Player("CPU 1", is_human=False, ai_type=cpu_ai[0]))
            if num_players == 3:
                players.append(Player("CPU 2", is_human=False, ai_type=cpu_ai[1]))

            game = Game(players)
            ui = GameUI(game)
            result = ui.run()

            if result == "restart":
                continue
            elif result == "menu":
                break
            else:
                return

if __name__ == "__main__":
    main()
