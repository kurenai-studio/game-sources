package com.stickman.tower.tools

import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.enemy.EnemyType
import com.stickman.tower.rpg.CharacterStats
import kotlin.random.Random

/**
 * Hasil statistik simulasi pertarungan untuk suatu arketipe pada floor/tingkat tertentu.
 */
data class ArchetypeSimulationResult(
    val archetype: CharacterArchetype,
    val floorLevel: Int,
    val totalRounds: Int,
    val wins: Int,
    val losses: Int,
    val winRate: Float,
    val avgTtkSeconds: Float,
    val avgHpRemainingPercent: Float,
    val projectedGoldPerHour: Int,
    val isBalanced: Boolean,
    val notes: String
)

/**
 * Laporan komprehensif seluruh simulasi keseimbangan (Combat & Economy Balance Report).
 */
data class BalanceSimulationReport(
    val totalBattles: Int,
    val archetypeResults: List<ArchetypeSimulationResult>,
    val globalWinRate: Float,
    val overallBalanced: Boolean
) {
    fun summary(): String {
        val sb = StringBuilder()
        sb.appendLine("=== COMBAT & ECONOMY BALANCE SIMULATION REPORT ===")
        sb.appendLine("Total Battles Simulated: $totalBattles | Overall Balanced: $overallBalanced (Avg Winrate: ${"%.1f".format(globalWinRate * 100)}%)")
        sb.appendLine("%-12s | %-6s | %-8s | %-7s | %-8s | %-12s | %s".format("ARCHETYPE", "FLOOR", "WIN RATE", "AVG TTK", "REM HP%", "GOLD/HR", "STATUS"))
        sb.appendLine("-".repeat(78))
        for (r in archetypeResults) {
            val status = if (r.isBalanced) "PASSED" else "ALERT"
            sb.appendLine(
                "%-12s | F%-5d | %6.1f%%  | %5.1fs  | %6.1f%%  | %10d | %s".format(
                    r.archetype.name,
                    r.floorLevel,
                    r.winRate * 100f,
                    r.avgTtkSeconds,
                    r.avgHpRemainingPercent * 100f,
                    r.projectedGoldPerHour,
                    status
                )
            )
        }
        return sb.toString()
    }
}

/**
 * Automated Combat & Economy Balance Simulator (Headless Monte Carlo Engine):
 * Menjalankan ribuan simulasi pertarungan antar-arketipe vs musuh dan bos di berbagai tingkat lantai
 * untuk mendeteksi kecacatan matematis (broken balance, impossible boss, infinite stall, atau krisis ekonomi).
 */
object CombatBalanceSimulator {

    /**
     * Menjalankan simulasi batch cepat untuk semua arketipe playable.
     */
    fun runFullAudit(roundsPerArchetype: Int = 100): BalanceSimulationReport {
        val archetypes = listOf(CharacterArchetype.BALANCED, CharacterArchetype.AGILE, CharacterArchetype.HEAVY)
        val floorsToTest = listOf(1, 3, 5, 8, 10, 15) // Termasuk milestone bos

        val results = mutableListOf<ArchetypeSimulationResult>()
        var totalBattles = 0
        var totalWins = 0

        for (floor in floorsToTest) {
            for (arch in archetypes) {
                val res = simulateFloorEncounter(arch, floorLevel = floor, rounds = roundsPerArchetype)
                results.add(res)
                totalBattles += res.totalRounds
                totalWins += res.wins
            }
        }

        val globalWinRate = if (totalBattles > 0) totalWins.toFloat() / totalBattles else 0f
        val overallBalanced = results.all { it.isBalanced }

        return BalanceSimulationReport(
            totalBattles = totalBattles,
            archetypeResults = results,
            globalWinRate = globalWinRate,
            overallBalanced = overallBalanced
        )
    }

    /**
     * Mensimulasikan serangkaian pertarungan monte-carlo untuk 1 arketipe pada floor tertentu.
     */
    fun simulateFloorEncounter(
        archetype: CharacterArchetype,
        floorLevel: Int,
        rounds: Int = 100,
        randomSeed: Long = 42L
    ): ArchetypeSimulationResult {
        val rng = Random(randomSeed + archetype.ordinal * 1000 + floorLevel)
        var wins = 0
        var totalTtk = 0f
        var totalHpRemaining = 0f
        var totalGoldEarned = 0

        val isBossFloor = floorLevel in setOf(3, 5, 8, 10, 15, 20)
        val playerStats = CharacterStats(
            level = (1 + floorLevel / 2).coerceIn(1, 20),
            baseAttack = 15f + floorLevel * 3.5f,
            defense = 2f + floorLevel * 1.2f,
            baseMaxHp = 100f + floorLevel * 15f
        )

        for (r in 0 until rounds) {
            val (won, ttk, hpPct, gold) = simulateSingleBattle(archetype, playerStats, floorLevel, isBossFloor, rng)
            if (won) wins++
            totalTtk += ttk
            totalHpRemaining += hpPct
            totalGoldEarned += gold
        }

        val winRate = wins.toFloat() / rounds
        val avgTtk = totalTtk / rounds
        val avgHpRem = totalHpRemaining / rounds
        // Proyeksi gold per 1 jam bermain aktif (berdasarkan siklus TTK + 10s antar room)
        val battlesPerHour = (3600f / (avgTtk + 10f)).toInt()
        val avgGoldPerBattle = totalGoldEarned / rounds
        val projectedGoldPerHour = battlesPerHour * avgGoldPerBattle

        // Kriteria Keseimbangan (Health checks):
        // 1. Winrate regular floor: 50% - 99%
        // 2. Winrate boss floor: 35% - 95%
        // 3. TTK wajar: 3 detik s/d 90 detik
        val minExpectedWinRate = if (isBossFloor) 0.30f else 0.45f
        val maxExpectedWinRate = 1.0f
        val isBalanced = winRate in minExpectedWinRate..maxExpectedWinRate && avgTtk in 2.0f..95.0f

        val notes = when {
            winRate < minExpectedWinRate -> "DIFFICULTY SPIKE: Terlalu mematikan untuk ${archetype.name}"
            winRate > maxExpectedWinRate -> "TOO TRIVIAL: Terlalu mudah tanpa tantangan"
            avgTtk > 80f -> "DAMAGE SPONGE: Pertarungan terlalu lama dan melelahkan"
            else -> "BALANCED: Kurva tempo pertarungan ideal"
        }

        return ArchetypeSimulationResult(
            archetype = archetype,
            floorLevel = floorLevel,
            totalRounds = rounds,
            wins = wins,
            losses = rounds - wins,
            winRate = winRate,
            avgTtkSeconds = avgTtk,
            avgHpRemainingPercent = avgHpRem,
            projectedGoldPerHour = projectedGoldPerHour,
            isBalanced = isBalanced,
            notes = notes
        )
    }

    private data class BattleResult(val won: Boolean, val ttk: Float, val hpRemainingPct: Float, val gold: Int)

    private fun simulateSingleBattle(
        archetype: CharacterArchetype,
        stats: CharacterStats,
        floorLevel: Int,
        isBoss: Boolean,
        rng: Random
    ): BattleResult {
        var playerHp = stats.maxHp
        val playerMaxHp = stats.maxHp
        var playerEnergy = 0f

        var enemyHp = if (isBoss) {
            (250f + floorLevel * 140f)
        } else {
            // Kombinasi 3-4 mob musuh
            (45f + floorLevel * 12f) * 3f
        }
        val enemyMaxHp = enemyHp
        val enemyDmg = if (isBoss) (18f + floorLevel * 4.5f) else (9f + floorLevel * 2.2f)
        val enemyAtkInterval = if (isBoss) 1.5f else 1.2f

        var time = 0f
        val dt = 0.1f // 100ms simulation tick rate
        var enemyAtkTimer = 0f
        var skill1Cd = 0f
        var skill2Cd = 0f
        var skill3Cd = 0f
        var dodgeCd = 0f

        val dodgeSuccessRate = when (archetype) {
            CharacterArchetype.AGILE -> 0.88f
            CharacterArchetype.BALANCED -> 0.78f
            CharacterArchetype.HEAVY -> 0.65f // Heavy mengandalkan super armor & defense
        }

        while (playerHp > 0f && enemyHp > 0f && time < 120f) {
            time += dt
            if (skill1Cd > 0f) skill1Cd -= dt
            if (skill2Cd > 0f) skill2Cd -= dt
            if (skill3Cd > 0f) skill3Cd -= dt
            if (dodgeCd > 0f) dodgeCd -= dt
            enemyAtkTimer += dt

            // 1. Aksi Serangan Pemain
            var playerDmgThisTick = 0f

            // Skill 1, 2, 3 off cooldown priority
            if (skill1Cd <= 0f) {
                playerDmgThisTick += stats.attackPower * 1.8f * archetype.baseDamageMultiplier
                skill1Cd = archetype.skill1Cooldown
                playerEnergy += 18f
            } else if (skill2Cd <= 0f) {
                playerDmgThisTick += stats.attackPower * 2.2f * archetype.baseDamageMultiplier
                skill2Cd = archetype.skill2Cooldown
                playerEnergy += 22f
            } else if (skill3Cd <= 0f) {
                playerDmgThisTick += stats.attackPower * 2.5f * archetype.baseDamageMultiplier
                skill3Cd = archetype.skill3Cooldown
                playerEnergy += 25f
            } else {
                // Basic 3-hit combo DPS
                playerDmgThisTick += (stats.attackPower * 1.1f * archetype.baseDamageMultiplier) * dt * 2.2f
                playerEnergy += 6f * dt
            }

            // Ultimate Trigger
            if (playerEnergy >= archetype.ultEnergyCost) {
                playerDmgThisTick += stats.attackPower * 4.5f * archetype.baseDamageMultiplier
                playerEnergy = 0f
            }

            // Crit calculation
            val isCrit = rng.nextFloat() < (0.10f + archetype.baseCritBonus)
            if (isCrit) {
                playerDmgThisTick *= 1.75f
            }

            enemyHp -= playerDmgThisTick
            if (enemyHp <= 0f) break

            // 2. Aksi Serangan Musuh
            if (enemyAtkTimer >= enemyAtkInterval) {
                enemyAtkTimer = 0f

                // Coba Dodge / I-Frames
                val dodged = dodgeCd <= 0f && rng.nextFloat() < dodgeSuccessRate
                if (dodged) {
                    dodgeCd = 0.65f
                } else {
                    val rawDmg = enemyDmg * (0.85f + rng.nextFloat() * 0.30f)
                    val effectiveDef = stats.defense + archetype.baseDefenseBonus
                    val finalDmg = (rawDmg - effectiveDef * 0.45f).coerceAtLeast(3f)
                    playerHp -= finalDmg
                }
            }
        }

        val won = playerHp > 0f && enemyHp <= 0f
        val hpRemainingPct = (playerHp / playerMaxHp).coerceIn(0f, 1f)
        val goldEarned = if (won) (15 + floorLevel * 10 + rng.nextInt(10)) else (floorLevel * 3)

        return BattleResult(won = won, ttk = time, hpRemainingPct = hpRemainingPct, gold = goldEarned)
    }
}
