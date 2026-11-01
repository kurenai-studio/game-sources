package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.BossStatus;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.port.LevelOutcome;
import dev.luchoc.littlespaceship.core.port.SimpleBossDefinition;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@code BossSystem} against content built inline, per the same reasoning {@code SpawnSystemTest}
 * states for the ordinary wave system.
 */
class BossSystemTest {

    private static final String LEVEL = "level-01";
    private static final float STEP = 1f / 60f;

    private final TestBalance balance = new TestBalance();

    @Test
    @DisplayName("rejects being built without a level id")
    void rejectsMissingLevelId() {
        assertThrows(IllegalArgumentException.class, () -> new BossSystem(null));
        assertThrows(IllegalArgumentException.class, () -> new BossSystem(""));
    }

    @Test
    @DisplayName("a level with no boss never reports one present, and never registers as a boss level")
    void levelWithNoBossStaysAbsent() {
        World world = new World(new TestContent(balance), new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        for (int i = 0; i < 10; i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }

        assertEquals(BossStatus.NONE, world.view().bossStatus());
        assertEquals(0, world.colliders().size());
        // Old, pre-boss outcome rule still governs a boss-less level: no wave timeline was ever
        // registered here, so the run simply never completes, which is the correct behaviour for a
        // run with no level to finish, exactly as the class it delegates to documents.
        assertEquals(LevelOutcome.IN_PROGRESS, world.view().outcome());
    }

    @Test
    @DisplayName("the boss stays absent before entersAt and spawns five parts once it is reached")
    void spawnsFivePartsAtEntersAt() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(1f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, 0.5f, InputFrame.IDLE);
        assertEquals(BossStatus.NONE, world.view().bossStatus());
        assertEquals(0, world.colliders().size());

        system.update(world, 0.6f, InputFrame.IDLE);
        assertEquals(6, world.colliders().size());
        BossStatus status = world.view().bossStatus();
        assertTrue(status.present());
        assertEquals(status.hpMax(), status.hp());
        for (int i = 0; i < world.colliders().size(); i++) {
            assertEquals(CollisionLayer.ENEMY, world.colliders().valueAt(i).layer);
            assertFalse(world.colliders().valueAt(i).fragile);
        }
    }

    @Test
    @DisplayName("the health bar is hidden before the boss spawns and after it is defeated")
    void presentOnlyDuringTheFight() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        assertTrue(world.view().bossStatus().present());

        int core = coreEntity(world);
        world.destroyEntity(core);
        system.update(world, STEP, InputFrame.IDLE);

        assertFalse(world.view().bossStatus().present());
    }

    @Test
    @DisplayName("defeating the core ends the fight, clears remaining parts and wins with a life left")
    void defeatingTheCoreWinsTheRun() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        int player = world.createEntity();
        world.players().set(player, new dev.luchoc.littlespaceship.core.domain.component.Player(3, 2, 1));
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        assertEquals(LevelOutcome.IN_PROGRESS, world.view().outcome());

        int core = coreEntity(world);
        world.destroyEntity(core);
        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(LevelOutcome.COMPLETED, world.view().outcome());
        // Every part but the core is marked for destruction with it: a defeated boss does not linger
        // as a headless husk. Actual removal is CleanupSystem's job, not exercised in this isolated
        // BossSystem test, so what is checked here is the marking, not the collider count.
        assertEquals(5, world.pendingDestruction().size());
    }

    @Test
    @DisplayName("losing every life defeats the run even mid-fight, and DEFEATED wins a same-tick tie")
    void defeatWinsATieWithBossDefeat() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        int player = world.createEntity();
        dev.luchoc.littlespaceship.core.domain.component.Player state =
            new dev.luchoc.littlespaceship.core.domain.component.Player(3, 2, 1);
        world.players().set(player, state);
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        int core = coreEntity(world);
        world.destroyEntity(core);
        state.lives = 0;
        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(LevelOutcome.DEFEATED, world.view().outcome());
    }

    @Test
    @DisplayName("the entrance holds the boss off screen and settles it at combatY before attacking")
    void entranceDescendsToCombatY() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        int core = coreEntity(world);
        float spawnY = world.transforms().get(core).y;
        assertTrue(spawnY > SpawnSystem.PLAYFIELD_HEIGHT);

        // A generous number of ticks at a fast entrance speed is enough to reach combatY, but not so
        // many that the fight's first cooldown-then-tell (0.2s + 0.75s = 0.95s, this fixture's own
        // boss()) elapses and the boss starts its first move away from combatY: since #325, the boss
        // travels to a star point once a volley resolves, so this test now needs to observe the
        // settle before that happens rather than well after it, unlike before movement existed.
        for (int i = 0; i < 20; i++) {
            system.update(world, STEP, InputFrame.IDLE);
        }

        assertEquals(120f, world.transforms().get(core).y, 0.01f);
    }

    @Test
    @DisplayName("the tell steps a charging pod's frame through 1, 2, 3 and back to 0 on fire")
    void tellStepsThroughThreeBeatsThenFires() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        // Reach the fight: one tick to spawn, one generous single step to clear the whole entrance
        // in one jump, so FIGHT starts with its cooldown untouched instead of already part spent.
        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        int pod = podEntity(world);
        Sprite sprite = world.sprites().get(pod);
        assertEquals(0, sprite.frame);

        // Real, small ticks: the cooldown (0.2s) elapses, then the tell steps 1, 2, 3 in order, and
        // fires once it reaches 0.75s, dropping the frame back to zero the same tick.
        int collidersBeforeFire = world.colliders().size();
        boolean sawOne = false;
        boolean sawTwo = false;
        boolean sawThree = false;
        boolean fired = false;
        for (int i = 0; i < 200 && !fired; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            int frame = sprite.frame;
            sawOne |= frame == 1;
            sawTwo |= sawOne && frame == 2;
            sawThree |= sawTwo && frame == 3;
            fired = sawThree && frame == 0;
        }

        assertTrue(sawOne, "never saw beat 1");
        assertTrue(sawTwo, "never saw beat 2");
        assertTrue(sawThree, "never saw beat 3");
        assertTrue(fired, "the tell never resolved into a fire");
        assertTrue(world.colliders().size() > collidersBeforeFire);
    }

    @Test
    @DisplayName(
        "a rear volley fans five rays per pod at the spread speed, and fires together with a front "
            + "volley fanning five rays per arm at the sweep speed")
    void rearVolleyFansFiveRaysPerPodAndFiresTogetherWithTheFront() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        // Reach the fight the same way tellStepsThroughThreeBeatsThenFires does.
        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        // The front weapon's own independent clock (FRONT_SHOTS_PER_CYCLE = 3) fires a pure shot
        // before the first rear volley ever resolves, so the chronologically first fire event is not
        // the one this test is about — the rear volley, wherever it falls, is: it is the first event
        // that contains a spread-speed (180) projectile, and issue #329's synchronisation rule fires
        // the front weapon together with it, in the very same tick.
        java.util.List<FireEvent> events = traceFireEvents(world, system, 200);
        FireEvent rearEvent = events.stream()
            .filter(event -> event.speeds().stream().anyMatch(speed -> Math.abs(speed - 180f) < 0.05f))
            .findFirst()
            .orElseThrow(() -> new IllegalStateException("no rear volley fired within the tick budget"));
        assertEquals(20, rearEvent.speeds().size(), "the rear volley and the coincident front shot together");
        assertSpeedCount(rearEvent.speeds(), 180f, 10);
        assertSpeedCount(rearEvent.speeds(), 160f, 10);
    }

    @Test
    @DisplayName("a move takes MOVE_DURATION whatever the distance, a short hop and a long one alike")
    void movesTakeTheSameFixedDurationRegardlessOfDistance() {
        // Two seeds, observed to send the very first move (an unrestricted pick over all ten points,
        // since the boss is not yet standing on any of them) to two star points at very different
        // distances from the entrance's own landing spot, (PLAYFIELD_WIDTH / 2, combatY) = (104, 120)
        // for this fixture's boss(). Both moves must still take the same number of ticks.
        MoveResult shortHop = firstMoveResult(new Rng(1));
        MoveResult longHop = firstMoveResult(new Rng(6));

        float fromX = MotionSystem.PLAYFIELD_WIDTH / 2f;
        float fromY = 120f;
        float shortDistance = distanceFrom(fromX, fromY, shortHop.starIndex());
        float longDistance = distanceFrom(fromX, fromY, longHop.starIndex());
        assertTrue(longDistance > shortDistance * 1.5f,
            "the two seeds picked for this test do not land on hops different enough to prove the rule: "
                + "short=" + shortDistance + " long=" + longDistance);

        int expectedTicks = Math.round(BossSystem.MOVE_DURATION / STEP);
        assertEquals(expectedTicks, shortHop.ticks(), 1, "a move's duration must not depend on distance");
        assertEquals(expectedTicks, longHop.ticks(), 1, "a move's duration must not depend on distance");
    }

    private static float distanceFrom(float fromX, float fromY, int starIndex) {
        float dx = BossSystem.STAR_X[starIndex] - fromX;
        float dy = BossSystem.STAR_Y[starIndex] - fromY;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    /** How many ticks the very first move took, and which star point it settled on. */
    private record MoveResult(int ticks, int starIndex) { }

    /**
     * Drives a fresh boss from the fight's start through its very first move and returns how long the
     * move itself took — from the tick the rear volley fires (entering {@code MOVING}) to the tick the
     * core stops changing position — and which star point it settled on.
     */
    private static MoveResult firstMoveResult(Rng rng) {
        TestContent content = new TestContent(new TestBalance()).withBoss(LEVEL, boss(0f));
        World world = new World(content, rng, new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);
        // Wait specifically for the rear (spread, 180) volley, not just any fire event: the front
        // weapon's own independent clock fires a pure shot before the rear volley ever resolves (see
        // frontFiresMoreOftenAndCoincidesWithEveryRearVolley), and that shot moves nothing.
        waitForRearVolley(world, system);

        int core = coreEntity(world);
        int ticks = 0;
        float lastX = world.transforms().get(core).x;
        float lastY = world.transforms().get(core).y;
        boolean moved = false;
        for (int i = 0; i < 300; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            ticks++;
            float x = world.transforms().get(core).x;
            float y = world.transforms().get(core).y;
            boolean stillMoving = x != lastX || y != lastY;
            if (stillMoving) {
                moved = true;
            } else if (moved) {
                int starIndex = findStarIndex(lastX, lastY);
                assertTrue(starIndex >= 0, "the boss settled somewhere that is not a star point");
                return new MoveResult(ticks - 1, starIndex);
            }
            lastX = x;
            lastY = y;
        }
        throw new IllegalStateException("the boss never settled after its first move");
    }

    /**
     * Drives {@code system} until a projectile at the rear's own spread speed (180, this fixture's
     * {@code boss()}) appears — the front weapon's independent clock can fire a pure shot first, and
     * this must not be mistaken for it.
     */
    private static void waitForRearVolley(World world, BossSystem system) {
        for (int i = 0; i < 200; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            for (int j = 0; j < world.colliders().size(); j++) {
                if (world.colliders().valueAt(j).layer != CollisionLayer.ENEMY_PROJECTILE) {
                    continue;
                }
                dev.luchoc.littlespaceship.core.domain.component.Motion motion =
                    world.motions().get(world.colliders().entityAt(j));
                float speed = (float) Math.sqrt(motion.vx * motion.vx + motion.vy * motion.vy);
                if (Math.abs(speed - 180f) < 0.05f) {
                    return;
                }
            }
        }
        throw new IllegalStateException("no rear volley fired within the tick budget");
    }

    @Test
    @DisplayName("the front weapon fires FRONT_SHOTS_PER_CYCLE times as often as the rear, coinciding "
        + "with every rear volley and firing exactly N-1 times independently between two of them")
    void frontFiresMoreOftenAndCoincidesWithEveryRearVolley() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        java.util.List<FireEvent> events = traceFireEvents(world, system, 320);
        assertTrue(events.size() >= 6, "not enough fire events traced to check the ratio");

        int coincidences = 0;
        int frontOnlyTotal = 0;
        int sinceLastCoincidence = 0;
        for (FireEvent event : events) {
            boolean isCoincidence = event.speeds().size() == 20;
            boolean isFrontOnly = event.speeds().size() == 10 && allNear(event.speeds(), 160f);
            assertTrue(isCoincidence || isFrontOnly,
                "an event is neither the rear/front coincidence nor a pure front shot: " + event.speeds());
            if (isCoincidence) {
                if (coincidences > 0) {
                    assertEquals(BossSystem.FRONT_SHOTS_PER_CYCLE - 1, sinceLastCoincidence,
                        "expected exactly FRONT_SHOTS_PER_CYCLE - 1 independent front shots "
                            + "between two rear volleys");
                }
                coincidences++;
                sinceLastCoincidence = 0;
            } else {
                frontOnlyTotal++;
                sinceLastCoincidence++;
            }
        }
        assertTrue(coincidences >= 3, "not enough rear volleys traced to check the ratio");
        assertTrue(frontOnlyTotal >= 2 * (BossSystem.FRONT_SHOTS_PER_CYCLE - 1),
            "the front weapon did not fire independently often enough");
    }

    /**
     * Replaces the #329 test {@code frontFiresWhileMoving}, deleted for #333 rather than weakened:
     * at {@code FRONT_SHOTS_PER_CYCLE = 2} the front's one independent shot per cycle lands at exactly
     * half the cycle, which for this fixture's {@code boss()} (cooldown 0.2 s, tell 0.75 s, move
     * 0.84 s, cycle 1.79 s) falls inside {@code COOLDOWN} (36.7%–63.3% of the cycle) — never inside
     * {@code MOVING} (its first 36.7%). A test asserting a shot fires during {@code MOVING} would now
     * be false, and asserting the opposite ("never during {@code MOVING}") would be a fact about this
     * one ratio, not about the design — it would pass again the moment {@code
     * FRONT_SHOTS_PER_CYCLE} is retuned back toward 3, telling a future reader nothing about what
     * actually still holds.
     *
     * <p>What survives issue #329's actual point, and what this test asserts instead, is that {@link
     * BossSystem#updateFrontWeapons} is never gated by {@code fightStage}: its clock keeps advancing
     * every tick, {@code MOVING} included, rather than pausing for it and resuming afterward.
     *
     * <p><b>A one-sided bound does not prove this, and an earlier version of this test asserted one.</b>
     * It checked only {@code deltaSeconds > MOVE_DURATION} (0.84 s), reasoning that a clock paused
     * through {@code MOVING} would arrive later and so fail that bound. It would not have: arriving
     * later makes the delta <i>larger</i>, and a larger value still satisfies {@code >}. A clock that
     * runs normally lands at the front period, {@code frontPeriod} ≈ 0.895 s for this fixture (see
     * below); a clock paused for the whole {@code MOVE_DURATION} (0.84 s) window would land at
     * {@code frontPeriod + MOVE_DURATION} ≈ 1.735 s — and both numbers are greater than 0.84 s, so the
     * one-sided bound cannot tell the two behaviours apart. **The bound must be two-sided**: the delta
     * has to sit within a tick or so of {@code frontPeriod} itself, not merely exceed
     * {@code MOVE_DURATION}. A paused clock lands roughly {@code MOVE_DURATION} outside that narrow
     * window and the test catches it. Falsified by a scratch copy of {@code updateFrontWeapons} with
     * an early {@code return} when {@code isMoving()}, confirmed red under the two-sided bound.
     */
    @Test
    @DisplayName("the front clock keeps advancing through the whole MOVING window, unpaused by fightStage")
    void frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);

        java.util.List<FireEvent> events = traceFireEvents(world, system, 320);
        int coincidenceIndex = -1;
        for (int i = 0; i < events.size(); i++) {
            if (events.get(i).speeds().size() == 20) {
                coincidenceIndex = i;
                break;
            }
        }
        assertTrue(coincidenceIndex >= 0 && coincidenceIndex + 1 < events.size(),
            "expected a rear/front coincidence followed by an independent front shot");
        FireEvent coincidence = events.get(coincidenceIndex);
        FireEvent independentShot = events.get(coincidenceIndex + 1);
        assertEquals(10, independentShot.speeds().size(), "expected a pure front-only shot next");
        assertTrue(allNear(independentShot.speeds(), 160f), "expected the front's own sweep speed");

        float deltaSeconds = (independentShot.tick() - coincidence.tick()) * STEP;
        // The front period, this fixture's own numbers (patternCooldown 0.2s, TELL_DURATION 0.75s,
        // MOVE_DURATION 0.84s): (0.2 + 0.75 + 0.84) / FRONT_SHOTS_PER_CYCLE = 1.79 / 2 = 0.895s. A
        // two-sided bound, not a one-sided "> MOVE_DURATION" one: a clock paused for the whole MOVING
        // window would land at frontPeriod + MOVE_DURATION (~1.735s) instead, well outside this window,
        // where a one-sided ">" bound would have missed it — both 0.895s and 1.735s exceed 0.84s.
        float expectedFrontPeriod = (0.2f + 0.75f + BossSystem.MOVE_DURATION) / BossSystem.FRONT_SHOTS_PER_CYCLE;
        float tolerance = 2 * STEP;
        assertEquals(expectedFrontPeriod, deltaSeconds, tolerance,
            "the independent front shot must land at the front period (" + expectedFrontPeriod
                + "s), not merely after MOVE_DURATION has elapsed — a front clock paused during MOVING "
                + "would land about MOVE_DURATION (" + BossSystem.MOVE_DURATION + "s) later than this; "
                + "observed delta was " + deltaSeconds + "s");

        // At N=2 this lands inside COOLDOWN for this fixture (documented in the fragment), not MOVING —
        // recorded here as a fact about this ratio, not asserted as a requirement of the design.
        assertFalse(independentShot.moving(),
            "at FRONT_SHOTS_PER_CYCLE=2 this fixture's independent shot is expected in COOLDOWN, not MOVING");
    }

    private static boolean allNear(java.util.List<Float> speeds, float target) {
        for (float speed : speeds) {
            if (Math.abs(speed - target) >= 0.05f) {
                return false;
            }
        }
        return true;
    }

    /**
     * One tick's worth of newly spawned {@code ENEMY_PROJECTILE} colliders, which tick it was ({@code
     * tick}, 1-based, counted from the start of the trace) and whether {@code fightStage == MOVING} at
     * the instant they were fired — read through {@link BossSystem#isMoving()}, package-visible for
     * exactly this.
     */
    private record FireEvent(int tick, java.util.List<Float> speeds, boolean moving) { }

    /**
     * Drives {@code system} for {@code ticks} ticks and returns one {@link FireEvent} per tick that
     * produced at least one new {@code ENEMY_PROJECTILE} collider — the whole fire history of the run,
     * in order, which is what tracing the synchronisation rule needs rather than stopping at the next
     * volley the way {@link #runToNextVolley} does.
     */
    private static java.util.List<FireEvent> traceFireEvents(World world, BossSystem system, int ticks) {
        java.util.Set<Integer> seen = new java.util.HashSet<>();
        java.util.List<FireEvent> events = new java.util.ArrayList<>();
        for (int i = 0; i < ticks; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            java.util.List<Float> speeds = new java.util.ArrayList<>();
            for (int j = 0; j < world.colliders().size(); j++) {
                if (world.colliders().valueAt(j).layer != CollisionLayer.ENEMY_PROJECTILE) {
                    continue;
                }
                int entity = world.colliders().entityAt(j);
                if (seen.add(entity)) {
                    dev.luchoc.littlespaceship.core.domain.component.Motion motion = world.motions().get(entity);
                    speeds.add((float) Math.sqrt(motion.vx * motion.vx + motion.vy * motion.vy));
                }
            }
            if (!speeds.isEmpty()) {
                events.add(new FireEvent(i + 1, speeds, system.isMoving()));
            }
        }
        return events;
    }

    @Test
    @DisplayName("the fan aims at the player's position as locked at the start of the tell, not at fire time")
    void volleyAimsAtThePlayerLockedAtTellStart() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(1), new GameEventQueue());
        int player = world.createEntity();
        world.players().set(player, new dev.luchoc.littlespaceship.core.domain.component.Player(3, 2, 1));
        world.transforms().set(
            player, new dev.luchoc.littlespaceship.core.domain.component.Transform(20f, 30f));
        BossSystem system = new BossSystem(LEVEL);

        // Reach the fight: spawn, then the entrance in one jump, then the fixed 0.2 s cooldown of
        // this fixture's own boss() definition.
        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);
        system.update(world, 0.2f, InputFrame.IDLE);

        // The tell has now begun and the aim is locked at (20, 30). Move the player far away before
        // the volley actually fires: an honest tell dodges the frozen point, not a live-tracking one.
        world.transforms().get(player).x = 150f;

        java.util.Set<Integer> seen = new java.util.HashSet<>();
        java.util.List<dev.luchoc.littlespaceship.core.domain.component.Motion> volley =
            runToNextVolley(world, system, seen);

        int pod = podEntity(world);
        Transform podOrigin = world.transforms().get(pod);
        float expectedDx = 20f - podOrigin.x;
        float expectedDy = 30f - podOrigin.y;
        float expectedLength = (float) Math.sqrt(expectedDx * expectedDx + expectedDy * expectedDy);
        // The centre ray of the fan (ratio 0) reproduces the locked aim direction exactly.
        dev.luchoc.littlespaceship.core.domain.component.Motion centreRay = null;
        float bestAlignment = -2f;
        for (dev.luchoc.littlespaceship.core.domain.component.Motion motion : volley) {
            float speed = (float) Math.sqrt(motion.vx * motion.vx + motion.vy * motion.vy);
            float alignment = (motion.vx * expectedDx + motion.vy * expectedDy) / (speed * expectedLength);
            if (alignment > bestAlignment) {
                bestAlignment = alignment;
                centreRay = motion;
            }
        }
        assertTrue(bestAlignment > 0.99f, "no ray points at the position locked at tell start");
        assertTrue(centreRay != null);
    }

    /**
     * Drives {@code system} until new {@code ENEMY_PROJECTILE} colliders appear beyond those already in
     * {@code seen}, then returns exactly the newly spawned ones — a whole volley, since {@code
     * BossSystem} fires a pattern's full fan within a single {@code update} call, and adds them to
     * {@code seen} so a later call for the next volley does not re-count them. No {@code MotionSystem}
     * or {@code CleanupSystem} runs in this isolated test, so a fired projectile stays a live collider
     * forever — {@code seen} is what stands in for their absence.
     */
    private static java.util.List<dev.luchoc.littlespaceship.core.domain.component.Motion> runToNextVolley(
        World world, BossSystem system, java.util.Set<Integer> seen) {
        for (int i = 0; i < 200; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            java.util.List<dev.luchoc.littlespaceship.core.domain.component.Motion> fresh =
                new java.util.ArrayList<>();
            for (int j = 0; j < world.colliders().size(); j++) {
                if (world.colliders().valueAt(j).layer != CollisionLayer.ENEMY_PROJECTILE) {
                    continue;
                }
                int entity = world.colliders().entityAt(j);
                if (seen.add(entity)) {
                    fresh.add(world.motions().get(entity));
                }
            }
            if (!fresh.isEmpty()) {
                return fresh;
            }
        }
        throw new IllegalStateException("no volley fired within the tick budget");
    }

    /**
     * Asserts that exactly {@code expectedCount} of {@code speeds} are {@code speed} — the aimed fan
     * spreads direction, never magnitude, so every ray of one pattern's volley shares exactly its own
     * speed. The rays' directions are covered separately by {@code volleyAimsAtThePlayerLockedAtTellStart}.
     */
    private static void assertSpeedCount(java.util.List<Float> speeds, float speed, int expectedCount) {
        int count = 0;
        for (float magnitude : speeds) {
            if (Math.abs(magnitude - speed) < 0.05f) {
                count++;
            }
        }
        assertEquals(expectedCount, count, "expected " + expectedCount + " projectiles at speed " + speed);
    }

    private static int coreEntity(World world) {
        for (int i = 0; i < world.colliders().size(); i++) {
            if (world.colliders().valueAt(i).radius > 17f) {
                return world.colliders().entityAt(i);
            }
        }
        throw new IllegalStateException("no core entity found");
    }

    private static int podEntity(World world) {
        for (int i = 0; i < world.colliders().size(); i++) {
            Collider collider = world.colliders().valueAt(i);
            if (collider.radius > 11f && collider.radius < 13f) {
                return world.colliders().entityAt(i);
            }
        }
        throw new IllegalStateException("no pod entity found");
    }

    @Test
    @DisplayName("the star points and the boss's whole six-collider extent stay inside the playfield, "
        + "clear of the bottom of the screen")
    void starPointsKeepTheWholeBossOnScreen() {
        // Mirrors the offsets and radii BossSystem hardcodes for its six parts, to check the extent
        // rather than the centre — the arm is the widest part, the keel the lowest, the core/pod the
        // highest, per the class javadoc on STAR_X/STAR_Y.
        float armHalfWidth = 44f + 14f;
        float keelBelowCore = 27f + 13f;
        float coreOrPodAboveCore = 18f;

        for (int i = 0; i < BossSystem.STAR_POINT_COUNT; i++) {
            float x = BossSystem.STAR_X[i];
            float y = BossSystem.STAR_Y[i];
            assertTrue(x - armHalfWidth >= 0f, "point " + (i + 1) + " lets an arm cross the left edge");
            assertTrue(x + armHalfWidth <= MotionSystem.PLAYFIELD_WIDTH,
                "point " + (i + 1) + " lets an arm cross the right edge");
            assertTrue(y - keelBelowCore >= 0f,
                "point " + (i + 1) + " lets the keel reach the bottom of the screen");
            assertTrue(y + coreOrPodAboveCore <= SpawnSystem.PLAYFIELD_HEIGHT,
                "point " + (i + 1) + " lets the core or a pod cross the top edge");
        }
    }

    @Test
    @DisplayName("the boss travels only between the ten star points, "
        + "never more than three perimeter steps per move")
    void bossVisitsOnlyStarPointsWithinThreeSteps() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(7), new GameEventQueue());
        BossSystem system = new BossSystem(LEVEL);

        java.util.List<Integer> starIndices = driveAndCollectStarIndices(world, system, 12);

        assertTrue(starIndices.size() >= 8, "not enough star points visited to check the rule");
        for (int i = 1; i < starIndices.size(); i++) {
            int previous = starIndices.get(i - 1);
            int current = starIndices.get(i);
            int forward = Math.floorMod(current - previous, BossSystem.STAR_POINT_COUNT);
            int backward = BossSystem.STAR_POINT_COUNT - forward;
            int steps = Math.min(forward, backward);
            assertTrue(steps >= 1 && steps <= 3,
                "move from point " + (previous + 1) + " to point " + (current + 1)
                    + " is " + steps + " perimeter steps, outside the legal 1-3 range");
        }
    }

    @Test
    @DisplayName("the same seed produces the same sequence of star points")
    void samePatternForTheSameSeed() {
        java.util.List<Integer> first = driveAndCollectStarIndices(
            new World(new TestContent(balance).withBoss(LEVEL, boss(0f)), new Rng(42), new GameEventQueue()),
            new BossSystem(LEVEL), 6);
        java.util.List<Integer> second = driveAndCollectStarIndices(
            new World(new TestContent(balance).withBoss(LEVEL, boss(0f)), new Rng(42), new GameEventQueue()),
            new BossSystem(LEVEL), 6);

        assertEquals(first, second);
    }

    @Test
    @DisplayName("after moving to a star point, the next attack still fires from a standstill, "
        + "aimed at the player position locked at that tell's start")
    void firesFromStandstillAfterMoving() {
        TestContent content = new TestContent(balance).withBoss(LEVEL, boss(0f));
        World world = new World(content, new Rng(3), new GameEventQueue());
        int player = world.createEntity();
        world.players().set(player, new dev.luchoc.littlespaceship.core.domain.component.Player(3, 2, 1));
        world.transforms().set(
            player, new dev.luchoc.littlespaceship.core.domain.component.Transform(50f, 40f));
        BossSystem system = new BossSystem(LEVEL);

        // Reach the fight and let the first volley fire, then wait through the move to the first
        // star point.
        system.update(world, STEP, InputFrame.IDLE);
        system.update(world, 1f, InputFrame.IDLE);
        java.util.Set<Integer> seen = new java.util.HashSet<>();
        runToNextVolley(world, system, seen);

        int core = coreEntity(world);
        // Drive until the core stops changing position for two consecutive ticks: the move to the
        // first star point has completed.
        float lastX = world.transforms().get(core).x;
        float lastY = world.transforms().get(core).y;
        boolean settled = false;
        for (int i = 0; i < 300 && !settled; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            float x = world.transforms().get(core).x;
            float y = world.transforms().get(core).y;
            settled = x == lastX && y == lastY;
            lastX = x;
            lastY = y;
        }
        assertTrue(settled, "the boss never settled after its first move");
        float settledX = lastX;
        float settledY = lastY;

        // The player moves away right after the boss has settled, before the next tell locks aim.
        world.transforms().get(player).x = 10f;
        world.transforms().get(player).y = 200f;

        java.util.List<dev.luchoc.littlespaceship.core.domain.component.Motion> secondVolley =
            runToNextVolley(world, system, seen);

        // The boss fired without having moved again: its position at fire time is exactly where it
        // settled.
        assertEquals(settledX, world.transforms().get(core).x, 0.001f);
        assertEquals(settledY, world.transforms().get(core).y, 0.001f);

        int pod = podEntity(world);
        Transform podOrigin = world.transforms().get(pod);
        float expectedDx = 10f - podOrigin.x;
        float expectedDy = 200f - podOrigin.y;
        float expectedLength = (float) Math.sqrt(expectedDx * expectedDx + expectedDy * expectedDy);
        float bestAlignment = -2f;
        for (dev.luchoc.littlespaceship.core.domain.component.Motion motion : secondVolley) {
            float speed = (float) Math.sqrt(motion.vx * motion.vx + motion.vy * motion.vy);
            float alignment = (motion.vx * expectedDx + motion.vy * expectedDy) / (speed * expectedLength);
            bestAlignment = Math.max(bestAlignment, alignment);
        }
        assertTrue(bestAlignment > 0.99f, "the post-move volley does not aim at the locked player position");
    }

    /**
     * Drives {@code system} through the fight and returns the sequence of star-point indices it
     * settles on — every position held for more than one consecutive tick once matched against {@link
     * BossSystem#STAR_X}/{@link BossSystem#STAR_Y} within a small tolerance. The very first hold is
     * the entrance's own landing spot at {@code combatY}, which the star does not claim as one of its
     * own, so it is dropped: only positions that actually match a star point are returned.
     */
    private static java.util.List<Integer> driveAndCollectStarIndices(
        World world, BossSystem system, int minStarStops) {
        java.util.List<Integer> indices = new java.util.ArrayList<>();
        Float previousX = null;
        Float previousY = null;
        boolean previousWasHold = false;
        int core = -1;
        for (int i = 0; i < 20000 && indices.size() < minStarStops; i++) {
            system.update(world, STEP, InputFrame.IDLE);
            if (core == -1 || !world.isAlive(core)) {
                try {
                    core = coreEntity(world);
                } catch (IllegalStateException notYetSpawned) {
                    continue;
                }
            }
            Transform transform = world.transforms().get(core);
            float x = transform.x;
            float y = transform.y;
            boolean sameAsPrevious = previousX != null && x == previousX && y == previousY;
            if (sameAsPrevious && !previousWasHold) {
                int index = findStarIndex(x, y);
                if (index >= 0) {
                    indices.add(index);
                }
                previousWasHold = true;
            } else if (!sameAsPrevious) {
                previousWasHold = false;
            }
            previousX = x;
            previousY = y;
        }
        return indices;
    }

    private static int findStarIndex(float x, float y) {
        for (int i = 0; i < BossSystem.STAR_POINT_COUNT; i++) {
            if (Math.abs(BossSystem.STAR_X[i] - x) < 0.01f && Math.abs(BossSystem.STAR_Y[i] - y) < 0.01f) {
                return i;
            }
        }
        return -1;
    }

    private static SimpleBossDefinition boss(float entersAt) {
        return new SimpleBossDefinition(
            "boss-l1", entersAt,
            10, 5, 5,
            5000, 500, 800,
            1000f, 120f,
            0.2f,
            180f, 160f);
    }
}
