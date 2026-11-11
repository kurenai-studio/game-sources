# -*- coding: utf-8 -*-
"""
《井字棋》主程序 —— Python + Pygame 实现

三种模式：
    双人对战    X / O 轮流鼠标点击落子
    人机·简单   电脑随机走子，适合新手练手
    人机·困难   电脑使用 minimax 完全搜索，永远不可能被战胜（最好成绩是平局）

按键：1/2/3 切换模式 · R 重开 · ESC 退出；终局后点击棋盘即可再来一局。

命令行参数：
    python main.py          正常启动
    python main.py --smoke  自测模式：无窗口模拟运行并生成界面预览图
"""

import os
import sys

_ROOT = os.path.dirname(os.path.abspath(__file__))

import pygame

from tictactoe import TicTacToe
from renderer import Renderer, WINDOW_W, WINDOW_H

SMOKE_FRAMES = 150      # --smoke 模式模拟的总帧数
SMOKE_SHOT_AT = 110     # 第几帧保存界面预览图


def run(smoke=False):
    if smoke:
        os.environ.setdefault('SDL_VIDEODRIVER', 'dummy')  # 无窗口自测

    pygame.init()
    screen = pygame.display.set_mode((WINDOW_W, WINDOW_H))
    pygame.display.set_caption('井字棋 Tic-Tac-Toe')

    game = TicTacToe(mode='hard')   # 默认人机·困难
    renderer = Renderer(screen)
    clock = pygame.time.Clock()
    frame = 0

    if smoke:
        # 自测：预演一局人机对弈（玩家先占中心，电脑 minimax 应对）
        game.play(4)
        game.ai_move()
        game.play(0)
        game.ai_move()
        game.play(8)
        game.ai_move()

    running = True
    while running:
        clock.tick(60)
        frame += 1

        # ---------- 事件处理 ----------
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                running = False
            elif e.type == pygame.KEYDOWN:
                if e.key == pygame.K_ESCAPE:
                    running = False
                elif e.key == pygame.K_r:
                    game.reset()
                elif e.key in (pygame.K_1, pygame.K_2, pygame.K_3):
                    game.mode = ('pvp', 'easy', 'hard')[e.key - pygame.K_1]
                    game.reset()
                elif e.key == pygame.K_SPACE and game.finished:
                    game.reset()
            elif e.type == pygame.MOUSEMOTION:
                renderer.hover = renderer.cell_at(*e.pos)
            elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
                mode = renderer.button_at(*e.pos)
                if mode:                      # 点到模式按钮：切换并重开本局
                    if mode != game.mode:
                        game.mode = mode
                        game.reset()
                    continue
                pos = renderer.cell_at(*e.pos)
                if pos is None:
                    continue
                if game.finished:             # 终局后点棋盘 = 再来一局
                    game.reset()
                elif game.human_turn:
                    if game.play(pos) and game.mode != 'pvp':
                        game.ai_move()        # 人机模式：玩家落子后电脑立即回应

        renderer.draw(game)

        if smoke:
            if frame == SMOKE_SHOT_AT:
                pygame.image.save(screen, os.path.join(_ROOT, '界面预览.png'))
            if frame >= SMOKE_FRAMES:
                print(f'--smoke 自测完成：模拟 {frame} 帧，'
                      f'X胜 {game.x_wins} / O胜 {game.o_wins} / 平局 {game.draws}，'
                      f'预览图已保存为 界面预览.png。')
                break

    pygame.quit()
    return 0


def main():
    smoke = '--smoke' in sys.argv[1:]
    print('=' * 46)
    print('  《井字棋》 Tic-Tac-Toe (Python + Pygame)')
    print('  鼠标点击落子 · 1/2/3 切换模式')
    print('  双人对战 / 人机·简单 / 人机·困难(必不败)')
    print('  R 重开 · ESC 退出')
    print('=' * 46)
    sys.exit(run(smoke=smoke))


if __name__ == '__main__':
    main()
