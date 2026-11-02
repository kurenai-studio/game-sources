package com.micro1.monstercafe;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The libGDX {@link Game}. Owns all shared, long-lived resources (the {@link SpriteBatch}, the {@link Assets}
 * textures, the fonts, the viewport/camera, a {@link ShapeRenderer}, a reusable {@link GlyphLayout}) so that
 * individual {@link Screen}s stay lightweight and can be created/discarded on every transition WITHOUT
 * leaking native memory ({@code Game.setScreen} never disposes the outgoing screen, so screens must own
 * nothing heavy). {@link #create()} loads everything once; {@link #dispose()} frees everything.
 */
public class MonsterCafeGame extends Game {

    public static final float WORLD_WIDTH = 1280f;
    public static final float WORLD_HEIGHT = 720f;
    public static final String TITLE = "Monster Café Madness";

    public SpriteBatch batch;
    public ShapeRenderer shapes;
    public Assets assets;
    public Viewport viewport;
    public GlyphLayout layout;

    public BitmapFont titleFont; // large  - menu title, VICTORY / GAME OVER headings
    public BitmapFont msgFont;   // medium - subtitles, final score, button captions
    public BitmapFont hudFont;   // small  - live score number, happiness percent

    // Optional offscreen QA capture, never used in normal play:
    //   --capture <file> [--scenario menu|play|victory|gameover]
    public boolean captureEnabled;
    public String captureFile;
    public String captureScenario = "menu";
    private int captureCountdown = 2; // render a couple of frames so all textures are uploaded, then grab

    @Override
    public void create() {
        batch = new SpriteBatch();
        shapes = new ShapeRenderer();
        assets = new Assets();
        viewport = new FitViewport(WORLD_WIDTH, WORLD_HEIGHT);
        layout = new GlyphLayout();

        titleFont = newFont(2.4f);
        msgFont = newFont(1.6f);
        hudFont = newFont(1.3f);

        setScreen(captureEnabled ? scenarioScreen(captureScenario) : new MainMenuScreen(this));
    }

    private BitmapFont newFont(float scale) {
        BitmapFont f = new BitmapFont(); // built-in Liberation Sans (includes accented glyphs); no font file shipped
        f.getRegion().getTexture().setFilter(TextureFilter.Linear, TextureFilter.Linear);
        f.getData().setScale(scale);
        f.setUseIntegerPositions(false);
        return f;
    }

    private Screen scenarioScreen(String scenario) {
        switch (scenario) {
            case "play":     return new GameplayScreen(this);
            case "victory":  return new VictoryScreen(this, 100);
            case "gameover": return new GameOverScreen(this, 40);
            case "menu":
            default:         return new MainMenuScreen(this);
        }
    }

    @Override
    public void render() {
        super.render(); // renders the current screen
        if (captureEnabled && --captureCountdown <= 0) {
            Pixmap pm = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                    Gdx.graphics.getBackBufferHeight());
            PixmapIO.writePNG(Gdx.files.local(captureFile), pm, -1, true);
            pm.dispose();
            Gdx.app.exit();
        }
    }

    @Override
    public void dispose() {
        if (getScreen() != null) {
            getScreen().dispose();
        }
        batch.dispose();
        shapes.dispose();
        assets.dispose();
        titleFont.dispose();
        msgFont.dispose();
        hudFont.dispose();
    }
}
