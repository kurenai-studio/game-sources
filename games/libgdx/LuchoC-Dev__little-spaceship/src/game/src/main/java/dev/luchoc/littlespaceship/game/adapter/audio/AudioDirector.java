package dev.luchoc.littlespaceship.game.adapter.audio;

import dev.luchoc.littlespaceship.core.domain.event.EnemyDestroyed;
import dev.luchoc.littlespaceship.core.domain.event.GameEvent;
import dev.luchoc.littlespaceship.core.port.BossStatus;
import dev.luchoc.littlespaceship.core.port.GameEventSink;
import dev.luchoc.littlespaceship.core.port.InvulnerabilitySource;
import dev.luchoc.littlespaceship.core.port.PlayerStatus;
import dev.luchoc.littlespaceship.core.port.SpriteId;
import dev.luchoc.littlespaceship.core.port.SpriteVisitor;
import dev.luchoc.littlespaceship.core.port.WorldView;

/**
 * Turns frame-over-frame differences in {@link WorldView} into sound, exactly the way {@code
 * HudRenderer} already turns them into pixels, plus the one event {@code core} does emit — {@link
 * EnemyDestroyed}, delivered through {@link GameEventSink#emit} outside the tick, per {@code
 * GameEventQueue}'s own ordering guarantee — for the one question a snapshot diff cannot answer:
 * what caused a change, not just that one happened.
 *
 * <p>Every {@link PlayerStatus}-driven trigger below reads a field it already exposes and asks only
 * "did this change since last frame". All six {@code PickupSystem} kinds are still fully
 * distinguishable from an ordinary kill this way, because unlike score — the field phase 06's review
 * found ambiguous — each pickup kind changes a field of its own that damage or a kill never touches:
 * lives only rises from the extra-life pickup, bombs only rises from the bomb-recharge pickup,
 * {@code shieldActive} only flips on from the shield pickup, and so on.
 *
 * <p>The boss music swap is a {@link BossStatus#present()} diff, the same shape: {@code false ->
 * true} starts {@link MusicTrack#BOSS}. The reverse edge — boss defeated, or the player dying mid
 * fight — needs no diff of its own: {@link dev.luchoc.littlespaceship.game.LittleSpaceshipGame
 * #setScreen} already stops whatever is playing the instant {@code PlayScreen} is replaced by
 * {@code VictoryScreen} or {@code DefeatScreen}, which is every way the fight can end.
 *
 * <p>Implements {@link SpriteVisitor} itself, the same reasoning {@code WorldRenderer} gives for
 * doing the same: a lambda handed to {@link WorldView#forEachSprite} would allocate every frame.
 * Counting player shots costs a second full traversal of every drawable entity, on top of the one
 * {@code WorldRenderer} already does to draw them — accepted deliberately, since nothing here
 * allocates, and a second {@code O(entities)} pass is nowhere near {@code CLAUDE.md}'s actual
 * concern, which is allocation, not traversal count. {@link #emit} is handed to {@code Simulation}
 * as its {@link GameEventSink} directly — implementing the interface instead of wrapping it in a
 * lambda avoids one more per-run allocation, though this one would not repeat per frame either way.
 */
public final class AudioDirector implements SpriteVisitor, GameEventSink {

    /** Matches {@code core.domain.system.WeaponSystem}'s own constants — not exposed through {@code
     * core.port}, the same situation {@code WorldRenderer.PLAYER_SPRITE_ID} already documents a
     * justification for. */
    private static final SpriteId SHOT_P1 = new SpriteId("shot-p1");
    private static final SpriteId SHOT_P2 = new SpriteId("shot-p2");

    private final AudioSystem audio;

    private boolean initialized;
    private PlayerStatus previous = PlayerStatus.NONE;
    private boolean previousBossPresent;
    private int previousShotSprites;
    private int shotSpritesThisFrame;

    public AudioDirector(AudioSystem audio) {
        this.audio = audio;
    }

    /**
     * Reads one frame's {@link WorldView} and {@link PlayerStatus} and plays whatever changed since
     * the last call. The very first call only records a baseline: comparing against {@link
     * PlayerStatus#NONE} would otherwise read the run's starting lives and bombs as pickups
     * collected in frame one, and a boss-less level's very first {@link BossStatus#NONE} would
     * otherwise never be recorded as the starting point either.
     */
    public void update(WorldView view, PlayerStatus current) {
        shotSpritesThisFrame = 0;
        view.forEachSprite(this);
        if (initialized && shotSpritesThisFrame > previousShotSprites) {
            audio.playSfx(Sfx.SHOOT);
        }
        previousShotSprites = shotSpritesThisFrame;

        boolean bossPresent = view.bossStatus().present();
        if (initialized) {
            diffPlayerStatus(current);
            if (bossPresent && !previousBossPresent) {
                audio.playMusic(MusicTrack.BOSS);
            }
        }
        previousBossPresent = bossPresent;
        previous = current;
        initialized = true;
    }

    /** {@link GameEventSink#emit}: the only {@code core} event reacted to today is {@link
     * EnemyDestroyed}, which has no position use here yet — {@link Sfx#EXPLOSION} is not played
     * positionally, matching every other one-shot {@link AudioSystem} already plays. */
    @Override
    public void emit(GameEvent event) {
        if (event instanceof EnemyDestroyed) {
            audio.playSfx(Sfx.EXPLOSION);
        }
    }

    @Override
    public void accept(SpriteId sprite, float x, float y, int frame, float rotation) {
        if (SHOT_P1.equals(sprite) || SHOT_P2.equals(sprite)) {
            shotSpritesThisFrame++;
        }
    }

    private void diffPlayerStatus(PlayerStatus current) {
        boolean pickedUp = current.lives() > previous.lives()
            || current.bombs() > previous.bombs()
            || current.weaponLevel() > previous.weaponLevel()
            || (current.shieldActive() && !previous.shieldActive())
            || (!current.attachmentId().isEmpty() && previous.attachmentId().isEmpty())
            || (current.invulnerabilitySource() == InvulnerabilitySource.POWERUP
                && previous.invulnerabilitySource() != InvulnerabilitySource.POWERUP);
        if (pickedUp) {
            audio.playSfx(Sfx.POWERUP);
        }

        if (current.bombs() < previous.bombs()) {
            audio.playSfx(Sfx.BOMB);
        }

        boolean justHit = current.invulnerabilitySource() != previous.invulnerabilitySource()
            && (current.invulnerabilitySource() == InvulnerabilitySource.DAMAGE
                || current.invulnerabilitySource() == InvulnerabilitySource.RESPAWN);
        if (justHit) {
            audio.playSfx(Sfx.IMPACT);
        }
    }
}
