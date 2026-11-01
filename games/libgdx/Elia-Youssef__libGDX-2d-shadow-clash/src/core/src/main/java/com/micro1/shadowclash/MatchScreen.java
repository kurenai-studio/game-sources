package com.micro1.shadowclash;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The single playable screen: reads the reference.png control scheme into an
 * {@link Intent}, ticks
 * the {@link ClashWorld}, and renders the arena, both fighters
 * (facing-flipped), projectiles,
 * effects, the two health bars, the state messages and the slow-motion tint. An
 * optional offscreen
 * capture harness (system property clash.capture) scripts a match and
 * screenshots the key states.
 */
public final class MatchScreen extends ScreenAdapter {

    private final Assets a;
    private final ClashWorld world = new ClashWorld();
    private final SpriteBatch batch = new SpriteBatch();
    private final ShapeRenderer shape = new ShapeRenderer();
    private final OrthographicCamera cam = new OrthographicCamera(K.WORLD_W, K.WORLD_H);
    private final GlyphLayout layout = new GlyphLayout();
    private final Intent input = new Intent();

    private float displayScale = 3.0f;
    private static final float PROJECTILE_SCALE = 1.9f;
    private static final float EFFECT_SCALE = 1.55f;

    // player input state
    private float holdTime;
    private int lastMoveDir;
    private float tapTimer = -1f;
    private int tapDir;

    public MatchScreen(Assets a) {
        this.a = a;
        cam.position.set(K.WORLD_W / 2f, K.WORLD_H / 2f, 0f);
        cam.update();
        TextureRegion idle0 = a.anim(true, "idle").getKeyFrame(0f);
        displayScale = 330f / idle0.getRegionHeight();
    }

    @Override
    public void render(float delta) {
        float dt = Math.max(0f, delta);

        if (Gdx.input.isKeyJustPressed(Input.Keys.R))
            restartMatch();
        readInput(dt);

        world.update(dt, input);
        draw();
    }

    // ------------------------------------------------------------------ input
    // (reference.png scheme)

    private void readInput(float dt) {
        input.clear();
        boolean left = Gdx.input.isKeyPressed(Input.Keys.LEFT);
        boolean right = Gdx.input.isKeyPressed(Input.Keys.RIGHT);
        input.moveDir = right ? 1 : (left ? -1 : 0);
        // hold a direction to break into a run (reference: "hold Run Forward /
        // Backward")
        if (input.moveDir != 0 && input.moveDir == lastMoveDir)
            holdTime += dt;
        else
            holdTime = 0f;
        lastMoveDir = input.moveDir;
        input.run = input.moveDir != 0 && holdTime > 0.32f;

        input.crouch = Gdx.input.isKeyPressed(Input.Keys.DOWN);
        input.jumpPressed = Gdx.input.isKeyJustPressed(Input.Keys.UP);
        input.standBlock = Gdx.input.isKeyPressed(Input.Keys.M);
        input.crouchBlock = Gdx.input.isKeyPressed(Input.Keys.COMMA);

        // double-tap left/right = back dash
        if (tapTimer >= 0f)
            tapTimer += dt;
        if (Gdx.input.isKeyJustPressed(Input.Keys.LEFT))
            input.backDashPressed |= tap(-1);
        if (Gdx.input.isKeyJustPressed(Input.Keys.RIGHT))
            input.backDashPressed |= tap(1);

        input.attack = readAttack();
    }

    private boolean tap(int dir) {
        boolean dash = tapTimer >= 0f && tapTimer < 0.28f && tapDir == dir;
        tapDir = dir;
        tapTimer = 0f;
        return dash;
    }

    private Move readAttack() {
        if (Gdx.input.isKeyJustPressed(Input.Keys.J))
            return Move.JAB;
        if (Gdx.input.isKeyJustPressed(Input.Keys.K))
            return Move.CROUCHJAB;
        if (Gdx.input.isKeyJustPressed(Input.Keys.L))
            return Move.STANDKICK;
        if (Gdx.input.isKeyJustPressed(Input.Keys.U))
            return Move.STRONGPUNCH;

        if (Gdx.input.isKeyJustPressed(Input.Keys.I))
            return Move.SWEEP;
        if (Gdx.input.isKeyJustPressed(Input.Keys.O))
            return Move.UPPERCUT;
        if (Gdx.input.isKeyJustPressed(Input.Keys.P))
            return Move.SHADOWBLAST;
        if (Gdx.input.isKeyJustPressed(Input.Keys.SEMICOLON))
            return Move.DARKCHARGE;
        if (Gdx.input.isKeyJustPressed(Input.Keys.APOSTROPHE))
            return Move.SPINSLASH;
        return null;
    }

    private void restartMatch() {
        world.reset();
        input.clear();
        holdTime = 0f;
        lastMoveDir = 0;
        tapTimer = -1f;
        tapDir = 0;
    }

    // ------------------------------------------------------------------ rendering

    private void draw() {
        ScreenUtils.clear(0.02f, 0.02f, 0.04f, 1f);
        cam.update();
        batch.setProjectionMatrix(cam.combined);
        shape.setProjectionMatrix(cam.combined);

        batch.begin();
        batch.draw(a.background(), 0f, 0f, K.WORLD_W, K.WORLD_H);
        drawFighter(world.cpu);
        drawFighter(world.player);
        drawProjectiles();
        drawEffects();
        batch.end();

        if (world.isSlowMotion())
            drawTint(0.10f, 0.06f, 0.20f, 0.30f); // dramatic slow-mo wash
        drawHealthBars();

        batch.begin();
        drawHud();
        batch.end();
    }

    private void drawFighter(Fighter f) {
        float blend = f.movementBlend();
        if (blend < 1f)
            drawFighterFrame(f, f.previousState, f.previousStateTime, 1f - blend);
        drawFighterFrame(f, f.state, f.stateTime, blend);
        batch.setColor(Color.WHITE);
    }

    private void drawFighterFrame(Fighter f, FighterState state, float stateTime, float alpha) {
        Animation<TextureRegion> anim = a.anim(f.isPlayer, state.animKey);
        TextureRegion fr = anim.getKeyFrame(stateTime, state.loop);
        float w = fr.getRegionWidth() * displayScale;
        float h = fr.getRegionHeight() * displayScale;
        float x = f.x - w / 2f;
        boolean flip = f.facing == -1;
        batch.setColor(1f, 1f, 1f, alpha);
        batch.draw(fr, x, f.y, w / 2f, 0f, w, h, flip ? -1f : 1f, 1f, 0f);
    }

    private void drawProjectiles() {
        for (int i = 0; i < world.projectiles.size(); i++) {
            Projectile p = world.projectiles.get(i);
            TextureRegion fr = a.anim(p.owner.isPlayer, "projectile").getKeyFrame(p.age, true);
            float w = fr.getRegionWidth() * PROJECTILE_SCALE;
            float h = fr.getRegionHeight() * PROJECTILE_SCALE;
            boolean flip = p.facing == -1;
            batch.draw(fr, p.x - w / 2f, p.y - h / 2f, w / 2f, h / 2f, w, h, flip ? -1f : 1f, 1f, 0f);
        }
    }

    private void drawEffects() {
        for (int i = 0; i < world.effects.size(); i++) {
            Effect e = world.effects.get(i);
            String key = e.kind == Effect.Kind.HIT ? "fx_hit"
                    : e.kind == Effect.Kind.BLOCK ? "fx_spark"
                            : e.kind == Effect.Kind.EXPLOSION ? "fx_explosion" : "fx_dust";
            Animation<TextureRegion> anim = a.anim(e.fromPlayer, key);
            TextureRegion fr = anim.getKeyFrame(e.time, false);
            float w = fr.getRegionWidth() * EFFECT_SCALE;
            float h = fr.getRegionHeight() * EFFECT_SCALE;
            batch.draw(fr, e.x - w / 2f, e.y - h / 2f, w, h);
        }
    }

    private void drawTint(float r, float g, float b, float alpha) {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        shape.begin(ShapeRenderer.ShapeType.Filled);
        shape.setColor(r, g, b, alpha);
        shape.rect(0f, 0f, K.WORLD_W, K.WORLD_H);
        shape.end();
    }

    private void drawHealthBars() {
        float bw = 430f, bh = 30f, pad = 26f, top = K.WORLD_H - 40f - bh;
        Gdx.gl.glEnable(GL20.GL_BLEND);
        shape.begin(ShapeRenderer.ShapeType.Filled);
        // backing
        shape.setColor(0f, 0f, 0f, 0.55f);
        shape.rect(pad, top, bw, bh);
        shape.rect(K.WORLD_W - pad - bw, top, bw, bh);
        // player fill (drains left-to-right)
        float pf = world.player.health / (float) K.MAX_HP;
        setHealthColor(pf);
        shape.rect(pad, top, bw * pf, bh);
        // cpu fill (drains right-to-left)
        float cf = world.cpu.health / (float) K.MAX_HP;
        setHealthColor(cf);
        shape.rect(K.WORLD_W - pad - bw * cf, top, bw * cf, bh);
        shape.end();

        shape.begin(ShapeRenderer.ShapeType.Line);
        shape.setColor(1f, 1f, 1f, 1f);
        shape.rect(pad, top, bw, bh);
        shape.rect(K.WORLD_W - pad - bw, top, bw, bh);
        shape.end();
    }

    private void setHealthColor(float f) {
        if (f > 0.5f)
            shape.setColor(0.15f + (1f - f) * 1.4f, 0.8f, 0.15f, 1f);
        else
            shape.setColor(0.9f, 0.15f + f * 1.2f, 0.1f, 1f);
    }

    private void drawHud() {
        BitmapFont font = a.font;
        // fighter names + health numbers
        font.getData().setScale(1.7f);
        font.setColor(Color.WHITE);
        float top = K.WORLD_H - 46f - 30f;
        font.draw(batch, "PLAYER", 28f, top + 62f);
        font.draw(batch, Integer.toString(world.player.health), 28f, top - 6f);
        drawRight(font, "CPU", K.WORLD_W - 28f, top + 62f);
        drawRight(font, Integer.toString(world.cpu.health), K.WORLD_W - 28f, top - 6f);

        // special-ready flags, tucked under each health bar so they never overlap
        // (only while the fighter is alive - a defeated fighter shows nothing)
        font.getData().setScale(1.05f);
        font.setColor(0.8f, 0.55f, 1f, 1f);
        if (world.player.specialsUnlocked && world.player.isAlive())
            font.draw(batch, "SPECIAL READY", 96f, top - 8f);
        if (world.cpu.specialsUnlocked && world.cpu.isAlive())
            drawRight(font, "SPECIAL READY", K.WORLD_W - 96f, top - 8f);

        // slow-motion label
        if (world.isSlowMotion()) {
            font.getData().setScale(1.6f);
            font.setColor(0.8f, 0.6f, 1f, 1f);
            center(font, "- SLOW MOTION -", K.WORLD_H - 150f);
        }

        // center message
        String msg = world.centerMessage();
        if (!msg.isEmpty()) {
            font.getData().setScale(6.2f);
            font.setColor(messageColor(world.phase));
            center(font, msg, K.WORLD_H / 2f + 40f);
        }
        if (world.phase == MatchState.VICTORY || world.phase == MatchState.DEFEAT) {
            font.getData().setScale(1.6f);
            font.setColor(Color.WHITE);
            center(font, "press  R  to fight again", K.WORLD_H / 2f - 40f);
        }

        // Controls stay in two short, scannable lines instead of one dense sentence.
        font.getData().setScale(0.95f);
        font.setColor(0.8f, 0.85f, 0.95f, 0.9f);
        center(font,
                "Move <- ->   hold to run   double-tap away to back-dash   Up jump   Down crouch",
                58f);
        center(font,
                "J K L light   U I O heavy   P ; ' special (<75 HP)   M , block   R restart",
                32f);

        font.getData().setScale(1f);
        font.setColor(Color.WHITE);
    }

    private void drawRight(BitmapFont font, String s, float rightX, float y) {
        layout.setText(font, s);
        font.draw(batch, s, rightX - layout.width, y);
    }

    private void center(BitmapFont font, String s, float y) {
        layout.setText(font, s);
        font.draw(batch, s, (K.WORLD_W - layout.width) / 2f, y);
    }

    private Color messageColor(MatchState phase) {
        switch (phase) {
            case READY:
                return new Color(1f, 0.95f, 0.85f, 1f);
            case FIGHT:
                return new Color(1f, 0.3f, 0.2f, 1f);
            case VICTORY:
                return new Color(1f, 0.85f, 0.25f, 1f);
            case DEFEAT:
                return new Color(1f, 0.25f, 0.25f, 1f);
            default:
                return Color.WHITE;
        }
    }

    @Override
    public void dispose() {
        batch.dispose();
        shape.dispose();
    }
}
