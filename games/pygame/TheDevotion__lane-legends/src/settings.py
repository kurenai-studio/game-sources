"""
Lane Legends: Human vs AI
settings.py - Game configurations, constants, difficulty levels, and RL hyperparameters.
"""

from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ASSETS_DIR = BASE_DIR / "assets"
IMAGES_DIR = ASSETS_DIR / "images"
SOUNDS_DIR = ASSETS_DIR / "sounds"

Q_TABLE_FILE = DATA_DIR / "q_table.json"
HIGH_SCORES_FILE = DATA_DIR / "high_scores.json"

# Display & Performance
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
FPS = 60
TITLE = "Lane Legends: Human vs AI"
SUBTITLE = "Human vs Machine — Who Rules the Road?"

# Track Geometry
TRACK_WIDTH = 480
LANE_COUNT = 3
LANE_WIDTH = TRACK_WIDTH // LANE_COUNT  # 160 px per lane

# Track 1 (Left: Human / Player 1)
TRACK_1_LEFT = 70
TRACK_1_RIGHT = TRACK_1_LEFT + TRACK_WIDTH  # 550
TRACK_1_LANES = [
    TRACK_1_LEFT + LANE_WIDTH * i + LANE_WIDTH // 2
    for i in range(LANE_COUNT)
]  # [150, 310, 470]

# Center Divider
CENTER_DIVIDER_LEFT = TRACK_1_RIGHT  # 550
CENTER_DIVIDER_WIDTH = 160
CENTER_DIVIDER_RIGHT = CENTER_DIVIDER_LEFT + CENTER_DIVIDER_WIDTH  # 710

# Track 2 (Right: AI / Player 2)
TRACK_2_LEFT = 730
TRACK_2_RIGHT = TRACK_2_LEFT + TRACK_WIDTH  # 1210
TRACK_2_LANES = [
    TRACK_2_LEFT + LANE_WIDTH * i + LANE_WIDTH // 2
    for i in range(LANE_COUNT)
]  # [810, 970, 1130]

# Vehicle Settings
CAR_WIDTH = 52
CAR_HEIGHT = 92
CAR_RESTING_Y = 560  # Y position on screen

LANE_CHANGE_LERP = 12.0  # Speed of lane change animation interpolation

# Speeds (in game pixels per second & km/h conversion)
KMH_CONVERSION = 0.5  # 1 pixel/sec ~ 0.5 km/h for HUD display
BASE_SPEED = 320.0     # px/s (~160 km/h)
MAX_SPEED = 460.0      # px/s (~230 km/h)
NITRO_SPEED = 640.0    # px/s (~320 km/h)
MIN_SPEED = 120.0      # px/s (~60 km/h after collision)
ACCELERATION = 140.0   # px/s^2
BRAKING_DECEL = 260.0  # px/s^2
COAST_DECEL = 60.0     # px/s^2 natural drag

# Nitro Mechanic
NITRO_CAPACITY = 100.0
NITRO_DRAIN_RATE = 42.0     # drains in ~2.4 seconds of continuous boost
NITRO_RECHARGE_RATE = 14.0  # full refill in ~7.1 seconds
NITRO_BOOST_MULTIPLIER = 1.38

# Collisions & Recovery
COLLISION_SPEED_DROP = 0.35  # drops to 35% of current speed
INVULNERABILITY_TIME = 1.35  # seconds of invulnerability & flashing after hit
OIL_SLIP_DURATION = 0.9      # seconds of steering disturbance and drag

# Race Distance
RACE_DISTANCE_METERS = 3000.0
METERS_PER_PIXEL = 0.25  # 12,000 pixels total race travel distance

# Obstacle Types
OBSTACLE_TRAFFIC = "traffic_car"
OBSTACLE_BARRIER = "road_barrier"
OBSTACLE_CONE = "traffic_cone"
OBSTACLE_OIL = "oil_spill"

# AI Difficulty Profiles
DIFFICULTY_EASY = "EASY"
DIFFICULTY_MEDIUM = "MEDIUM"
DIFFICULTY_HARD = "HARD"

DIFFICULTY_PROFILES = {
    DIFFICULTY_EASY: {
        "name": "Puncture Panda 🐼",
        "tag": "EASY",
        "speed_multiplier": 0.88,
        "reaction_interval": 0.48,     # evaluates decisions every ~0.48s
        "epsilon_randomness": 0.24,    # 24% chance of random suboptimal lane
        "nitro_threshold": 92.0,       # only uses boost when meter is nearly full
        "nitro_chance": 0.45,
        "description": "Slow reactions, occasional blunders, rarely hits nitro.",
    },
    DIFFICULTY_MEDIUM: {
        "name": "Nitro Nawab 🏎️",
        "tag": "MEDIUM",
        "speed_multiplier": 1.00,
        "reaction_interval": 0.26,     # evaluates decisions every ~0.26s
        "epsilon_randomness": 0.05,    # 5% chance of randomness
        "nitro_threshold": 55.0,       # uses nitro when half charged and road ahead is safe
        "nitro_chance": 0.75,
        "description": "Balanced pace, solid Q-learning lane choices, strategic nitro.",
    },
    DIFFICULTY_HARD: {
        "name": "Cyber Cheetah 🐆",
        "tag": "HARD",
        "speed_multiplier": 1.10,
        "reaction_interval": 0.12,     # lightning reactions ~0.12s
        "epsilon_randomness": 0.00,    # 100% optimal exploitation of Q-values
        "nitro_threshold": 30.0,       # aggressive nitro on open lanes
        "nitro_chance": 0.95,
        "description": "Blistering speed, razor-sharp reactions, ruthless nitro usage.",
    },
}

# Q-Learning Hyperparameters & State-Action Space
RL_ALPHA = 0.15        # Learning rate
RL_GAMMA = 0.90        # Discount factor
RL_EPSILON_START = 1.0 # Initial exploration
RL_EPSILON_MIN = 0.03  # Minimum exploration
RL_EPSILON_DECAY = 0.996
RL_TRAINING_EPISODES = 1600

# State discretization distance boundaries (in pixels relative to car)
DIST_NEAR = 175.0      # Near danger zone (< 175px ahead)
DIST_MEDIUM = 360.0    # Medium awareness zone (175px - 360px)
# > 360px is considered Far / Clear

STATE_DIST_NEAR = 0
STATE_DIST_MEDIUM = 1
STATE_DIST_FAR = 2

# Actions
ACTION_LEFT = 0
ACTION_STAY = 1
ACTION_RIGHT = 2
ACTION_NAMES = ["MOVE_LEFT", "STAY", "MOVE_RIGHT"]

# Rewards for training
REWARD_PROGRESS = 1.0
REWARD_PASS_OBSTACLE = 10.0
REWARD_AVOID_DANGER = 6.0
REWARD_UNNECESSARY_CHANGE = -1.5
REWARD_COLLISION = -28.0
REWARD_FINISH = 35.0

# Colors (Hex / RGB)
COLOR_BG = (13, 17, 23)
COLOR_ASPHALT = (26, 29, 36)
COLOR_ASPHALT_LINE = (38, 43, 53)
COLOR_GRASS = (18, 38, 24)
COLOR_GRASS_DETAIL = (25, 52, 33)
COLOR_KERB_RED = (220, 38, 38)
COLOR_KERB_WHITE = (245, 245, 245)
COLOR_LANE_MARKING = (240, 220, 90)
COLOR_ROAD_BORDER = (90, 100, 115)

COLOR_WHITE = (255, 255, 255)
COLOR_OFFWHITE = (225, 230, 240)
COLOR_MUTED = (139, 148, 158)
COLOR_DARK_CARD = (22, 27, 34)
COLOR_CARD_BORDER = (48, 54, 61)

# Neon Accent Colors
COLOR_CYAN = (0, 229, 255)
COLOR_CYAN_GLOW = (0, 180, 216)
COLOR_ORANGE = (255, 145, 0)
COLOR_ORANGE_GLOW = (255, 109, 0)
COLOR_CRIMSON = (255, 23, 68)
COLOR_CRIMSON_GLOW = (213, 0, 0)
COLOR_GREEN = (0, 230, 118)
COLOR_YELLOW = (255, 214, 0)
COLOR_PURPLE = (171, 71, 188)

# Player Car Color Themes
CAR_P1_COLOR = (0, 210, 255)       # Electric Cyan
CAR_P2_COLOR = (255, 140, 0)       # Sunset Orange
CAR_AI_COLOR = (245, 34, 45)       # Cyber Crimson
