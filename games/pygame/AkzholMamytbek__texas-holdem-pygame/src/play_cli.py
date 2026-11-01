"""Play the engine in the terminal. Run: python3 play_cli.py"""
import random

from ai import make_opponents
from game import Game, Player


def random_bot(game):
    """Random opponent, used by the tests: mostly checks/calls, sometimes raises or folds."""
    legal = game.legal_actions()
    roll = random.random()
    if legal["can_raise"] and roll < 0.15:
        size = random.choice([2, 3, 4]) * game.bb + game.current_bet
        return "raise", size
    if legal["can_check"]:
        return "check", 0
    if roll < 0.25 and legal["to_call"] > game.bb:
        return "fold", 0
    return "call", 0


def show_table(game, you):
    board = " ".join(map(str, game.board)) or "(none)"
    print(f"\n  Board: {board}    Pot: {game.pot}")
    for p in game.players:
        status = "folded" if p.folded else ("ALL-IN" if p.all_in else "")
        print(f"  {p.name:7} chips {p.chips:5}  bet {p.bet:4}  {status}")
    print(f"  Your hand: {' '.join(map(str, you.hole))}")


def ask_human(game, you):
    show_table(game, you)
    legal = game.legal_actions()
    options = ["[f]old"]
    options.append("[c]heck" if legal["can_check"] else f"[c]all {legal['to_call']}")
    if legal["can_raise"]:
        word = "bet" if legal["is_bet"] else "raise to"
        options.append(f"[r] <amount> {word} ({legal['min_raise_to']}-{legal['max_raise_to']})")
    while True:
        cmd = input("  " + "  ".join(options) + " > ").strip().lower().split()
        if not cmd:
            continue
        if cmd[0] == "f":
            return "fold", 0
        if cmd[0] == "c":
            return ("check", 0) if legal["can_check"] else ("call", 0)
        if cmd[0] == "r" and legal["can_raise"]:
            if len(cmd) == 2 and cmd[1].isdigit():
                return "raise", int(cmd[1])
            if len(cmd) == 2 and cmd[1] == "all":
                return "raise", legal["max_raise_to"]
            print("  Usage: r 60   (or 'r all' for all-in)")
            continue
        print("  Didn't understand that.")


def main():
    you = Player("You", 1000, is_human=True)
    game = Game([you, Player("Shark", 1000), Player("Dealer", 1000)])
    bots = make_opponents()
    seen = 0
    while not game.game_over:
        game.start_hand()
        while True:
            for msg in game.log[seen:]:
                print(msg)
            seen = len(game.log)
            if game.hand_over:
                break
            p = game.current_player
            action, amount = ask_human(game, you) if p.is_human else bots[p.name].decide(game)
            game.act(action, amount)
        print("  Chips:", ", ".join(f"{p.name} {p.chips}" for p in game.players))
        if input("\nEnter for next hand, q to quit > ").strip().lower() == "q":
            return
    winner = max(game.players, key=lambda p: p.chips)
    print(f"\nGame over! {winner.name} wins with {winner.chips} chips.")


if __name__ == "__main__":
    main()
