package com.micro1.pong;

import java.util.Random;

/**
 * All Primitive Pong gameplay state and rules, with no libGDX / GL dependency so every rule is
 * unit-testable headlessly. Coordinate space is the 800x600 field with a bottom-left origin.
 *
 * <p>The render/input layer ({@link PongGame}) reads keys and calls {@link #update} once per frame;
 * it never reaches into the rules here beyond reading public state to draw it.
 */
public class PongWorld {
    public enum State { PLAYING, GAME_OVER }

    // Field + entity dimensions (px) and motion constants (px/s).
    public static final float FIELD_W = 800f;
    public static final float FIELD_H = 600f;
    public static final float PADDLE_W = 12f;
    public static final float PADDLE_H = 80f;
    public static final float BALL = 12f;
    public static final float PADDLE_SPEED = 400f;
    public static final float PADDLE_Y_MIN = 0f;
    public static final float PADDLE_Y_MAX = FIELD_H - PADDLE_H; // 520
    public static final float BALL_START_SPEED = 300f;
    public static final float BALL_MAX_SPEED = 600f;
    public static final float SPEED_GAIN = 1.05f;
    public static final float SERVE_VY_MIN = 20f;
    public static final float SERVE_VY_MAX = 100f;
    public static final float REFLECT_RANGE = 40f;   // half paddle height
    public static final float REFLECT_MAX_VY = 300f;
    public static final int WIN_SCORE = 7;

    // Canonical start positions (bottom-left).
    public static final float P1_START_X = 20f;
    public static final float P2_START_X = 768f;
    public static final float PADDLE_START_Y = 260f;
    public static final float BALL_START_X = 394f;
    public static final float BALL_START_Y = 294f;

    public final Paddle p1 = new Paddle(P1_START_X, PADDLE_START_Y);
    public final Paddle p2 = new Paddle(P2_START_X, PADDLE_START_Y);
    public final Ball ball = new Ball();
    public int score1;
    public int score2;
    public State state = State.PLAYING;
    public int winner; // 1 or 2 once GAME_OVER, else 0

    private final Random rng;

    public PongWorld() {
        this(new Random());
    }

    public PongWorld(Random rng) {
        this.rng = rng;
    }

    /** Full match reset (game start and R restart): scores 0, paddles home, ball served toward P2. */
    public void newMatch() {
        score1 = 0;
        score2 = 0;
        p1.x = P1_START_X;
        p1.y = PADDLE_START_Y;
        p2.x = P2_START_X;
        p2.y = PADDLE_START_Y;
        winner = 0;
        state = State.PLAYING;
        serve(+1); // first serve toward Player 2 (positive horizontal velocity)
    }

    /**
     * Reset the ball to center and serve it at the base speed. {@code dir} is +1 to serve toward P2
     * (right) or -1 toward P1 (left). |vy| is random in [20,100]; vx keeps total speed at exactly 300.
     */
    public void serve(int dir) {
        ball.x = BALL_START_X;
        ball.y = BALL_START_Y;
        ball.speed = BALL_START_SPEED;
        float mag = SERVE_VY_MIN + rng.nextFloat() * (SERVE_VY_MAX - SERVE_VY_MIN);
        float vy = rng.nextBoolean() ? mag : -mag;
        ball.vy = vy;
        ball.vx = (float) Math.sqrt(BALL_START_SPEED * BALL_START_SPEED - vy * vy) * dir;
    }

    /**
     * Advance one frame. Inputs are the held state of each control plus a just-pressed restart (R).
     * During GAME_OVER all motion and scoring freeze and only R is honored.
     */
    public void update(float dt, boolean up1, boolean down1, boolean up2, boolean down2, boolean restart) {
        if (state == State.GAME_OVER) {
            if (restart) {
                newMatch();
            }
            return; // freeze: paddles, ball, and score do not change
        }

        movePaddle(p1, up1, down1, dt);
        movePaddle(p2, up2, down2, dt);

        ball.x += ball.vx * dt;
        ball.y += ball.vy * dt;

        // Top / bottom walls: clamp inside the field, then reverse vertical velocity.
        if (ball.y + BALL > FIELD_H) {
            ball.y = FIELD_H - BALL;
            ball.vy = -ball.vy;
        }
        if (ball.y < 0f) {
            ball.y = 0f;
            ball.vy = -ball.vy;
        }

        // Paddle collisions: AABB overlap, only while the ball moves toward that paddle.
        if (ball.vx < 0f && overlaps(p1)) {
            bounce(p1, +1);
        } else if (ball.vx > 0f && overlaps(p2)) {
            bounce(p2, -1);
        }

        // Scoring: a point is the ball's leading edge crossing a goal line.
        if (ball.x + BALL > FIELD_W) {        // right edge past 800 -> P1 scores (P2 conceded)
            score1++;
            if (score1 >= WIN_SCORE) {
                gameOver(1);
            } else {
                serve(+1);                    // serve toward the conceder, P2 (right)
            }
        } else if (ball.x < 0f) {             // left edge past 0 -> P2 scores (P1 conceded)
            score2++;
            if (score2 >= WIN_SCORE) {
                gameOver(2);
            } else {
                serve(-1);                    // serve toward the conceder, P1 (left)
            }
        }
    }

    private void movePaddle(Paddle p, boolean up, boolean down, float dt) {
        float dir = (up ? 1f : 0f) - (down ? 1f : 0f);
        p.y += dir * PADDLE_SPEED * dt;
        p.y = clamp(p.y, PADDLE_Y_MIN, PADDLE_Y_MAX);
    }

    private boolean overlaps(Paddle p) {
        return ball.x < p.x + PADDLE_W
            && ball.x + BALL > p.x
            && ball.y < p.y + PADDLE_H
            && ball.y + BALL > p.y;
    }

    /**
     * Reflect off a paddle. {@code dirAway} is +1 (off P1, sending the ball right) or -1 (off P2,
     * sending it left). Reposition just outside the paddle, set vy from the contact offset, grow the
     * total speed by 5% (capped), then recompute vx so the new total speed is preserved.
     */
    private void bounce(Paddle p, int dirAway) {
        if (dirAway > 0) {
            ball.x = p.x + PADDLE_W;   // P1: ball left edge at paddle right edge
        } else {
            ball.x = p.x - BALL;       // P2: ball right edge at paddle left edge
        }
        float offset = clamp((ball.centerY() - p.centerY()) / REFLECT_RANGE, -1f, 1f);
        ball.vy = offset * REFLECT_MAX_VY;
        ball.speed = Math.min(ball.speed * SPEED_GAIN, BALL_MAX_SPEED);
        ball.vx = (float) Math.sqrt(ball.speed * ball.speed - ball.vy * ball.vy) * dirAway;
    }

    private void gameOver(int who) {
        state = State.GAME_OVER;
        winner = who;
    }

    /** QA-only helper: force a GAME_OVER state so the overlay can be screenshotted. */
    public void forceGameOverForQA(int who) {
        score1 = (who == 1) ? WIN_SCORE : 3;
        score2 = (who == 2) ? WIN_SCORE : 3;
        gameOver(who);
    }

    public static float clamp(float v, float lo, float hi) {
        return v < lo ? lo : (v > hi ? hi : v);
    }
}
