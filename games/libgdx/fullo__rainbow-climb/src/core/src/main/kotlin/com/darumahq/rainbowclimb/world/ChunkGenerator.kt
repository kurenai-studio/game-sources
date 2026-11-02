package com.darumahq.rainbowclimb.world

import com.darumahq.rainbowclimb.entity.CollectibleType
import com.darumahq.rainbowclimb.entity.EnemyType
import com.darumahq.rainbowclimb.util.Constants
import com.darumahq.rainbowclimb.util.SeededRandom

data class PlatformDef(
    val x: Float,
    val y: Float,
    val width: Float,
    val type: PlatformType
)

data class EnemyDef(
    val x: Float,
    val y: Float,
    val type: EnemyType
)

data class CollectibleDef(
    val x: Float,
    val y: Float,
    val type: CollectibleType
)

data class Chunk(
    val platforms: List<PlatformDef>,
    val enemies: List<EnemyDef>,
    val collectibles: List<CollectibleDef>
)

class ChunkGenerator(private val random: SeededRandom) {

    private var currentLevel = 0

    fun setLevel(level: Int) {
        currentLevel = level
    }

    fun generate(chunkBottomY: Float): Chunk {
        val platforms = mutableListOf<PlatformDef>()
        val enemies = mutableListOf<EnemyDef>()
        val collectibles = mutableListOf<CollectibleDef>()

        val difficultyMult = Math.pow(1.0 + Constants.DIFFICULTY_INCREASE, currentLevel.toDouble()).toFloat()

        // Divide chunk into horizontal bands
        val bandCount = random.nextInt(3, 5)
        val bandHeight = Constants.CHUNK_HEIGHT_PX / bandCount

        for (band in 0 until bandCount) {
            val bandY = chunkBottomY + band * bandHeight

            // Place 1-2 platforms per band
            val platformCount = random.nextInt(1, 2)
            for (p in 0 until platformCount) {
                val platWidth = random.nextFloat(32f, 64f)
                val platX = random.nextFloat(0f, Constants.VIRTUAL_WIDTH - platWidth)
                val platY = bandY + random.nextFloat(8f, bandHeight - 16f)

                val platType = choosePlatformType(difficultyMult)
                platforms.add(PlatformDef(platX, platY, platWidth, platType))

                // Maybe place enemy on platform
                if (random.nextFloat() < 0.2f * difficultyMult.coerceAtMost(3f)) {
                    val enemyType = chooseEnemyType(difficultyMult)
                    enemies.add(EnemyDef(platX + platWidth / 2f, platY + 8f, enemyType))
                }

                // Maybe place collectible
                if (random.nextFloat() < 0.3f) {
                    val collectType = chooseCollectibleType()
                    collectibles.add(CollectibleDef(
                        platX + random.nextFloat(0f, platWidth - 8f),
                        platY + 12f,
                        collectType
                    ))
                }
            }
        }

        return Chunk(platforms, enemies, collectibles)
    }

    private fun choosePlatformType(difficulty: Float): PlatformType {
        val roll = random.nextFloat()
        val movingChance = 0.1f * difficulty.coerceAtMost(3f)
        val crumbleChance = 0.05f * difficulty.coerceAtMost(3f)

        return when {
            roll < movingChance -> PlatformType.MOVING
            roll < movingChance + crumbleChance -> PlatformType.CRUMBLING
            roll < movingChance + crumbleChance + 0.1f -> PlatformType.ONE_WAY
            else -> PlatformType.STATIC
        }
    }

    private fun chooseEnemyType(difficulty: Float): EnemyType {
        val types = mutableListOf(EnemyType.WALKER, EnemyType.FLYER)
        if (difficulty > 1.2f) types.add(EnemyType.HOPPER)
        if (difficulty > 1.5f) types.add(EnemyType.SHOOTER)
        if (difficulty > 2.0f) types.add(EnemyType.BOMBER)
        if (difficulty > 2.5f) types.add(EnemyType.CHASER)
        return types[random.nextInt(types.size)]
    }

    private fun chooseCollectibleType(): CollectibleType {
        val roll = random.nextFloat()
        return when {
            roll < Constants.POWERUP_SPAWN_CHANCE -> {
                val powerUps = listOf(
                    CollectibleType.RAINBOW_BOOST,
                    CollectibleType.DOUBLE_JUMP,
                    CollectibleType.SHIELD,
                    CollectibleType.SLOW_TIME,
                    CollectibleType.MAGNET
                )
                powerUps[random.nextInt(powerUps.size)]
            }
            roll < 0.15f -> CollectibleType.STAR
            else -> CollectibleType.GEM
        }
    }
}
