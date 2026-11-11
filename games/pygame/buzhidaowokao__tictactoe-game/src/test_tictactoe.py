# -*- coding: utf-8 -*-
"""
test_tictactoe.py —— 井字棋核心逻辑自测（纯逻辑，无需 GUI/pygame）

运行：python test_tictactoe.py
"""

import random

from tictactoe import TicTacToe, winner, available_moves, best_move, LINES


def main():
    failed = 0

    def check(name, ok, detail=''):
        nonlocal failed
        failed += not ok
        mark = 'PASS' if ok else 'FAIL'
        print(f'[{mark}] {name}' + (f'（{detail}）' if detail else ''))

    # ---- 1. 胜负判定：行 / 对角线都能检出并返回连线 ----
    # 斜线 (2,4,6) = O,O,O
    ok = (winner(['X', 'X', 'X', None, 'O', None, 'O', None, None]) == ('X', LINES[0])
          and winner(['X', 'X', 'O', 'O', 'O', 'X', 'O', None, None]) == ('O', LINES[7]))
    check('胜负判定：行与对角线', ok)

    # ---- 2. 平局判定 ----
    draw = ['X', 'O', 'X', 'X', 'O', 'O', 'O', 'X', 'X']
    ok = winner(draw) is None and not available_moves(draw)
    g = TicTacToe()
    g.board = draw[:]
    g._check_end()
    ok = ok and g.finished and g.result == ('draw', None) and g.draws == 1
    check('平局：棋满无胜负时正确记为平局', ok)

    # ---- 3. 双人模式：轮流落子、占位拒绝 ----
    g = TicTacToe(mode='pvp')
    ok = (g.play(0) and g.board[0] == 'X'          # X 先手
          and not g.play(0)                        # 占位不能重复落子
          and g.play(4) and g.board[4] == 'O'      # 轮到 O
          and g.current == 'X')                    # 自动轮换回 X
    check('双人模式：X/O 轮流且占位被拒', ok)

    # ---- 4. 人机模式：AI 回合人类无法落子 ----
    g = TicTacToe(mode='hard')
    g.play(4)                       # 玩家落子 → 轮到 AI
    ok = not g.play(0)              # AI 回合人类落子被拒
    g.ai_move()
    ok = ok and g.current == 'X'    # AI 落子后回到玩家
    check('人机模式：回合控制正确', ok)

    # ---- 5. 困难 AI：能一步取胜时绝不手软 ----
    g = TicTacToe(mode='hard')
    g.board = ['O', 'O', None, 'X', 'X', None, None, None, None]
    g.current = 'O'
    g.ai_move()
    check('困难 AI：抓住制胜点', g.board[2] == 'O')

    # ---- 6. 困难 AI：及时封堵玩家的威胁 ----
    g = TicTacToe(mode='hard')
    g.board = ['X', 'X', None, 'O', None, None, None, None, None]
    g.current = 'O'
    g.ai_move()
    check('困难 AI：封堵必败点', g.board[2] == 'O')

    # ---- 7. 困难 AI 必不败：与随机玩家对战 300 局，AI 不输一局 ----
    losses = 0
    rng = random.Random(2024)
    for _ in range(300):
        g = TicTacToe(mode='hard', seed=rng.randint(0, 10**9))
        while not g.finished:
            if g.human_turn:
                g.play(rng.choice(available_moves(g.board)))  # 玩家随机走
            else:
                g.ai_move()
        if g.result[0] == 'X':
            losses += 1
    check('困难 AI 必不败：随机玩家 300 局全不败', losses == 0, f'AI 输 {losses} 局')

    # ---- 8. minimax 自我对弈必然平局（双方都完美） ----
    board = [None] * 9
    turn = 'X'
    while winner(board) is None and available_moves(board):
        board[best_move(board, turn)] = turn
        turn = 'O' if turn == 'X' else 'X'
    check('完美自弈：必然平局', winner(board) is None)

    # ---- 9. 比分统计与重开 ----
    g = TicTacToe(mode='hard')
    g.board = ['X', 'X', 'X', None, 'O', None, 'O', None, None]
    g._check_end()
    ok = g.x_wins == 1 and g.finished
    g.reset()
    ok = ok and g.board == [None] * 9 and g.x_wins == 1   # 保留比分
    g.reset(keep_score=False)
    ok = ok and g.x_wins == 0
    check('重开：棋盘清空、比分可保留可清零', ok)

    print('-' * 46)
    if failed:
        print(f'共 {failed} 项未通过！')
        raise SystemExit(1)
    print('全部测试通过 ✔')


if __name__ == '__main__':
    main()
