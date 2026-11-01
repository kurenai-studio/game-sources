package com.micro1.shadowclash;

import java.util.Random;

/**
 * The CPU brain. Each frame it fills the controlled fighter's {@link Intent} from the game state:
 * distance to the player, its own remaining health, and the current threat. It approaches when far,
 * mixes light/heavy attacks in range, blocks by attack height, jumps incoming projectiles, back-dashes
 * to make space, and (once below 75 health) mixes in special moves. Deterministic given a seed so the
 * behaviour is unit-testable.
 */
public final class AIController {

    private enum Plan { APPROACH, ATTACK, BLOCK, BACKDASH, CROUCH, JUMP, WAIT }

    private final Random rng;
    private Plan plan = Plan.APPROACH;
    private float planTimer = 0f;
    private float attackCooldown = 0f;
    private boolean plannedCrouchBlock;

    public AIController(long seed) {
        this.rng = new Random(seed);
    }

    public void reset() {
        plan = Plan.APPROACH;
        planTimer = 0f;
        attackCooldown = 0f;
        plannedCrouchBlock = false;
    }

    public void decide(float dt, ClashWorld w, Fighter self, Fighter opp) {
        self.intent.clear();
        planTimer -= dt;
        if (attackCooldown > 0f) attackCooldown -= dt;

        float dist = opp.x - self.x;
        float adist = Math.abs(dist);
        int dir = dist >= 0 ? 1 : -1;
        boolean busy = self.state.isAttack() || self.state.isHitReaction()
            || self.state == FighterState.BACKDASH || !self.onGround;

        // --- reactive overrides (every frame) ---
        // jump an incoming projectile
        Projectile inc = w.incomingProjectile(self);
        if (inc != null && !busy && Math.abs(inc.x - self.x) < 260f) {
            self.intent.jumpPressed = true;
            return;
        }
        // React to both the attack windup already on screen and a newly pressed attack. The
        // latter is copied onto the opponent before this method runs, so the CPU does not spend
        // a frame starting a random plan while the player begins a strike.
        Move threat = opp.state.isAttack() ? opp.curMove : opp.intent.attack;
        if (!busy && threat != null && adist < 170f) {
            if (threat.height == Move.Height.UNBLOCKABLE) {
                self.intent.backDashPressed = true;
            } else if (threat.height == Move.Height.LOW) {
                self.intent.crouchBlock = true;
            } else {
                self.intent.standBlock = true;
            }
            return;
        }

        // --- pick a plan on a timer ---
        if (planTimer <= 0f) {
            planTimer = 0.25f + rng.nextFloat() * 0.35f;
            float roll = rng.nextFloat();
            if (adist > 360f) {
                plan = roll < 0.9f ? Plan.APPROACH : Plan.JUMP;                  // mostly close in
            } else if (adist > 165f) {
                plan = roll < 0.46f ? Plan.APPROACH
                    : (roll < 0.68f ? Plan.ATTACK
                    : (roll < 0.80f ? Plan.BACKDASH
                    : (roll < 0.90f ? Plan.CROUCH : Plan.JUMP)));
            } else { // close
                if (self.health < 22 && roll < 0.30f) plan = Plan.BACKDASH;      // retreat when low
                else if (roll < 0.52f) plan = Plan.ATTACK;
                else if (roll < 0.68f) {
                    plan = Plan.BLOCK;
                    plannedCrouchBlock = rng.nextBoolean();
                }
                else if (roll < 0.80f) plan = Plan.BACKDASH;
                else if (roll < 0.90f) plan = Plan.CROUCH;                       // duck / bait
                else plan = Plan.JUMP;
            }
        }

        // --- execute the plan ---
        switch (plan) {
            case APPROACH:
                self.intent.moveDir = dir;
                self.intent.run = adist > 300f;
                break;
            case ATTACK:
                float attackRange = self.specialsUnlocked ? 360f : 150f;
                if (!busy && attackCooldown <= 0f && adist < attackRange) {
                    self.intent.attack = chooseAttack(self, adist);
                    attackCooldown = 0.35f + rng.nextFloat() * 0.4f;
                    plan = Plan.WAIT; planTimer = 0.3f;
                } else if (adist >= 150f) {
                    self.intent.moveDir = dir; // close the gap first
                }
                break;
            case BLOCK:
                if (plannedCrouchBlock) self.intent.crouchBlock = true;
                else self.intent.standBlock = true;
                break;
            case CROUCH:
                self.intent.crouch = true;   // held for the plan window -> the CPU visibly ducks
                break;
            case JUMP:
                if (!busy) { self.intent.jumpPressed = true; plan = Plan.WAIT; planTimer = 0.5f; }
                break;
            case BACKDASH:
                if (!busy) { self.intent.backDashPressed = true; plan = Plan.WAIT; planTimer = 0.35f; }
                break;
            case WAIT:
            default:
                break;
        }
    }

    /** Mix light and heavy attacks; use specials (when unlocked) at the right range. */
    private Move chooseAttack(Fighter self, float adist) {
        if (self.specialsUnlocked && adist > 150f) return Move.SHADOWBLAST;
        if (self.specialsUnlocked && rng.nextFloat() < 0.4f) {
            if (adist > 130f) return Move.SHADOWBLAST;
            return rng.nextBoolean() ? Move.DARKCHARGE : Move.SPINSLASH;
        }
        float r = rng.nextFloat();
        if (r < 0.5f) { // light
            return r < 0.2f ? Move.JAB : (r < 0.35f ? Move.CROUCHJAB : Move.STANDKICK);
        }
        // heavy
        return r < 0.7f ? Move.STRONGPUNCH : (r < 0.85f ? Move.SWEEP : Move.UPPERCUT);
    }
}
