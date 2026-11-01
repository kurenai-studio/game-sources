import os
import sys
import time

import chess

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "Bot"))

from engine import choose_move, game_over_message, search_best_move  # noqa: E402


def test_every_difficulty_returns_a_legal_move():
    board = chess.Board()
    for level in ("easy", "medium", "hard"):
        move = choose_move(board, level)
        assert move in board.legal_moves, level


def test_no_move_when_game_is_over():
    board = chess.Board("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")  # stalemate
    assert choose_move(board, "hard") is None


def test_hard_finds_mate_in_one():
    # Back-rank mate: Ra8#
    board = chess.Board("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
    assert search_best_move(board) == chess.Move.from_uci("a1a8")


def test_hard_takes_a_hanging_queen():
    board = chess.Board("4k3/8/8/3q4/8/8/8/3QK3 w - - 0 1")
    assert search_best_move(board) == chess.Move.from_uci("d1d5")


def test_medium_prefers_the_most_valuable_capture():
    # The rook on d4 can take the pawn on d5 or the queen on h4.
    board = chess.Board("4k3/8/8/3p4/3R3q/8/8/4K3 w - - 0 1")
    assert choose_move(board, "medium") == chess.Move.from_uci("d4h4")


def test_unknown_difficulty_is_an_error():
    try:
        choose_move(chess.Board(), "impossible")
    except ValueError:
        return
    raise AssertionError("expected ValueError")


def test_hard_move_is_fast_enough_in_the_opening_and_middlegame():
    for fen in (chess.STARTING_FEN,
                "r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"):
        start = time.perf_counter()
        search_best_move(chess.Board(fen))
        assert time.perf_counter() - start < 10


def test_messages():
    assert game_over_message(chess.Board(), vs_bot=True) is None
    mate = chess.Board("R5k1/5ppp/8/8/8/8/8/6K1 b - - 0 1")
    assert game_over_message(mate, vs_bot=True) == "Checkmate! You Win!"
    assert game_over_message(mate, vs_bot=False) == "Checkmate! White Wins!"
    stalemate = chess.Board("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
    assert "Stalemate" in game_over_message(stalemate, vs_bot=True)


def test_threefold_repetition_is_claimed():
    board = chess.Board()
    for _ in range(2):
        for uci in ("g1f3", "g8f6", "f3g1", "f6g8"):
            board.push_uci(uci)
    assert game_over_message(board, vs_bot=True) == "Draw by Repetition"
