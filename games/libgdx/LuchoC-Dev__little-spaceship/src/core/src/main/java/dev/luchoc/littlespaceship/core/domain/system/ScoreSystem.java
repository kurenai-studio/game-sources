package dev.luchoc.littlespaceship.core.domain.system;

import dev.luchoc.littlespaceship.core.domain.World;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.port.BalanceValues;
import dev.luchoc.littlespaceship.core.port.CompletionBonus;
import dev.luchoc.littlespaceship.core.port.InputFrame;
import java.util.List;

/**
 * Accumulates {@link Player#score}, the one mechanism every point in the game goes through.
 *
 * <p>Runs after {@code DAMAGE} and {@code PICKUP}, both of which may have called {@link
 * World#markForDestruction(int)} this tick — for an enemy destroyed by a player projectile, by
 * ramming, or by a bomb, and for a pickup collected at the cap. This system does not care which:
 * it sweeps {@link World#pendingDestruction()} once, right before {@code CleanupSystem} would clear
 * it, and awards whatever {@link ScoreValue} the destroyed entity carries.
 *
 * <p>An entity's {@link ScoreValue} is removed the moment it is awarded, not left for {@code
 * CleanupSystem} to strip along with everything else. That is what makes the sweep safe against
 * {@link World#markForDestruction(int)} having been called twice for the same entity in the same
 * tick — a real possibility with no dedication against it, since an enemy could in principle be both
 * rammed and shot in one tick — without this system double-counting the points: the second
 * occurrence finds no {@link ScoreValue} left and contributes nothing.
 *
 * <p>No combos or multipliers exist in the MVP, per {@code 02-mvp-functional-spec.md}: every point
 * awarded here is exactly the destroyed entity's {@link ScoreValue#points}, nothing scaled by
 * streaks or timing.
 */
public final class ScoreSystem implements GameSystem {

    @Override
    public SystemOrder order() {
        return SystemOrder.SCORE;
    }

    @Override
    public void update(World world, float step, InputFrame input) {
        int player = world.playerEntity();
        if (player == EntityId.NONE) {
            return;
        }
        Player state = world.players().get(player);
        if (state == null) {
            return;
        }

        List<Integer> pending = world.pendingDestruction();
        for (int i = 0; i < pending.size(); i++) {
            int entity = pending.get(i);
            ScoreValue value = world.scoreValues().get(entity);
            if (value != null) {
                state.score += value.points;
                world.scoreValues().remove(entity);
            }
        }
    }

    /**
     * The end-of-level bonus per {@code 10-mvp-initial-values.md}: a fixed amount per remaining life
     * and per remaining bomb, no combos or multipliers involved. A pure function and not a system.
     *
     * <p>Public so {@code World.View.completionBonus()} can call it: that method is the only crossing
     * this needs, since {@link Player} is a mutable {@code domain.component} type {@code game} can
     * never obtain, and {@link CompletionBonus} is the read-only shape that carries the same numbers
     * across the boundary instead. Nothing else outside this package should call this directly —
     * whoever needs the bonus asks {@code WorldView}, not this system.
     *
     * @param balance where the per-life and per-bomb bonus amounts come from
     * @param player the player's state at the moment the level is completed
     * @return the completion bonus, split into its lives and bombs components
     */
    public static CompletionBonus completionBonus(BalanceValues balance, Player player) {
        return new CompletionBonus(
            player.lives * balance.lifeCompletionBonus(),
            player.bombs * balance.bombCompletionBonus());
    }
}
