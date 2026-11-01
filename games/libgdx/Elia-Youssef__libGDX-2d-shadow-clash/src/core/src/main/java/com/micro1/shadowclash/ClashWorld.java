package com.micro1.shadowclash;

import com.badlogic.gdx.math.Rectangle;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * The whole fight simulation, GL-free and headlessly testable. Owns the two fighters, the
 * projectiles and visual effects, the match-state machine (Ready -> Fight -> Combat ->
 * Slow-Motion(KO) -> Victory/Defeat), the slow-motion timescale, and all combat resolution
 * (multi-volume hit detection, damage 1/3/5, block rules, hit reactions, knockback, KO + restart).
 *
 * The render/input layer feeds it the player's {@link Intent} each frame and reads state back;
 * it never reaches into rendering.
 */
public final class ClashWorld {

    private static final float PLAYER_START_X = 330f;
    private static final float CPU_START_X = 770f;

    public final Fighter player = new Fighter(true, "PLAYER");
    public final Fighter cpu = new Fighter(false, "CPU");
    private final AIController ai;

    public final List<Projectile> projectiles = new ArrayList<Projectile>();
    public final List<Effect> effects = new ArrayList<Effect>();

    public MatchState phase = MatchState.READY;
    private float readyTimer, fightTimer, koTimer, slowMoTimer;
    private float timeScale = 1f;

    /** When false the CPU intent is left untouched (test hook to drive a passive or scripted CPU). */
    public boolean aiEnabled = true;

    private final Rectangle rA = new Rectangle(), rB = new Rectangle();

    public ClashWorld(long seed) {
        ai = new AIController(seed);
        reset();
    }

    public ClashWorld() { this(20260714L); }

    /** Full reset to the Ready state (rubric restart: health, positions, states, projectiles,
     *  inputs, and time scale all cleared). */
    public void reset() {
        player.reset(PLAYER_START_X, +1);   // player left, facing right
        cpu.reset(CPU_START_X, -1);         // cpu right, facing left
        projectiles.clear();
        effects.clear();
        ai.reset();
        phase = MatchState.READY;
        readyTimer = K.READY_TIME;
        fightTimer = K.FIGHT_TIME;
        koTimer = 0f;
        slowMoTimer = 0f;
        timeScale = 1f;
        aiEnabled = true;
    }

    // ------------------------------------------------------------------ main loop

    /** Advance the match by one frame. realDt is the wall-clock delta; the simulation runs at
     *  realDt * timeScale so slow motion affects movement and animation together. */
    public void update(float realDt, Intent playerInput) {
        if (Float.isNaN(realDt) || realDt <= 0f) return;

        // Keep collision steps small without throwing wall-clock time away. This preserves the
        // three-second countdown and movement speed at low frame rates while preventing tunnelling.
        float remaining = realDt;
        boolean includePressedActions = true;
        while (remaining > 0.000001f) {
            float step = Math.min(remaining, 1f / 60f);
            updateStep(step, playerInput, includePressedActions);
            includePressedActions = false;
            remaining -= step;
        }
    }

    private void updateStep(float realDt, Intent playerInput, boolean includePressedActions) {
        stepTimeScale(realDt);

        switch (phase) {
            case READY: {
                player.intent.clear();
                cpu.intent.clear();
                player.update(realDt, this);   // locked idle: cleared intent = no movement/attacks
                cpu.update(realDt, this);
                readyTimer -= realDt;
                if (readyTimer <= 0.0001f) { phase = MatchState.FIGHT; fightTimer = K.FIGHT_TIME; }
                break;
            }
            case FIGHT:
            case COMBAT: {
                float dt = realDt * timeScale;
                copyInput(playerInput, player.intent, includePressedActions);
                if (aiEnabled) ai.decide(dt, this, cpu, player);
                player.update(dt, this);
                cpu.update(dt, this);
                updateProjectiles(dt);
                resolveCombat();
                separate();
                updateEffects(dt);
                if (slowMoTimer > 0f) slowMoTimer -= realDt;
                if (phase == MatchState.FIGHT) {
                    fightTimer -= realDt;
                    if (fightTimer <= 0.0001f) phase = MatchState.COMBAT;
                }
                break;
            }
            case SLOWMO_KO: {
                float dt = realDt * timeScale;   // timeScale held at SLOW during the finish
                player.intent.clear();
                cpu.intent.clear();
                player.update(dt, this);
                cpu.update(dt, this);
                updateProjectiles(dt);
                updateEffects(dt);
                koTimer -= realDt;
                if (koTimer <= 0f) settleOutcome();
                break;
            }
            case VICTORY:
            case DEFEAT: {
                player.intent.clear();
                cpu.intent.clear();
                player.update(realDt, this);     // winner's victory animation plays at full speed
                cpu.update(realDt, this);
                updateEffects(realDt);
                break;
            }
        }
    }

    private void stepTimeScale(float realDt) {
        boolean slow = phase == MatchState.SLOWMO_KO || slowMoTimer > 0f || specialMoveInProgress();
        float target = slow ? K.SLOW_SCALE : 1f;
        timeScale += (target - timeScale) * Math.min(1f, realDt * 10f);
        if (Math.abs(timeScale - target) < 0.01f) timeScale = target;
    }

    private void copyInput(Intent src, Intent dst, boolean includePressedActions) {
        dst.clear();
        if (src == null) return;
        dst.moveDir = src.moveDir;
        dst.run = src.run;
        dst.crouch = src.crouch;
        dst.jumpPressed = includePressedActions && src.jumpPressed;
        dst.backDashPressed = includePressedActions && src.backDashPressed;
        dst.standBlock = src.standBlock;
        dst.crouchBlock = src.crouchBlock;
        dst.attack = includePressedActions ? src.attack : null;
    }

    // ------------------------------------------------------------------ combat

    private void resolveCombat() {
        tryMelee(player, cpu);
        tryMelee(cpu, player);
    }

    private void tryMelee(Fighter attacker, Fighter defender) {
        if (!attacker.hasActiveHitbox() || !matchLive()) return;
        attacker.hitBox(rA);
        defender.hurtBox(rB);
        if (!rA.overlaps(rB)) return;
        Move m = attacker.curMove;
        attacker.markHit();
        landHit(attacker, defender, m, (rA.x + rA.width / 2f + rB.x + rB.width / 2f) / 2f,
            defender.y + (m.hitLo + m.hitHi) / 2f);
    }

    /** Resolve one connecting attack (melee or projectile) against a defender. */
    private void landHit(Fighter attacker, Fighter defender, Move m, float cx, float cy) {
        boolean blocked = defender.isBlocking()
            && m.blockedBy(defender.state == FighterState.BLOCK_STAND,
                           defender.state == FighterState.BLOCK_CROUCH);
        if (blocked) {
            defender.takeBlock(m);
            addEffect(Effect.Kind.BLOCK, cx, cy, defender.facing, 0.28f, defender.isPlayer);
            int away = attacker.x >= defender.x ? 1 : -1;   // push the attacker back
            attacker.vx = away * 190f;
        } else {
            defender.takeHit(m, attacker);
            addEffect(Effect.Kind.HIT, cx, cy, attacker.facing, 0.30f, attacker.isPlayer);
            if (m.isSpecial()) triggerSpecialSlowMo();
            if (!defender.isAlive()) startKO(attacker, defender);
        }
    }

    private void updateProjectiles(float dt) {
        Iterator<Projectile> it = projectiles.iterator();
        while (it.hasNext()) {
            Projectile p = it.next();
            p.update(dt);
            if (p.alive && matchLive()) {
                Fighter target = opponentOf(p.owner);
                p.box(rA);
                target.hurtBox(rB);
                if (rA.overlaps(rB)) {
                    p.alive = false;
                    if (isBlockedProjectile(target)) {
                        target.takeBlock(Move.SHADOWBLAST);
                        addEffect(Effect.Kind.BLOCK, p.x, p.y, target.facing, 0.28f, target.isPlayer);
                    } else {
                        target.takeHit(Move.SHADOWBLAST, p.owner);
                        addEffect(Effect.Kind.EXPLOSION, p.x, p.y, p.facing, 0.30f, p.owner.isPlayer);
                        triggerSpecialSlowMo();
                        if (!target.isAlive()) startKO(p.owner, target);
                    }
                }
            }
            if (!p.alive) it.remove();
        }
    }

    private boolean isBlockedProjectile(Fighter target) {
        // Shadow Blast is a MID attack: a standing block stops it.
        return target.isBlocking()
            && Move.SHADOWBLAST.blockedBy(target.state == FighterState.BLOCK_STAND,
                                          target.state == FighterState.BLOCK_CROUCH);
    }

    public void spawnProjectile(Fighter owner) {
        float sx = owner.x + owner.facing * (K.BODY_W * 0.5f);
        projectiles.add(new Projectile(owner, sx, owner.y + K.TORSO, owner.facing));
    }

    public void triggerSpecialSlowMo() {
        if (slowMoTimer < K.SPECIAL_SLOWMO) slowMoTimer = K.SPECIAL_SLOWMO;
    }

    private void startKO(Fighter winner, Fighter loser) {
        if (phase == MatchState.SLOWMO_KO || phase == MatchState.VICTORY || phase == MatchState.DEFEAT) return;
        loser.setDefeated();
        phase = MatchState.SLOWMO_KO;
        koTimer = K.KO_SLOWMO;
        slowMoTimer = K.KO_SLOWMO;
        addEffect(Effect.Kind.EXPLOSION, loser.x, loser.y + K.TORSO, -loser.facing, 0.4f, winner.isPlayer);
    }

    private void addEffect(Effect.Kind kind, float x, float y, int facing, float life, boolean fromPlayer) {
        Effect e = new Effect(kind, x, y, facing, life);
        e.fromPlayer = fromPlayer;
        effects.add(e);
    }

    private void settleOutcome() {
        if (player.isAlive()) {
            phase = MatchState.VICTORY;
            player.x = PLAYER_START_X; cpu.x = CPU_START_X;
            player.facing = 1; cpu.facing = -1;
            player.setVictory(); cpu.setDefeated();
        } else {
            phase = MatchState.DEFEAT;
            player.x = PLAYER_START_X; cpu.x = CPU_START_X;
            player.facing = 1; cpu.facing = -1;
            cpu.setVictory(); player.setDefeated();
        }
        slowMoTimer = 0f;
    }

    // ------------------------------------------------------------------ positioning

    private void separate() {
        // Resolve the actual body volumes, including airborne overlap. A fighter can jump fully
        // over the other, but their bodies never occupy the same space or pass through a boundary.
        player.bodyBox(rA);
        cpu.bodyBox(rB);
        if (!rA.overlaps(rB)) return;

        float overlap = Math.min(rA.x + rA.width, rB.x + rB.width)
            - Math.max(rA.x, rB.x) + 0.01f;
        int order = cpu.x > player.x ? 1 : (cpu.x < player.x ? -1 : (player.facing >= 0 ? 1 : -1));

        float playerRoom = order > 0 ? player.x - K.ARENA_LEFT : K.ARENA_RIGHT - player.x;
        float cpuRoom = order > 0 ? K.ARENA_RIGHT - cpu.x : cpu.x - K.ARENA_LEFT;
        float playerPush = Math.min(overlap * 0.5f, playerRoom);
        float cpuPush = Math.min(overlap - playerPush, cpuRoom);

        float left = overlap - playerPush - cpuPush;
        if (left > 0f) {
            float extraPlayer = Math.min(left, playerRoom - playerPush);
            playerPush += extraPlayer;
            left -= extraPlayer;
        }
        if (left > 0f) cpuPush += Math.min(left, cpuRoom - cpuPush);

        player.x -= order * playerPush;
        cpu.x += order * cpuPush;
        clampX(player);
        clampX(cpu);
    }

    private void clampX(Fighter f) {
        if (f.x < K.ARENA_LEFT) f.x = K.ARENA_LEFT;
        if (f.x > K.ARENA_RIGHT) f.x = K.ARENA_RIGHT;
    }

    private void updateEffects(float dt) {
        Iterator<Effect> it = effects.iterator();
        while (it.hasNext()) {
            if (!it.next().update(dt)) it.remove();
        }
    }

    // ------------------------------------------------------------------ queries

    /** Test hook: jump straight to the live COMBAT phase (skips the Ready + Fight banners). */
    public void testEnterCombat() {
        phase = MatchState.COMBAT;
        readyTimer = 0f;
        fightTimer = 0f;
    }

    public Fighter opponentOf(Fighter f) { return f == player ? cpu : player; }

    public boolean matchLive() { return phase == MatchState.FIGHT || phase == MatchState.COMBAT; }

    public boolean isSlowMotion() {
        return phase == MatchState.SLOWMO_KO || slowMoTimer > 0f || specialMoveInProgress();
    }

    private boolean specialMoveInProgress() {
        return isUsingSpecial(player) || isUsingSpecial(cpu);
    }

    private boolean isUsingSpecial(Fighter fighter) {
        return fighter.state.isAttack() && fighter.curMove != null && fighter.curMove.isSpecial();
    }

    public float getTimeScale() { return timeScale; }

    public float readyCountdown() { return Math.max(0f, readyTimer); }

    /** A projectile heading toward the given fighter (used by the AI to decide to jump). */
    public Projectile incomingProjectile(Fighter self) {
        for (int i = 0; i < projectiles.size(); i++) {
            Projectile p = projectiles.get(i);
            if (p.owner != self && p.alive) {
                int toward = (self.x - p.x) >= 0 ? 1 : -1;
                if (p.facing == toward) return p;
            }
        }
        return null;
    }

    public String centerMessage() {
        switch (phase) {
            case READY:   return "GET READY";
            case FIGHT:   return "FIGHT";
            case VICTORY: return "YOU WIN";
            case DEFEAT:  return "YOU LOSE";
            default:      return "";
        }
    }
}
