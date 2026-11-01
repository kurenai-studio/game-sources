# games/rock_paper_scissors/game.py
import random
import time

from python_game_suite.common.game_template import Game

WEAPONS = {
    "r": "rock",
    "p": "paper",
    "s": "scissors",
}


class RockPaperScissorsGame(Game):
    """A class representing the Rock, Paper, Scissors game."""

    @staticmethod
    def get_name():
        """Return the display name of the game."""
        return "Rock, Paper, Scissors"

    def run(self):
        """Run the main game loop."""
        print("\n--- Welcome to Rock, Paper, Scissors! ---")
        print("press Q to quit \n")
        time.sleep(1)

        while True:
            self._play_round()
            if not self._play_again():
                print("Bye, Thanks for playing!")
                break

    def _get_player_move(self):
        """Gets the player's move."""
        while True:
            weapon = input("(R)ock, (P)aper, or (S)scissors?: ").lower()
            if weapon == "q":
                return None  # Signal to quit
            if weapon in WEAPONS:
                return WEAPONS.get(weapon)
            print("Invalid input. Please try again.")

    def _play_round(self):
        """Plays a single best-of-five round of the game."""
        player_score = 0
        computer_score = 0
        ties = 0
        rounds = 0

        while player_score < 3 and computer_score < 3:
            rounds += 1
            print(f"\n--- Round {rounds} ---")

            player_move = self._get_player_move()
            if player_move is None:
                # Player chose to quit mid-game
                return

            computer_move = WEAPONS.get(random.choice(list(WEAPONS)))

            print(f"\nPlayer: {player_move}")
            print(f"Computer: {computer_move}")

            if player_move == computer_move:
                print("It's a Tie!")
                ties += 1
            elif (
                (player_move == "rock" and computer_move == "scissors")
                or (player_move == "paper" and computer_move == "rock")
                or (player_move == "scissors" and computer_move == "paper")
            ):
                print("You win this round!")
                player_score += 1
            else:
                print("You lose this round!")
                computer_score += 1

            print(f"Score: Player {player_score}, Computer {computer_score}")

        print("\n-----------------------")
        if player_score > computer_score:
            print(f"You won the match in {rounds} rounds!")
        else:
            print(f"The Computer won the match in {rounds} rounds.")
        print(
            f"Final Score: You: {player_score}, Computer: {computer_score}, Ties: {ties}"
        )

    def _play_again(self):
        """Asks the user if they want to play another match."""
        while True:
            choice = input("\nPlay another match? (y/n): ").lower().strip()
            if choice in ["y", "n"]:
                return choice == "y"
            print("Invalid input. Please enter 'y' or 'n'.")
