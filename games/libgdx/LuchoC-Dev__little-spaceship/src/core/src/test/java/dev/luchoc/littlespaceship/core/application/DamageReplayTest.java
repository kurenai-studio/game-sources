package dev.luchoc.littlespaceship.core.application;

import static org.junit.jupiter.api.Assertions.assertEquals;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Attachment;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.Invulnerable;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.Shield;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import dev.luchoc.littlespaceship.core.testsupport.TestContent;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * A scripted damage sequence, run through the real MVP pipeline — motion, collision, damage,
 * cleanup — twice, has to land on exactly the same final state both times. That is what every
 * recorded replay ultimately depends on.
 */
class DamageReplayTest {

    private static final int TICKS = 180;

    @Test
    @DisplayName("a scripted damage sequence reproduces the same final state twice")
    void damageSequenceIsDeterministic() {
        String first = fingerprintOf(run());
        String second = fingerprintOf(run());

        assertEquals(first, second);
    }

    /** Builds and runs the scenario once: a player crashing into a weak enemy and weaving near a
     *  heavy one, with a shield and an attachment equipped so the whole chain is exercised. */
    private static Simulation run() {
        Simulation simulation = new Simulation(new TestContent(), event -> {
        }, 7);
        World world = simulation.world();

        // The player entity already exists from construction; this scenario overrides its state
        // instead of creating a second one, which is what `world.playerEntity()` would otherwise
        // resolve to first and leave this scripted player unreachable by DamageSystem.
        int player = world.playerEntity();
        world.transforms().set(player, new Transform(100f, 50f));
        world.motions().set(player, new Motion(0f, 0f));
        world.colliders().set(player, new Collider(4f, CollisionLayer.PLAYER));
        world.players().set(player, new Player(3, 2, 1));
        world.shields().set(player, new Shield());
        world.attachments().set(player, new Attachment("attachment", 1));

        int weakEnemy = world.createEntity();
        world.transforms().set(weakEnemy, new Transform(100f, 50f));
        world.colliders().set(weakEnemy, new Collider(4f, CollisionLayer.ENEMY, true));

        int heavyEnemy = world.createEntity();
        world.transforms().set(heavyEnemy, new Transform(140f, 90f));
        world.colliders().set(heavyEnemy, new Collider(6f, CollisionLayer.ENEMY, false));

        for (int tick = 0; tick < TICKS; tick++) {
            simulation.tick(GameLoop.STEP, scriptedFrame(tick));
        }
        return simulation;
    }

    /**
     * Movement that drives the player back and forth across the playfield, with no randomness, so
     * both runs of {@link #run()} see exactly the same sequence of frames.
     */
    private static InputFrame scriptedFrame(int tick) {
        float moveX = ((tick / 5) % 3) - 1f;
        float moveY = ((tick / 7) % 3) - 1f;
        boolean slow = tick % 17 == 0;
        return new InputFrame(moveX * 200f, moveY * 200f, false, slow, false);
    }

    /**
     * A textual snapshot of the whole world, positions and defensive state included. Comparing
     * strings and not floats is deliberate: a difference of one bit has to fail, because one bit is
     * all it takes for a replay to diverge.
     */
    private static String fingerprintOf(Simulation simulation) {
        World world = simulation.world();
        List<String> lines = new ArrayList<>();
        for (int i = 0; i < world.transforms().size(); i++) {
            int entity = world.transforms().entityAt(i);
            Transform transform = world.transforms().valueAt(i);
            StringBuilder line = new StringBuilder();
            line.append(entity)
                .append(" p ").append(Float.floatToIntBits(transform.x))
                .append(',').append(Float.floatToIntBits(transform.y));
            Player player = world.players().get(entity);
            if (player != null) {
                line.append(" player ").append(player.lives).append(',').append(player.bombs)
                    .append(',').append(player.shotLevel);
                line.append(" shield ").append(world.shields().has(entity));
                Attachment attachment = world.attachments().get(entity);
                line.append(" attachment ")
                    .append(attachment == null ? "none" : attachment.durability);
                Invulnerable invulnerable = world.invulnerabilities().get(entity);
                line.append(" invuln ").append(
                    invulnerable == null ? "none" : Float.floatToIntBits(invulnerable.remaining));
            }
            lines.add(line.toString());
        }
        lines.sort(String::compareTo);
        return world.entityCount() + " entities\n" + String.join("\n", lines);
    }
}
