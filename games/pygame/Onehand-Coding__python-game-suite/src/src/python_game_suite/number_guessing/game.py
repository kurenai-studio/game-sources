# games/number_guessing/game.py
import random

from python_game_suite.common.game_template import Game


class NumberGuessingGame(Game):
    """A class representing the Number Guessing game."""

    @staticmethod
    def get_name():
        """Return the display name of the game."""
        return "Number Guessing"

    def run(self):
        """Run the main game loop."""
        print("--- Welcome to the Number Guessing Game! ---")
        while True:
            self._play_round()
            if not self._play_again():
                print("Thanks for playing!")
                break

    def _play_round(self):
        """Plays one round of the number guessing game."""
        print("\nI'm thinking of a number between 1 and 100.")
        secret_number = random.randint(1, 100)
        attempts = 0

        while True:
            try:
                guess = input("Your guess? ")
                # Allow quitting
                if guess.lower() == "q":
                    print(f"The number was {secret_number}. Better luck next time!")
                    return

                guess_num = int(guess)
                attempts += 1

                if guess_num < secret_number:
                    print("Too low!")
                elif guess_num > secret_number:
                    print("Too high!")
                else:
                    print(f"You got it! The number was {secret_number}.")
                    print(f"It took you {attempts} attempts.")
                    break
            except ValueError:
                print("Invalid input. Please enter a number or 'q' to quit.")

    def _play_again(self):
        """Asks the user if they want to play another round."""
        while True:
            choice = input("\nPlay again? (y/n): ").lower().strip()
            if choice in ["y", "n"]:
                return choice == "y"
            print("Invalid input. Please enter 'y' or 'n'.")
