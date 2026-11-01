# games/mastermind/game.py
import random

from python_game_suite.common.game_template import Game


class MastermindGame(Game):
    """A class representing the game Mastermind."""

    @staticmethod
    def get_name():
        """Return the display name of the game."""
        return "Mastermind"

    def run(self):
        """Run the main game loop."""
        print("--- Welcome to Mastermind! ---")
        print("I'm thinking of a 4-digit number. Try to guess it.")
        print("Clues: 'O' means a correct digit in the correct position.")
        print("       'X' means a correct digit in the wrong position.")

        while True:
            secret_code = self._generate_code()
            self._play_round(secret_code)
            if not self._play_again():
                print("Thanks for playing Mastermind!")
                break

    def _generate_code(self):
        """Generates a random 4-digit code with unique digits."""
        digits = [str(i) for i in range(10)]
        random.shuffle(digits)
        return "".join(digits[:4])

    def _get_guess(self):
        """Prompts the user for a guess and validates it."""
        while True:
            guess = input("\nEnter your 4-digit guess: ").strip()
            if len(guess) == 4 and guess.isdigit() and len(set(guess)) == 4:
                return guess
            print("Invalid guess. Please enter a 4-digit number with unique digits.")

    def _evaluate_guess(self, secret_code, guess):
        """Evaluates the guess and returns clues."""
        clues = []
        for i in range(4):
            if guess[i] == secret_code[i]:
                clues.append("O")
            elif guess[i] in secret_code:
                clues.append("X")

        random.shuffle(clues)
        return "".join(clues)

    def _play_round(self, secret_code):
        """Plays one full round of the game."""
        attempts = 0
        max_attempts = 10

        while attempts < max_attempts:
            attempts += 1
            print(f"\n--- Attempt {attempts}/{max_attempts} ---")

            guess = self._get_guess()
            if guess == secret_code:
                print(
                    f"Congratulations! You guessed the code {secret_code} in {attempts} attempts."
                )
                return

            clues = self._evaluate_guess(secret_code, guess)
            print(f"Clue: {clues}")

        print(f"\nGame over! You've used all {max_attempts} attempts.")
        print(f"The secret code was {secret_code}.")

    def _play_again(self):
        """Asks the user if they want to play another round."""
        while True:
            choice = input("\nPlay again? (y/n): ").lower().strip()
            if choice in ["y", "n"]:
                return choice == "y"
            print("Invalid input. Please enter 'y' or 'n'.")
