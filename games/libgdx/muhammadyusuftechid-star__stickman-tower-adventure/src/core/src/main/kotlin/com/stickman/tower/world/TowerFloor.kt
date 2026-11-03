package com.stickman.tower.world

import com.badlogic.gdx.math.Rectangle
import com.stickman.tower.enemy.BossEnemy
import com.stickman.tower.enemy.Enemy
import com.stickman.tower.physics.Platform

/**
 * Merepresentasikan data struktural dan objek satu lantai Menara (Tower Floor).
 */
data class TowerFloor(
    val floorNumber: Int,
    val floorName: String = "Floor $floorNumber",
    val mapBounds: Rectangle = Rectangle(0f, 0f, 30f, 15f),
    val spawnX: Float = 2f,
    val spawnY: Float = 2f,
    val platforms: List<Platform> = emptyList(),
    val spikes: List<SpikeHazard> = emptyList(),
    val chests: List<TreasureChest> = emptyList(),
    val enemies: List<Enemy> = emptyList(),
    val boss: BossEnemy? = null,
    val checkpoint: Checkpoint? = null,
    val exitPortal: StageExit = StageExit(28f, 2f),
    val isBossFloor: Boolean = false,
    val actTitle: String = "ACT I: THE INITIATION",
    val actSubtitle: String = "LOWER SPIRE",
    val loreTablets: List<LoreTablet> = emptyList(),
    val storyDialogues: List<StoryDialogue> = emptyList(),
    val environmentalProps: List<EnvironmentalProp> = emptyList(),
    val bloodAltar: BloodAltar? = null,
    val isSafeZone: Boolean = false,
    val gravityScale: Float = 1.0f,
    val runicBarriers: List<RunicBarrier> = emptyList(),
    val runicKeys: List<RunicKey> = emptyList(),
    var zephyrCocoon: ZephyrCocoon? = null,
    var titanPillar: TitanPillar? = null,
    val basaltWalls: List<TitanBasaltWall> = emptyList(),
    val prismAltar: PrismAltar? = null
) {
    val dynamicEnemies = mutableListOf<Enemy>()
    val allEnemies: List<Enemy> get() = if (dynamicEnemies.isEmpty()) enemies else enemies + dynamicEnemies
}
