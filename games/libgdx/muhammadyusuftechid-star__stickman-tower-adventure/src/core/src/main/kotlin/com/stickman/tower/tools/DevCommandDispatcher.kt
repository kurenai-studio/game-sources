package com.stickman.tower.tools

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.world.TowerFloor
import com.stickman.tower.world.TowerLevelBuilder

/**
 * Hasil eksekusi sebuah perintah developer console (CLI).
 */
data class DevCommandResult(
    val success: Boolean,
    val message: String
)

/**
 * Interactive CLI & Scriptable Command Dispatcher:
 * Menerima string input dari terminal, UI console, skrip QA, atau automation test,
 * mem-parsing argumen, dan mengeksekusi aksi in-game secara deterministik.
 */
class DevCommandDispatcher {

    // Callbacks aksi permainan yang dihubungkan ke PlayScreen / DevToolsOverlay
    var onSetGodMode: ((Boolean) -> Unit)? = null
    var onSetInfiniteEnergy: ((Boolean) -> Unit)? = null
    var onSetTimeScale: ((Float) -> Unit)? = null
    var onStepFrame: (() -> Unit)? = null
    var onWarpFloor: ((Int) -> Unit)? = null
    var onHealFull: (() -> Unit)? = null
    var onGrantGold: ((Int) -> Unit)? = null
    var onGrantLevel: (() -> Unit)? = null
    var onKillAllEnemies: (() -> Unit)? = null
    var onSwitchArchetype: ((CharacterArchetype) -> Unit)? = null
    var onSpawnEnemy: ((EnemyType) -> Unit)? = null
    var onToggleHitboxes: ((Boolean?) -> Unit)? = null
    var onWarpBossRushStage: ((Int) -> Unit)? = null
    var onSetBossRushTimer: ((Float) -> Unit)? = null
    var onUnlockAllTitles: (() -> Unit)? = null
    var onUnlockAllContent: (() -> Unit)? = null
    var onResetSave: (() -> Unit)? = null
    var getCurrentFloor: (() -> TowerFloor?)? = null

    // Riwayat Log Konsol
    val commandHistory = mutableListOf<String>()
    val consoleLog = mutableListOf<String>()

    /**
     * Mengeksekusi string perintah tunggal (misal: "gold 5000", "warp 3", "archetype AGILE").
     */
    fun dispatch(commandLine: String): DevCommandResult {
        val trimmed = commandLine.trim()
        if (trimmed.isEmpty()) {
            return DevCommandResult(false, "Perintah kosong.")
        }

        commandHistory.add(trimmed)
        val tokens = trimmed.split("\\s+".toRegex())
        val cmd = tokens[0].lowercase()
        val args = tokens.drop(1)

        val result = try {
            when (cmd) {
                "help", "?" -> handleHelp()
                "god" -> handleGodMode(args)
                "energy", "infenergy" -> handleInfiniteEnergy(args)
                "speed", "timescale" -> handleTimeScale(args)
                "pause" -> {
                    onSetTimeScale?.invoke(0f)
                    DevCommandResult(true, "Simulasi di-pause (timescale = 0.0x).")
                }
                "resume" -> {
                    onSetTimeScale?.invoke(1.0f)
                    DevCommandResult(true, "Simulasi dilanjutkan (timescale = 1.0x).")
                }
                "step" -> {
                    onStepFrame?.invoke()
                    DevCommandResult(true, "Memajukan simulasi tepat 1 frame (1/60s).")
                }
                "heal" -> {
                    onHealFull?.invoke()
                    DevCommandResult(true, "HP pemain dipulihkan 100%.")
                }
                "gold" -> {
                    val amount = args.firstOrNull()?.toIntOrNull() ?: 1000
                    onGrantGold?.invoke(amount)
                    DevCommandResult(true, "+$amount Gold berhasil ditambahkan.")
                }
                "level", "levelup" -> {
                    onGrantLevel?.invoke()
                    DevCommandResult(true, "Pemain naik 1 level.")
                }
                "kill", "nuke" -> {
                    onKillAllEnemies?.invoke()
                    DevCommandResult(true, "Semua musuh di lantai saat ini telah dieliminasi.")
                }
                "warp", "floor" -> handleWarp(args)
                "archetype", "class" -> handleArchetype(args)
                "spawn" -> handleSpawn(args)
                "hitbox", "bounds" -> handleHitbox(args)
                "audit" -> handleAudit(args)
                "reachability" -> handleReachability(args)
                "simulate", "balance" -> handleSimulate(args)
                "validate_assets", "assets" -> handleValidateAssets()
                "bossrush", "gauntlet" -> handleBossRush(args)
                "bossrush_time", "br_time" -> handleBossRushTime(args)
                "unlock_titles", "titles" -> handleUnlockTitles()
                "unlock_all", "unlockall" -> handleUnlockAll()
                "reset_save", "resetsave" -> handleResetSave()
                "metrics", "stats", "mem" -> handleMetrics()
                else -> DevCommandResult(false, "Perintah '$cmd' tidak dikenali. Ketik 'help' untuk daftar perintah.")
            }
        } catch (t: Throwable) {
            DevCommandResult(false, "Error mengeksekusi '$trimmed': ${t.message}")
        }

        val logEntry = "[CMD] $trimmed -> ${if (result.success) "OK: " else "ERR: "}${result.message}"
        consoleLog.add(logEntry)
        if (consoleLog.size > 50) consoleLog.removeAt(0)

        return result
    }

    private fun handleHelp(): DevCommandResult {
        val helpText = """
            Daftar Perintah Developer Console:
            - god [on|off]           : Toggle / set invulnerability
            - energy [on|off]        : Toggle infinite skill & ult energy
            - timescale <float>      : Ubah kecepatan game (0.1x s/d 10.0x)
            - pause / resume / step  : Jeda waktu atau maju 1 frame
            - heal                   : Pulihkan HP pemain ke 100%
            - gold <jumlah>          : Berikan gold (default: 1000)
            - level                  : Berikan 1 level up
            - kill                   : Basmi semua musuh di ruangan
            - warp <1..50>           : Teleportasi ke lantai tertentu
            - archetype <nama>       : Hot-swap arketipe (BALANCED, AGILE, HEAVY)
            - spawn <tipe>           : Spawn musuh (MELEE, RANGED, FLYING, SHIELDED)
            - hitbox [on|off]        : Tampilkan bounding boxes & gizmos
            - audit [lantai]         : Audit integritas platform & softlock
            - reachability [lantai]  : Audit keterjangkauan jalur BFS platform
            - simulate [ronde]       : Jalankan simulasi balancing pertarungan
            - validate_assets        : Validasi file aset font, gambar & lore
            - bossrush <1..5>        : Lompat langsung ke tahap Boss Rush
            - bossrush_time <detik>  : Set timer Boss Rush untuk uji rank
            - unlock_titles          : Buka seluruh gelar ksatria untuk QA
            - unlock_all             : Buka 50 lantai, seluruh hero, relik & lore
            - reset_save             : Reset save data ke kondisi awal onboarding
            - metrics / stats        : Tampilkan info JVM heap & floor entities
        """.trimIndent()
        return DevCommandResult(true, helpText)
    }

    private fun handleGodMode(args: List<String>): DevCommandResult {
        val newState = when (args.firstOrNull()?.lowercase()) {
            "on", "true", "1" -> true
            "off", "false", "0" -> false
            else -> true
        }
        onSetGodMode?.invoke(newState)
        return DevCommandResult(true, "God Mode disetel ke: $newState")
    }

    private fun handleInfiniteEnergy(args: List<String>): DevCommandResult {
        val newState = when (args.firstOrNull()?.lowercase()) {
            "on", "true", "1" -> true
            "off", "false", "0" -> false
            else -> true
        }
        onSetInfiniteEnergy?.invoke(newState)
        return DevCommandResult(true, "Infinite Energy disetel ke: $newState")
    }

    private fun handleTimeScale(args: List<String>): DevCommandResult {
        val scale = args.firstOrNull()?.toFloatOrNull() ?: 1.0f
        val clamped = scale.coerceIn(0.0f, 10.0f)
        onSetTimeScale?.invoke(clamped)
        return DevCommandResult(true, "Timescale diubah menjadi: ${clamped}x")
    }

    private fun handleWarp(args: List<String>): DevCommandResult {
        val target = args.firstOrNull()?.toIntOrNull()
            ?: return DevCommandResult(false, "Sintaks: warp <nomor_lantai>")
        if (target < 1) return DevCommandResult(false, "Nomor lantai harus >= 1")
        onWarpFloor?.invoke(target)
        return DevCommandResult(true, "Teleportasi ke Lantai $target diproses.")
    }

    private fun handleArchetype(args: List<String>): DevCommandResult {
        val archName = args.firstOrNull()
            ?: return DevCommandResult(false, "Sintaks: archetype <BALANCED|AGILE|HEAVY>")
        val arch = CharacterArchetype.entries.firstOrNull { it.name.equals(archName, ignoreCase = true) }
            ?: return DevCommandResult(false, "Arketipe '$archName' tidak valid. Pilihan: BALANCED, AGILE, HEAVY")
        onSwitchArchetype?.invoke(arch)
        return DevCommandResult(true, "Karakter berhasil di-switch ke arketipe: ${arch.name} (${arch.characterName})")
    }

    private fun handleSpawn(args: List<String>): DevCommandResult {
        val typeName = args.firstOrNull()
            ?: return DevCommandResult(false, "Sintaks: spawn <MELEE|RANGED|FLYING|SHIELDED>")
        val enemyType = EnemyType.entries.firstOrNull { it.name.equals(typeName, ignoreCase = true) }
            ?: return DevCommandResult(false, "Tipe musuh '$typeName' tidak valid. Pilihan: MELEE, RANGED, FLYING, SHIELDED")
        onSpawnEnemy?.invoke(enemyType)
        return DevCommandResult(true, "Musuh varian ${enemyType.name} berhasil di-spawn di arena.")
    }

    private fun handleHitbox(args: List<String>): DevCommandResult {
        val target = when (args.firstOrNull()?.lowercase()) {
            "on", "true", "1" -> true
            "off", "false", "0" -> false
            else -> null // Toggle
        }
        onToggleHitboxes?.invoke(target)
        return DevCommandResult(true, "Visual hitbox / debug bounds diubah.")
    }

    private fun handleAudit(args: List<String>): DevCommandResult {
        val targetFloor = args.firstOrNull()?.toIntOrNull()
        return if (targetFloor != null) {
            val floor = TowerLevelBuilder.buildFloor(targetFloor)
            val report = LevelSanityValidator.validateFloor(floor)
            DevCommandResult(report.isValid, report.summary())
        } else {
            val curr = getCurrentFloor?.invoke()
            if (curr != null) {
                val report = LevelSanityValidator.validateFloor(curr)
                DevCommandResult(report.isValid, report.summary())
            } else {
                val reports = LevelSanityValidator.auditAllStoryFloors()
                val failed = reports.filter { !it.isValid }
                if (failed.isEmpty()) {
                    DevCommandResult(true, "✓ Semua 10 lantai Story lolos audit level sanity.")
                } else {
                    DevCommandResult(false, "✗ Ditemukan kegagalan pada: ${failed.map { it.floorNumber }}")
                }
            }
        }
    }

    private fun handleReachability(args: List<String>): DevCommandResult {
        val targetFloor = args.firstOrNull()?.toIntOrNull()
        val floor = if (targetFloor != null) {
            TowerLevelBuilder.buildFloor(targetFloor)
        } else {
            getCurrentFloor?.invoke() ?: TowerLevelBuilder.buildFloor(1)
        }
        val result = LevelReachabilityGraph.analyzeFloor(floor)
        return DevCommandResult(result.isPassed, result.summary())
    }

    private fun handleSimulate(args: List<String>): DevCommandResult {
        val rounds = args.firstOrNull()?.toIntOrNull() ?: 50
        val report = CombatBalanceSimulator.runFullAudit(roundsPerArchetype = rounds)
        return DevCommandResult(true, report.summary())
    }

    private fun handleValidateAssets(): DevCommandResult {
        val report = AssetPipelineValidator.validateAll()
        return DevCommandResult(report.isClean, report.summary())
    }

    private fun handleBossRush(args: List<String>): DevCommandResult {
        val stage = args.firstOrNull()?.toIntOrNull()?.coerceIn(1, 5) ?: 1
        if (onWarpBossRushStage != null) {
            onWarpBossRushStage?.invoke(stage)
            return DevCommandResult(true, "Warp ke Boss Rush Tahap $stage.")
        }
        return DevCommandResult(false, "Handler Boss Rush belum terhubung.")
    }

    private fun handleBossRushTime(args: List<String>): DevCommandResult {
        val timeSec = args.firstOrNull()?.toFloatOrNull()?.coerceAtLeast(0f) ?: 120f
        if (onSetBossRushTimer != null) {
            onSetBossRushTimer?.invoke(timeSec)
            return DevCommandResult(true, "Timer Boss Rush disetel ke ${timeSec}s.")
        }
        return DevCommandResult(false, "Handler Boss Rush Timer belum terhubung.")
    }

    private fun handleUnlockTitles(): DevCommandResult {
        if (onUnlockAllTitles != null) {
            onUnlockAllTitles?.invoke()
            return DevCommandResult(true, "Seluruh gelar ksatria siluet telah dibuka untuk inspeksi visual.")
        }
        return DevCommandResult(false, "Handler unlock titles belum terhubung.")
    }

    private fun handleUnlockAll(): DevCommandResult {
        if (onUnlockAllContent != null) {
            onUnlockAllContent?.invoke()
            return DevCommandResult(true, "Seluruh konten (50 Lantai, Semua Pahlawan, Relik, & Lore) telah dibuka untuk pengujian.")
        }
        return DevCommandResult(false, "Handler unlock all content belum terhubung.")
    }

    private fun handleResetSave(): DevCommandResult {
        if (onResetSave != null) {
            onResetSave?.invoke()
            return DevCommandResult(true, "Save data telah direset ke kondisi awal untuk QA onboarding.")
        }
        return DevCommandResult(false, "Handler reset save belum terhubung.")
    }

    private fun handleMetrics(): DevCommandResult {
        val runtime = Runtime.getRuntime()
        val usedMB = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        val totalMB = runtime.totalMemory() / (1024 * 1024)
        val maxMB = runtime.maxMemory() / (1024 * 1024)
        val floor = getCurrentFloor?.invoke()
        val mobCount = floor?.enemies?.count { !it.health.isDead } ?: 0
        return DevCommandResult(true, "Metrics: Heap $usedMB/$totalMB MB (Max $maxMB MB) | Floor: ${floor?.floorNumber ?: 0} | Active Mobs: $mobCount")
    }
}
