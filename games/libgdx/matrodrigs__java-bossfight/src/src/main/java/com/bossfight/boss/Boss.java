package com.bossfight.boss;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.math.MathUtils;
import com.bossfight.config.Constants;
import com.bossfight.entities.Hitbox;
import com.bossfight.entities.Player;

import java.util.ArrayDeque;

public class Boss {
    private static final float ACTION_IMPULSE_DURATION = 0.30f;
    private static final float HIT_REACTION_DURATION = 0.18f;
    private static final float SPECIAL_HIT_REACTION_DURATION = 0.36f;
    private static final float PHASE_ONE_RECOVERY_DURATION = 0.90f;
    private static final float PHASE_TWO_RECOVERY_DURATION = 0.42f;
    private static final float FINAL_RAGE_RECOVERY_DURATION = 0.34f;
    private static final float CHAIN_RECOVERY_DURATION = 0.20f;
    private static final float FINAL_RAGE_HEALTH_RATIO = 0.20f;

    private enum Phase {
        ONE,
        TWO,
        FINAL_RAGE
    }

    private final Hitbox hitbox;
    private final ArrayDeque<BossSoundEvent> soundEvents = new ArrayDeque<>();
    private final Color telegraphColor = new Color(1f, 0.24f, 0.1f, 1f);
    private BossState currentState;
    private Phase phase = Phase.ONE;
    private int health;
    private int lastAttackIndex = -1;
    private int phaseTwoAttackCount;
    private BossState queuedFollowUpState;
    private float telegraphTimer;
    private float telegraphDuration = 1f;
    private float visualStateTime;
    private float actionImpulseTimer;
    private float hitReactionTimer;
    private float specialHitReactionTimer;

    public Boss() {
        health = Constants.BOSS_MAX_HEALTH;
        hitbox = new Hitbox(Constants.BOSS_START_X, Constants.BOSS_START_Y,
                Constants.BOSS_WIDTH, Constants.BOSS_HEIGHT);
        currentState = new IdleState(1.2f);
    }

    public void update(float delta, ProjectileSpawner projectileSpawner, Player player) {
        telegraphTimer = Math.max(0f, telegraphTimer - delta);
        visualStateTime += delta;
        actionImpulseTimer = Math.max(0f, actionImpulseTimer - delta);
        hitReactionTimer = Math.max(0f, hitReactionTimer - delta);
        specialHitReactionTimer = Math.max(0f, specialHitReactionTimer - delta);

        if (phase == Phase.ONE && reachedPhaseTwoHealth()) {
            phase = Phase.TWO;
            setState(new PhaseTwoTransitionState());
        } else if (phase == Phase.TWO && reachedFinalRageHealth()) {
            phase = Phase.FINAL_RAGE;
            setState(new FinalRageState());
        }

        currentState.update(this, delta, projectileSpawner, player);
    }

    public boolean takeDamage(int amount, boolean specialHit) {
        if (isDefeated() || currentState.isInvulnerable()) {
            return false;
        }

        health = MathUtils.clamp(health - amount, 0, Constants.BOSS_MAX_HEALTH);
        hitReactionTimer = HIT_REACTION_DURATION;
        specialHitReactionTimer = specialHit ? SPECIAL_HIT_REACTION_DURATION : 0f;
        if (health == 0) {
            soundEvents.clear();
            setState(new DefeatedState());
        } else if (specialHit) {
            emitSound(BossSoundEvent.STAGGER);
        }
        return true;
    }

    void emitSound(BossSoundEvent soundEvent) {
        if (soundEvent != null && !isDefeated()) {
            soundEvents.offer(soundEvent);
            if (soundEvent.triggersActionImpulse()) {
                actionImpulseTimer = ACTION_IMPULSE_DURATION;
            }
        }
    }

    public BossSoundEvent pollSoundEvent() {
        return soundEvents.poll();
    }

    public void showTelegraph(Color color, float duration) {
        telegraphColor.set(color);
        telegraphDuration = Math.max(0.01f, duration);
        telegraphTimer = telegraphDuration;
    }

    BossState createNextAttackState() {
        if (queuedFollowUpState != null) {
            BossState followUpState = queuedFollowUpState;
            queuedFollowUpState = null;
            return followUpState;
        }

        int attackCount = isPhaseTwo() ? 5 : 3;
        int nextAttackIndex;

        if (isPhaseTwo() && phaseTwoAttackCount % 5 == 4 && lastAttackIndex != 4) {
            nextAttackIndex = 4;
        } else if (isPhaseTwo() && phaseTwoAttackCount % 4 == 3 && lastAttackIndex != 3) {
            nextAttackIndex = 3;
        } else {
            do {
                nextAttackIndex = MathUtils.random(attackCount - 1);
            } while (nextAttackIndex == lastAttackIndex);
        }

        lastAttackIndex = nextAttackIndex;
        if (isPhaseTwo()) {
            phaseTwoAttackCount++;
        }

        return switch (nextAttackIndex) {
            case 0 -> new VineStrikeState();
            case 1 -> new MagicVolleyState();
            case 2 -> new PollenRainState();
            case 3 -> new SporeCorridorState();
            case 4 -> new VineBarrageState();
            default -> throw new IllegalStateException("Índice de ataque inválido: " + nextAttackIndex);
        };
    }

    void finishCurrentAttack() {
        float recoveryDuration;
        if (isFinalRage()) {
            recoveryDuration = FINAL_RAGE_RECOVERY_DURATION;
        } else if (isPhaseTwo()) {
            recoveryDuration = PHASE_TWO_RECOVERY_DURATION;
        } else {
            recoveryDuration = PHASE_ONE_RECOVERY_DURATION;
        }
        setState(new IdleState(recoveryDuration));
    }

    void finishCurrentAttack(BossState followUpState) {
        queuedFollowUpState = followUpState;
        setState(new IdleState(CHAIN_RECOVERY_DURATION));
    }

    void setState(BossState nextState) {
        currentState = nextState;
        visualStateTime = 0f;
        actionImpulseTimer = 0f;
        currentState.enter(this);
    }

    public boolean isPhaseTwo() {
        return phase != Phase.ONE && !isDefeated();
    }

    public boolean isFinalRage() {
        return phase == Phase.FINAL_RAGE && !isDefeated();
    }

    public boolean isDefeated() {
        return health <= 0;
    }

    private boolean reachedPhaseTwoHealth() {
        return health <= Constants.BOSS_MAX_HEALTH * 0.5f && !isDefeated();
    }

    private boolean reachedFinalRageHealth() {
        return health <= Constants.BOSS_MAX_HEALTH * FINAL_RAGE_HEALTH_RATIO && !isDefeated();
    }

    public float getCenterX() {
        return Constants.BOSS_START_X + Constants.BOSS_WIDTH * 0.5f;
    }

    public float getCenterY() {
        return Constants.BOSS_START_Y + Constants.BOSS_HEIGHT * 0.5f;
    }

    public Hitbox getHitbox() {
        return hitbox;
    }

    public BossVisualState getVisualState() {
        return currentState.getVisualState();
    }

    public boolean isTelegraphing() {
        return telegraphTimer > 0f;
    }

    public float getTelegraphAlpha() {
        if (telegraphTimer <= 0f) {
            return 0f;
        }
        return MathUtils.clamp(telegraphTimer / telegraphDuration, 0f, 1f);
    }

    public Color getTelegraphColor() {
        return telegraphColor;
    }

    public float getVisualStateTime() {
        return visualStateTime;
    }

    public float getActionImpulse() {
        return MathUtils.clamp(actionImpulseTimer / ACTION_IMPULSE_DURATION, 0f, 1f);
    }

    public float getHitReaction() {
        return MathUtils.clamp(hitReactionTimer / HIT_REACTION_DURATION, 0f, 1f);
    }

    public float getSpecialHitReaction() {
        return MathUtils.clamp(specialHitReactionTimer / SPECIAL_HIT_REACTION_DURATION, 0f, 1f);
    }
}
