# main.py
import importlib
import inspect
import pkgutil
import sys

import python_game_suite
from python_game_suite.common.game_template import Game


def discover_games():
    """Finds all Game classes in the 'python_game_suite' package."""
    game_classes = {}

    # The path to the 'python_game_suite' package
    package_path = python_game_suite.__path__
    package_name = python_game_suite.__name__

    # Walk through all modules in the 'python_game_suite' package
    for _, module_name, _ in pkgutil.walk_packages(
        package_path, prefix=f"{package_name}."
    ):
        try:
            # Import the module
            module = importlib.import_module(module_name)

            # Find all classes in the module that are subclasses of Game
            for _, obj in inspect.getmembers(module, inspect.isclass):
                if issubclass(obj, Game) and obj is not Game:
                    game_name = obj.get_name()
                    if game_name:
                        game_classes[game_name] = obj
        except Exception as e:
            print(f"Warning: Could not import module {module_name}: {e}")

    return game_classes


def main():
    """The main entry point for the game suite."""
    print("--- Welcome to the Python Game Suite! ---")

    available_games = discover_games()

    if not available_games:
        print("No games found. Exiting.")
        sys.exit(1)

    while True:
        print("\nPlease choose a game to play:")
        # Create a numbered list of games
        game_map = sorted(available_games)
        for i, name in enumerate(game_map, 1):
            print(f"  {i}. {name}")
        print(f"  {len(game_map) + 1}. Exit")

        try:
            choice = int(input("\nEnter the number of your choice: ").strip())

            if choice == len(game_map) + 1:
                print("\nThanks for playing!")
                break

            if 1 <= choice <= len(game_map):
                selected_game_name = game_map[choice - 1]
                game_class = available_games[selected_game_name]

                # Create an instance of the chosen game and run it
                game_instance = game_class()
                game_instance.run()
            else:
                print("Invalid choice, please try again.")
        except ValueError:
            print("Invalid input. Please enter a number.")
        except KeyboardInterrupt:
            print("\n\nThanks for playing!")
            break


if __name__ == "__main__":
    main()
