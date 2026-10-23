# -*- coding: utf-8 -*-
"""
《打工人生存记》—— 一个轻松、全年龄向的 2D 休闲躲避小游戏。

玩法简介：
    * 使用方向键（也支持 WASD）在办公室里自由移动；
    * 躲开写着“画饼”“加班”的红色障碍，避免损失精力；
    * 收集绿色的“准时下班”和蓝色的“周末”，获得分数；
    * 连续收集可以提升倍率，撑过三个难度递增的关卡。

技术约束：
    * 只使用 pygame（以及 Python 标准库）实现；
    * 不读取任何外部图片、字体文件或音频文件；
    * 所有画面元素都由几何图形和文字实时绘制；
    * 中文字体使用操作系统自带字体，找不到时回退到 pygame 默认字体。

运行方式：
    python main.py
    python main.py --self-test    # 无窗口基础自检，适合 CI / 快速验证

按 ESC 随时退出。
"""

from __future__ import annotations

import math
import os
import random
import sys
from dataclasses import dataclass

# 在导入 pygame 之前关闭它默认打印的欢迎信息，让控制台更干净。
os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

try:
    import pygame
except ModuleNotFoundError as exc:  # 给没有安装依赖的玩家一个友好提示
    raise SystemExit(
        "未检测到 pygame。请先运行：python -m pip install -r requirements.txt"
    ) from exc


# ---------------------------------------------------------------------------
# 基础常量
# ---------------------------------------------------------------------------
WIDTH, HEIGHT = 960, 640
FPS = 60
GAME_TITLE = "打工人生存记"

# 游戏区域：顶部留给 HUD，底部留一行轻松的小字。
ARENA = pygame.Rect(36, 146, 888, 460)
HUD_RECT = pygame.Rect(24, 18, 912, 110)

# 所有可移动按键。方向键和 WASD 会同时被两种机制监听：
#   1) get_pressed() 读取实时键盘状态；
#   2) KEYDOWN / KEYUP 事件维护一份“按住中”的集合。
# 两者取并集，可以规避部分系统、输入法或失焦场景下的按键状态丢失。
MOVEMENT_KEYS = frozenset(
    (
        pygame.K_LEFT,
        pygame.K_RIGHT,
        pygame.K_UP,
        pygame.K_DOWN,
        pygame.K_w,
        pygame.K_a,
        pygame.K_s,
        pygame.K_d,
    )
)

# 整套配色使用低饱和度的“办公室午后”色系，避免刺眼。
BG_TOP = (255, 248, 236)
BG_BOTTOM = (238, 216, 194)
ARENA_FILL = (252, 248, 239)
ARENA_GRID = (239, 229, 214)
INK = (43, 52, 74)
INK_SOFT = (91, 101, 122)
MUTED = (170, 181, 200)
MUTED_DARK = (139, 122, 102)
NAVY = (36, 47, 70)
NAVY_LIGHT = (54, 69, 98)
PANEL_BORDER = (93, 110, 143)
CREAM = (255, 250, 239)
GOLD = (247, 193, 92)
GOLD_LIGHT = (255, 224, 155)
CORAL = (235, 110, 93)
RED = (224, 86, 95)
MINT = (66, 178, 150)
BLUE = (79, 125, 226)
PURPLE = (157, 118, 218)

# 三个关卡的核心参数。
# 设计原则：每一关都同时提高“生成频率、下落速度、障碍占比”，
# 第三关再加入一次生成两件的“双人成行”压力，但始终保持可反应的空间。
LEVELS = (
    {
        "name": "实习期",
        "intro": "先熟悉工位，躲开第一张画饼。",
        "duration": 26.0,
        "spawn_min": 0.82,
        "spawn_max": 1.12,
        "obstacle_chance": 0.50,
        "speed_min": 100.0,
        "speed_max": 142.0,
        "double_chance": 0.00,
        "accent": CORAL,
    },
    {
        "name": "转正冲刺",
        "intro": "任务变多了，记得先照顾自己。",
        "duration": 28.0,
        "spawn_min": 0.60,
        "spawn_max": 0.86,
        "obstacle_chance": 0.61,
        "speed_min": 125.0,
        "speed_max": 172.0,
        "double_chance": 0.10,
        "accent": BLUE,
    },
    {
        "name": "周五保卫战",
        "intro": "最后一关，守住属于你的周末！",
        "duration": 30.0,
        "spawn_min": 0.44,
        "spawn_max": 0.66,
        "obstacle_chance": 0.68,
        "speed_min": 150.0,
        "speed_max": 200.0,
        "double_chance": 0.24,
        "accent": PURPLE,
    },
)

# 所有可下落物件的视觉与数值配置。
# is_item=False 表示障碍，碰到会扣精力；True 表示可收集物，碰到加分。
OBJECT_SPECS = {
    "pie": {
        "label": "画饼",
        "width": 98,
        "height": 64,
        "is_item": False,
        "points": 0,
        "fill": (246, 164, 95),
        "border": (135, 77, 47),
        "text": (68, 41, 26),
        "speed_scale": 0.92,
    },
    "overtime": {
        "label": "加班",
        "width": 96,
        "height": 62,
        "is_item": False,
        "points": 0,
        "fill": (232, 100, 102),
        "border": (123, 45, 55),
        "text": (255, 245, 231),
        "speed_scale": 1.08,
    },
    "offwork": {
        "label": "准时下班",
        "width": 112,
        "height": 64,
        "is_item": True,
        "points": 100,
        "fill": (66, 177, 151),
        "border": (21, 100, 86),
        "text": (255, 252, 242),
        "speed_scale": 1.00,
    },
    "weekend": {
        "label": "周末",
        "width": 92,
        "height": 64,
        "is_item": True,
        "points": 200,
        "fill": (85, 125, 224),
        "border": (38, 65, 140),
        "text": (255, 251, 238),
        "speed_scale": 0.95,
    },
}


# ---------------------------------------------------------------------------
# 小工具函数
# ---------------------------------------------------------------------------
def clamp(value: float, low: float, high: float) -> float:
    """把数值限制在 [low, high] 区间内。"""
    return max(low, min(high, value))


def lerp_color(color_a, color_b, amount: float):
    """线性混合两个 RGB 颜色，amount=0 返回前者，1 返回后者。"""
    amount = clamp(amount, 0.0, 1.0)
    return tuple(
        int(color_a[i] + (color_b[i] - color_a[i]) * amount) for i in range(3)
    )


def format_clock(seconds: float) -> str:
    """把秒数格式化成 mm:ss，用于计时 HUD 和结算页。"""
    total = max(0, int(seconds))
    return f"{total // 60:02d}:{total % 60:02d}"


def draw_star(surface, color, cx: float, cy: float, radius: float, points: int = 5):
    """画一个五角星，用于装饰和收集品的闪光。"""
    vertices = []
    for i in range(points * 2):
        angle = -math.pi / 2 + i * math.pi / points
        r = radius if i % 2 == 0 else radius * 0.45
        vertices.append((cx + math.cos(angle) * r, cy + math.sin(angle) * r))
    if len(vertices) >= 3:
        pygame.draw.polygon(surface, color, vertices)


def draw_soft_panel(surface, rect: pygame.Rect, fill, border, radius: int = 26):
    """
    画出带柔和投影的圆角面板。
    投影用一层带透明度的 Surface 预绘制，再整体贴到目标画布上。
    """
    shadow = pygame.Surface((rect.width + 34, rect.height + 38), pygame.SRCALPHA)
    pygame.draw.rect(
        shadow,
        (25, 31, 47, 80),
        pygame.Rect(17, 20, rect.width, rect.height),
        border_radius=radius,
    )
    surface.blit(shadow, (rect.x - 17, rect.y - 17))
    pygame.draw.rect(surface, fill, rect, border_radius=radius)
    if border is not None:
        pygame.draw.rect(surface, border, rect, width=2, border_radius=radius)


def draw_heart(surface, center_x: int, center_y: int, size: int, filled: bool):
    """用两个圆和一个三角形拼成爱心，表示剩余精力。"""
    color = CORAL if filled else (67, 81, 109)
    r = max(2, size // 4)
    pygame.draw.circle(surface, color, (center_x - r, center_y - r // 2), r)
    pygame.draw.circle(surface, color, (center_x + r, center_y - r // 2), r)
    pygame.draw.polygon(
        surface,
        color,
        [
            (center_x - size // 2, center_y),
            (center_x + size // 2, center_y),
            (center_x, center_y + size // 2),
        ],
    )


def draw_briefcase_icon(surface, rect: pygame.Rect, case_color, detail_color):
    """画一个小公文包图标，用作标题 logo。"""
    left, top, w, h = rect
    pygame.draw.rect(
        surface,
        detail_color,
        pygame.Rect(left + w // 2 - 9, top + 7, 18, 10),
        width=3,
        border_radius=3,
    )
    body = pygame.Rect(left + 5, top + 13, w - 10, h - 20)
    pygame.draw.rect(surface, case_color, body, border_radius=5)
    pygame.draw.rect(surface, detail_color, body, width=2, border_radius=5)
    pygame.draw.line(
        surface,
        detail_color,
        (left + w // 2, top + 16),
        (left + w // 2, top + h - 10),
        2,
    )


def draw_object_card(
    surface,
    fonts: "FontBook",
    kind: str,
    cx: float,
    cy: float,
    age: float = 0.0,
    floor_shadow: bool = True,
):
    """
    绘制一个下落物件的完整卡片外观。

    四种物件共享圆角卡片结构，再通过颜色、图标和文字区分：
        画饼   —— 橙色对话气泡；
        加班   —— 红色时钟卡片；
        准时下班 —— 绿色工牌；
        周末   —— 蓝色日历卡。
    """
    spec = OBJECT_SPECS[kind]
    # 收集品轻微呼吸，障碍物只有很细小的晃动，保证可读性。
    pulse = 1.0
    if spec["is_item"]:
        pulse += 0.035 * math.sin(age * 5.0)
    else:
        pulse += 0.015 * math.sin(age * 7.0)

    w = spec["width"] * pulse
    h = spec["height"] * pulse
    left = cx - w / 2
    top = cy - h / 2
    body = pygame.Rect(int(left), int(top), int(w), int(h))

    # 阴影。场地内使用暖灰色，菜单的深色面板上则使用半透明深色。
    if floor_shadow:
        pygame.draw.ellipse(
            surface,
            (199, 183, 163),
            pygame.Rect(int(cx - w * 0.42 + 4), int(cy + h * 0.38), int(w * 0.84), 12),
        )
    else:
        shadow = pygame.Surface((int(w + 24), int(h + 24)), pygame.SRCALPHA)
        pygame.draw.ellipse(
            shadow,
            (9, 14, 25, 90),
            pygame.Rect(12, int(h * 0.58), int(w), 18),
        )
        surface.blit(shadow, (int(cx - w / 2 - 12), int(cy - h / 2 + 2)))

    # 可收集物带一圈淡淡的同色光晕，让玩家一眼分清“奖励”和“危险”。
    if spec["is_item"]:
        glow = pygame.Surface((int(w + 56), int(h + 56)), pygame.SRCALPHA)
        glow_rect = pygame.Rect(14, 14, int(w + 28), int(h + 28))
        pygame.draw.ellipse(glow, (*spec["fill"], 30), glow_rect)
        pygame.draw.ellipse(glow, (*spec["fill"], 36), glow_rect.inflate(-22, -22))
        surface.blit(glow, (int(cx - w / 2 - 28), int(cy - h / 2 - 28)))

    # “画饼”带一个对话气泡的小尾巴。
    if kind == "pie":
        tail = [
            (int(cx - 22), int(cy + h * 0.31)),
            (int(cx - 8), int(cy + h * 0.34)),
            (int(cx - 31), int(cy + h * 0.56)),
        ]
        pygame.draw.polygon(surface, spec["border"], tail)
        inner_tail = [
            (int(cx - 21), int(cy + h * 0.34)),
            (int(cx - 12), int(cy + h * 0.36)),
            (int(cx - 26), int(cy + h * 0.49)),
        ]
        pygame.draw.polygon(surface, spec["fill"], inner_tail)

    # 卡片主体：先填充，再描深色边。
    pygame.draw.rect(surface, spec["fill"], body, border_radius=17)
    pygame.draw.rect(surface, spec["border"], body, width=3, border_radius=17)

    # 顶部一条浅浅的高光，让卡片看起来更有实体感。
    pygame.draw.line(
        surface,
        (255, 255, 255, 70) if spec["is_item"] else (255, 240, 220),
        (body.left + 18, body.top + 7),
        (body.right - 18, body.top + 7),
        2,
    )

    if kind == "pie":
        # 画饼：文字就是最好的图标，再用三个小气泡点增加“正在画饼”的感觉。
        fonts.draw(
            surface,
            "画饼",
            22,
            spec["text"],
            (cx, cy + 2),
            anchor="center",
            bold=True,
        )
        for i in range(3):
            pygame.draw.circle(
                surface,
                spec["border"],
                (int(left + w - 22 + i * 6), int(top + 14)),
                2,
            )

    elif kind == "overtime":
        # 加班：左侧时钟，右侧文字。
        clock_center = (int(cx - w * 0.28), int(cy))
        pygame.draw.circle(surface, (255, 246, 232), clock_center, 14)
        pygame.draw.circle(surface, spec["border"], clock_center, 14, 2)
        pygame.draw.line(
            surface,
            spec["border"],
            clock_center,
            (clock_center[0], clock_center[1] - 8),
            2,
        )
        pygame.draw.line(
            surface,
            spec["border"],
            clock_center,
            (clock_center[0] + 7, clock_center[1] + 3),
            2,
        )
        fonts.draw(
            surface,
            "加班",
            20,
            spec["text"],
            (cx + w * 0.10, cy + 1),
            anchor="center",
            bold=True,
            shadow=(120, 44, 52),
        )

    elif kind == "offwork":
        # 准时下班：绿色工牌 + 白色手表。
        clock_center = (int(cx - w * 0.30), int(cy))
        pygame.draw.circle(surface, (248, 255, 248), clock_center, 15)
        pygame.draw.circle(surface, spec["border"], clock_center, 15, 2)
        pygame.draw.line(
            surface,
            spec["border"],
            clock_center,
            (clock_center[0], clock_center[1] - 9),
            2,
        )
        pygame.draw.line(
            surface,
            spec["border"],
            clock_center,
            (clock_center[0] + 8, clock_center[1] + 4),
            2,
        )
        fonts.draw(
            surface,
            "准时下班",
            15,
            spec["text"],
            (cx + w * 0.13, cy + 1),
            anchor="center",
            bold=True,
            shadow=(20, 85, 72),
        )

    elif kind == "weekend":
        # 周末：日历卡上挂两个小圆环，再配一颗金色小星星。
        for dx in (-8, 8):
            pygame.draw.circle(
                surface,
                spec["border"],
                (int(cx + dx), int(top + 6)),
                3,
            )
        draw_star(surface, GOLD_LIGHT, left + 20, top + 18, 6)
        fonts.draw(
            surface,
            "周末",
            20,
            spec["text"],
            (cx + 4, cy + 2),
            anchor="center",
            bold=True,
            shadow=(28, 51, 112),
        )

    # 收集品周围的闪烁小星星。
    if spec["is_item"]:
        for i in range(3):
            angle = age * 1.8 + i * 2.1
            sx = cx + math.cos(angle) * (w * 0.62)
            sy = cy + math.sin(angle) * (h * 0.58)
            draw_star(surface, GOLD_LIGHT, sx, sy, 3.2)


# ---------------------------------------------------------------------------
# 字体管理
# ---------------------------------------------------------------------------
class FontBook:
    """
    统一管理字体和文字渲染，并缓存已经渲染过的文字。

    pygame 本身不能“画出”中文字形，因此这里依次尝试系统常见中文字体。
    这里没有加载项目目录中的任何字体文件，只使用操作系统自带字体；
    如果系统没有中文字体，会回退到 pygame 默认字体（可能显示为方框）。
    """

    FONT_CANDIDATES = (
        "microsoftyahei",
        "microsoftyaheiui",
        "simhei",
        "dengxian",
        "microsoftjhenghei",
        "notosanssc",
        "notosanscjksc",
        "wenquanyizenhei",
        "sourcehansanssc",
        "simsun",
    )

    def __init__(self):
        self.font_path = None
        for name in self.FONT_CANDIDATES:
            path = pygame.font.match_font(name)
            if path:
                self.font_path = path
                break
        self._fonts = {}
        self._cache = {}

    def _get_font(self, size: int, bold: bool):
        key = (size, bold)
        if key not in self._fonts:
            if self.font_path:
                font = pygame.font.Font(self.font_path, size)
            else:
                font = pygame.font.SysFont(None, size)
            font.set_bold(bold)
            self._fonts[key] = font
        return self._fonts[key]

    def render(self, text: str, size: int, color, bold: bool = False, alpha: int = 255):
        """渲染文字并缓存；alpha 会记录进缓存键，避免互相污染。"""
        key = (text, size, tuple(color), bold, alpha)
        cached = self._cache.get(key)
        if cached is not None:
            return cached

        surface = self._get_font(size, bold).render(text, True, color)
        if alpha < 255:
            surface = surface.convert_alpha()
            surface.set_alpha(alpha)
        # 缓存不设太大，避免一局游戏中不断变化的分数撑爆内存。
        if len(self._cache) > 500:
            self._cache.clear()
        self._cache[key] = surface
        return surface

    def draw(
        self,
        surface,
        text: str,
        size: int,
        color,
        pos,
        anchor: str = "topleft",
        bold: bool = False,
        alpha: int = 255,
        shadow=None,
    ):
        """按指定锚点绘制文字，可选一层偏移阴影。"""
        image = self.render(text, size, color, bold, alpha)
        rect = image.get_rect(**{anchor: pos})
        if shadow is not None:
            shadow_image = self.render(text, size, shadow, bold, alpha)
            surface.blit(shadow_image, rect.move(2, 2))
        surface.blit(image, rect)
        return rect


# ---------------------------------------------------------------------------
# 角色与可下落物件
# ---------------------------------------------------------------------------
class Player:
    """玩家的职场小人：有简单的走路动画、受击保护圈和公文包。"""

    def __init__(self):
        self.max_energy = 3
        self.reset()

    def reset(self):
        self.x = WIDTH / 2
        self.y = ARENA.bottom - 74
        self.speed = 300.0
        self.invincible = 0.0
        self.walk_phase = 0.0
        self.idle_time = 0.0
        self.moving = False

    @property
    def hitbox(self) -> pygame.Rect:
        """真正参与碰撞的判定框，比视觉角色略小，手感更宽容。"""
        return pygame.Rect(int(self.x - 17), int(self.y - 32), 34, 60)

    def update(self, dt: float, keys, held_keys=None):
        """
        根据按键状态移动，并限制在游戏区域内。

        keys 是 pygame.key.get_pressed() 的实时状态；
        held_keys 是从 KEYDOWN / KEYUP 事件维护的按住集合。
        两者任意一个认为按键按下即生效，避免 WASD 在部分环境下失效。
        """
        held_keys = held_keys or ()

        def down(key_code) -> bool:
            if key_code in held_keys:
                return True
            try:
                return bool(keys[key_code])
            except (KeyError, IndexError):
                return False

        dx = int(down(pygame.K_RIGHT) or down(pygame.K_d)) - int(
            down(pygame.K_LEFT) or down(pygame.K_a)
        )
        dy = int(down(pygame.K_DOWN) or down(pygame.K_s)) - int(
            down(pygame.K_UP) or down(pygame.K_w)
        )

        length = math.hypot(dx, dy)
        self.moving = length > 0
        if self.moving:
            # 归一化，避免斜向移动比直线更快。
            dx /= length
            dy /= length
            self.x += dx * self.speed * dt
            self.y += dy * self.speed * dt
            self.walk_phase += dt * 13.0
        else:
            self.walk_phase += dt * 2.0

        self.idle_time += dt
        self.invincible = max(0.0, self.invincible - dt)

        # 左右留出公文包和手臂的空间，上下留出头和脚的空间。
        self.x = clamp(self.x, ARENA.left + 31, ARENA.right - 31)
        self.y = clamp(self.y, ARENA.top + 46, ARENA.bottom - 39)

    def draw(self, surface):
        """全部用圆形、矩形和线条拼出一个可爱的职场小人。"""
        bob = math.sin(self.walk_phase) * 2.0 if self.moving else math.sin(
            self.idle_time * 3.0
        )
        x = int(self.x)
        y = int(self.y + bob)

        # 脚下阴影
        shadow = pygame.Surface((66, 20), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow, (35, 43, 60, 55), shadow.get_rect())
        surface.blit(shadow, (x - 33, y + 27))

        # 双腿与鞋子，走路时前后摆动。
        swing = math.sin(self.walk_phase) * 4.0 if self.moving else 0.0
        leg_color = (55, 64, 87)
        shoe_color = (31, 38, 55)
        pygame.draw.rect(
            surface,
            leg_color,
            pygame.Rect(x - 12, int(y + 12 + swing), 9, 18),
            border_radius=4,
        )
        pygame.draw.rect(
            surface,
            leg_color,
            pygame.Rect(x + 3, int(y + 12 - swing), 9, 18),
            border_radius=4,
        )
        pygame.draw.ellipse(
            surface, shoe_color, pygame.Rect(x - 15, int(y + 27 + swing), 14, 7)
        )
        pygame.draw.ellipse(
            surface, shoe_color, pygame.Rect(x + 2, int(y + 27 - swing), 14, 7)
        )

        # 身体、白衬衫和红领带。
        pygame.draw.rect(
            surface,
            (30, 38, 57),
            pygame.Rect(x - 20, y - 14, 40, 34),
            border_radius=12,
        )
        pygame.draw.rect(
            surface,
            (244, 181, 67),
            pygame.Rect(x - 18, y - 12, 36, 30),
            border_radius=10,
        )
        pygame.draw.rect(
            surface,
            (253, 249, 238),
            pygame.Rect(x - 8, y - 10, 16, 20),
            border_radius=4,
        )
        pygame.draw.polygon(
            surface,
            CORAL,
            [(x - 3, y - 8), (x + 3, y - 8), (x + 2, y + 6), (x, y + 9), (x - 2, y + 6)],
        )
        # 工牌上的小蓝点
        pygame.draw.circle(surface, BLUE, (x - 12, y - 2), 3)

        # 手臂
        pygame.draw.line(surface, (30, 38, 57), (x - 17, y - 5), (x - 23, y + 9), 7)
        pygame.draw.line(surface, (30, 38, 57), (x + 17, y - 5), (x + 22, y + 8), 7)
        pygame.draw.circle(surface, (247, 205, 173), (x - 23, y + 10), 4)
        pygame.draw.circle(surface, (247, 205, 173), (x + 22, y + 9), 4)

        # 公文包：玩家“打工人”身份的小标志。
        case_rect = pygame.Rect(x + 18, y + 3, 18, 14)
        pygame.draw.rect(surface, (40, 135, 127), case_rect, border_radius=3)
        pygame.draw.rect(surface, (238, 252, 245), case_rect, width=1, border_radius=3)
        pygame.draw.rect(
            surface,
            (238, 252, 245),
            pygame.Rect(x + 23, y - 1, 8, 5),
            width=2,
            border_radius=2,
        )

        # 头部：深色头发、肤色脸、眼睛和微笑。
        pygame.draw.circle(surface, (44, 51, 72), (x, y - 27), 13)
        pygame.draw.circle(surface, (247, 205, 173), (x, y - 24), 11)
        pygame.draw.arc(
            surface,
            (44, 51, 72),
            pygame.Rect(x - 11, y - 36, 22, 17),
            0.15,
            math.pi - 0.15,
            5,
        )
        pygame.draw.circle(surface, (53, 48, 62), (x - 4, y - 24), 1.7)
        pygame.draw.circle(surface, (53, 48, 62), (x + 4, y - 24), 1.7)
        pygame.draw.arc(
            surface,
            (169, 96, 79),
            pygame.Rect(x - 4, y - 21, 8, 6),
            0.15,
            math.pi - 0.15,
            2,
        )

        # 受击后的短暂保护圈：提醒玩家现在撞到障碍也不会再扣精力。
        if self.invincible > 0:
            ring = pygame.Surface((94, 104), pygame.SRCALPHA)
            alpha = int(100 + 70 * (0.5 + 0.5 * math.sin(self.invincible * 18)))
            pygame.draw.ellipse(ring, (255, 224, 150, alpha), ring.get_rect(), 3)
            surface.blit(ring, (x - 47, y - 55))


@dataclass
class FallingObject:
    """一个从顶部下落的障碍或收集品。"""

    kind: str
    base_x: float
    y: float
    speed: float
    sway: float
    sway_speed: float
    phase: float
    x: float = 0.0
    age: float = 0.0

    def __post_init__(self):
        self.x = self.base_x + math.sin(self.phase) * self.sway

    @property
    def spec(self):
        return OBJECT_SPECS[self.kind]

    @property
    def is_item(self) -> bool:
        return bool(self.spec["is_item"])

    @property
    def width(self) -> int:
        return int(self.spec["width"])

    @property
    def height(self) -> int:
        return int(self.spec["height"])

    @property
    def rect(self) -> pygame.Rect:
        return pygame.Rect(
            int(self.x - self.width / 2),
            int(self.y - self.height / 2),
            self.width,
            self.height,
        )

    @property
    def hitbox(self) -> pygame.Rect:
        """碰撞框比卡片略小，视觉上擦到边不算撞上。"""
        return self.rect.inflate(-14, -12)

    def update(self, dt: float):
        """向下移动，同时做轻微左右摇摆。"""
        self.age += dt
        self.y += self.speed * dt
        self.phase += self.sway_speed * dt
        self.x = self.base_x + math.sin(self.phase) * self.sway

    def draw(self, surface, fonts: FontBook):
        draw_object_card(surface, fonts, self.kind, self.x, self.y, self.age)


@dataclass
class Particle:
    """用于收集、受击和通关反馈的小粒子。"""

    x: float
    y: float
    vx: float
    vy: float
    life: float
    max_life: float
    size: float
    color: tuple
    square: bool = False

    def update(self, dt: float):
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.vy += 330.0 * dt
        self.vx *= 0.985
        self.life -= dt

    def draw(self, surface):
        if self.life <= 0:
            return
        ratio = clamp(self.life / self.max_life, 0.0, 1.0)
        size = max(1, int(self.size * ratio))
        if self.square:
            pygame.draw.rect(
                surface,
                self.color,
                pygame.Rect(int(self.x - size / 2), int(self.y - size / 2), size, size),
                border_radius=1,
            )
        else:
            pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), size)


@dataclass
class FloatingText:
    """向上飘散并淡出的得分 / 扣分提示。"""

    text: str
    x: float
    y: float
    color: tuple
    life: float = 1.0
    max_life: float = 1.0
    size: int = 18
    vy: float = 44.0

    def update(self, dt: float):
        self.y -= self.vy * dt
        self.vy *= 0.97
        self.life -= dt

    def draw(self, surface, fonts: FontBook):
        if self.life <= 0:
            return
        alpha = int(255 * clamp(self.life / self.max_life * 1.8, 0.0, 1.0))
        fonts.draw(
            surface,
            self.text,
            self.size,
            self.color,
            (int(self.x), int(self.y)),
            anchor="center",
            bold=True,
            alpha=alpha,
            shadow=(29, 37, 54),
        )


# ---------------------------------------------------------------------------
# 游戏主体
# ---------------------------------------------------------------------------
class Game:
    """管理场景、输入、关卡、计分和所有绘制逻辑。"""

    def __init__(self):
        # 只初始化显示和字体模块，不初始化音频，因为本游戏完全静音。
        pygame.display.init()
        pygame.font.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption(f"{GAME_TITLE}  |  Work Life Survival")
        pygame.display.set_icon(self._make_window_icon())
        # 本游戏不需要输入文字。关闭文本输入/输入法编辑后，
        # 可以避免中文输入法把 W/A/S/D 当成拼音候选而吞掉按键。
        pygame.key.stop_text_input()

        self.fonts = FontBook()
        self.clock = pygame.time.Clock()
        self.canvas = pygame.Surface((WIDTH, HEIGHT)).convert()
        self.background = self._build_background()
        self.menu_dim = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        self.menu_dim.fill((25, 32, 49, 92))
        self.modal_dim = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        self.modal_dim.fill((20, 26, 40, 145))
        self.result_dim = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        self.result_dim.fill((20, 26, 40, 170))
        self.damage_overlay = self._build_damage_overlay()

        self.player = Player()
        self.objects: list[FallingObject] = []
        self.particles: list[Particle] = []
        self.float_texts: list[FloatingText] = []

        self.running = True
        self.closed = False
        self.anim_time = 0.0
        # 由 KEYDOWN / KEYUP 维护的移动按键集合，和 get_pressed() 互为补充。
        self.held_movement_keys: set[int] = set()

        # 一局游戏的统计变量。最高分只保留在本次进程内，不写外部存档。
        self.best_score = 0
        self.state = "menu"
        self.level_index = 0
        self.score = 0
        self.energy = self.player.max_energy
        self.level_time_left = 0.0
        self.level_start_score = 0
        self.level_earned = 0
        self.last_bonus = 0
        self.run_time = 0.0
        self.total_collected_offwork = 0
        self.total_collected_weekend = 0
        self.hit_count = 0
        self.dodged_count = 0
        self.combo = 0
        self.max_combo = 0
        self.levels_cleared = 0
        self.result_victory = False
        self.result_rank = ""
        self._survival_score_accum = 0.0
        self._first_spawn_is_item = True
        self.spawn_timer = 1.0
        self.toast_text = ""
        self.toast_color = CREAM
        self.toast_timer = 0.0
        self.toast_duration = 0.0
        self.damage_timer = 0.0
        self.shake_timer = 0.0
        self.shake_duration = 0.30
        self.menu_cards = (
            ("weekend", 68, 172, 0.0),
            ("pie", 892, 300, 1.2),
            ("offwork", 62, 464, 2.1),
            ("overtime", 888, 520, 3.0),
        )

    # ------------------------------------------------------------------
    # 初始化辅助
    # ------------------------------------------------------------------
    @staticmethod
    def _make_window_icon() -> pygame.Surface:
        """用几何图形生成窗口图标，不读取外部文件。"""
        icon = pygame.Surface((32, 32), pygame.SRCALPHA)
        pygame.draw.rect(icon, NAVY, pygame.Rect(2, 2, 28, 28), border_radius=8)
        pygame.draw.rect(icon, (244, 181, 67), pygame.Rect(7, 12, 18, 13), border_radius=3)
        pygame.draw.rect(
            icon, CREAM, pygame.Rect(7, 12, 18, 13), width=2, border_radius=3
        )
        pygame.draw.rect(icon, CREAM, pygame.Rect(12, 8, 8, 5), width=2, border_radius=2)
        return icon

    def _build_damage_overlay(self) -> pygame.Surface:
        """生成受击时用的红色边缘光效，避免每帧重新创建大 Surface。"""
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        for i in range(9):
            alpha = max(4, 20 - i * 2)
            pygame.draw.rect(
                overlay,
                (235, 86, 86, alpha),
                pygame.Rect(2 + i * 3, 2 + i * 3, WIDTH - 4 - i * 6, HEIGHT - 4 - i * 6),
                width=5,
                border_radius=18,
            )
        return overlay

    def _build_background(self) -> pygame.Surface:
        """
        预先绘制静态背景：渐变墙纸、办公室地板、网格和角落小盆栽。
        预绘制可以避免每帧重复画上百条线。
        """
        bg = pygame.Surface((WIDTH, HEIGHT)).convert()
        for y in range(HEIGHT):
            color = lerp_color(BG_TOP, BG_BOTTOM, y / (HEIGHT - 1))
            pygame.draw.line(bg, color, (0, y), (WIDTH, y))

        decor = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        pygame.draw.circle(decor, (255, 255, 255, 60), (92, 72), 150)
        pygame.draw.circle(decor, (255, 218, 161, 42), (858, 532), 215)
        pygame.draw.circle(decor, (255, 255, 255, 38), (870, 74), 95)
        bg.blit(decor, (0, 0))

        # 游戏区投影与底板
        shadow = pygame.Surface((ARENA.width + 40, ARENA.height + 40), pygame.SRCALPHA)
        pygame.draw.rect(
            shadow,
            (83, 62, 40, 60),
            pygame.Rect(20, 26, ARENA.width, ARENA.height),
            border_radius=28,
        )
        bg.blit(shadow, (ARENA.x - 20, ARENA.y - 20))
        pygame.draw.rect(bg, ARENA_FILL, ARENA, border_radius=24)

        # 很淡的办公地板网格，让移动有空间参照，但不抢物件的视觉焦点。
        old_clip = bg.get_clip()
        bg.set_clip(ARENA.inflate(-6, -6))
        for gx in range(ARENA.left + 32, ARENA.right, 58):
            pygame.draw.line(
                bg, ARENA_GRID, (gx, ARENA.top + 6), (gx, ARENA.bottom - 6), 1
            )
        for gy in range(ARENA.top + 32, ARENA.bottom, 58):
            pygame.draw.line(
                bg, ARENA_GRID, (ARENA.left + 6, gy), (ARENA.right - 6, gy), 1
            )
        bg.set_clip(old_clip)

        pygame.draw.rect(bg, (205, 187, 163), ARENA, width=3, border_radius=24)
        pygame.draw.rect(
            bg, (255, 255, 255), ARENA.inflate(-8, -8), width=1, border_radius=20
        )

        # 两侧角落的小盆栽：纯装饰，不参与碰撞，透明度也很低。
        plants = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        self._draw_plant(plants, ARENA.left + 36, ARENA.bottom - 18, 1.0)
        self._draw_plant(plants, ARENA.right - 36, ARENA.bottom - 18, -1.0)
        bg.blit(plants, (0, 0))

        # 底部的温柔提示语
        self.fonts.draw(
            bg,
            "今天也要好好生活 · 准点下班不是梦",
            13,
            MUTED_DARK,
            (WIDTH // 2, HEIGHT - 16),
            anchor="center",
        )
        return bg

    @staticmethod
    def _draw_plant(surface, x: int, ground_y: int, direction: float):
        """在背景层画一株极简小盆栽，direction 控制叶子的倾斜方向。"""
        pot = pygame.Rect(x - 17, ground_y - 18, 34, 23)
        pygame.draw.rect(surface, (183, 130, 94, 75), pot, border_radius=5)
        pygame.draw.rect(surface, (112, 75, 55, 70), pot, width=2, border_radius=5)
        stem_x = x
        pygame.draw.line(
            surface,
            (77, 139, 107, 85),
            (stem_x, ground_y - 18),
            (stem_x - int(4 * direction), ground_y - 45),
            3,
        )
        for i, (dx, dy, radius) in enumerate(
            [(-18, -41, 12), (13, -48, 11), (-4, -57, 10)]
        ):
            color = (68, 145, 108, 70) if i % 2 == 0 else (94, 162, 115, 65)
            pygame.draw.ellipse(
                surface,
                color,
                pygame.Rect(
                    int(stem_x + dx * direction) - radius,
                    ground_y + dy - radius // 2,
                    radius * 2,
                    radius + 8,
                ),
            )

    # ------------------------------------------------------------------
    # 游戏流程
    # ------------------------------------------------------------------
    def _reset_run_stats(self):
        """在重新开始时清空本局统计，但保留本次会话最高分。"""
        self.score = 0
        self.energy = self.player.max_energy
        self.level_index = 0
        self.level_time_left = 0.0
        self.level_start_score = 0
        self.level_earned = 0
        self.last_bonus = 0
        self.run_time = 0.0
        self.total_collected_offwork = 0
        self.total_collected_weekend = 0
        self.hit_count = 0
        self.dodged_count = 0
        self.combo = 0
        self.max_combo = 0
        self.levels_cleared = 0
        self.result_victory = False
        self.result_rank = ""
        self._survival_score_accum = 0.0
        self.objects.clear()
        self.particles.clear()
        self.float_texts.clear()
        self.toast_timer = 0.0
        self.damage_timer = 0.0
        self.shake_timer = 0.0

    def start_run(self):
        """从标题页或结算页开始新的一局。"""
        self._reset_run_stats()
        self._begin_level(0)

    def _begin_level(self, index: int):
        """进入指定关卡，重置场地并给予一点短暂保护。"""
        # 从第二关开始补回 1 点精力（不超过上限），让后两关仍然有容错空间。
        restored = 0
        if index > 0 and self.energy < self.player.max_energy:
            self.energy += 1
            restored = 1

        self.level_index = index
        self.level_time_left = float(LEVELS[index]["duration"])
        self.level_start_score = self.score
        self.level_earned = 0
        self.last_bonus = 0
        self.objects.clear()
        self.particles.clear()
        self.float_texts.clear()
        self.player.reset()
        self.player.invincible = 1.0
        self.spawn_timer = 1.1
        self._first_spawn_is_item = True
        self.state = "playing"

        # 新关卡第一次生成一定是一个收集品，给玩家一个友好的开场。
        config = LEVELS[index]
        toast = f"第 {index + 1} 关 · {config['name']}　{config['intro']}"
        if restored:
            toast += "　精力 +1"
        self._show_toast(toast, config["accent"], 2.4)

    def _advance_after_clear(self):
        """通关面板按 Enter 后的处理：进入下一关或查看总结算。"""
        if self.level_index >= len(LEVELS) - 1:
            self._finish_run(True)
        else:
            self._begin_level(self.level_index + 1)

    def _complete_level(self):
        """本关倒计时归零：结算本关奖励并暂停等待玩家确认。"""
        config = LEVELS[self.level_index]
        self.levels_cleared += 1
        self.level_earned = max(0, self.score - self.level_start_score)
        # 奖励设计：越靠后的关卡奖励越高，剩余精力也能换成额外分数。
        self.last_bonus = 250 + self.level_index * 150 + self.energy * 40
        self.score += self.last_bonus
        self.state = "level_clear"
        self.objects.clear()
        self.toast_timer = 0.0
        self.damage_timer = 0.0
        self.shake_timer = 0.0
        self.player.invincible = 0.0
        self._spawn_confetti(45, config["accent"])

    def _finish_run(self, victory: bool):
        """结束本局，更新本次会话最高分并生成结算信息。"""
        self.state = "results"
        self.result_victory = victory
        self.objects.clear()
        self.toast_timer = 0.0
        self.damage_timer = 0.0
        self.shake_timer = 0.0
        self.best_score = max(self.best_score, self.score)
        self.result_rank = self._calculate_rank(victory)
        if victory:
            self._spawn_confetti(60, GOLD)

    def _go_menu(self):
        """从结算页返回标题页。"""
        self.state = "menu"
        self.objects.clear()
        self.particles.clear()
        self.float_texts.clear()
        self.toast_timer = 0.0
        self.damage_timer = 0.0
        self.shake_timer = 0.0

    def _calculate_rank(self, victory: bool) -> str:
        """根据通关情况和得分给出一个轻松的头衔。"""
        if victory and self.score >= 4500:
            return "准点下班传说"
        if victory:
            return "周末守护者"
        if self.levels_cleared >= 2:
            return "加班幸存者"
        if self.levels_cleared >= 1:
            return "职场新星"
        return "明天再战"

    def _handle_keydown(self, key: int):
        """集中处理各场景下的按键。ESC 的退出逻辑在事件循环中统一处理。"""
        if self.state == "menu":
            if key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self.start_run()

        elif self.state == "playing":
            if key == pygame.K_p:
                self.state = "paused"

        elif self.state == "paused":
            if key in (pygame.K_p, pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self.state = "playing"

        elif self.state == "level_clear":
            if key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self._advance_after_clear()

        elif self.state == "results":
            if key in (pygame.K_r, pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self.start_run()
            elif key == pygame.K_m:
                self._go_menu()

    def _process_event(self, event):
        """
        处理单个 pygame 事件。

        移动按键除了每帧轮询，还会在 KEYDOWN 时加入按住集合、KEYUP 时移出。
        这样即使某个平台上 WASD 的轮询状态异常，仍然可以通过事件正常移动。
        独立成方法也便于自检直接注入事件。
        """
        if event.type == pygame.QUIT:
            self.running = False

        elif event.type == pygame.KEYDOWN:
            # 先记录移动键，再交给各场景处理功能键。
            if event.key in MOVEMENT_KEYS:
                self.held_movement_keys.add(event.key)
            if event.key == pygame.K_ESCAPE:
                self.running = False
            else:
                self._handle_keydown(event.key)

        elif event.type == pygame.KEYUP:
            self.held_movement_keys.discard(event.key)

        elif event.type == pygame.WINDOWFOCUSLOST:
            # 窗口失焦时系统可能收不到 KEYUP，必须主动清空，避免角色一直移动。
            self.held_movement_keys.clear()
            if self.state == "playing":
                self.state = "paused"

    def run(self):
        """主循环：事件 -> 更新 -> 绘制，ESC 或窗口关闭都会退出。"""
        try:
            while self.running:
                # 把 dt 限制在 1/30 秒以内，防止窗口被拖动后游戏瞬移。
                dt = min(self.clock.tick(FPS) / 1000.0, 1.0 / 30.0)
                for event in pygame.event.get():
                    self._process_event(event)
                if not self.running:
                    break
                self.update(dt)
                self.render()
        finally:
            self.shutdown()

    # ------------------------------------------------------------------
    # 更新逻辑
    # ------------------------------------------------------------------
    def update(self, dt: float):
        """根据当前场景更新动画、计时、移动、碰撞和得分。"""
        self.anim_time += dt

        if self.state == "menu":
            return

        if self.state == "paused":
            return

        if self.state in ("level_clear", "results"):
            self._update_effects(dt)
            return

        if self.state != "playing":
            return

        self.run_time += dt
        config = LEVELS[self.level_index]

        # 生存分：每坚持 1 秒加 5 分，用小数累计避免被帧率截断。
        self._survival_score_accum += dt * 5.0
        gained = int(self._survival_score_accum)
        if gained > 0:
            self.score += gained
            self._survival_score_accum -= gained

        self.level_time_left -= dt
        keys = pygame.key.get_pressed()
        self.player.update(dt, keys, self.held_movement_keys)

        # 生成节奏
        self.spawn_timer -= dt
        if self.spawn_timer <= 0:
            self._spawn_wave()

        # 物件移动与离场统计
        for obj in self.objects[:]:
            obj.update(dt)
            if obj.rect.top > ARENA.bottom + 30:
                self.objects.remove(obj)
                if not obj.is_item:
                    self.dodged_count += 1

        self._handle_collisions()
        if self.energy <= 0:
            self._finish_run(False)
            return

        self._update_effects(dt)

        if self.level_time_left <= 0:
            self._complete_level()
            return

        # 倒计时进入最后 6 秒时给一声文字提醒（不依赖音频）。
        if self.level_time_left <= 6.0 and not getattr(self, "_low_time_warned", False):
            self._low_time_warned = True
            self._show_toast("马上下班，坚持住！", GOLD, 1.4)
        elif self.level_time_left > 6.2:
            self._low_time_warned = False

    def _update_effects(self, dt: float):
        """更新粒子、飘字、提示条、受击闪屏和屏幕震动计时。"""
        for particle in self.particles[:]:
            particle.update(dt)
            if particle.life <= 0:
                self.particles.remove(particle)
        for text in self.float_texts[:]:
            text.update(dt)
            if text.life <= 0:
                self.float_texts.remove(text)
        self.toast_timer = max(0.0, self.toast_timer - dt)
        self.damage_timer = max(0.0, self.damage_timer - dt)
        self.shake_timer = max(0.0, self.shake_timer - dt)

    def _spawn_wave(self):
        """按关卡配置生成一波物件，最多同时两件，并尽量分散在五条纵向通道。"""
        config = LEVELS[self.level_index]
        count = 1
        # 第一件固定为收集品，避免开局就被障碍包围。
        if not self._first_spawn_is_item and random.random() < config["double_chance"]:
            count = 2
        lanes = random.sample(range(5), count)

        for lane in lanes:
            if self._first_spawn_is_item:
                kind = random.choices(
                    ("offwork", "weekend"), weights=(74, 26), k=1
                )[0]
                self._first_spawn_is_item = False
            else:
                if random.random() < config["obstacle_chance"]:
                    kind = random.choices(("pie", "overtime"), weights=(54, 46), k=1)[0]
                else:
                    kind = random.choices(
                        ("offwork", "weekend"), weights=(74, 26), k=1
                    )[0]
            self._spawn_one(kind, lane)

        self.spawn_timer = random.uniform(config["spawn_min"], config["spawn_max"])

    def _spawn_one(self, kind: str, lane: int):
        """在指定通道生成一个物件。"""
        config = LEVELS[self.level_index]
        spec = OBJECT_SPECS[kind]
        lane_width = ARENA.width / 5.0
        base_x = ARENA.left + lane_width * (lane + 0.5)
        base_x += random.uniform(-lane_width * 0.20, lane_width * 0.20)
        sway = random.uniform(0.0, 13.0)
        half_w = spec["width"] / 2 + 10
        base_x = clamp(
            base_x,
            ARENA.left + half_w + sway,
            ARENA.right - half_w - sway,
        )
        speed = random.uniform(config["speed_min"], config["speed_max"]) * spec[
            "speed_scale"
        ]
        obj = FallingObject(
            kind=kind,
            base_x=base_x,
            y=ARENA.top - spec["height"] / 2 - 14,
            speed=speed,
            sway=sway,
            sway_speed=random.uniform(1.4, 2.5),
            phase=random.uniform(0.0, math.tau),
        )
        self.objects.append(obj)

    def _handle_collisions(self):
        """检查玩家与所有物件的碰撞，并处理收集 / 扣精力。"""
        player_hitbox = self.player.hitbox
        for obj in self.objects[:]:
            if not player_hitbox.colliderect(obj.hitbox):
                continue

            if obj.is_item:
                self.objects.remove(obj)
                self._collect(obj)
            elif self.player.invincible <= 0:
                self.objects.remove(obj)
                self._hit_by(obj)
                # 精力耗尽时立刻结束，避免同一帧继续触发更多反馈。
                if self.energy <= 0:
                    return

    def _collect(self, obj: FallingObject):
        """收集到奖励卡片：增加连击、计算倍率分数并播放粒子。"""
        self.combo += 1
        self.max_combo = max(self.max_combo, self.combo)
        multiplier = self._combo_multiplier()
        points = obj.spec["points"] * multiplier
        self.score += points

        if obj.kind == "offwork":
            self.total_collected_offwork += 1
            label = "准时下班"
        else:
            self.total_collected_weekend += 1
            label = "周末"

        color = obj.spec["fill"]
        suffix = f"  ×{multiplier}" if multiplier > 1 else ""
        self.float_texts.append(
            FloatingText(
                f"{label} +{points}{suffix}",
                obj.x,
                obj.y - 12,
                color,
                life=1.0,
                max_life=1.0,
                size=19,
            )
        )
        for _ in range(13):
            angle = random.uniform(0.0, math.tau)
            speed = random.uniform(60.0, 190.0)
            self.particles.append(
                Particle(
                    obj.x,
                    obj.y,
                    math.cos(angle) * speed,
                    math.sin(angle) * speed - 40,
                    random.uniform(0.35, 0.75),
                    0.75,
                    random.uniform(2.0, 5.0),
                    random.choice((color, GOLD_LIGHT, CREAM)),
                    square=random.random() < 0.35,
                )
            )

    def _hit_by(self, obj: FallingObject):
        """撞到障碍：扣一点精力、清空连击，并触发屏幕震动和红色闪屏。"""
        self.energy = max(0, self.energy - 1)
        self.hit_count += 1
        self.combo = 0
        self.player.invincible = 1.45
        self.damage_timer = 0.35
        self.shake_timer = self.shake_duration = 0.30
        name = obj.spec["label"]
        self._show_toast(f"被『{name}』击中，精力 -1", RED, 1.2)
        self.float_texts.append(
            FloatingText("精力 -1", self.player.x, self.player.y - 52, RED, 0.9, 0.9, 20)
        )
        for _ in range(16):
            angle = random.uniform(0.0, math.tau)
            speed = random.uniform(70.0, 210.0)
            self.particles.append(
                Particle(
                    obj.x,
                    obj.y,
                    math.cos(angle) * speed,
                    math.sin(angle) * speed - 20,
                    random.uniform(0.30, 0.65),
                    0.65,
                    random.uniform(2.0, 5.0),
                    random.choice((RED, CORAL, GOLD_LIGHT)),
                    square=random.random() < 0.5,
                )
            )

    def _combo_multiplier(self) -> int:
        """连击倍率：3 连击 ×2，6 连击 ×3，10 连击及以上 ×4。"""
        if self.combo >= 10:
            return 4
        if self.combo >= 6:
            return 3
        if self.combo >= 3:
            return 2
        return 1

    def _show_toast(self, text: str, color, duration: float):
        """显示一条位于场地顶部的短提示。"""
        self.toast_text = text
        self.toast_color = color
        self.toast_timer = duration
        self.toast_duration = duration

    def _spawn_confetti(self, amount: int, accent):
        """在通关 / 胜利时撒一些几何彩色纸片。"""
        palette = (accent, GOLD, MINT, BLUE, CREAM, CORAL)
        for _ in range(amount):
            self.particles.append(
                Particle(
                    random.uniform(ARENA.left + 20, ARENA.right - 20),
                    random.uniform(ARENA.top + 20, ARENA.centery),
                    random.uniform(-90, 90),
                    random.uniform(-190, -50),
                    random.uniform(0.9, 1.8),
                    1.8,
                    random.uniform(2.5, 5.5),
                    random.choice(palette),
                    square=True,
                )
            )

    # ------------------------------------------------------------------
    # 绘制入口
    # ------------------------------------------------------------------
    def render(self):
        """把当前场景画到 canvas 上，再按需要应用屏幕震动并翻转显示。"""
        if self.state in ("playing", "paused", "level_clear"):
            self._draw_gameplay_scene()
            if self.state == "paused":
                self._draw_pause_overlay()
            elif self.state == "level_clear":
                self._draw_level_clear_overlay()
        elif self.state == "menu":
            self._draw_menu()
        else:
            self._draw_results()

        # 受击时让整个画面轻微抖动，增强反馈。抖动只发生在游戏进行中。
        offset = (0, 0)
        if self.state == "playing" and self.shake_timer > 0:
            ratio = clamp(self.shake_timer / max(self.shake_duration, 0.001), 0.0, 1.0)
            magnitude = int(7 * ratio)
            offset = (
                random.randint(-magnitude, magnitude),
                random.randint(-magnitude, magnitude),
            )
        self.screen.fill((24, 30, 43))
        self.screen.blit(self.canvas, offset)
        pygame.display.flip()

    def _draw_gameplay_scene(self):
        """绘制 HUD、场地、物件、玩家和特效。"""
        surface = self.canvas
        surface.blit(self.background, (0, 0))
        self._draw_hud(surface)

        old_clip = surface.get_clip()
        surface.set_clip(ARENA.inflate(-2, -2))
        for obj in sorted(self.objects, key=lambda item: item.y):
            obj.draw(surface, self.fonts)
        self.player.draw(surface)
        for particle in self.particles:
            particle.draw(surface)
        for text in self.float_texts:
            text.draw(surface, self.fonts)
        surface.set_clip(old_clip)

        self._draw_toast(surface)

        if self.damage_timer > 0:
            alpha = int(150 * clamp(self.damage_timer / 0.35, 0.0, 1.0))
            self.damage_overlay.set_alpha(alpha)
            surface.blit(self.damage_overlay, (0, 0))

    def _draw_hud(self, surface):
        """顶部信息条：标题、关卡、倒计时、分数、精力和连击。"""
        config = LEVELS[self.level_index]
        pygame.draw.rect(surface, (205, 190, 172), HUD_RECT.move(0, 5), border_radius=22)
        pygame.draw.rect(surface, NAVY, HUD_RECT, border_radius=22)
        pygame.draw.rect(surface, (78, 94, 126), HUD_RECT, width=1, border_radius=22)

        # 左侧 logo 和名称
        icon_rect = pygame.Rect(47, 45, 44, 44)
        pygame.draw.rect(surface, CORAL, icon_rect, border_radius=13)
        draw_briefcase_icon(surface, icon_rect, CREAM, NAVY)
        self.fonts.draw(
            surface, GAME_TITLE, 28, CREAM, (105, 34), bold=True, shadow=(20, 27, 43)
        )
        self.fonts.draw(
            surface,
            "躲避职场小烦恼，收集生活小确幸",
            13,
            MUTED,
            (107, 74),
        )

        # 分隔线
        pygame.draw.line(surface, (67, 82, 112), (334, 34), (334, 111), 1)

        # 中间：关卡与倒计时
        self.fonts.draw(
            surface,
            f"第 {self.level_index + 1} 关 / 3 · {config['name']}",
            15,
            (200, 210, 228),
            (356, 31),
        )
        remaining = max(0.0, self.level_time_left)
        clock_seconds = int(math.ceil(remaining - 1e-9))
        urgent = self.state == "playing" and remaining <= 6.0
        timer_color = CREAM
        if urgent:
            pulse = 0.5 + 0.5 * math.sin(self.anim_time * 10.0)
            timer_color = lerp_color(CREAM, (255, 139, 120), pulse)
        self.fonts.draw(
            surface,
            format_clock(clock_seconds),
            30,
            timer_color,
            (356, 53),
            bold=True,
            shadow=(17, 24, 38),
        )
        self.fonts.draw(
            surface,
            "剩余时间",
            12,
            MUTED,
            (466, 65),
        )

        # 进度条
        bar_bg = pygame.Rect(356, 101, 250, 8)
        pygame.draw.rect(surface, (62, 78, 107), bar_bg, border_radius=4)
        duration = max(config["duration"], 0.001)
        progress = clamp(1.0 - remaining / duration, 0.0, 1.0)
        bar_fill = bar_bg.copy()
        bar_fill.width = int(bar_bg.width * progress)
        if bar_fill.width > 0:
            pygame.draw.rect(
                surface,
                config["accent"] if not urgent else CORAL,
                bar_fill,
                border_radius=4,
            )

        pygame.draw.line(surface, (67, 82, 112), (654, 34), (654, 111), 1)

        # 右侧：分数、精力、连击
        self.fonts.draw(surface, "本局得分", 13, MUTED, (675, 30))
        self.fonts.draw(
            surface,
            f"{self.score:,}",
            30,
            GOLD_LIGHT,
            (675, 50),
            bold=True,
            shadow=(17, 24, 38),
        )

        self.fonts.draw(
            surface,
            "精力",
            13,
            MUTED,
            (916, 30),
            anchor="topright",
        )
        for i in range(self.player.max_energy):
            draw_heart(surface, 856 + i * 26, 73, 19, i < self.energy)

        combo_mult = self._combo_multiplier()
        if self.combo >= 2:
            combo_text = f"连击 {self.combo} · 得分 ×{combo_mult}"
            combo_color = GOLD_LIGHT if combo_mult > 1 else (205, 213, 228)
        else:
            combo_text = "连续收集可提升倍率"
            combo_color = (143, 157, 181)
        self.fonts.draw(
            surface,
            combo_text,
            12,
            combo_color,
            (918, 92),
            anchor="topright",
        )

        # HUD 最底部的强调色短线
        pygame.draw.line(
            surface,
            config["accent"],
            (HUD_RECT.left + 24, HUD_RECT.bottom - 1),
            (HUD_RECT.right - 24, HUD_RECT.bottom - 1),
            2,
        )

    def _draw_toast(self, surface):
        """绘制顶部短暂提示条，带透明度和淡出。"""
        if self.toast_timer <= 0 or not self.toast_text:
            return
        alpha = 255
        if self.toast_timer < 0.35:
            alpha = int(255 * (self.toast_timer / 0.35))
        text_image = self.fonts.render(self.toast_text, 15, CREAM, bold=False, alpha=alpha)
        width = text_image.get_width() + 38
        height = 38
        x = WIDTH // 2 - width // 2
        y = ARENA.top + 16
        box = pygame.Surface((width, height), pygame.SRCALPHA)
        pygame.draw.rect(box, (35, 46, 70, int(225 * alpha / 255)), box.get_rect(), border_radius=19)
        pygame.draw.rect(
            box,
            (*self.toast_color, int(180 * alpha / 255)),
            box.get_rect(),
            width=1,
            border_radius=19,
        )
        box.blit(text_image, (19, (height - text_image.get_height()) // 2))
        surface.blit(box, (x, y))

    # ------------------------------------------------------------------
    # 场景：标题页
    # ------------------------------------------------------------------
    def _draw_menu(self):
        surface = self.canvas
        surface.blit(self.background, (0, 0))

        # 背景里缓慢上下浮动的小卡片，强化主题但不抢文字。
        for kind, x, y, phase in self.menu_cards:
            bob = math.sin(self.anim_time * 1.15 + phase) * 9.0
            draw_object_card(
                surface,
                self.fonts,
                kind,
                x,
                y + bob,
                self.anim_time + phase,
                floor_shadow=False,
            )

        surface.blit(self.menu_dim, (0, 0))
        panel = pygame.Rect(120, 42, 720, 556)
        draw_soft_panel(surface, panel, (37, 48, 74), (111, 127, 160), radius=28)
        pygame.draw.line(
            surface, (255, 255, 255), (panel.left + 60, panel.top + 1), (panel.right - 60, panel.top + 1), 1
        )

        # 顶部小徽章
        badge = pygame.Rect(390, 64, 180, 27)
        pygame.draw.rect(surface, (53, 68, 96), badge, border_radius=14)
        pygame.draw.rect(surface, (93, 110, 143), badge, width=1, border_radius=14)
        self.fonts.draw(
            surface,
            "全年龄 · 轻松一刻",
            13,
            (218, 227, 241),
            badge.center,
            anchor="center",
        )

        # 标题分两段上色，让“打工人”更醒目。
        title_left = self.fonts.render("打工人", 54, GOLD, bold=True)
        title_right = self.fonts.render("生存记", 54, CREAM, bold=True)
        total_width = title_left.get_width() + title_right.get_width()
        title_x = WIDTH // 2 - total_width // 2
        title_y = 100
        shadow_left = self.fonts.render("打工人", 54, (18, 25, 40), bold=True)
        shadow_right = self.fonts.render("生存记", 54, (18, 25, 40), bold=True)
        surface.blit(shadow_left, (title_x + 3, title_y + 3))
        surface.blit(shadow_right, (title_x + title_left.get_width() + 3, title_y + 3))
        surface.blit(title_left, (title_x, title_y))
        surface.blit(title_right, (title_x + title_left.get_width(), title_y))

        self.fonts.draw(
            surface,
            "躲开画饼与加班，收集准时下班和周末。",
            18,
            (220, 228, 241),
            (WIDTH // 2, 182),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            "方向键 / WASD 移动　·　红色扣 1 点精力　·　绿色加分　·　ESC 随时退出",
            13,
            (151, 166, 192),
            (WIDTH // 2, 218),
            anchor="center",
        )

        pygame.draw.line(surface, (73, 88, 116), (178, 248), (782, 248), 1)
        self.fonts.draw(
            surface,
            "今 日 职 场 图 鉴",
            14,
            GOLD,
            (WIDTH // 2, 266),
            anchor="center",
            bold=True,
        )

        # 四个图鉴卡片。菜单中不画地板阴影，使用深色投影。
        card_y = 334
        card_data = (
            ("pie", 266, "红色：躲开！"),
            ("overtime", 398, None),
            ("offwork", 548, "绿色：收集！"),
            ("weekend", 684, None),
        )
        for kind, cx, _caption in card_data:
            draw_object_card(
                surface,
                self.fonts,
                kind,
                cx,
                card_y,
                self.anim_time + cx * 0.01,
                floor_shadow=False,
            )
        self.fonts.draw(
            surface,
            "红色：躲开，别让它们靠近",
            14,
            (255, 157, 145),
            (332, 382),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            "绿色：收集，给今天加点分",
            14,
            (125, 224, 196),
            (616, 382),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            "连续收集可提升得分倍率，最高 ×4",
            12,
            (143, 158, 184),
            (WIDTH // 2, 409),
            anchor="center",
        )

        # 开始按钮：用呼吸式高亮提示操作。
        pulse = 0.5 + 0.5 * math.sin(self.anim_time * 3.2)
        button = pygame.Rect(320, 434, 320, 58)
        pygame.draw.rect(
            surface, (16, 24, 39), button.move(0, 5), border_radius=18
        )
        button_fill = lerp_color(GOLD, (255, 226, 157), pulse * 0.65)
        pygame.draw.rect(surface, button_fill, button, border_radius=18)
        pygame.draw.rect(surface, (255, 241, 204), button, width=2, border_radius=18)
        self.fonts.draw(
            surface,
            "按 Enter / 空格 开始打工",
            20,
            (48, 48, 51),
            button.center,
            anchor="center",
            bold=True,
        )

        record_text = (
            f"本次会话最高分　{self.best_score:,}"
            if self.best_score > 0
            else "第一次来打工？慢慢来，准点下班最重要。"
        )
        self.fonts.draw(
            surface,
            record_text,
            13,
            (188, 200, 218),
            (WIDTH // 2, 520),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            "3 个关卡 · 难度递增 · P 暂停 · 无外部素材",
            12,
            (118, 134, 161),
            (WIDTH // 2, 548),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            "本作纯属轻松娱乐，祝每位打工人都有好心情。",
            11,
            (100, 117, 144),
            (WIDTH // 2, 574),
            anchor="center",
        )

    # ------------------------------------------------------------------
    # 场景：暂停
    # ------------------------------------------------------------------
    def _draw_pause_overlay(self):
        """在游戏画面之上盖一层暂停面板。"""
        self.canvas.blit(self.modal_dim, (0, 0))
        panel = pygame.Rect(326, 206, 308, 220)
        draw_soft_panel(self.canvas, panel, (37, 48, 74), (111, 127, 160), radius=24)
        self.fonts.draw(
            self.canvas,
            "暂停中",
            34,
            CREAM,
            (WIDTH // 2, 242),
            anchor="center",
            bold=True,
        )
        self.fonts.draw(
            self.canvas,
            "先喝口水，再继续。",
            15,
            (186, 199, 219),
            (WIDTH // 2, 288),
            anchor="center",
        )
        self.fonts.draw(
            self.canvas,
            "P / Enter 继续　·　ESC 退出",
            14,
            GOLD_LIGHT,
            (WIDTH // 2, 346),
            anchor="center",
            bold=True,
        )
        self.fonts.draw(
            self.canvas,
            "游戏计时已暂停",
            12,
            (132, 148, 175),
            (WIDTH // 2, 386),
            anchor="center",
        )

    # ------------------------------------------------------------------
    # 场景：关卡完成
    # ------------------------------------------------------------------
    def _draw_level_clear_overlay(self):
        """显示本关奖励与下一关提示。"""
        self.canvas.blit(self.modal_dim, (0, 0))
        config = LEVELS[self.level_index]
        panel = pygame.Rect(242, 130, 476, 432)
        draw_soft_panel(self.canvas, panel, (37, 48, 74), (111, 127, 160), radius=28)

        final_level = self.level_index >= len(LEVELS) - 1
        # 顶部圆形勾选图标
        center_x = WIDTH // 2
        pygame.draw.circle(self.canvas, config["accent"], (center_x, 180), 31)
        pygame.draw.circle(self.canvas, CREAM, (center_x, 180), 31, 2)
        pygame.draw.lines(
            self.canvas,
            CREAM,
            False,
            [(center_x - 13, 180), (center_x - 3, 190), (center_x + 15, 168)],
            4,
        )

        title = "全部关卡完成！" if final_level else f"第 {self.level_index + 1} 关完成"
        self.fonts.draw(
            self.canvas,
            title,
            34,
            CREAM,
            (center_x, 220),
            anchor="center",
            bold=True,
            shadow=(18, 25, 40),
        )
        subtitle = (
            "三关全部通过，今晚的快乐属于你。"
            if final_level
            else f"{config['name']} · 短暂休息一下。"
        )
        self.fonts.draw(
            self.canvas,
            subtitle,
            14,
            (183, 197, 218),
            (center_x, 257),
            anchor="center",
        )
        pygame.draw.line(
            self.canvas, (73, 88, 116), (panel.left + 54, 282), (panel.right - 54, 282), 1
        )

        # 本关数据
        rows = (
            ("本关得分", f"{self.level_earned:,}"),
            ("通关奖励", f"+{self.last_bonus:,}"),
            ("剩余精力", f"{self.energy} / {self.player.max_energy}"),
            ("累计得分", f"{self.score:,}"),
        )
        line_y = 306
        for label, value in rows:
            self.fonts.draw(
                self.canvas,
                label,
                14,
                (155, 171, 195),
                (panel.left + 70, line_y),
            )
            self.fonts.draw(
                self.canvas,
                value,
                18,
                GOLD_LIGHT if label == "累计得分" else CREAM,
                (panel.right - 70, line_y - 2),
                anchor="topright",
                bold=True,
            )
            line_y += 34

        if final_level:
            hint = "按 Enter 查看本局结算"
        else:
            next_config = LEVELS[self.level_index + 1]
            hint = f"按 Enter 进入第 {self.level_index + 2} 关 · {next_config['name']}"
            if self.energy < self.player.max_energy:
                hint += "（精力 +1）"
        pulse = 0.5 + 0.5 * math.sin(self.anim_time * 4.0)
        button = pygame.Rect(panel.left + 66, 452, panel.width - 132, 52)
        pygame.draw.rect(self.canvas, (27, 37, 57), button.move(0, 4), border_radius=16)
        pygame.draw.rect(
            self.canvas,
            lerp_color(config["accent"], (255, 255, 255), 0.15 + 0.12 * pulse),
            button,
            border_radius=16,
        )
        self.fonts.draw(
            self.canvas,
            hint,
            15,
            CREAM,
            button.center,
            anchor="center",
            bold=True,
        )
        self.fonts.draw(
            self.canvas,
            "ESC 退出游戏",
            11,
            (120, 136, 162),
            (center_x, 530),
            anchor="center",
        )

    # ------------------------------------------------------------------
    # 场景：结算
    # ------------------------------------------------------------------
    def _draw_results(self):
        """完整展示本局数据、头衔和重开选项。"""
        surface = self.canvas
        surface.blit(self.background, (0, 0))
        surface.blit(self.result_dim, (0, 0))
        panel = pygame.Rect(150, 42, 660, 556)
        draw_soft_panel(surface, panel, (37, 48, 74), (111, 127, 160), radius=28)

        # 顶部徽章与标题
        badge = pygame.Rect(390, 54, 180, 27)
        pygame.draw.rect(surface, (53, 68, 96), badge, border_radius=14)
        pygame.draw.rect(surface, (93, 110, 143), badge, width=1, border_radius=14)
        self.fonts.draw(
            surface,
            "打工结算 · 本局报告",
            13,
            (218, 227, 241),
            badge.center,
            anchor="center",
        )

        title = "顺利下班，周末快乐！" if self.result_victory else "今天先到这里"
        self.fonts.draw(
            surface,
            title,
            32,
            CREAM,
            (WIDTH // 2, 110),
            anchor="center",
            bold=True,
            shadow=(18, 25, 40),
        )
        subtitle = (
            "三关全部通过，你把生活守住了。"
            if self.result_victory
            else "精力用完啦，下次记得先照顾自己。"
        )
        self.fonts.draw(
            surface,
            subtitle,
            14,
            (183, 197, 218),
            (WIDTH // 2, 147),
            anchor="center",
        )

        # 头衔徽章
        rank_image = self.fonts.render(self.result_rank, 15, NAVY, bold=True)
        rank_rect = pygame.Rect(
            WIDTH // 2 - (rank_image.get_width() + 42) // 2,
            162,
            rank_image.get_width() + 42,
            28,
        )
        pygame.draw.rect(surface, GOLD, rank_rect, border_radius=14)
        surface.blit(rank_image, rank_image.get_rect(center=rank_rect.center))

        # 大分数
        self.fonts.draw(
            surface,
            "本局得分",
            12,
            (155, 171, 195),
            (WIDTH // 2, 201),
            anchor="center",
        )
        self.fonts.draw(
            surface,
            f"{self.score:,}",
            46,
            GOLD_LIGHT,
            (WIDTH // 2, 212),
            anchor="midtop",
            bold=True,
            shadow=(18, 25, 40),
        )
        pygame.draw.line(
            surface, (73, 88, 116), (panel.left + 50, 280), (panel.right - 50, 280), 1
        )

        # 数据统计：两列四行
        left_label_x = panel.left + 58
        left_value_x = panel.left + 296
        right_label_x = panel.left + 336
        right_value_x = panel.right - 58
        stats = (
            (f"{self.levels_cleared} / 3", "通关进度", f"{format_clock(self.run_time)}", "坚持时间"),
            (f"{self.total_collected_offwork} 次", "准时下班", f"{self.total_collected_weekend} 次", "周末"),
            (f"{self.dodged_count} 个", "成功躲避", f"{self.max_combo} 连" if self.max_combo else "—", "最高连击"),
            (f"{self.hit_count} 次", "被命中", f"{self.best_score:,}", "本次最佳"),
        )
        row_y = 296
        for left_value, left_label, right_value, right_label in stats:
            self.fonts.draw(surface, left_label, 13, (155, 171, 195), (left_label_x, row_y + 3))
            self.fonts.draw(
                surface,
                left_value,
                17,
                CREAM,
                (left_value_x, row_y),
                anchor="topright",
                bold=True,
            )
            self.fonts.draw(surface, right_label, 13, (155, 171, 195), (right_label_x, row_y + 3))
            self.fonts.draw(
                surface,
                right_value,
                17,
                CREAM,
                (right_value_x, row_y),
                anchor="topright",
                bold=True,
            )
            row_y += 36

        # 按钮
        primary = pygame.Rect(262, 456, 276, 50)
        secondary = pygame.Rect(554, 456, 134, 50)
        pygame.draw.rect(surface, (24, 33, 51), primary.move(0, 4), border_radius=16)
        pygame.draw.rect(surface, GOLD, primary, border_radius=16)
        pygame.draw.rect(surface, (255, 241, 204), primary, width=1, border_radius=16)
        self.fonts.draw(
            surface,
            "R / Enter 再来一次",
            17,
            (47, 48, 54),
            primary.center,
            anchor="center",
            bold=True,
        )
        pygame.draw.rect(surface, (53, 68, 96), secondary, border_radius=16)
        pygame.draw.rect(surface, (111, 127, 160), secondary, width=1, border_radius=16)
        self.fonts.draw(
            surface,
            "M 回标题",
            15,
            CREAM,
            secondary.center,
            anchor="center",
            bold=True,
        )
        self.fonts.draw(
            surface,
            "ESC 退出游戏　·　本次最高分已记录在本次会话中",
            11,
            (120, 136, 162),
            (WIDTH // 2, 534),
            anchor="center",
        )

    # ------------------------------------------------------------------
    # 自检
    # ------------------------------------------------------------------
    def self_test(self) -> bool:
        """
        无窗口基础自检。

        依次验证：
            1. 标题页能正常初始化与绘制；
            2. 可以开始游戏，方向键和 WASD 事件都能移动玩家；
            3. 收集加分、碰撞扣精力均生效；
            4. 三个关卡能依次完成并进入结算页；
            5. 结算页可以重新开始一局。
        """
        print("[self-test] pygame display/font initialization: OK")

        def check(condition: bool, message: str):
            if not condition:
                raise AssertionError(message)
            print(f"[self-test] {message}: OK")

        check(len(LEVELS) == 3, "three levels configured")
        check(self.state == "menu", "menu state ready")
        self.render()

        self.start_run()
        check(self.state == "playing", "run starts in playing state")
        check(self.energy == 3, "initial energy is 3")
        self.render()

        # 禁用自然生成，避免自检结果受随机数影响。
        self.spawn_timer = 999.0
        before_x = self.player.x
        self.player.update(0.08, _TestKeys(pygame.K_RIGHT))
        check(self.player.x > before_x, "arrow-key movement works")

        # 测试 WASD 的事件跟踪路径：即使 get_pressed() 没有状态，
        # KEYDOWN 维护的按住集合同样应该能驱动角色移动。
        self.held_movement_keys.clear()
        before_x = self.player.x
        self._process_event(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_d))
        check(pygame.K_d in self.held_movement_keys, "WASD keydown is tracked")
        self.player.update(0.08, _TestKeys(), self.held_movement_keys)
        check(self.player.x > before_x, "WASD movement works")
        self._process_event(pygame.event.Event(pygame.KEYUP, key=pygame.K_d))
        check(pygame.K_d not in self.held_movement_keys, "WASD keyup is tracked")

        # 收集测试：把一张“准时下班”直接放到玩家身上。
        self.objects.clear()
        collectible = FallingObject(
            kind="offwork",
            base_x=self.player.x,
            y=self.player.y,
            speed=0.0,
            sway=0.0,
            sway_speed=0.0,
            phase=0.0,
        )
        self.objects.append(collectible)
        before_score = self.score
        self.update(1.0 / 60.0)
        check(self.score > before_score, "collectible adds score")
        check(self.total_collected_offwork == 1, "collectible counter updates")

        # 碰撞测试：确保无敌时间已结束，再撞一次“加班”。
        self.player.invincible = 0.0
        self.objects.clear()
        hazard = FallingObject(
            kind="overtime",
            base_x=self.player.x,
            y=self.player.y,
            speed=0.0,
            sway=0.0,
            sway_speed=0.0,
            phase=0.0,
        )
        self.objects.append(hazard)
        before_energy = self.energy
        self.update(1.0 / 60.0)
        check(self.energy == before_energy - 1, "obstacle reduces energy")
        check(self.hit_count == 1, "hit counter updates")

        # 依次强制结束三关，验证关卡流转与最终结算。
        for index in range(3):
            self.spawn_timer = 999.0
            self.objects.clear()
            self.level_time_left = 0.001
            self.update(1.0 / 60.0)
            check(self.state == "level_clear", f"level {index + 1} clear screen")
            self.render()
            self._handle_keydown(pygame.K_RETURN)

        check(self.state == "results", "all levels lead to results")
        check(self.result_victory, "victory result recorded")
        self.render()

        self._handle_keydown(pygame.K_r)
        check(self.state == "playing", "restart from results works")
        check(self.score < 20, "restart resets score")  # 仅允许刚开始的一两分生存分
        self.render()

        print("[self-test] all checks passed.")
        return True

    def shutdown(self):
        """安全关闭 pygame 模块。重复调用无副作用。"""
        if not self.closed:
            pygame.quit()
            self.closed = True


class _TestKeys:
    """自检用的按键模拟对象，只实现玩家移动需要的索引访问。"""

    def __init__(self, *pressed):
        self.pressed = set(pressed)

    def __getitem__(self, key):
        return key in self.pressed


# ---------------------------------------------------------------------------
# 程序入口
# ---------------------------------------------------------------------------
def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    self_test = "--self-test" in argv

    # 自检使用 SDL 的 dummy 视频驱动：不弹窗口，也不依赖桌面环境。
    if self_test:
        os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

    game = None
    try:
        game = Game()
        if self_test:
            return 0 if game.self_test() else 1
        game.run()
        return 0
    except pygame.error as exc:
        print(f"pygame 初始化或运行失败：{exc}", file=sys.stderr)
        print("请确认图形环境可用，或先用 --self-test 做无窗口自检。", file=sys.stderr)
        return 1
    finally:
        if game is not None:
            game.shutdown()


if __name__ == "__main__":
    raise SystemExit(main())
