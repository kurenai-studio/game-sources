import { ACHIEVEMENTS } from '../data/achievements.js';
import EventBus from '../utils/EventBus.js';
import { awardXP } from './XPSystem.js';

export const AchievementSystem = {

    init(player) {
        if (!player.achievements) player.achievements = {};
        if (!player.stats) player.stats = {};
        const s = player.stats;
        if (s.eliteKills        === undefined) s.eliteKills        = 0;
        if (s.mimicKills        === undefined) s.mimicKills        = 0;
        if (s.longestStreak     === undefined) s.longestStreak     = 0;
        if (s.bountiesCompleted === undefined) s.bountiesCompleted = 0;
        if (s.perfectCombats    === undefined) s.perfectCombats    = 0;
        // Migrate from questStats if totalKills not yet tracked here
        if (s.totalKills === undefined) {
            s.totalKills = Object.values(player.questStats?.kills || {}).reduce((a, b) => a + b, 0);
        }
    },

    // Check all achievements and unlock any newly earned ones.
    // Returns array of newly unlocked achievement definitions.
    check(player, ctx = {}) {
        this.init(player);
        const unlocked = [];
        for (const ach of Object.values(ACHIEVEMENTS)) {
            if (player.achievements[ach.id]) continue;
            try {
                if (ach.check(player, ctx)) {
                    player.achievements[ach.id] = new Date().toISOString();
                    unlocked.push(ach);
                    const xpEarned = ach.xpReward ? awardXP(player, ach.xpReward) : 0;
                    const goldEarned = ach.goldReward || 0;
                    if (goldEarned > 0) {
                        player.gold = (player.gold || 0) + goldEarned;
                    }
                    EventBus.emit('achievement-unlocked', { achievement: ach, player, xpEarned, goldEarned });
                }
            } catch { /* guard against missing data mid-check */ }
        }
        return unlocked;
    },

    // Called from WorldScene after each combat ends.
    recordCombat(player, { outcome, maxStreak, allCorrect, isElite, isMimic }) {
        this.init(player);
        if (maxStreak > (player.stats.longestStreak || 0)) {
            player.stats.longestStreak = maxStreak;
        }
        if (outcome === 'win') {
            player.stats.totalKills = (player.stats.totalKills || 0) + 1;
            if (isElite)    player.stats.eliteKills    = (player.stats.eliteKills    || 0) + 1;
            if (isMimic)    player.stats.mimicKills    = (player.stats.mimicKills    || 0) + 1;
            if (allCorrect) player.stats.perfectCombats = (player.stats.perfectCombats || 0) + 1;
        }
    },

    // Called from WorldScene when a bounty is completed.
    recordBounty(player) {
        this.init(player);
        player.stats.bountiesCompleted = (player.stats.bountiesCompleted || 0) + 1;
    },

    isUnlocked(player, id) {
        return !!(player.achievements || {})[id];
    },

    // Returns all achievements with unlock status for display.
    getAll(player) {
        this.init(player);
        return Object.values(ACHIEVEMENTS).map(a => ({
            ...a,
            unlocked: !!player.achievements[a.id],
            unlockedAt: player.achievements[a.id] || null,
        }));
    },

    count(player) {
        return Object.keys(player.achievements || {}).length;
    },
};
