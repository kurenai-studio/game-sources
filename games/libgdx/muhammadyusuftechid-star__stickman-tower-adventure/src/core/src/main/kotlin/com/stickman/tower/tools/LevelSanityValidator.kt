package com.stickman.tower.tools

import com.stickman.tower.world.TowerFloor
import com.stickman.tower.world.TowerLevelBuilder

/**
 * Laporan hasil audit diagnostik level/lantai menara.
 */
data class LevelValidationReport(
    val floorNumber: Int,
    val floorName: String,
    val isValid: Boolean,
    val errors: List<String>,
    val warnings: List<String>,
    val platformCount: Int,
    val spikeCount: Int,
    val enemyCount: Int,
    val hasBoss: Boolean,
    val reachability: ReachabilityAuditResult? = null
) {
    fun summary(): String {
        return if (isValid) {
            val reachStr = if (reachability != null) " Plats:${reachability.reachablePlatformsCount}/$platformCount" else ""
            "✓ [PASSED] $floorName (P:$platformCount, S:$spikeCount, E:$enemyCount, Boss:$hasBoss$reachStr)"
        } else {
            "✗ [FAILED] $floorName - ${errors.size} Errors: ${errors.joinToString("; ")}"
        }
    }
}

/**
 * Alat Diagnostik & Validasi Level Otomatis (Level Sanity & Playability Validator Tool):
 * - Memverifikasi titik spawn pemain tidak tertusuk duri atau melayang tanpa dasar.
 * - Memverifikasi portal stage exit dapat dicapai dan memiliki pijakan kokoh.
 * - Memverifikasi tidak ada rintangan duri yang menutupi checkpoint aman.
 * - Memeriksa konsistensi ketinggian lompatan agar bebas dari softlock/deadlock.
 * - Memeriksa integritas musuh dan bos di arena.
 */
object LevelSanityValidator {

    // Batas lompatan fisik pemain tanpa double-jump (vy = 11.5f, g = -28f -> h_max ≈ 2.36m)
    const val MAX_SINGLE_JUMP_REACH = 2.45f

    fun validateFloor(floor: TowerFloor): LevelValidationReport {
        val errors = mutableListOf<String>()
        val warnings = mutableListOf<String>()

        // 1. Validasi Batas Map (Map Bounds)
        if (floor.mapBounds.width <= 0f || floor.mapBounds.height <= 0f) {
            errors.add("Map bounds berdimensi tidak valid: ${floor.mapBounds.width} x ${floor.mapBounds.height}")
        }

        // 2. Validasi Titik Spawn Pemain
        val spawnX = floor.spawnX
        val spawnY = floor.spawnY

        if (spawnX < floor.mapBounds.x || spawnX > floor.mapBounds.x + floor.mapBounds.width) {
            errors.add("Spawn X ($spawnX) berada di luar batas horizontal map [${floor.mapBounds.x} .. ${floor.mapBounds.x + floor.mapBounds.width}]")
        }

        // Cek apakah spawn menimpa duri
        val spawnOnSpike = floor.spikes.any {
            spawnX >= it.bounds.x && spawnX <= it.bounds.x + it.bounds.width &&
            spawnY >= it.bounds.y && spawnY <= it.bounds.y + it.bounds.height
        }
        if (spawnOnSpike) {
            errors.add("FATAL: Titik spawn pemain ($spawnX, $spawnY) bertabrakan langsung dengan SpikeHazard!")
        }

        // Cek apakah ada platform di bawah spawn
        val groundBelowSpawn = floor.platforms.any {
            spawnX >= it.left - 0.5f && spawnX <= it.right + 0.5f &&
            spawnY >= it.top - 0.2f && spawnY <= it.top + 4.0f
        }
        if (!groundBelowSpawn) {
            warnings.add("Peringatan: Tidak ada platform terdeteksi tepat di bawah titik spawn ($spawnX, $spawnY)")
        }

        // 3. Validasi Portal Exit
        val exit = floor.exitPortal
        val exitOnSpike = floor.spikes.any {
            exit.bounds.overlaps(it.bounds)
        }
        if (exitOnSpike) {
            errors.add("FATAL: Portal keluar bertabrakan dengan SpikeHazard!")
        }

        val groundBelowExit = floor.platforms.any {
            exit.x >= it.left - 0.8f && exit.x <= it.right + 0.8f &&
            exit.y >= it.top - 0.5f && exit.y <= it.top + 1.5f
        }
        if (!groundBelowExit) {
            warnings.add("Portal keluar mungkin melayang tanpa pijakan platform di bawahnya")
        }

        // 4. Validasi Checkpoint
        val cp = floor.checkpoint
        if (cp != null) {
            val cpOnSpike = floor.spikes.any { cp.bounds.overlaps(it.bounds) }
            if (cpOnSpike) {
                errors.add("Checkpoint bertabrakan dengan SpikeHazard!")
            }
        }

        // 5. Validasi Dimensi Platform
        for ((idx, p) in floor.platforms.withIndex()) {
            if (p.bounds.width <= 0.2f || p.bounds.height <= 0.1f) {
                errors.add("Platform #$idx berdimensi terlalu kecil (${p.bounds.width} x ${p.bounds.height})")
            }
        }

        // 6. Validasi Boss Floor
        if (floor.isBossFloor && floor.boss == null) {
            errors.add("Lantai berstatus isBossFloor=true namun entitas Boss null!")
        }

        // 7. Validasi Keterjangkauan Graph (Reachability BFS)
        val reachability = LevelReachabilityGraph.analyzeFloor(floor)
        if (!reachability.isExitReachable) {
            errors.add("FATAL SOFTLOCK: Portal keluar tidak dapat dicapai dari titik spawn melalui lintasan platform!")
        }
        if (!reachability.areCheckpointsReachable) {
            warnings.add("Checkpoint tidak dapat dicapai dari titik spawn")
        }
        if (reachability.unreachableChestsCount > 0) {
            warnings.add("${reachability.unreachableChestsCount} peti harta karun tidak dapat dicapai")
        }

        return LevelValidationReport(
            floorNumber = floor.floorNumber,
            floorName = floor.floorName,
            isValid = errors.isEmpty(),
            errors = errors,
            warnings = warnings,
            platformCount = floor.platforms.size,
            spikeCount = floor.spikes.size,
            enemyCount = floor.enemies.size,
            hasBoss = floor.boss != null,
            reachability = reachability
        )
    }

    /**
     * Mengaudit seluruh lantai Story Mode (Lantai 1 s/d 10).
     */
    fun auditAllStoryFloors(): List<LevelValidationReport> {
        return (1..10).map { floorNum ->
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            validateFloor(floor)
        }
    }

    /**
     * Mengaudit sampel lantai prosedural Endless Spire (Lantai 11 ke atas).
     */
    fun auditEndlessFloors(count: Int = 10): List<LevelValidationReport> {
        return (11 until 11 + count).map { floorNum ->
            val floor = TowerLevelBuilder.buildFloor(floorNum)
            validateFloor(floor)
        }
    }
}
