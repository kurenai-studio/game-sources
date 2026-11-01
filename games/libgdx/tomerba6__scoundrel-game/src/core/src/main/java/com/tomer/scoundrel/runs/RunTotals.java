package com.tomer.scoundrel.runs;

import com.tomer.scoundrel.model.Status;

import java.util.List;

/**
 * Lifetime sums across finished runs — a pure view over the run log like
 * {@link HighScores}, no I/O. "Finished" is the whole universe by design:
 * abandoned games are never recorded.
 *
 * @param runs             finished runs, won or lost
 * @param wins             runs won
 * @param losses           runs lost; {@code wins + losses == runs}
 * @param monstersDefeated monsters fought, all runs together
 * @param damageTaken      health lost to monsters, all runs together
 * @param healthHealed     health restored by potions, all runs together
 * @param potionsDrunk     potions that healed, all runs together
 * @param potionsWasted    potions taken past a turn's allowance, all runs together
 * @param weaponsEquipped  weapons taken, all runs together
 * @param roomsAvoided     rooms avoided, all runs together
 * @param secondsPlayed    wall-clock seconds across all runs
 */
public record RunTotals(
        int runs,
        int wins,
        int losses,
        int monstersDefeated,
        int damageTaken,
        int healthHealed,
        int potionsDrunk,
        int potionsWasted,
        int weaponsEquipped,
        int roomsAvoided,
        long secondsPlayed) {

    /**
     * Sums a history.
     *
     * @param records the runs to total, in any order; every mode counts
     * @return the totals, all zero for an empty history
     */
    public static RunTotals of(List<RunRecord> records) {
        int wins = 0;
        int losses = 0;
        int monsters = 0;
        int damage = 0;
        int healed = 0;
        int drunk = 0;
        int wasted = 0;
        int equips = 0;
        int avoids = 0;
        long seconds = 0;
        for (RunRecord record : records) {
            if (record.outcome() == Status.WON) {
                wins++;
            } else {
                losses++;
            }
            monsters += record.monstersDefeated();
            damage += record.damageTaken();
            healed += record.healthHealed();
            drunk += record.potionsDrunk();
            wasted += record.potionsWasted();
            equips += record.weaponsEquipped();
            avoids += record.roomsAvoided();
            seconds += record.seconds();
        }
        return new RunTotals(records.size(), wins, losses, monsters, damage,
                healed, drunk, wasted, equips, avoids, seconds);
    }

    /**
     * Fraction of runs cleared; 0 while no runs exist.
     *
     * @return {@code wins / runs}, from 0.0 to 1.0
     */
    public double winRate() {
        return runs == 0 ? 0 : (double) wins / runs;
    }
}
