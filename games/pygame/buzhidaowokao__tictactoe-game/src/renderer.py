# -*- coding: utf-8 -*-
"""
renderer.py —— pygame 渲染层

负责绘制：顶部标题与模式切换按钮、3×3 棋盘与网格、X/O 棋子、
悬停高亮、胜利连线、比分面板、终局遮罩与底部提示条。
中文文字使用系统微软雅黑渲染。
"""

import pygame

WINDOW_W, WINDOW_H = 560, 680
BOARD_SIZE = 450                 # 棋盘边长（3 格 × 150）
CELL = BOARD_SIZE // 3
BOARD_X = (WINDOW_W - BOARD_SIZE) // 2
BOARD_Y = 118

X_COLOR = (235, 90, 90)          # X 珊瑚红
O_COLOR = (80, 170, 250)         # O 天蓝
WIN_COLOR = (255, 214, 90)       # 胜利连线金黄
BG = (18, 20, 28)
PANEL_BG = (13, 15, 22)
GRID_COLOR = (58, 64, 84)
TEXT = (232, 234, 242)
TEXT_DIM = (140, 146, 160)

FONT_PATHS = [
    r"C:\Windows\Fonts\msyhbd.ttc",
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
]
_font_cache = {}


def _font(size, bold=False):
    key = (size, bold)
    if key not in _font_cache:
        f = None
        for p in ([FONT_PATHS[0]] if bold else []) + FONT_PATHS:
            try:
                f = pygame.font.Font(p, size)
                break
            except Exception:
                continue
        _font_cache[key] = f or pygame.font.Font(None, size + 10)
    return _font_cache[key]


# 模式切换按钮（文字, 模式代号）
MODE_BUTTONS = [('双人对战', 'pvp'), ('人机·简单', 'easy'), ('人机·困难', 'hard')]


class Renderer:
    """把一局井字棋画到屏幕上"""

    def __init__(self, screen):
        self.screen = screen
        self.hover = None        # 鼠标悬停的格子下标（由 main 每帧更新）

    def cell_rect(self, pos):
        """棋盘格下标 → 屏幕矩形"""
        row, col = divmod(pos, 3)
        return pygame.Rect(BOARD_X + col * CELL, BOARD_Y + row * CELL, CELL, CELL)

    def cell_at(self, mx, my):
        """屏幕坐标 → 棋盘格下标（不在棋盘内返回 None）"""
        if BOARD_X <= mx < BOARD_X + BOARD_SIZE and BOARD_Y <= my < BOARD_Y + BOARD_SIZE:
            return (my - BOARD_Y) // CELL * 3 + (mx - BOARD_X) // CELL
        return None

    def button_at(self, mx, my):
        """屏幕坐标 → 模式按钮代号"""
        for i, (_, mode) in enumerate(MODE_BUTTONS):
            if self._button_rect(i).collidepoint(mx, my):
                return mode
        return None

    def _button_rect(self, i):
        w, h = 112, 38
        return pygame.Rect(WINDOW_W - 3 * (w + 10) - 16 + i * (w + 10), 22, w, h)

    # ---------- 主入口 ----------

    def draw(self, game):
        self.screen.fill(BG)
        self._draw_title(game)
        self._draw_mode_buttons(game)
        self._draw_board(game)
        self._draw_score(game)
        self._draw_hint()
        if game.finished:
            self._draw_overlay(game)
        pygame.display.flip()

    # ---------- 各部分 ----------

    def _draw_title(self, game):
        self.screen.blit(_font(26, bold=True).render('井字棋', True, TEXT), (24, 20))
        self.screen.blit(_font(13).render('Tic-Tac-Toe', True, TEXT_DIM), (26, 52))
        mode_name = dict((m, t) for t, m in MODE_BUTTONS)[game.mode]
        self.screen.blit(_font(15).render(f'当前模式：{mode_name}', True, TEXT_DIM),
                         (24, 76))

    def _draw_mode_buttons(self, game):
        for i, (text, mode) in enumerate(MODE_BUTTONS):
            r = self._button_rect(i)
            active = mode == game.mode
            pygame.draw.rect(self.screen, (46, 66, 110) if active else PANEL_BG,
                             r, border_radius=9)
            pygame.draw.rect(self.screen, (96, 140, 220) if active else GRID_COLOR,
                             r, 1, border_radius=9)
            surf = _font(13, bold=active).render(text, True,
                                                 TEXT if active else TEXT_DIM)
            self.screen.blit(surf, (r.centerx - surf.get_width() // 2,
                                    r.centery - surf.get_height() // 2))

    def _draw_board(self, game):
        board_rect = pygame.Rect(BOARD_X, BOARD_Y, BOARD_SIZE, BOARD_SIZE)
        pygame.draw.rect(self.screen, PANEL_BG, board_rect, border_radius=14)
        pygame.draw.rect(self.screen, GRID_COLOR, board_rect, 1, border_radius=14)

        # 悬停高亮（仅人类回合且格子为空）
        if self.hover is not None and game.human_turn and game.board[self.hover] is None:
            r = self.cell_rect(self.hover).inflate(-10, -10)
            pygame.draw.rect(self.screen, (32, 38, 54), r, border_radius=10)

        # 网格线
        for i in (1, 2):
            pygame.draw.line(self.screen, GRID_COLOR,
                             (BOARD_X + i * CELL, BOARD_Y + 10),
                             (BOARD_X + i * CELL, BOARD_Y + BOARD_SIZE - 10), 4)
            pygame.draw.line(self.screen, GRID_COLOR,
                             (BOARD_X + 10, BOARD_Y + i * CELL),
                             (BOARD_X + BOARD_SIZE - 10, BOARD_Y + i * CELL), 4)

        # 棋子
        for pos, mark in enumerate(game.board):
            if mark:
                self._draw_mark(mark, self.cell_rect(pos))

        # 胜利连线
        if game.result and game.result[1]:
            a, _, c = game.result[1]
            pa = self.cell_rect(a).center
            pc = self.cell_rect(c).center
            color = X_COLOR if game.result[0] == 'X' else O_COLOR
            pygame.draw.line(self.screen, _dim(color), pa, pc, 14)
            pygame.draw.line(self.screen, WIN_COLOR, pa, pc, 6)

    def _draw_mark(self, mark, rect):
        """画一个棋子：X = 两道圆头粗线，O = 粗描边圆"""
        cx, cy = rect.center
        if mark == 'X':
            off = 44
            for dx in (-off, off):
                pygame.draw.line(self.screen, X_COLOR,
                                 (cx - dx, cy - off), (cx + dx, cy + off), 14)
                pygame.draw.line(self.screen, X_COLOR,
                                 (cx - dx, cy + off), (cx + dx, cy - off), 14)
            center = pygame.Surface((4, 4), pygame.SRCALPHA)
            self.screen.blit(center, (cx, cy))
        else:
            pygame.draw.circle(self.screen, O_COLOR, (cx, cy), 52, 14)
            pygame.draw.circle(self.screen, O_COLOR, (cx, cy), 8)

    def _draw_score(self, game):
        r = pygame.Rect(BOARD_X, BOARD_Y + BOARD_SIZE + 16, BOARD_SIZE, 56)
        pygame.draw.rect(self.screen, PANEL_BG, r, border_radius=10)
        pygame.draw.rect(self.screen, GRID_COLOR, r, 1, border_radius=10)
        items = [('X 胜', str(game.x_wins), X_COLOR),
                 ('O 胜', str(game.o_wins), O_COLOR),
                 ('平局', str(game.draws), TEXT_DIM)]
        cw = BOARD_SIZE // 3
        for i, (label, value, color) in enumerate(items):
            x0 = r.x + i * cw + cw // 2
            self.screen.blit(_font(14).render(label, True, TEXT_DIM),
                             (x0 - 18, r.y + 8))
            surf = _font(24, bold=True).render(value, True, color)
            self.screen.blit(surf, (x0 - surf.get_width() // 2, r.y + 24))

    def _draw_hint(self):
        r = pygame.Rect(BOARD_X, WINDOW_H - 42, BOARD_SIZE, 30)
        pygame.draw.rect(self.screen, PANEL_BG, r, border_radius=8)
        text = '鼠标点击落子 · 1/2/3 切换模式 · R 重开 · ESC 退出'
        surf = _font(13).render(text, True, TEXT_DIM)
        self.screen.blit(surf, (r.centerx - surf.get_width() // 2,
                                r.centery - surf.get_height() // 2))

    def _draw_overlay(self, game):
        """终局遮罩：胜负 / 平局结果"""
        outcome = game.result[0]
        if outcome == 'draw':
            title, color = '平局！', TEXT
        else:
            title = f'{outcome} 获胜！'
            color = X_COLOR if outcome == 'X' else O_COLOR
        overlay = pygame.Surface((BOARD_SIZE, BOARD_SIZE), pygame.SRCALPHA)
        overlay.fill((8, 9, 14, 190))
        self.screen.blit(overlay, (BOARD_X, BOARD_Y))
        surf = _font(38, bold=True).render(title, True, color)
        self.screen.blit(surf, (BOARD_X + (BOARD_SIZE - surf.get_width()) // 2,
                                BOARD_Y + BOARD_SIZE // 2 - 50))
        surf = _font(17).render('点击棋盘或按 R 再来一局', True, TEXT_DIM)
        self.screen.blit(surf, (BOARD_X + (BOARD_SIZE - surf.get_width()) // 2,
                                BOARD_Y + BOARD_SIZE // 2 + 8))


def _dim(color):
    return tuple(c // 3 for c in color)
