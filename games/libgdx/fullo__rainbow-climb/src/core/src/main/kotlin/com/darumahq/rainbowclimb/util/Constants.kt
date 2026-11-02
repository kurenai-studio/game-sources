package com.darumahq.rainbowclimb.util

object Constants {
    // Virtual resolution (doubled for 32x32 sprites)
    const val VIRTUAL_WIDTH = 480f
    const val VIRTUAL_HEIGHT = 800f

    // Tile size
    const val TILE_SIZE = 32f

    // Physics (scaled 2x for new resolution)
    const val GRAVITY = -1800f
    const val JUMP_VELOCITY = 700f
    const val MOVE_SPEED = 300f
    const val MAX_FALL_SPEED = -1000f

    // Player (32x32 sprite)
    const val PLAYER_WIDTH = 32f
    const val PLAYER_HEIGHT = 32f

    // Rainbow bridge
    const val RAINBOW_MAX_AMMO = 3
    const val RAINBOW_REGEN_TIME = 1f
    const val RAINBOW_DURATION = 4f
    const val RAINBOW_LENGTH = 128f   // ~4 tiles
    const val RAINBOW_WIDTH = 8f      // platform height (32x8 sprite)

    // Camera
    const val BASE_SCROLL_SPEED = 60f  // scaled 2x
    const val DIFFICULTY_INCREASE = 0.002f

    // Chunks
    const val CHUNK_HEIGHT = 16
    const val CHUNK_HEIGHT_PX = CHUNK_HEIGHT * TILE_SIZE
    const val PLATFORMS_PER_LEVEL = 50

    // Enemies (32x32 sprite)
    const val ENEMY_SIZE = 32f
    const val BOMBER_WIDTH = 32f
    const val BOMBER_HEIGHT = 32f

    // Projectiles
    const val PROJECTILE_SIZE = 10f
    const val PROJECTILE_SPEED = 240f
    const val BOMB_FALL_SPEED = -300f
    const val PROJECTILE_LIFETIME = 3f

    // Enemy AI (scaled 2x for distances)
    const val SHOOTER_COOLDOWN = 2.5f
    const val BOMBER_COOLDOWN = 3.0f
    const val BOMBER_DROP_RANGE_X = 40f
    const val BOMBER_HEIGHT_OFFSET = 120f
    const val CHASER_DETECT_RADIUS = 192f  // 6 tiles
    const val CHASER_DURATION = 3f
    const val CHASER_SPEED_MULT = 2.5f

    // Power-ups
    const val POWERUP_SPAWN_CHANCE = 0.05f

    // Collectibles
    const val COLLECTIBLE_SIZE = 32f
    const val GEM_SIZE = 16f
}
