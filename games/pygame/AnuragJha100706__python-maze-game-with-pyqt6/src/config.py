"""
Global Configuration & Aesthetic Tokens.
Defines color palettes, typography, grid defaults, and application metadata.
"""

# Application Metadata
APP_NAME = "MAZE // CORE WORKBENCH"
APP_SUBTITLE = "Advanced Algorithmic Research & Gaming Platform"
APP_VERSION = "2.0.0 (Postgraduate Edition)"

# Dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 800
DEFAULT_GRID_SIZE = 20
MIN_GRID_SIZE = 10
MAX_GRID_SIZE = 60

# Palette Tokens (Cyberpunk / Modern Dark Glassmorphism)
COLORS = {
    "bg_dark": "#0B0E17",          # Deep Obsidian Canvas
    "bg_card": "#131826",          # Card Surface
    "bg_card_alt": "#181E30",      # Alternate Row / Hover Surface
    "border": "#222B42",           # 1px Structure Border
    "primary": "#00F0FF",          # Cyberpunk Cyan
    "primary_hover": "#33F3FF",
    "secondary": "#7B2CBF",        # Electric Violet
    "secondary_hover": "#9D4EDD",
    "accent_gold": "#FFB703",      # Amber Gold (Keys, Frontier, Rank 1)
    "accent_silver": "#C0C0C0",    # Rank 2
    "accent_bronze": "#CD7F32",    # Rank 3
    "success": "#06D6A0",          # Emerald Neon (Goals, Player 1)
    "danger": "#EF476F",           # Coral Neon (Hunter AI, Traps)
    "text_high": "#F8F9FA",        # Primary White
    "text_muted": "#8E9AAF",       # Secondary Silver
    "text_dim": "#5C677D"          # Placeholder Dark Gray
}

# RGB Equivalents for Pygame
PYGAME_COLORS = {
    "background": (11, 14, 23),
    "wall": (78, 120, 180),        # Bright high-visibility cyber steel-blue walls
    "passage": (14, 18, 28),       # Deep dark obsidian corridor floor
    "player1": (0, 240, 255),      # Cyan
    "player2": (123, 44, 191),     # Purple
    "computer": (239, 71, 111),    # Coral Red
    "goal": (6, 214, 160),         # Emerald Green
    "key": (255, 183, 3),          # Amber Gold
    "frontier": (255, 183, 3),     # Amber Open Set
    "closed": (0, 150, 180),       # Translucent Cyan Visited
    "optimal_path": (6, 214, 160), # Neon Emerald Path
    "text": (248, 249, 250)
}

# Game Modes Mapping
GAME_MODES = {
    0: {"name": "Solo Time Trial", "badge": "MODE 0", "desc": "Race against the clock to the exit."},
    1: {"name": "Two Player PvP", "badge": "MODE 1", "desc": "Player 1 (Arrows) vs Player 2 (WASD)."},
    2: {"name": "Race vs AI", "badge": "MODE 2", "desc": "Compete against an optimal A* pathfinding agent."},
    3: {"name": "Chase Survival", "badge": "MODE 3", "desc": "Evade the Hunter AI with predictive pursuit."},
    4: {"name": "Escape Heist", "badge": "MODE 4", "desc": "Collect 8 keys & blast walls to unlock the exit."}
}
