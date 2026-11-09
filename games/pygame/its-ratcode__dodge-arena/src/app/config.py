"""Engine and gameplay tuning.

Every number that changes how the game runs or plays lives in this module,
so balancing never means hunting through the code.

Values that grow harder over a run come in ``*_START`` / ``*_END`` pairs:
the start value applies at 0% danger, the end value at 100% danger.
"""

import math

# --- Window / timing ------------------------------------------------------------
SCREEN_WIDTH = 1100
SCREEN_HEIGHT = 750
FPS = 60
MAX_FRAME_DT = 0.05        # clamp each frame's delta time (s) so a hitch can't teleport things

# --- Arena ------------------------------------------------------------------------
GRID_SPACING = 50          # px between grid lines
GRID_MAJOR_EVERY = 4       # every Nth grid line is drawn brighter
ARENA_BORDER_INSET = 6     # px between the window edge and the arena border

# --- Player -------------------------------------------------------------------------
PLAYER_RADIUS = 16
PLAYER_SPEED = 325         # px/s

# --- Controls (defaults; players change them in Settings) ----------------------------
# Action -> pygame key name. The order here is the order of the Settings list.
DEFAULT_KEYBINDS = {
    "shield": "q", "wall": "w", "dash": "e",       # abilities
    "sprint": "d", "blink": "f",                    # utility spells
    "powerup": "space",
    "pause": "escape",
    "restart": "r",                                 # play again (game over) / restart (pause)
}
DEFAULT_MOVE_BUTTON = 3    # pygame mouse button: 1 = left, 3 = right

# --- Click marker ---------------------------------------------------------------------
CLICK_MARKER_DURATION = 0.4    # s
CLICK_MARKER_RADIUS = 12       # px

# --- Danger (difficulty) ------------------------------------------------------------------
DANGER_RAMP_TIME = 120.0       # s for danger to climb from 0% to 100%

# --- Bolts (the threats) ----------------------------------------------------------------
BOLT_SPEED_START = 400         # px/s
BOLT_SPEED_END = 640
BOLT_SPEED_VARIANCE = 0.10     # each bolt gets a random +/-10% speed
BOLT_SPAWN_INTERVAL_START = 0.8    # s between bolts
BOLT_SPAWN_INTERVAL_END = 0.30
DOUBLE_SHOT_CHANCE_START = 0.0     # chance a spawn sends a second bolt from another edge
DOUBLE_SHOT_CHANCE_END = 0.35
BOLT_LENGTH = 70               # px, along the flight direction
BOLT_WIDTH = 20                # px, across the flight direction
BOLT_SPAWN_MARGIN = 10         # px outside the window edge where bolts appear
FIRST_SPAWN_DELAY = 1.0        # s of calm at the start of a run

# --- Lasers ------------------------------------------------------------------------------
LASER_FIRST_DELAY = 10.0       # s into a run before the first laser
LASER_INTERVAL_MIN_START = 8.0     # random gap between lasers ...
LASER_INTERVAL_MAX_START = 13.0
LASER_INTERVAL_MIN_END = 3.5       # ... shrinking as danger rises
LASER_INTERVAL_MAX_END = 6.5
LASER_WARNING_START = 1.10     # s of harmless warning before it fires
LASER_WARNING_END = 0.70
LASER_ACTIVE_TIME = 0.35       # s the beam is deadly
LASER_FADE_TIME = 0.25         # s of harmless fade-out
LASER_WIDTH = 46               # px
LASER_LENGTH = 2 * math.hypot(SCREEN_WIDTH, SCREEN_HEIGHT) + 200   # always spans the arena

# --- Abilities ----------------------------------------------------------------------------
SHIELD_COOLDOWN = 12.0         # s
SHIELD_DURATION = 1.5          # s the bubble lasts if nothing hits it
SHIELD_RADIUS = PLAYER_RADIUS + 10     # px; while shielded, the bubble is your hitbox

WALL_COOLDOWN = 18.0
WALL_DURATION = 3.0
WALL_LENGTH = 150              # px
WALL_THICKNESS = 14            # px
WALL_DISTANCE = 60             # px in front of the player, toward the cursor
WALL_BLINK_TIME = 0.6          # s before vanishing that the wall blinks

DASH_COOLDOWN = 7.0
DASH_RANGE = 200               # px
DASH_SPEED = 1400              # px/s; you travel the distance, so you can be hit mid-dash

# --- Utility spells (long cooldowns, for emergencies) ---------------------------------------
SPRINT_COOLDOWN = 20.0         # s
SPRINT_DURATION = 3.0          # s
SPRINT_MULTIPLIER = 1.5        # x movement speed

BLINK_COOLDOWN = 25.0
BLINK_RANGE = 220              # px; a closer cursor means a shorter blink. Further than Dash: it's the emergency spell

# --- Power-ups (one-use pickups) ----------------------------------------------------------------
POWERUP_FIRST_DELAY = 12.0     # s into a run before the first pickup appears
POWERUP_RESPAWN_MIN = 6.0      # s after one is taken or expires before the next appears
POWERUP_RESPAWN_MAX = 10.0
POWERUP_MAP_LIFETIME = 9.0     # s a pickup lies on the map
POWERUP_BLINK_TIME = 2.5       # s before vanishing that the pickup blinks
POWERUP_RADIUS = 15            # px
POWERUP_HOLD_TIME = 25.0       # s a picked-up power-up can be held before it expires

STASIS_DURATION = 1.5          # s frozen and invulnerable: no moving, no casting
TIME_WARP_DURATION = 3.0       # s
TIME_WARP_FACTOR = 0.4         # threats and their spawn timers run at 40% speed
WARP_RANGE = 320               # px; a long-range Blink
NOVA_EFFECT_DURATION = 0.5     # s; Nova clears every bolt and laser at once
COIN_RUSH_DURATION = 8.0       # s
COIN_RUSH_MULT = 2             # coins are worth double ...
COIN_RUSH_INTERVAL_FACTOR = 0.35   # ... spawn ~3x as often ...
COIN_RUSH_EXTRA_COINS = 3      # ... and the cap on the field rises by this much

# --- Second Wind (passive upgrade) ---------------------------------------------------------------
SECOND_WIND_COOLDOWN = 120.0   # s to recharge at level 1; each extra level takes 30 s off
SECOND_WIND_MIN_COOLDOWN = 10.0
SECOND_WIND_INVULN_TIME = 1.5  # s of invulnerability after it saves you

# --- Coins ------------------------------------------------------------------------------------
COIN_FIRST_DELAY = 2.0         # s into a run before the first coin
COIN_SPAWN_INTERVAL = 2.5      # s between coins
COIN_MAX_ON_FIELD = 4
COIN_LIFETIME = 8.0            # s before an uncollected coin disappears
COIN_BLINK_TIME = 2.0          # s before vanishing that the coin blinks
COIN_RADIUS = 9                # px
COIN_VALUE = 1
BIG_COIN_VALUE = 5
BIG_COIN_CHANCE = 0.12
BIG_COIN_RADIUS_SCALE = 1.5
COIN_MAGNET_SPEED = 320        # px/s a coin flies toward you inside the magnet radius
COIN_EDGE_MARGIN = 70          # px from the left/right edges where coins never spawn ...
COIN_TOP_MARGIN = 120          # ... the timer at the top ...
COIN_BOTTOM_MARGIN = 140       # ... and the ability bar at the bottom
COIN_MIN_PLAYER_DISTANCE = 150     # px; coins never spawn right on top of you
COINS_PER_SECOND_SURVIVED = 0.2    # end-of-run bonus: 1 coin per 5 s alive

# --- Progression --------------------------------------------------------------------------------
# Upgrade prices and effects are in app/progression/upgrades.py.
MIN_COOLDOWN_MULT = 0.3        # cooldowns never drop below 30% however much haste you buy
SAVE_FILENAME = "save.json"    # in the user data folder (app.core.storage); delete it to reset progress

# --- Audio ---------------------------------------------------------------------------------------
AUDIO_RATE = 22050             # samples per second (plenty for synthesized effects, quick to build)
AUDIO_CHANNELS = 24            # sounds that can play at the same time
SOUND_MIN_GAP = 0.03           # s; the same sound can't retrigger faster than this
COIN_COMBO_WINDOW = 1.5        # s; coins grabbed within this window of each other rise in pitch ...
COIN_COMBO_STEPS = 6           # ... through this many pitches
LASER_CHARGE_SOUND_TIME = 0.6  # s before a laser fires that its charge-up whine starts
MUSIC_BPM = 128                # tempo of the soundtrack
MUSIC_BARS = 4                 # loop length in bars (one chord per bar: Am - F - C - G)
MUSIC_LEVEL_THRESHOLDS = (0.2, 0.45, 0.75)     # danger at which the music gains a layer
MUSIC_DUCK = 0.45              # music volume factor while paused or on the game over card

# --- Game feel -------------------------------------------------------------------------------
SHAKE_DECAY = 9.0              # how quickly screen shake settles (higher = faster)
SHAKE_BLOCK = 6                # px of shake when the Shield blocks a hit ...
SHAKE_SECOND_WIND = 12         # ... when Second Wind saves you ...
SHAKE_NOVA = 9                 # ... when Nova goes off ...
SHAKE_DEATH = 16               # ... and when a hit ends the run
HITSTOP_BLOCK = 0.05           # s the action freezes on a blocked hit, so it lands with weight ...
HITSTOP_SECOND_WIND = 0.12     # ... and on a Second Wind save
DEATH_SEQUENCE_TIME = 0.9      # s of slow motion after the fatal hit, before the game over card
DEATH_SLOWMO = 0.25            # threats move at this speed during it
INTRO_READY_TIME = 0.8         # s "GET READY" shows ...
INTRO_GO_TIME = 0.55           # ... then "GO!"
TOAST_DURATION = 2.6           # s a pop-up message stays
SCENE_FADE_TIME = 0.15         # s the old screen takes to fade out when the screen changes
FLOATING_TEXT_DURATION = 0.8   # s a "+1" / "BLOCKED" rises and fades
PATH_DOT_SPACING = 18          # px between the dots of the movement path preview
NEAR_MISS_DISTANCE = 26        # px; a threat passing this close without hitting is a close call ...
CLOSE_CALL_COINS = 1           # ... and pays this much (risk = reward)
DANGER_MILESTONES = (0.25, 0.5, 0.75, 1.0)     # announced with a message and a sound
SURVIVAL_MILESTONE_INTERVAL = 30.0             # s; a fanfare every time you last this much longer

# --- Effects ----------------------------------------------------------------------------------
BURST_DURATION = 0.35          # s; ring shown when a hit is blocked or a bolt hits a wall
BLINK_EFFECT_DURATION = 0.4    # s
SPEED_TRAIL_LENGTH = 8         # positions kept for the trail while sprinting or dashing
