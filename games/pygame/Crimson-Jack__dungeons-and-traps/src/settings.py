class Settings:
    # Clock
    FPS = 60

    # Debug mode switched on and off with F1/F2/F3 during the game; False in the release version
    DEBUG_MODE_AVAILABLE = True

    # Screen size
    FULL_SCREEN_MODE = False
    # Window size in windowed mode; full screen mode uses the monitor resolution
    WIDTH = 1200
    HEIGHT = 720

    # HEADER_HEIGHT + DASHBOARD_HEIGHT must be smaller than the screen height — the remaining space becomes
    # the game surface height (see screen_manager.py).
    # Header size
    HEADER_HEIGHT = 80
    # Dashboard size
    DASHBOARD_HEIGHT = 144

    # Tile size (rendered). Should be a multiple of 16 (source sprite pixel size) so scaling
    # stays an even integer ratio and pixels don't get blurred/misaligned.
    TILE_SIZE = 48

    # Explosion
    EXPLOSION_WEAPON_RANGE = 5
    NUMBER_OF_EXPLOSION_STEPS = 12

    # Blast effect: number of updates it needs to grow to the size of the game surface
    NUMBER_OF_BLAST_EFFECT_STEPS = 8

    # Score awarded at level completion when all enemies are defeated
    LEVEL_COMPLETION_BONUS = 1000

    # Colors
    GAME_BACKGROUND_COLOR = 39, 39, 39
    ENEMY_PARTICLE_COLORS = [(240, 89, 65), (190, 49, 68), (135, 35, 65), (34, 9, 44)]
    OBSTACLE_PARTICLE_COLORS = [(255, 255, 255), (240, 240, 240), (230, 230, 230), (220, 220, 220)]
    MESSAGE_BACKGROUND_COLOR = 39, 39, 39
    MESSAGE_BORDER_COLOR = 120, 120, 120
    SURFACE_COLOR = 100, 100, 100
    BACKGROUND_COLOR = 120, 120, 120
    BORDER_COLOR = 70, 70, 70
    TEXT_COLOR = 208, 208, 208
    HIGHLIGHTED_TEXT_COLOR = 255, 255, 255
    BAR_TEXT_COLOR = 50, 50, 50
    BLAST_EFFECT_COLOR = 255, 255, 255
    EXPLODE_EFFECT_COLOR = 255, 210, 0
