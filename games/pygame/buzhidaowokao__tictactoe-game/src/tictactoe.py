# -*- coding: utf-8 -*-
"""
tictactoe.py —— 井字棋核心逻辑（纯逻辑模块，不依赖 pygame，可独立测试）

包含：棋盘与胜负判定、minimax 完全博弈搜索（困难 AI 必不败）、
随机走子（简单 AI）、比分统计。
"""

import random

# 全部 8 条获胜连线（棋盘格下标 0~8，按行排列）
LINES = [
    (0, 1, 2), (3, 4, 5), (6, 7, 8),   # 三行
    (0, 3, 6), (1, 4, 7), (2, 5, 8),   # 三列
    (0, 4, 8), (2, 4, 6),              # 两斜
]


def other(player):
    """返回另一方"""
    return 'O' if player == 'X' else 'X'


def winner(board):
    """返回 (胜者, 获胜连线) 或 None"""
    for line in LINES:
        a, b, c = line
        if board[a] and board[a] == board[b] == board[c]:
            return board[a], line
    return None


def available_moves(board):
    """所有可落子的格子下标"""
    return [i for i, v in enumerate(board) if v is None]


def best_move(board, player):
    """minimax 全搜索：返回对 player 最优的落点

    打分偏好：赢越早分越高、输越晚分越高，因此 AI 在能赢时绝不拖延，
    在必输时也会坚持最久并优先制造逼平。"""
    best, best_score = None, None
    for pos in available_moves(board):
        board[pos] = player
        score = _minimax(board, player, other(player), 1)
        board[pos] = None
        if best_score is None or score > best_score:
            best, best_score = pos, score
    return best


def _minimax(board, me, turn, depth):
    """站在 me 的视角给局面打分：胜 = 10-depth，负 = depth-10，平 = 0"""
    w = winner(board)
    if w:
        return (10 - depth) if w[0] == me else (depth - 10)
    moves = available_moves(board)
    if not moves:
        return 0
    scores = []
    for pos in moves:
        board[pos] = turn
        scores.append(_minimax(board, me, other(turn), depth + 1))
        board[pos] = None
    return max(scores) if turn == me else min(scores)


class TicTacToe:
    """一局井字棋的状态与操作

    X 总是先手。人机模式下玩家执 X、电脑执 O；
    双人模式下 X 与 O 轮流由两位玩家操作。"""

    HUMAN, AI = 'X', 'O'
    MODES = ('pvp', 'easy', 'hard')   # 双人 / 人机·简单 / 人机·困难

    def __init__(self, mode='hard', seed=None):
        self.rng = random.Random(seed)
        self.mode = mode
        self.x_wins = self.o_wins = self.draws = 0
        self.reset()

    def reset(self, keep_score=True):
        """重开一局（默认保留比分）"""
        self.board = [None] * 9
        self.current = self.HUMAN       # X 先手
        self.finished = False
        self.result = None              # ('X'|'O'|'draw', 获胜连线或 None)
        if not keep_score:
            self.x_wins = self.o_wins = self.draws = 0

    # ---------- 内部 ----------

    def _check_end(self):
        """落子后检查终局并记分"""
        w = winner(self.board)
        if w:
            self.finished = True
            self.result = (w[0], w[1])
            if w[0] == self.HUMAN:
                self.x_wins += 1
            else:
                self.o_wins += 1
        elif not available_moves(self.board):
            self.finished = True
            self.result = ('draw', None)
            self.draws += 1

    # ---------- 落子 ----------

    def play(self, pos):
        """人类玩家在 pos 落子。占位/游戏结束/非人类回合时返回 False"""
        if self.finished or self.board[pos] is not None:
            return False
        if self.mode != 'pvp' and self.current == self.AI:
            return False
        self.board[pos] = self.current
        self._check_end()
        if not self.finished:
            self.current = other(self.current)
        return True

    def ai_move(self):
        """电脑落子一步（简单=随机；困难=minimax 必不败）"""
        if self.finished or self.current != self.AI:
            return False
        if self.mode == 'easy':
            pos = self.rng.choice(available_moves(self.board))
        else:
            pos = best_move(self.board, self.AI)
        self.board[pos] = self.AI
        self._check_end()
        if not self.finished:
            self.current = self.HUMAN
        return True

    @property
    def human_turn(self):
        """当前是否轮到人类点击落子"""
        return not self.finished and (self.mode == 'pvp' or self.current == self.HUMAN)
