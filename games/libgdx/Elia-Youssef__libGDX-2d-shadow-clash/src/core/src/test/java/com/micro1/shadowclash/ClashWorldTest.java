package com.micro1.shadowclash;

import com.badlogic.gdx.math.Rectangle;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

/**
 * Headless verification of the GL-free fight simulation against the rubric: start layout, the
 * Ready lock, damage tiers (1/3/5), special unlock threshold, the named block rules, hit reactions,
 * knockback, the projectile, slow motion, KO -> victory/defeat, no-timer play, facing / bounds /
 * separation, restart reset, and frame-rate independence.
 */
public class ClashWorldTest {

    private static final float DT = 1f / 60f;

    private ClashWorld combat() {
        ClashWorld w = new ClashWorld();
        w.testEnterCombat();
        w.aiEnabled = false;   // CPU passive unless a test drives it
        return w;
    }

    private void step(ClashWorld w, float seconds, Intent in) {
        int n = Math.max(1, Math.round(seconds / DT));
        for (int i = 0; i < n; i++) {
            w.update(DT, in);
            if (in != null) { in.jumpPressed = false; in.backDashPressed = false; in.attack = null; }
        }
    }

    private void stepNone(ClashWorld w, float seconds) { step(w, seconds, null); }

    /** Player performs one attack against the passive CPU and the move resolves fully. */
    private void playerAttack(ClashWorld w, Move m) {
        Intent in = new Intent();
        in.attack = m;
        w.update(DT, in);                 // start the move
        stepNone(w, m.total() + 0.15f);   // let its active + recovery frames resolve
    }

    private void inRange(ClashWorld w) {
        w.player.x = 500f; w.player.facing = 1;
        w.cpu.x = 590f;    w.cpu.facing = -1;
    }

    // ------------------------------------------------------------------ layout + flow

    @Test public void startLayoutAndFacing() {
        ClashWorld w = new ClashWorld();
        assertEquals(MatchState.READY, w.phase);
        assertTrue("player starts on the left", w.player.x < w.cpu.x);
        assertEquals(1, w.player.facing);      // player faces right (inward)
        assertEquals(-1, w.cpu.facing);        // cpu faces left (inward)
        assertEquals(100, w.player.health);
        assertEquals(100, w.cpu.health);
    }

    @Test public void readyLocksBothFighters() {
        ClashWorld w = new ClashWorld();
        float px = w.player.x;
        Intent in = new Intent();
        in.moveDir = 1; in.attack = Move.JAB;
        step(w, 2.0f, in);                     // still inside the 3s Ready window
        assertEquals(MatchState.READY, w.phase);
        assertEquals("no movement during Ready", px, w.player.x, 0.001f);
        assertEquals(FighterState.IDLE, w.player.state);
        assertEquals(100, w.cpu.health);
    }

    @Test public void readyThenFightThenCombat() {
        ClashWorld w = new ClashWorld();
        stepNone(w, 3.1f);
        assertEquals(MatchState.FIGHT, w.phase);
        stepNone(w, 1.1f);
        assertEquals(MatchState.COMBAT, w.phase);
    }

    @Test public void readyTimerUsesWallTimeAtTenFps() {
        ClashWorld w = new ClashWorld();
        for (int i = 0; i < 30; i++) w.update(0.1f, null);
        assertEquals("GET READY lasts three wall-clock seconds", MatchState.FIGHT, w.phase);
    }

    // ------------------------------------------------------------------ damage tiers

    @Test public void lightAttackDealsOne() {
        ClashWorld w = combat(); inRange(w);
        playerAttack(w, Move.JAB);
        assertEquals(99, w.cpu.health);
    }

    @Test public void heavyAttackDealsThree() {
        ClashWorld w = combat(); inRange(w);
        playerAttack(w, Move.STRONGPUNCH);
        assertEquals(97, w.cpu.health);
    }

    @Test public void specialDealsFive() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 50;                  // below 75 -> specials unlocked
        playerAttack(w, Move.DARKCHARGE);
        assertEquals(95, w.cpu.health);
    }

    @Test public void specialsLockedAbove75() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 100;
        playerAttack(w, Move.DARKCHARGE);
        assertEquals("special must not fire above 75 health", 100, w.cpu.health);
        assertFalse(w.player.state == FighterState.DARKCHARGE);
        w.player.health = 60;                  // now unlocked
        playerAttack(w, Move.DARKCHARGE);
        assertEquals(95, w.cpu.health);
    }

    @Test public void allNamedMovesDealTheirExactDamage() {
        for (Move move : Move.ALL) {
            ClashWorld w = combat();
            inRange(w);
            if (move.isSpecial()) w.player.health = 50;
            playerAttack(w, move);
            if (move.projectile) stepNone(w, 1.2f);
            assertEquals(move.name, 100 - move.damage, w.cpu.health);
        }
    }

    // ------------------------------------------------------------------ block rules

    @Test public void standingBlockStopsMidNotLow() {
        ClashWorld w = combat(); inRange(w);
        w.cpu.intent.standBlock = true;        // held
        playerAttack(w, Move.JAB);             // MID -> blocked
        assertEquals("standing block stops jab", 100, w.cpu.health);

        w.cpu.intent.standBlock = true;
        playerAttack(w, Move.CROUCHJAB);       // LOW -> not stopped by standing block
        assertTrue("standing block does not stop a low attack", w.cpu.health < 100);
    }

    @Test public void crouchingBlockStopsLowNotMid() {
        ClashWorld w = combat(); inRange(w);
        w.cpu.intent.crouchBlock = true;
        playerAttack(w, Move.SWEEP);           // LOW -> blocked
        assertEquals("crouch block stops sweep", 100, w.cpu.health);

        w.cpu.intent.crouchBlock = true;
        playerAttack(w, Move.STANDKICK);       // MID -> not stopped by crouch block
        assertTrue("crouch block does not stop a mid attack", w.cpu.health < 100);
    }

    @Test public void everyNamedBlockMatchupPreventsDamage() {
        Move[] standing = {Move.JAB, Move.STANDKICK, Move.STRONGPUNCH, Move.SHADOWBLAST, Move.DARKCHARGE};
        for (Move move : standing) assertBlocked(move, false);
        assertBlocked(Move.CROUCHJAB, true);
        assertBlocked(Move.SWEEP, true);
    }

    private void assertBlocked(Move move, boolean crouching) {
        ClashWorld w = combat();
        inRange(w);
        if (move.isSpecial()) w.player.health = 50;
        w.cpu.intent.crouchBlock = crouching;
        w.cpu.intent.standBlock = !crouching;
        playerAttack(w, move);
        if (move.projectile) stepNone(w, 1.2f);
        assertEquals(move.name + " should be blocked", 100, w.cpu.health);
    }

    // ------------------------------------------------------------------ reactions

    @Test public void reactionsMatchMoves() {
        ClashWorld w = combat(); inRange(w);
        playerAttack(w, Move.JAB);
        assertReactionSeen(w);                 // some hit reaction was entered

        w = combat(); inRange(w);
        w.cpu.x = 590f;
        // uppercut launches the opponent into the air
        Intent in = new Intent(); in.attack = Move.UPPERCUT;
        w.update(DT, in);
        stepNone(w, 0.25f);
        assertTrue("uppercut launches (airborne)", !w.cpu.onGround || w.cpu.state == FighterState.LAUNCH);
    }

    private void assertReactionSeen(ClashWorld w) {
        // right after a light hit the victim is in a light-hit reaction
        assertTrue(w.cpu.state == FighterState.HIT_LIGHT || w.cpu.health < 100);
    }

    @Test public void heavyKnockbackPushesAway() {
        ClashWorld w = combat(); inRange(w);
        float before = w.cpu.x;
        playerAttack(w, Move.STRONGPUNCH);
        assertTrue("heavy hit knocks the victim back", w.cpu.x > before + 8f);
    }

    @Test public void namedReactionsEnterDistinctStates() {
        assertReaction(Move.JAB, FighterState.HIT_LIGHT);
        assertReaction(Move.STRONGPUNCH, FighterState.HIT_HEAVY);
        assertReaction(Move.SWEEP, FighterState.KNOCKDOWN);
        assertReaction(Move.UPPERCUT, FighterState.LAUNCH);
    }

    private void assertReaction(Move move, FighterState expected) {
        ClashWorld w = combat();
        inRange(w);
        Intent in = new Intent();
        in.attack = move;
        w.update(DT, in);
        stepNone(w, move.startup + move.active * 0.5f);
        assertEquals(move.name, expected, w.cpu.state);
    }

    // ------------------------------------------------------------------ projectile

    @Test public void shadowBlastProjectileHitsForFive() {
        ClashWorld w = combat();
        w.player.x = 480f; w.player.facing = 1;
        w.cpu.x = 700f; w.cpu.facing = -1;
        w.player.health = 50;
        Intent in = new Intent(); in.attack = Move.SHADOWBLAST;
        w.update(DT, in);
        assertTrue("a projectile is spawned", stepUntilProjectile(w));
        stepNone(w, 2.5f);                     // let it travel (slow-mo lengthens this)
        assertEquals("Shadow Blast deals 5", 95, w.cpu.health);
        assertTrue("projectile removed on impact", w.projectiles.isEmpty());
    }

    private boolean stepUntilProjectile(ClashWorld w) {
        for (int i = 0; i < 60; i++) {
            stepNone(w, DT);
            if (!w.projectiles.isEmpty()) return true;
        }
        return false;
    }

    @Test public void shadowBlastBlockedByStandingBlock() {
        ClashWorld w = combat();
        w.player.x = 480f; w.player.facing = 1;
        w.cpu.x = 660f; w.cpu.facing = -1;
        w.player.health = 50;
        w.cpu.intent.standBlock = true;
        playerAttack(w, Move.SHADOWBLAST);
        stepNone(w, 1.5f);
        assertEquals("standing block stops Shadow Blast", 100, w.cpu.health);
    }

    // ------------------------------------------------------------------ slow motion

    @Test public void specialTriggersSlowMotionThenRecovers() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 50;
        Intent in = new Intent(); in.attack = Move.SPINSLASH;
        w.update(DT, in);
        stepNone(w, 0.15f);
        assertTrue("slow motion active during a special", w.isSlowMotion());
        assertTrue("time scale reduced", w.getTimeScale() < 0.8f);
        stepNone(w, 3.0f);                     // full special animation plays in slow motion
        assertFalse("returns to normal speed", w.isSlowMotion());
        assertTrue("time scale restored", w.getTimeScale() > 0.95f);
    }

    @Test public void slowMotionCoversEveryWhiffedSpecial() {
        Move[] specials = {Move.SHADOWBLAST, Move.DARKCHARGE, Move.SPINSLASH};
        for (Move move : specials) {
            ClashWorld w = combat();
            w.player.x = 180f; w.cpu.x = 900f;
            w.player.health = 50;
            Intent in = new Intent(); in.attack = move;
            w.update(DT, in);
            stepNone(w, 0.95f);
            assertEquals(move.name + " is still playing", move.state, w.player.state);
            assertTrue(move.name + " remains in slow motion", w.isSlowMotion());
            stepNone(w, 2.5f);
            assertFalse(move.name + " eventually returns to normal", w.isSlowMotion());
        }
    }

    // ------------------------------------------------------------------ KO / outcomes

    @Test public void koLeadsToVictory() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 50; w.cpu.health = 3;
        playerAttack(w, Move.DARKCHARGE);      // 5 dmg finishes the CPU
        assertTrue(w.phase == MatchState.SLOWMO_KO || w.phase == MatchState.VICTORY);
        stepNone(w, 2.2f);                     // KO slow-mo then settle
        assertEquals(MatchState.VICTORY, w.phase);
        assertEquals("YOU WIN", w.centerMessage());
        assertEquals(FighterState.VICTORY, w.player.state);
        assertEquals(FighterState.DEFEAT, w.cpu.state);
    }

    @Test public void koLeadsToDefeat() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 2;
        w.cpu.intent.attack = Move.STRONGPUNCH;   // CPU (driven manually) lands a finisher
        w.update(DT, null);
        w.cpu.intent.attack = null;
        stepNone(w, 2.6f);
        assertEquals(MatchState.DEFEAT, w.phase);
        assertEquals("YOU LOSE", w.centerMessage());
        assertFalse(w.player.isAlive());
    }

    @Test public void slowMotionOnFinishingHit() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 50; w.cpu.health = 3;
        playerAttack(w, Move.STRONGPUNCH);
        assertTrue("finishing hit enters slow motion", w.isSlowMotion());
    }

    // ------------------------------------------------------------------ no timer

    @Test public void matchDoesNotEndWithoutAKnockout() {
        ClashWorld w = combat();
        w.player.x = 300f; w.cpu.x = 800f;     // apart, both idle
        stepNone(w, 25f);
        assertTrue(w.phase == MatchState.COMBAT || w.phase == MatchState.FIGHT);
        assertEquals(100, w.player.health);
        assertEquals(100, w.cpu.health);
    }

    // ------------------------------------------------------------------ facing / bounds / separation

    @Test public void fightersFaceEachOtherAfterCrossing() {
        ClashWorld w = combat();
        w.player.x = 620f; w.cpu.x = 420f;     // player now to the RIGHT of the cpu
        stepNone(w, 0.1f);
        assertEquals("player faces left toward cpu", -1, w.player.facing);
        assertEquals("cpu faces right toward player", 1, w.cpu.facing);
    }

    @Test public void arenaBoundsClampMovement() {
        ClashWorld w = combat();
        w.cpu.x = 950f;
        Intent left = new Intent(); left.moveDir = -1;
        step(w, 5f, left);
        assertTrue("player cannot leave the left edge", w.player.x >= K.ARENA_LEFT - 0.5f);
        assertTrue(w.player.x <= K.ARENA_LEFT + 2f);
    }

    @Test public void fightersCannotOverlap() {
        ClashWorld w = combat();
        w.player.x = 500f; w.cpu.x = 500f;     // exactly overlapping
        stepNone(w, 0.3f);
        assertBodyBoxesDoNotOverlap(w);
    }

    @Test public void separationUsesBodyBoxesAtBoundariesAndInAir() {
        ClashWorld w = combat();
        w.player.x = K.ARENA_LEFT; w.cpu.x = K.ARENA_LEFT;
        stepNone(w, DT);
        assertBodyBoxesDoNotOverlap(w);

        w.player.x = 500f; w.player.y = 300f;
        w.cpu.x = 500f; w.cpu.y = K.GROUND;
        stepNone(w, DT);
        assertBodyBoxesDoNotOverlap(w);
    }

    private void assertBodyBoxesDoNotOverlap(ClashWorld w) {
        Rectangle playerBox = w.player.bodyBox(new Rectangle());
        Rectangle cpuBox = w.cpu.bodyBox(new Rectangle());
        assertFalse("fighter body boxes must not overlap", playerBox.overlaps(cpuBox));
    }

    @Test public void airborneFightersStillFaceTheirOpponent() {
        ClashWorld w = combat();
        w.player.x = 620f; w.player.y = 420f; w.player.onGround = false;
        w.cpu.x = 420f;
        stepNone(w, DT);
        assertEquals(-1, w.player.facing);
        assertEquals(1, w.cpu.facing);
    }

    // ------------------------------------------------------------------ restart

    @Test public void restartResetsEverything() {
        ClashWorld w = combat(); inRange(w);
        w.player.health = 40; w.cpu.health = 3;
        w.player.health = 50;
        w.aiEnabled = false;
        playerAttack(w, Move.SHADOWBLAST);
        stepNone(w, 2.5f);
        w.reset();
        assertEquals(MatchState.READY, w.phase);
        assertEquals(100, w.player.health);
        assertEquals(100, w.cpu.health);
        assertTrue(w.player.x < w.cpu.x);
        assertTrue(w.projectiles.isEmpty());
        assertEquals(1f, w.getTimeScale(), 0.001f);
        assertEquals(FighterState.IDLE, w.player.state);
        assertTrue("restart restores the CPU controller", w.aiEnabled);
    }

    // ------------------------------------------------------------------ frame-rate independence

    @Test public void cpuReachesEveryMovementState() {
        // Across a few AI-driven matches the CPU must exhibit the neutral crouch (and the rest of
        // the movement set), so "6 movement states for both fighters" holds for the CPU too.
        boolean idle = true, crouch = false, walk = false, run = false, jump = false, backdash = false;
        for (long seed = 1; seed <= 10 && !(crouch && walk && run && jump && backdash); seed++) {
            ClashWorld w = new ClashWorld(seed);
            w.testEnterCombat();
            Intent passive = new Intent();
            for (int i = 0; i < 60 * 30; i++) {
                w.update(DT, passive);
                switch (w.cpu.state) {
                    case CROUCH: crouch = true; break;
                    case WALK: walk = true; break;
                    case RUN: run = true; break;
                    case JUMP: jump = true; break;
                    case BACKDASH: backdash = true; break;
                    default: break;
                }
                if (!w.matchLive()) break;
            }
        }
        assertTrue("CPU idles", idle);
        assertTrue("CPU reaches neutral CROUCH", crouch);
        assertTrue("CPU walks", walk);
        assertTrue("CPU runs", run);
        assertTrue("CPU jumps", jump);
        assertTrue("CPU back-dashes", backdash);
    }

    @Test public void deltaTimeIndependentMovement() {
        ClashWorld a = new ClashWorld(); a.testEnterCombat(); a.aiEnabled = false; a.cpu.x = 900f;
        ClashWorld b = new ClashWorld(); b.testEnterCombat(); b.aiEnabled = false; b.cpu.x = 900f;
        ClashWorld c = new ClashWorld(); c.testEnterCombat(); c.aiEnabled = false; c.cpu.x = 900f;
        Intent walk = new Intent(); walk.moveDir = 1;
        for (int i = 0; i < 30; i++) a.update(1f / 30f, walk);
        for (int i = 0; i < 120; i++) b.update(1f / 120f, walk);
        for (int i = 0; i < 10; i++) c.update(1f / 10f, walk);
        assertEquals("walk distance is frame-rate independent", a.player.x, b.player.x, 6f);
        assertEquals("walk distance also holds below 30 FPS", a.player.x, c.player.x, 6f);
    }

    @Test public void cpuReactsToProjectilesAndIncomingAttacks() {
        ClashWorld w = new ClashWorld(4L);
        w.testEnterCombat();
        w.player.x = 500f; w.player.facing = 1;
        w.cpu.x = 700f;
        w.spawnProjectile(w.player);
        w.update(DT, null);
        assertFalse("CPU jumps an incoming projectile", w.cpu.onGround);

        w = new ClashWorld(4L);
        w.testEnterCombat();
        inRange(w);
        Intent jab = new Intent(); jab.attack = Move.JAB;
        w.update(DT, jab);
        w.update(DT, null);
        assertEquals("CPU reads a mid attack and stands guard", FighterState.BLOCK_STAND, w.cpu.state);
    }

    @Test public void cpuUsesRangedSpecialBelow75Health() {
        ClashWorld w = new ClashWorld(3L);
        w.testEnterCombat();
        w.player.x = 500f;
        w.cpu.x = 700f;
        w.cpu.health = 50;

        w.update(DT, null); // refresh the shared special-unlock rule
        w.update(DT, null); // seeded attack plan chooses range-appropriate Shadow Blast

        assertEquals(Move.SHADOWBLAST, w.cpu.curMove);
        assertEquals(FighterState.SHADOWBLAST, w.cpu.state);
    }
}
