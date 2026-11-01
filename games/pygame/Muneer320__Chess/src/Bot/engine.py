"""Move selection for the chess bot.

Rules (legality, check, mate, draws) all come from python-chess; this module
only decides which legal move the bot plays.

- easy:   a random legal move
- medium: the most valuable capture available, otherwise a random move
- hard:   a 3-ply alpha-beta search over material plus simple positional terms
"""

import random

import chess

PIECE_VALUES = {
    chess.PAWN: 100,
    chess.KNIGHT: 320,
    chess.BISHOP: 330,
    chess.ROOK: 500,
    chess.QUEEN: 900,
    chess.KING: 0,
}

MATE_SCORE = 100_000
HARD_DEPTH = 3

# Small bonus for occupying or controlling the centre.
CENTER = {chess.D4, chess.E4, chess.D5, chess.E5}
EXTENDED_CENTER = {
    chess.C3, chess.D3, chess.E3, chess.F3,
    chess.C4, chess.F4, chess.C5, chess.F5,
    chess.C6, chess.D6, chess.E6, chess.F6,
}


def evaluate(board: chess.Board) -> int:
    """Static score from White's point of view, in centipawns (material + placement)."""
    score = 0
    for square, piece in board.piece_map().items():
        value = PIECE_VALUES[piece.piece_type]
        if piece.piece_type in (chess.PAWN, chess.KNIGHT, chess.BISHOP):
            if square in CENTER:
                value += 20
            elif square in EXTENDED_CENTER:
                value += 8
        if piece.piece_type == chess.PAWN:
            # Reward advancing pawns a little.
            rank = chess.square_rank(square)
            value += 4 * (rank if piece.color == chess.WHITE else 7 - rank)
        score += value if piece.color == chess.WHITE else -value
    return score


def _ordered_moves(board: chess.Board):
    """Captures and promotions first, which makes alpha-beta prune far more."""
    def key(move):
        if move.promotion:
            return 0
        if board.is_capture(move):
            victim = board.piece_at(move.to_square)
            return 1 - (PIECE_VALUES[victim.piece_type] if victim else 100) / 1000
        return 2
    return sorted(board.legal_moves, key=key)


def _alphabeta(board: chess.Board, depth: int, alpha: int, beta: int) -> int:
    if depth == 0:
        return evaluate(board)
    moves = _ordered_moves(board)
    if not moves:
        if board.is_check():
            # Checkmate: prefer faster mates and slower losses.
            return (-MATE_SCORE - depth) if board.turn == chess.WHITE else (MATE_SCORE + depth)
        return 0  # stalemate
    if board.is_insufficient_material() or board.halfmove_clock >= 100:
        return 0
    maximizing = board.turn == chess.WHITE
    best = -MATE_SCORE * 2 if maximizing else MATE_SCORE * 2
    for move in moves:
        board.push(move)
        score = _alphabeta(board, depth - 1, alpha, beta)
        board.pop()
        if maximizing:
            best = max(best, score)
            alpha = max(alpha, score)
        else:
            best = min(best, score)
            beta = min(beta, score)
        if beta <= alpha:
            break
    return best


def search_best_move(board: chess.Board, depth: int = HARD_DEPTH):
    """Return the best move for the side to move, breaking ties randomly."""
    moves = list(board.legal_moves)
    if not moves:
        return None
    maximizing = board.turn == chess.WHITE
    scored = []
    alpha, beta = -MATE_SCORE * 3, MATE_SCORE * 3
    for move in _ordered_moves(board):
        board.push(move)
        if board.can_claim_threefold_repetition():
            score = 0  # walking into a repetition draw
        else:
            score = _alphabeta(board, depth - 1, alpha, beta)
        board.pop()
        scored.append((score, move))
    target = max(s for s, _ in scored) if maximizing else min(s for s, _ in scored)
    return random.choice([m for s, m in scored if s == target])


def choose_move(board: chess.Board, difficulty: str):
    moves = list(board.legal_moves)
    if not moves:
        return None
    if difficulty == "easy":
        return random.choice(moves)
    if difficulty == "medium":
        captures = [m for m in moves if board.is_capture(m)]
        if not captures:
            return random.choice(moves)

        def captured_value(move):
            if board.is_en_passant(move):
                return PIECE_VALUES[chess.PAWN]
            return PIECE_VALUES[board.piece_at(move.to_square).piece_type]

        best = max(captured_value(m) for m in captures)
        return random.choice([m for m in captures if captured_value(m) == best])
    if difficulty == "hard":
        return search_best_move(board)
    raise ValueError(f"Unknown difficulty: {difficulty!r}")


def game_over_message(board: chess.Board, vs_bot: bool):
    """Human-readable result, or None while the game is still on.

    Threefold repetition and the fifty-move rule are claimed automatically.
    """
    outcome = board.outcome(claim_draw=True)
    if outcome is None:
        return None
    if outcome.termination == chess.Termination.CHECKMATE:
        if vs_bot:
            return "Checkmate! You Win!" if outcome.winner == chess.WHITE else "Checkmate! Bot Wins!"
        return "Checkmate! White Wins!" if outcome.winner == chess.WHITE else "Checkmate! Black Wins!"
    return {
        chess.Termination.STALEMATE: "Stalemate! It's a Draw!",
        chess.Termination.INSUFFICIENT_MATERIAL: "Draw: Insufficient Material",
        chess.Termination.SEVENTYFIVE_MOVES: "Draw: 75-move Rule",
        chess.Termination.FIVEFOLD_REPETITION: "Draw by Repetition",
        chess.Termination.THREEFOLD_REPETITION: "Draw by Repetition",
        chess.Termination.FIFTY_MOVES: "Draw: 50-move Rule",
    }.get(outcome.termination, "Draw!")
