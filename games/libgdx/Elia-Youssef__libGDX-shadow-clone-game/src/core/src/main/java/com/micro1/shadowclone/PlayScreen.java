package com.micro1.shadowclone;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * Drives the twelve gameplay levels (scenes 2..13). It runs the simulation on a fixed 60 Hz step via
 * an accumulator (so replays are frame-exact), reads input, rolls the 5 second recording that deploys
 * clones, resolves hazards, detects the exit, and advances to the next level or the Victory screen.
 * Its per-step order is the canonical one verified headlessly by the test harness.
 */
public final class PlayScreen implements Screen {

    private final ShadowCloneGame game;
    private final WorldRenderer worldRenderer;
    private final Hud hud;

    private int index;
    private Level level;
    private Player player;
    private final Array<Clone> clones = new Array<>();
    private final Recorder recorder = new Recorder();

    private float acc;
    private float time;
    private boolean pendingJump, pendingInteract;
    private boolean solved;
    private float solvedTimer;
    private float deathFlash;        // >0 while the failure banner is showing
    private String deathMsg = "";
    private final Matrix4 worldMatrix = new Matrix4();

    public PlayScreen(ShadowCloneGame game, int index) {
        this.game = game;
        this.worldRenderer = new WorldRenderer(game);
        this.hud = new Hud(game);
        this.index = index;
        loadLevel(index);
    }

    private void loadLevel(int i) {
        index = i;
        level = Levels.build(i);
        player = new Player(level.spawnX, level.spawnY);
        clones.clear();
        recorder.beginTake(player);
        solved = false;
        solvedTimer = 0f;
        acc = 0f;
    }

    private void restartLevel() {
        loadLevel(index);
    }

    private void advance() {
        if (index + 1 >= Levels.COUNT) {
            game.toVictory();
        } else {
            loadLevel(index + 1);
        }
    }

    // ------------------------------------------------------------------------------- render ---
    @Override
    public void render(float delta) {
        time += delta;
        // A failure (countdown expired or a fall) freezes the level briefly and shows why, then
        // rebuilds it - so the consequence is unmistakable rather than a silent teleport (item 15).
        if (deathFlash > 0f) {
            deathFlash -= delta;
            if (deathFlash <= 0f) {
                game.stats.deaths++;
                loadLevel(index);
            } else {
                draw();
                return;
            }
        }
        if (handleGlobalKeys()) return;

        if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE)
            || Gdx.input.isKeyJustPressed(Input.Keys.UP)
            || Gdx.input.isKeyJustPressed(Input.Keys.W)) pendingJump = true;
        if (Gdx.input.isKeyJustPressed(Input.Keys.E)) pendingInteract = true;

        acc += Math.min(delta, 0.25f);
        while (acc >= Theme.DT) {
            step(buildInput());
            acc -= Theme.DT;
            if (solvedJustAdvanced) { solvedJustAdvanced = false; return; }
        }
        draw();
    }

    private boolean solvedJustAdvanced;

    private InputFrame buildInput() {
        boolean left = Gdx.input.isKeyPressed(Input.Keys.LEFT) || Gdx.input.isKeyPressed(Input.Keys.A);
        boolean right = Gdx.input.isKeyPressed(Input.Keys.RIGHT) || Gdx.input.isKeyPressed(Input.Keys.D);
        InputFrame in = new InputFrame(left, right, pendingJump, pendingInteract);
        pendingJump = false;
        pendingInteract = false;
        return in;
    }

    private boolean handleGlobalKeys() {
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) { game.toMenu(); return true; }
        if (Gdx.input.isKeyJustPressed(Input.Keys.BACKSPACE)) { restartLevel(); return true; }
        if (Gdx.input.isKeyJustPressed(Input.Keys.R)) {
            recorder.beginTake(player);
        }
        return false;
    }

    private void step(InputFrame in) {
        level.advanceHazards(Theme.DT);
        level.recomputeSwitches(player, clones);
        level.updateCarriers(Theme.DT);

        player.interactedThisStep = in.interactPressed;
        Physics.step(player, in, level, Theme.DT);
        for (Clone c : clones) {
            InputFrame f = c.next();
            c.interactedThisStep = f.interactPressed;
            Physics.step(c, f, level, Theme.DT);
        }

        Hazards.blockPlayerAtLasers(level, player);   // before recompute: player cannot trip in-beam switches
        level.recomputeSwitches(player, clones);
        level.updateSystems(Theme.DT, player, clones);

        for (int i = clones.size - 1; i >= 0; i--) {
            Clone c = clones.get(i);
            if (Hazards.cloneHitByLaser(level, c) || Hazards.pitDeath(c)) clones.removeIndex(i);
        }
        for (Switch s : level.switches) {
            if (s.justActivated && !s.hidden) game.stats.switchesActivated++;
        }

        // A camera that saw the player fails the current recording.
        if (level.recordingFailRequested) {
            recorder.beginTake(player);
            level.recordingFailRequested = false;
        }

        game.stats.elapsedTime += Theme.DT;

        if (!solved) {
            boolean complete = recorder.record(in, Theme.DT);
            if (complete) {
                clones.add(new Clone(recorder.buildRecording()));
                if (clones.size > Theme.MAX_CLONES) clones.removeIndex(0);
                game.stats.recordingsMade++;
                game.stats.clonesUsed++;
                recorder.beginTake(player);
            }
        }

        if (Hazards.pitDeath(player) || level.escapeFailed) {
            deathMsg = level.escapeFailed ? "TIME UP" : "YOU FELL";
            deathFlash = 1.2f;
            solvedJustAdvanced = true;   // stop stepping; render() shows the banner then rebuilds
            return;
        }

        if (!solved && level.exitReached(player)) {
            solved = true;
            solvedTimer = 1.1f;
            game.stats.puzzlesSolved++;
        }
        if (solved) {
            solvedTimer -= Theme.DT;
            if (solvedTimer <= 0f) {
                advance();
                solvedJustAdvanced = true;
            }
        }
    }

    private void draw() {
        ScreenUtils.clear(Theme.BG_BOTTOM.r, Theme.BG_BOTTOM.g, Theme.BG_BOTTOM.b, 1f);
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);

        game.camera.update();
        float shakeX = 0f, shakeY = 0f;
        if (level.escaping) {
            float mag = MathUtils.clamp(2.5f + (1f - level.escapeTime / level.escapeLimit) * 6f, 2.5f, 9f);
            shakeX = mag * 0.5f * (MathUtils.sin(time * 53f) + MathUtils.sin(time * 97f));
            shakeY = mag * 0.5f * (MathUtils.cos(time * 61f) + MathUtils.sin(time * 89f));
        }
        float ox = game.camera.position.x, oy = game.camera.position.y;
        game.camera.position.add(shakeX, shakeY, 0f);
        game.camera.update();
        worldMatrix.set(game.camera.combined);
        game.camera.position.set(ox, oy, 0f);
        game.camera.update();

        ShapeRenderer sr = game.shapes;
        // World (shaken).
        sr.setProjectionMatrix(worldMatrix);
        sr.begin(ShapeRenderer.ShapeType.Filled);
        worldRenderer.fillPass(sr, level, player, clones, time);
        sr.end();
        sr.begin(ShapeRenderer.ShapeType.Line);
        worldRenderer.linePass(sr, level, player, clones, time);
        sr.end();
        // HUD (steady).
        sr.setProjectionMatrix(game.camera.combined);
        sr.begin(ShapeRenderer.ShapeType.Filled);
        hud.fillPass(sr, level, recorder.remainingSeconds(), recorder.progress(), clones.size, solved);
        if (deathFlash > 0f) {
            sr.setColor(0.30f, 0.05f, 0.06f, 0.55f);
            sr.rect(0f, 0f, Theme.WORLD_W, Theme.WORLD_H);
            Draw.fill(sr, Theme.WORLD_W * 0.5f - 200f, 330f, 400f, 90f, new Color(0.16f, 0.03f, 0.04f, 0.95f));
        }
        sr.end();
        sr.begin(ShapeRenderer.ShapeType.Line);
        hud.linePass(sr, level, solved);
        if (deathFlash > 0f) Draw.border(sr, Theme.WORLD_W * 0.5f - 200f, 330f, 400f, 90f, Theme.LASER);
        sr.end();

        // Text: world labels (shaken), then HUD (steady).
        game.batch.setProjectionMatrix(worldMatrix);
        game.batch.begin();
        worldRenderer.textPass(level, player, clones);
        game.batch.end();
        game.batch.setProjectionMatrix(game.camera.combined);
        game.batch.begin();
        hud.textPass(level, recorder.remainingSeconds(), clones.size, solved);
        if (deathFlash > 0f) {
            game.text(deathMsg, Theme.WORLD_W * 0.5f, 396f, 2.0f, Theme.LASER, 0);
            game.text("restarting the level...", Theme.WORLD_W * 0.5f, 354f, 0.9f, Theme.INK_DIM, 0);
        }
        game.batch.end();
    }

    // ------------------------------------------------------------------------- Screen stubs ---
    @Override public void resize(int width, int height) { game.viewport.update(width, height, false); }
    @Override public void show() {}
    @Override public void hide() {}
    @Override public void pause() {}
    @Override public void resume() {}
    @Override public void dispose() {}
}
