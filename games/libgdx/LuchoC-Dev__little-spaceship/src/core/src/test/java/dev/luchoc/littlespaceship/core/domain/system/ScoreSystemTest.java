package dev.luchoc.littlespaceship.core.domain.system;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestBalance;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ScoreSystemTest {

    private static final float STEP = 1f / 60f;

    private final TestBalance balance = new TestBalance();
    private final World world = new World(new TestContent(balance), new Rng(1), new GameEventQueue());
    private final ScoreSystem system = new ScoreSystem();

    @Test
    @DisplayName("a destroyed entity's score value is credited to the player")
    void creditsTheDestroyedEntitysPoints() {
        int player = spawnPlayer();
        int enemy = scoredEntity(100);
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(100, world.players().get(player).score);
    }

    @Test
    @DisplayName("an entity destroyed with no score value contributes nothing")
    void entityWithNoScoreValueContributesNothing() {
        int player = spawnPlayer();
        int entity = world.createEntity();
        world.markForDestruction(entity);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(0, world.players().get(player).score);
    }

    @Test
    @DisplayName("several destroyed entities in the same tick all add up")
    void severalDestructionsAddUp() {
        int player = spawnPlayer();
        world.markForDestruction(scoredEntity(100));
        world.markForDestruction(scoredEntity(250));
        world.markForDestruction(scoredEntity(500));

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(850, world.players().get(player).score);
    }

    @Test
    @DisplayName("an entity marked for destruction twice in the same tick is only scored once")
    void doubleMarkingIsScoredOnce() {
        int player = spawnPlayer();
        int enemy = scoredEntity(100);
        world.markForDestruction(enemy);
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(100, world.players().get(player).score);
    }

    @Test
    @DisplayName("the score value is removed once awarded")
    void scoreValueIsRemovedOnceAwarded() {
        spawnPlayer();
        int enemy = scoredEntity(100);
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertNull(world.scoreValues().get(enemy));
    }

    @Test
    @DisplayName("something not marked for destruction is never scored, even alive with a score value")
    void aliveEntitiesAreNeverScored() {
        int player = spawnPlayer();
        scoredEntity(100);

        system.update(world, STEP, InputFrame.IDLE);

        assertEquals(0, world.players().get(player).score);
    }

    @Test
    @DisplayName("the completion bonus is the per-life and per-bomb amounts, scaled by what remains")
    void completionBonusScalesByRemainingLivesAndBombs() {
        Player player = new Player(3, 2, 1);

        var bonus = ScoreSystem.completionBonus(balance, player);

        assertEquals(3 * balance.lifeCompletionBonus, bonus.livesBonus());
        assertEquals(2 * balance.bombCompletionBonus, bonus.bombsBonus());
    }

    @Test
    @DisplayName("does nothing when there is no player entity")
    void noPlayerIsHarmless() {
        int enemy = scoredEntity(100);
        world.markForDestruction(enemy);

        system.update(world, STEP, InputFrame.IDLE);

        assertNull(world.players().get(0));
    }

    private int spawnPlayer() {
        int player = world.createEntity();
        world.players().set(player, new Player(3, 2, 1));
        return player;
    }

    private int scoredEntity(int points) {
        int entity = world.createEntity();
        world.scoreValues().set(entity, new ScoreValue(points));
        return entity;
    }
}
