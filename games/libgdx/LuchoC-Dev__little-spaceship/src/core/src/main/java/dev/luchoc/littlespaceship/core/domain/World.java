package dev.luchoc.littlespaceship.core.domain;

import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;
import dev.luchoc.littlespaceship.core.domain.component.Attachment;
import dev.luchoc.littlespaceship.core.domain.component.BombState;
import dev.luchoc.littlespaceship.core.domain.component.Collider;
import dev.luchoc.littlespaceship.core.domain.component.CollisionLayer;
import dev.luchoc.littlespaceship.core.domain.component.ComponentStore;
import dev.luchoc.littlespaceship.core.domain.component.Drop;
import dev.luchoc.littlespaceship.core.domain.component.EnemyWeapon;
import dev.luchoc.littlespaceship.core.domain.component.Health;
import dev.luchoc.littlespaceship.core.domain.component.Invulnerable;
import dev.luchoc.littlespaceship.core.domain.component.Lifetime;
import dev.luchoc.littlespaceship.core.domain.component.Motion;
import dev.luchoc.littlespaceship.core.domain.component.Pickup;
import dev.luchoc.littlespaceship.core.domain.component.Player;
import dev.luchoc.littlespaceship.core.domain.component.ScoreValue;
import dev.luchoc.littlespaceship.core.domain.component.Shield;
import dev.luchoc.littlespaceship.core.domain.component.Spawner;
import dev.luchoc.littlespaceship.core.domain.component.Sprite;
import dev.luchoc.littlespaceship.core.domain.component.Trajectory;
import dev.luchoc.littlespaceship.core.domain.component.Transform;
import dev.luchoc.littlespaceship.core.domain.component.Weapon;
import dev.luchoc.littlespaceship.core.domain.component.WaveOrigin;
import dev.luchoc.littlespaceship.core.domain.entity.EntityId;
import dev.luchoc.littlespaceship.core.domain.entity.EntityRegistry;
import dev.luchoc.littlespaceship.core.domain.event.GameEventQueue;
import dev.luchoc.littlespaceship.core.domain.rng.Rng;
import dev.luchoc.littlespaceship.core.domain.system.ScoreSystem;
import dev.luchoc.littlespaceship.core.port.BossStatus;
import dev.luchoc.littlespaceship.core.port.CompletionBonus;
import dev.luchoc.littlespaceship.core.port.ContentSource;
import dev.luchoc.littlespaceship.core.port.InvulnerabilitySource;
import dev.luchoc.littlespaceship.core.port.LevelOutcome;
import dev.luchoc.littlespaceship.core.port.PlayerStatus;
import dev.luchoc.littlespaceship.core.port.SpriteVisitor;
import dev.luchoc.littlespaceship.core.port.WorldView;
import java.util.ArrayList;
import java.util.List;

/**
 * Everything the simulation knows: which entities exist, what components they hold, and the three
 * services the systems share —randomness, content and the event queue—.
 *
 * <p>Stores are named, one field per component type, instead of a map keyed by class. It is more
 * lines and it is worth them: the domain stays explicit, the compiler checks every access, and
 * nothing has to be cast. Adding a component means adding a field here and freeing it in
 * {@link #destroyEntity(int)}, which is the one place that has to know every store.
 *
 * <p>The world does not run the systems and does not know they exist. Composing and running them is
 * the job of the application layer, which is what keeps the dependency between the two pointing in
 * a single direction.
 *
 * <p>Presentation never receives this object: it receives {@link #view()}, which can only read.
 */
public final class World {

    private final EntityRegistry entities = new EntityRegistry();

    private final ComponentStore<Transform> transforms = new ComponentStore<>();
    private final ComponentStore<Motion> motions = new ComponentStore<>();
    private final ComponentStore<Collider> colliders = new ComponentStore<>();
    private final ComponentStore<Sprite> sprites = new ComponentStore<>();
    private final ComponentStore<Player> players = new ComponentStore<>();
    private final ComponentStore<Invulnerable> invulnerabilities = new ComponentStore<>();
    private final ComponentStore<Shield> shields = new ComponentStore<>();
    private final ComponentStore<Attachment> attachments = new ComponentStore<>();
    private final ComponentStore<ScoreValue> scoreValues = new ComponentStore<>();
    private final ComponentStore<Drop> drops = new ComponentStore<>();
    private final ComponentStore<Weapon> weapons = new ComponentStore<>();
    private final ComponentStore<Pickup> pickups = new ComponentStore<>();
    private final ComponentStore<Health> healths = new ComponentStore<>();
    private final ComponentStore<BombState> bombStates = new ComponentStore<>();
    private final ComponentStore<Spawner> spawners = new ComponentStore<>();
    private final ComponentStore<EnemyWeapon> enemyWeapons = new ComponentStore<>();
    private final ComponentStore<Lifetime> lifetimes = new ComponentStore<>();
    private final ComponentStore<WaveOrigin> waveOrigins = new ComponentStore<>();
    private final ComponentStore<Trajectory> trajectories = new ComponentStore<>();

    /**
     * Overlaps detected by {@code CollisionSystem} this tick, consumed by {@code DamageSystem} right
     * after in the same tick. Internal to the domain: it never crosses towards presentation and is
     * unrelated to {@link #events}, which drains only once the whole tick is over.
     */
    private final List<CollisionHit> collisionHits = new ArrayList<>();

    /**
     * Entities marked for destruction this tick, resolved by {@code CleanupSystem} and nowhere else.
     * Marking instead of destroying immediately is what keeps every other system safe to iterate a
     * component store without an entity vanishing under it mid-tick.
     */
    private final List<Integer> pendingDestruction = new ArrayList<>();

    /**
     * Whether {@code SpawnSystem} has walked every event of the level's {@code WaveTimeline}. Read
     * by {@link View#outcome()} to decide {@link LevelOutcome#COMPLETED}; a run built without a
     * {@code SpawnSystem} — the level-less constructor {@code Simulation} offers for sandboxes and
     * tests — simply never sets this, so it never completes, which is the correct behaviour for a
     * run with no level to finish.
     */
    private boolean waveTimelineExhausted;

    /**
     * Whether this run's level has a boss at all, set by {@code BossSystem} the moment it first
     * updates. {@link View#outcome()} branches on this: a boss level can only ever complete by
     * {@link #bossDefeated}, never by the older "wave timeline dry, no enemy left" rule — a boss's
     * own parts are {@code ENEMY}-layer colliders, so that older rule would otherwise report {@link
     * LevelOutcome#COMPLETED} the instant the boss's own entrance quiet gap left no enemy on screen,
     * long before the fight even started. A level with no {@code BossSystem} registered never sets
     * this, so it keeps the older rule exactly as before phase 07.
     */
    private boolean bossLevel;

    /** Whether the boss's core has been destroyed. Set once by {@code BossSystem}, never cleared. */
    private boolean bossDefeated;

    /** Whether the boss is currently on screen — spawned and not yet defeated. */
    private boolean bossPresent;

    private int bossHp;
    private int bossHpMax;

    private final ContentSource content;
    private final Rng rng;
    private final GameEventQueue events;

    private final WorldView view = new View();

    /**
     * Creates an empty world.
     *
     * @param content where balance values and definitions come from
     * @param rng the seeded generator every random decision goes through
     * @param events the queue the systems drop their events into
     */
    public World(ContentSource content, Rng rng, GameEventQueue events) {
        if (content == null || rng == null || events == null) {
            throw new IllegalArgumentException("a world needs content, rng and an event queue");
        }
        this.content = content;
        this.rng = rng;
        this.events = events;
    }

    /**
     * Creates an entity with no components.
     *
     * @return the new entity handle
     */
    public int createEntity() {
        return entities.create();
    }

    /**
     * Destroys an entity and strips every component it had.
     *
     * <p>Every store is listed here on purpose: forgetting one would leave data attached to a slot
     * that is about to be handed out again, and the next entity to land on it would inherit it.
     *
     * @param entity the handle to destroy
     * @return true when something was actually destroyed
     */
    public boolean destroyEntity(int entity) {
        if (!entities.isAlive(entity)) {
            return false;
        }
        transforms.remove(entity);
        motions.remove(entity);
        colliders.remove(entity);
        sprites.remove(entity);
        players.remove(entity);
        invulnerabilities.remove(entity);
        shields.remove(entity);
        attachments.remove(entity);
        scoreValues.remove(entity);
        drops.remove(entity);
        weapons.remove(entity);
        pickups.remove(entity);
        healths.remove(entity);
        bombStates.remove(entity);
        spawners.remove(entity);
        enemyWeapons.remove(entity);
        lifetimes.remove(entity);
        waveOrigins.remove(entity);
        trajectories.remove(entity);
        return entities.destroy(entity);
    }

    /**
     * Tells whether a handle still refers to a live entity.
     *
     * @param entity the handle to check
     * @return true when the entity is alive
     */
    public boolean isAlive(int entity) {
        return entities.isAlive(entity);
    }

    /**
     * @return how many entities are alive right now
     */
    public int entityCount() {
        return entities.aliveCount();
    }

    /**
     * @return positions
     */
    public ComponentStore<Transform> transforms() {
        return transforms;
    }

    /**
     * @return velocities
     */
    public ComponentStore<Motion> motions() {
        return motions;
    }

    /**
     * @return collision volumes
     */
    public ComponentStore<Collider> colliders() {
        return colliders;
    }

    /**
     * @return drawing state
     */
    public ComponentStore<Sprite> sprites() {
        return sprites;
    }

    /**
     * @return the player's persistent stats; holds at most one entity
     */
    public ComponentStore<Player> players() {
        return players;
    }

    /**
     * @return remaining grace time against damage
     */
    public ComponentStore<Invulnerable> invulnerabilities() {
        return invulnerabilities;
    }

    /**
     * @return active shields
     */
    public ComponentStore<Shield> shields() {
        return shields;
    }

    /**
     * @return the equipped attachment, if any
     */
    public ComponentStore<Attachment> attachments() {
        return attachments;
    }

    /**
     * @return points awarded for destroying each entity that carries one
     */
    public ComponentStore<ScoreValue> scoreValues() {
        return scoreValues;
    }

    /**
     * @return the designed drop of each entity that carries one
     */
    public ComponentStore<Drop> drops() {
        return drops;
    }

    /**
     * @return the player's firing state
     */
    public ComponentStore<Weapon> weapons() {
        return weapons;
    }

    /**
     * @return pickups lying in the playfield, waiting to be collected
     */
    public ComponentStore<Pickup> pickups() {
        return pickups;
    }

    /**
     * @return hit points of the entities that need more than one hit to go down
     */
    public ComponentStore<Health> healths() {
        return healths;
    }

    /**
     * @return the tick-level rising-edge state {@code BombSystem} tracks for the player
     */
    public ComponentStore<BombState> bombStates() {
        return bombStates;
    }

    /**
     * @return periodic-spawn state for the entities that carry one, such as the heavy carrier
     */
    public ComponentStore<Spawner> spawners() {
        return spawners;
    }

    /**
     * @return per-archetype firing state for the entities that carry one, such as {@code enemy-shooter}
     */
    public ComponentStore<EnemyWeapon> enemyWeapons() {
        return enemyWeapons;
    }

    /**
     * @return the maximum-lifetime countdown for the entities that carry one
     */
    public ComponentStore<Lifetime> lifetimes() {
        return lifetimes;
    }

    /**
     * @return which wave spawned each entity that carries one, directly or through a carrier
     */
    public ComponentStore<WaveOrigin> waveOrigins() {
        return waveOrigins;
    }

    /**
     * @return the elapsed-time state a movement shape resolves against, for the entities that carry
     *     one
     */
    public ComponentStore<Trajectory> trajectories() {
        return trajectories;
    }

    /**
     * Finds the player's entity.
     *
     * <p>Exactly one entity holds {@link Player} at a time in the MVP; this is a lookup convenience
     * for the systems that need it, not a claim that a second one could not exist mechanically.
     *
     * @return the player's handle, or {@link EntityId#NONE} if no entity holds {@link Player}
     */
    public int playerEntity() {
        return players.size() > 0 ? players.entityAt(0) : EntityId.NONE;
    }

    /**
     * @return overlaps detected this tick, for {@code DamageSystem} to resolve right after
     */
    public List<CollisionHit> collisionHits() {
        return collisionHits;
    }

    /**
     * Marks an entity to be destroyed once {@code CleanupSystem} runs, at the end of the tick.
     *
     * <p>No system destroys an entity directly outside of that stage: doing so mid-tick would reorder
     * a component store's dense array under whichever system is iterating it.
     *
     * @param entity the handle to mark; a dead or stale handle is ignored
     */
    public void markForDestruction(int entity) {
        if (isAlive(entity)) {
            pendingDestruction.add(entity);
        }
    }

    /**
     * @return entities marked for destruction this tick, resolved and cleared by {@code
     *     CleanupSystem}
     */
    public List<Integer> pendingDestruction() {
        return pendingDestruction;
    }

    /**
     * Records that {@code SpawnSystem} has walked every event of the level's {@code WaveTimeline}.
     * Idempotent: called every tick once the cursor reaches the end, not just once.
     */
    public void markWaveTimelineExhausted() {
        waveTimelineExhausted = true;
    }

    /**
     * Records that this run's level has a boss, so {@link View#outcome()} knows to require {@link
     * #markBossDefeated()} instead of the older wave-timeline rule. Idempotent: {@code BossSystem}
     * calls it every tick, not just once.
     */
    public void markBossLevel() {
        bossLevel = true;
    }

    /**
     * Records that the boss's core has been destroyed and clears {@link #bossPresent}, so the health
     * bar and the victory condition agree on the same instant.
     */
    public void markBossDefeated() {
        bossDefeated = true;
        bossPresent = false;
    }

    /**
     * Reports the boss's current aggregate health, called by {@code BossSystem} every tick the boss
     * is on screen — from the start of its entrance through the fight, stopping once {@link
     * #markBossDefeated()} is called instead.
     *
     * @param hp current combined hit points across every surviving part
     * @param hpMax the combined hit points the boss started the fight with
     */
    public void setBossStatus(int hp, int hpMax) {
        bossPresent = true;
        bossHp = hp;
        bossHpMax = hpMax;
    }

    /**
     * @return the content the simulation reads its numbers from
     */
    public ContentSource content() {
        return content;
    }

    /**
     * @return the seeded generator; no system may use any other source of randomness
     */
    public Rng rng() {
        return rng;
    }

    /**
     * @return the queue where events wait until the tick is over
     */
    public GameEventQueue events() {
        return events;
    }

    /**
     * Returns the read-only face of this world, the only thing presentation ever sees.
     *
     * @return a view that cannot modify anything
     */
    public WorldView view() {
        return view;
    }

    /**
     * Reads the world without exposing it. It is an inner class and not the world itself so that
     * nobody can cast the view back into something mutable.
     */
    private final class View implements WorldView {

        @Override
        public void forEachSprite(SpriteVisitor visitor) {
            if (visitor == null) {
                throw new IllegalArgumentException("a visitor cannot be null");
            }
            for (int i = 0; i < sprites.size(); i++) {
                int entity = sprites.entityAt(i);
                Transform transform = transforms.get(entity);
                if (transform == null) {
                    // Something drawable with no position is a bug in whoever built the entity,
                    // but the renderer is not the place to blow up over it.
                    continue;
                }
                Sprite sprite = sprites.valueAt(i);
                visitor.accept(sprite.id, transform.x, transform.y, sprite.frame, sprite.rotation);
            }
        }

        @Override
        public PlayerStatus player() {
            int entity = playerEntity();
            if (entity == EntityId.NONE) {
                return PlayerStatus.NONE;
            }
            Player state = players.get(entity);
            if (state == null) {
                return PlayerStatus.NONE;
            }
            Attachment attachment = attachments.get(entity);
            Invulnerable invulnerable = invulnerabilities.get(entity);
            return new PlayerStatus(
                state.lives,
                state.bombs,
                state.shotLevel,
                shields.has(entity),
                attachment != null ? attachment.id : "",
                invulnerable != null ? invulnerable.source : InvulnerabilitySource.NONE,
                invulnerable != null ? invulnerable.remaining : 0f,
                state.score);
        }

        @Override
        public CompletionBonus completionBonus() {
            int entity = playerEntity();
            Player state = entity == EntityId.NONE ? null : players.get(entity);
            if (state == null) {
                return new CompletionBonus(0, 0);
            }
            return ScoreSystem.completionBonus(content.balance(), state);
        }

        @Override
        public LevelOutcome outcome() {
            int entity = playerEntity();
            Player state = entity == EntityId.NONE ? null : players.get(entity);
            if (state != null && state.lives <= 0) {
                return LevelOutcome.DEFEATED;
            }
            boolean alive = state == null || state.lives > 0;
            if (bossLevel) {
                // A boss level completes only by defeating the boss — see bossLevel's javadoc for
                // why the older wave-timeline rule below would lie once a boss exists.
                return bossDefeated && alive ? LevelOutcome.COMPLETED : LevelOutcome.IN_PROGRESS;
            }
            if (waveTimelineExhausted && noEnemyLeft() && alive) {
                return LevelOutcome.COMPLETED;
            }
            return LevelOutcome.IN_PROGRESS;
        }

        @Override
        public BossStatus bossStatus() {
            if (!bossPresent) {
                return BossStatus.NONE;
            }
            return new BossStatus(true, bossHp, bossHpMax);
        }

        /**
         * True when no entity carries an {@code ENEMY} collider, checked by walking {@link
         * #colliders} directly rather than adding a fourth, redundant store just to count them —
         * the same trade a spatial structure for collision would make with no case in the MVP that
         * needs it.
         */
        private boolean noEnemyLeft() {
            for (int i = 0; i < colliders.size(); i++) {
                if (colliders.valueAt(i).layer == CollisionLayer.ENEMY) {
                    return false;
                }
            }
            return true;
        }
    }
}
