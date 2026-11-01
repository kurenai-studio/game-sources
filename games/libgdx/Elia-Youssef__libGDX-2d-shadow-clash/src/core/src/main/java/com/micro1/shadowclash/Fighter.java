package com.micro1.shadowclash;

import com.badlogic.gdx.math.Rectangle;

/**
 * One combatant: an animation-driven state machine plus simple side-view physics. Pure logic
 * (libGDX math only, no GL / no Gdx.* statics) so it runs headlessly under JUnit.
 *
 * Collision volumes (rubric): a BODY box (movement, separation, stage bounds), a HURT box (the
 * vulnerable area, shorter when crouching), and an ATTACK hitbox that exists only during a move's
 * active frames. The fighter always faces its opponent while grounded and actionable.
 */
public final class Fighter {

    public final boolean isPlayer;
    public final String name;
    public final Intent intent = new Intent();

    public float x, y;          // feet position (y == GROUND when standing)
    public float vx, vy;        // external horizontal velocity (knockback/dash/push) + vertical
    public int facing = 1;      // +1 faces right, -1 faces left (toward the opponent)
    public boolean onGround = true;
    public int health = K.MAX_HP;

    public FighterState state = FighterState.IDLE;
    public float stateTime = 0f;
    public FighterState previousState = FighterState.IDLE;
    public float previousStateTime = 0f;
    public float transitionTime = MOVEMENT_BLEND_TIME;
    public boolean specialsUnlocked = false;

    public static final float MOVEMENT_BLEND_TIME = 0.09f;

    public Move curMove;        // the attack in progress, or null
    private boolean hasHit;     // this attack already connected (one hit per activation)
    private boolean spawnedProjectile;
    private float reactionDur;  // how long the current hit reaction lasts
    private float blockLock;    // brief input lock after absorbing a blocked hit

    public Fighter(boolean isPlayer, String name) {
        this.isPlayer = isPlayer;
        this.name = name;
    }

    public void reset(float startX, int startFacing) {
        x = startX; y = K.GROUND; vx = 0; vy = 0; facing = startFacing;
        onGround = true; health = K.MAX_HP;
        state = FighterState.IDLE; stateTime = 0f;
        previousState = FighterState.IDLE; previousStateTime = 0f;
        transitionTime = MOVEMENT_BLEND_TIME;
        specialsUnlocked = false;
        curMove = null; hasHit = false; spawnedProjectile = false;
        reactionDur = 0f; blockLock = 0f;
        intent.clear();
    }

    // ------------------------------------------------------------------ update

    public void update(float dt, ClashWorld w) {
        stateTime += dt;
        transitionTime += dt;
        if (blockLock > 0f) blockLock -= dt;
        specialsUnlocked = health < K.UNLOCK_HP;
        Fighter opp = w.opponentOf(this);

        // Track the opponent during jumps, attacks and reactions too. Jump-overs stay readable
        // because both sprites flip as soon as the fighters exchange sides.
        if (state != FighterState.VICTORY && state != FighterState.DEFEAT) faceToward(opp);

        if (state.isAttack()) {
            updateAttack(dt, w);
        } else if (state == FighterState.BACKDASH) {
            if (stateTime >= K.BACKDASH_TIME) setState(FighterState.IDLE);
        } else if (state.isHitReaction()) {
            updateReaction();
        } else if (state == FighterState.VICTORY || state == FighterState.DEFEAT) {
            // settled: hold the pose, no input, no physics
            return;
        } else {
            updateFree(dt, w, opp);
        }
        applyPhysics(dt);
        clampArena();
    }

    private void updateFree(float dt, ClashWorld w, Fighter opp) {
        if (!onGround) {                       // airborne after a jump: limited air drift only
            setState(FighterState.JUMP);
            x += intent.moveDir * K.WALK * 0.5f * dt;
            return;
        }
        // grounded and actionable: priority order attack > block > dash > jump > crouch > move
        if (blockLock <= 0f && intent.attack != null) {
            Move m = intent.attack;
            if (!m.isSpecial() || specialsUnlocked) { startMove(m, w); return; }
            // special not yet unlocked (health >= 75): the input does nothing
        }
        if (intent.standBlock) { setState(FighterState.BLOCK_STAND); return; }
        if (intent.crouchBlock) { setState(FighterState.BLOCK_CROUCH); return; }
        if (blockLock > 0f) { setState(FighterState.IDLE); return; }
        if (intent.backDashPressed) { startBackdash(); return; }
        if (intent.jumpPressed) { vy = K.JUMP_V; onGround = false; setState(FighterState.JUMP); return; }
        if (intent.crouch) { setState(FighterState.CROUCH); return; }
        if (intent.moveDir != 0) {
            float sp = intent.run ? K.RUN : K.WALK;
            x += intent.moveDir * sp * dt;
            setState(intent.run ? FighterState.RUN : FighterState.WALK);
            return;
        }
        setState(FighterState.IDLE);
    }

    private void updateAttack(float dt, ClashWorld w) {
        Move m = curMove;
        float t = stateTime;
        boolean activeWindow = t >= m.startup && t < m.startup + m.active;
        if (m.forwardSpeed > 0f && activeWindow) {
            x += facing * m.forwardSpeed * dt;
        }
        if (m.projectile && !spawnedProjectile && t >= m.startup) {
            spawnedProjectile = true;
            w.spawnProjectile(this);
        }
        if (t >= m.total()) {
            curMove = null;
            setState(FighterState.IDLE);
        }
    }

    private void updateReaction() {
        if (state == FighterState.LAUNCH) {
            if (onGround && stateTime > 0.25f) setState(FighterState.IDLE);
        } else if (stateTime >= reactionDur) {
            setState(FighterState.IDLE);
        }
    }

    // ------------------------------------------------------------------ physics

    private void applyPhysics(float dt) {
        if (!onGround || vy != 0f) {
            y += vy * dt;
            vy += K.GRAVITY * dt;
            if (y <= K.GROUND) {
                y = K.GROUND; vy = 0f;
                if (!onGround) { onGround = true; onLand(); }
            } else {
                onGround = false;
            }
        }
        if (vx != 0f) {
            x += vx * dt;
            vx *= (1f - Math.min(1f, dt * 6f));
            if (Math.abs(vx) < 4f) vx = 0f;
        }
    }

    private void onLand() {
        if (state == FighterState.JUMP) setState(FighterState.IDLE);
    }

    private void clampArena() {
        if (x < K.ARENA_LEFT) x = K.ARENA_LEFT;
        if (x > K.ARENA_RIGHT) x = K.ARENA_RIGHT;
    }

    // ------------------------------------------------------------------ actions

    private void startMove(Move m, ClashWorld w) {
        curMove = m; hasHit = false; spawnedProjectile = false; vx = 0f;
        setState(m.state);
        if (m.isSpecial()) w.triggerSpecialSlowMo();
    }

    private void startBackdash() {
        setState(FighterState.BACKDASH);
        vx = -facing * K.BACKDASH_SPEED;   // dash away from the opponent
    }

    private void faceToward(Fighter opp) {
        facing = (opp.x >= x) ? 1 : -1;
    }

    private void setState(FighterState s) {
        if (state != s) {
            previousState = state;
            previousStateTime = stateTime;
            transitionTime = 0f;
            state = s;
            stateTime = 0f;
        }
    }

    // ------------------------------------------------------------------ hit application (called by world)

    /** Apply an unblocked hit: damage, reaction, knockback. */
    public void takeHit(Move m, Fighter attacker) {
        health -= m.damage;
        if (health < 0) health = 0;
        specialsUnlocked = health < K.UNLOCK_HP;
        curMove = null; spawnedProjectile = false;
        int away = (x >= attacker.x) ? 1 : -1;   // push direction, away from attacker
        facing = -away;                          // turn to face the attacker
        switch (m.reaction) {
            case LIGHT:
                setState(FighterState.HIT_LIGHT); reactionDur = 0.28f; vx = away * 130f; break;
            case HEAVY:
                setState(FighterState.HIT_HEAVY); reactionDur = 0.44f; vx = away * m.knockback; break;
            case KNOCKDOWN:
                setState(FighterState.KNOCKDOWN); reactionDur = 0.95f; vx = away * m.knockback; break;
            case LAUNCH:
                setState(FighterState.LAUNCH); reactionDur = 0.60f;
                vx = away * 90f; vy = K.LAUNCH_V; onGround = false; break;
        }
    }

    /** Register a successful block: no damage, keep the block pose, brief input lock. */
    public void takeBlock(Move m) {
        blockLock = 0.16f;
        // remain in whatever block stance we were in; render shows the block spark
    }

    /** Force the defeated pose (lying on the ground) for the finish / defeat state. */
    public void setDefeated() {
        state = FighterState.DEFEAT; stateTime = 0f;
        curMove = null; vx = 0f; vy = 0f; onGround = true; y = K.GROUND;
    }

    /** Force the victory pose for the winner. */
    public void setVictory() {
        state = FighterState.VICTORY; stateTime = 0f;
        curMove = null; vx = 0f; vy = 0f; onGround = true; y = K.GROUND;
    }

    // ------------------------------------------------------------------ volumes

    public boolean crouchingPose() {
        return state == FighterState.CROUCH || state == FighterState.BLOCK_CROUCH
            || state == FighterState.CROUCHJAB || state == FighterState.SWEEP;
    }

    public Rectangle bodyBox(Rectangle r) {
        return r.set(x - K.BODY_W / 2f, y, K.BODY_W, K.BODY_H);
    }

    public Rectangle hurtBox(Rectangle r) {
        float h = crouchingPose() ? K.CROUCH_H : K.BODY_H;
        return r.set(x - K.BODY_W / 2f, y, K.BODY_W, h);
    }

    public boolean hasActiveHitbox() {
        return state.isAttack() && curMove != null && !curMove.projectile && !hasHit
            && stateTime >= curMove.startup && stateTime < curMove.startup + curMove.active;
    }

    public Rectangle hitBox(Rectangle r) {
        float inner = x + facing * (K.BODY_W * 0.35f);
        float outer = x + facing * curMove.reach;
        float left = Math.min(inner, outer);
        float w = Math.abs(outer - inner);
        return r.set(left, y + curMove.hitLo, w, curMove.hitHi - curMove.hitLo);
    }

    public void markHit() { hasHit = true; }

    public boolean isBlocking() { return state == FighterState.BLOCK_STAND || state == FighterState.BLOCK_CROUCH; }

    public boolean isAlive() { return health > 0; }

    /** Alpha of the new pose during a short movement-to-movement cross-fade. */
    public float movementBlend() {
        if (!previousState.isMovement() || !state.isMovement() || previousState == state) return 1f;
        return Math.min(1f, transitionTime / MOVEMENT_BLEND_TIME);
    }
}
