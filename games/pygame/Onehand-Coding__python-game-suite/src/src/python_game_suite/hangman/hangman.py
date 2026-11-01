import string

from python_game_suite.common.game_template import Game

from .words import getWord  # The relative import is correct


class HangmanGame(Game):
    """A class representing the game Hangman."""

    @staticmethod
    def get_name():
        """Return the display name of the game."""
        return "Hangman"

    def run(self):
        """Run the main game loop."""
        print("--- Welcome to Hangman! ---")
        while True:
            self._play_round()
            if not self._play_again():
                print("\nThanks for playing Hangman!")
                break

    def _get_word_length_from_user(self):
        """Prompts the user to select a valid word length."""
        while True:
            try:
                length = int(input("Choose a word length (e.g., 5, 6, 7): "))
                if length > 0:
                    # We can immediately check if a word of this length exists
                    getWord(length)
                    return length
                else:
                    print("Please enter a positive number.")
            except ValueError as e:
                # Catches both non-integer input and errors from getWord
                print(f"Invalid choice. {e}. Please try again.")
            except TypeError:
                print("Invalid input. Please enter a number.")

    def _display_hangman(self, tries):
        """Displays the hangman ASCII art based on the number of tries left."""
        stages = [  # Final state: head, torso, both arms, both legs
            """
                       --------
                       |      |
                       |      O
                       |     \\|/
                       |      |
                       |     / \\
                       -
                    """,
            # Head, torso, both arms, one leg
            """
                       --------
                       |      |
                       |      O
                       |     \\|/
                       |      |
                       |     /
                       -
                    """,
            # Head, torso, both arms
            """
                       --------
                       |      |
                       |      O
                       |     \\|/
                       |      |
                       |
                       -
                    """,
            # Head, torso, one arm
            """
                       --------
                       |      |
                       |      O
                       |     \\|
                       |      |
                       |
                       -
                    """,
            # Head and torso
            """
                       --------
                       |      |
                       |      O
                       |      |
                       |      |
                       |
                       -
                    """,
            # Head
            """
                       --------
                       |      |
                       |      O
                       |
                       |
                       |
                       -
                    """,
            # Initial empty state
            """
                       --------
                       |      |
                       |
                       |
                       |
                       |
                       -
                    """,
        ]
        print(stages[tries])

    def _play_round(self):
        """Plays one full round of Hangman."""
        word_length = self._get_word_length_from_user()
        word = getWord(word_length).upper()
        word_letters = set(word)  # Letters in the word
        alphabet = set(string.ascii_uppercase)
        used_letters = set()  # Letters the user has guessed

        tries = 6

        while len(word_letters) > 0 and tries > 0:
            # Display current game state
            print("\n" + "=" * 20)
            self._display_hangman(tries)
            print(f"You have {tries} tries left.")
            print("Used letters: ", " ".join(sorted(list(used_letters))))

            # Display the current word (e.g., W - R D)
            word_list = [letter if letter in used_letters else "-" for letter in word]
            print("Current word: ", " ".join(word_list))

            # Get user input
            user_letter = input("Guess a letter: ").upper()
            if user_letter in alphabet - used_letters:
                used_letters.add(user_letter)
                if user_letter in word_letters:
                    word_letters.remove(user_letter)
                    print(f"Good guess! '{user_letter}' is in the word.")
                else:
                    tries -= 1
                    print(f"Sorry, '{user_letter}' is not in the word.")

            elif user_letter in used_letters:
                print("You have already used that letter. Please try again.")
            else:
                print("Invalid character. Please enter a letter.")

        # Game conclusion
        self._display_hangman(tries)
        if tries == 0:
            print(f"You died, sorry. The word was {word}")
        else:
            print(f"Congratulations! You guessed the word '{word}' correctly!")

    def _play_again(self):
        """Asks the user if they want to play another round."""
        while True:
            choice = input("\nPlay again? (y/n): ").lower().strip()
            if choice in ["y", "n"]:
                return choice == "y"
            print("Invalid input. Please enter 'y' or 'n'.")
