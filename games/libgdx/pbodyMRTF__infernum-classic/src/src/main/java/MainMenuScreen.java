import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.utils.Align;
import java.util.Random;

public class MainMenuScreen implements Screen {
    private static final int PARTICLE_COUNT = 50;
    private static final float REF_WIDTH = 1280f;
    private static final float REF_HEIGHT = 720f;

    final Jgame game;
    BitmapFont font;
    String titleText;

    private float titleScale = 1.0f;
    private float titlePulse = 0.0f;
    private float menuAlpha = 0.0f;
    private float backgroundHue = 0.0f;
    private int selectedOption = 0;
    private float selectionBlink = 0.0f;

    private final float[] particleX = new float[PARTICLE_COUNT];
    private final float[] particleY = new float[PARTICLE_COUNT];
    private final float[] particleSpeed = new float[PARTICLE_COUNT];
    private final float[] particleSize = new float[PARTICLE_COUNT];
    private final Random rand = new Random();

    private final SpriteBatch batch = new SpriteBatch();
    private final ShapeRenderer shapeRenderer = new ShapeRenderer();
    private final Color bgColor = new Color();

    private Sound selectSound;
    private Sound confirmSound;

    // Pencere boyutuna göre ölçek
    private float uiScale = 1f;

    public MainMenuScreen(Jgame game) {
        this.game = game;
        this.font = game.font;
        this.titleText = "Infernum:\nClassic Edition";
        updateProjection(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        initParticles();
        loadAssets();
    }

    private void updateProjection(int width, int height) {
        uiScale = Math.min(width / REF_WIDTH, height / REF_HEIGHT);
        Matrix4 proj = new Matrix4().setToOrtho2D(0, 0, width, height);
        batch.setProjectionMatrix(proj);
        shapeRenderer.setProjectionMatrix(proj);
    }

    private void initParticles() {
        for (int i = 0; i < PARTICLE_COUNT; i++) {
            particleX[i] = rand.nextFloat() * Gdx.graphics.getWidth();
            particleY[i] = rand.nextFloat() * Gdx.graphics.getHeight();
            particleSpeed[i] = 20.0f + (rand.nextFloat() * 40.0f);
            particleSize[i] = 2.0f + (rand.nextFloat() * 4.0f);
        }
    }

    @Override
    public void render(float delta) {
        updateAnimations(delta);

        bgColor.fromHsv(backgroundHue, 0.6f, 0.3f);
        Gdx.gl.glClearColor(bgColor.r, bgColor.g, bgColor.b, 1.0f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        int w = Gdx.graphics.getWidth();
        int h = Gdx.graphics.getHeight();

        drawDecorations(w, h);
        drawParticles(delta, w, h);

        batch.begin();

        // Başlık (ortalanmış)
        font.getData().setScale((2.3f + titleScale * 0.1f) * uiScale);
        font.setColor(1f, 1f, 1f, 1f);
        font.draw(batch, titleText, 0, h / 2f + 100f * uiScale, w, Align.center, false);

        // Menü seçenekleri
        font.getData().setScale(uiScale);
        float startY = h / 2f - 40f * uiScale;
        float gap = 50f * uiScale;

        drawMenuItem("Start", 0, w, startY);
        drawMenuItem("Exit", 1, w, startY - gap);

        // Alt bilgi
        font.setColor(0.7f, 0.7f, 0.7f, menuAlpha * 0.6f);
        font.getData().setScale(0.7f * uiScale);
        font.draw(batch, "powered by LibGDX and LWJGL | " + Jgame.Version,
                10f * uiScale, 20f * uiScale + 10f);

        font.getData().setScale(1.0f);
        font.setColor(Color.WHITE);
        batch.end();

        handleInput();
    }

    private void drawMenuItem(String label, int index, int w, float y) {
        if (selectedOption == index) {
            font.setColor(1f, 1f, 0f, menuAlpha * selectionBlink);
            font.draw(batch, "> " + label + " <", 0, y, w, Align.center, false);
        } else {
            font.setColor(1f, 1f, 1f, menuAlpha);
            font.draw(batch, label, 0, y, w, Align.center, false);
        }
    }

    private void loadAssets() {
        selectSound = Assets.getSound(Assets.Sounds.SELECT);
        confirmSound = Assets.getSound(Assets.Sounds.CONFIRM);
    }

    private void updateAnimations(float delta) {
        titlePulse += delta * 3.0f;
        titleScale = (MathUtils.sin(titlePulse) * 0.5f) + 0.5f;
        menuAlpha = Math.min(menuAlpha + (delta * 1.2f), 1.0f);
        backgroundHue = (backgroundHue + (delta * 20.0f)) % 360.0f;
        selectionBlink += delta * 4.0f;
        selectionBlink = (MathUtils.sin(selectionBlink) * 0.3f) + 0.7f;
    }

    private void drawParticles(float delta, int w, int h) {
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        shapeRenderer.setColor(1f, 1f, 1f, 0.3f);
        for (int i = 0; i < PARTICLE_COUNT; i++) {
            particleY[i] -= particleSpeed[i] * uiScale * delta;
            if (particleY[i] < -10f) {
                particleY[i] = h + 10f;
                particleX[i] = rand.nextFloat() * w;
            }
            shapeRenderer.circle(particleX[i], particleY[i], particleSize[i] * uiScale);
        }
        shapeRenderer.end();
    }

    private void drawDecorations(int w, int h) {
        float m = 30f * uiScale;   // kenar boşluğu
        float c = 20f * uiScale;   // köşe çizgisi uzunluğu

        shapeRenderer.begin(ShapeRenderer.ShapeType.Line);
        shapeRenderer.setColor(1f, 1f, 1f, 0.2f);
        shapeRenderer.rect(m, m, w - m * 2f, h - m * 2f);

        // Sol üst
        shapeRenderer.line(m, h - m, m + c, h - m);
        shapeRenderer.line(m, h - m, m, h - m - c);
        // Sağ üst
        shapeRenderer.line(w - m, h - m, w - m - c, h - m);
        shapeRenderer.line(w - m, h - m, w - m, h - m - c);
        // Sol alt
        shapeRenderer.line(m, m, m + c, m);
        shapeRenderer.line(m, m, m, m + c);
        // Sağ alt
        shapeRenderer.line(w - m, m, w - m - c, m);
        shapeRenderer.line(w - m, m, w - m, m + c);
        shapeRenderer.end();
    }

    private void handleInput() {
        boolean up = Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W);
        boolean down = Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S);
        if (up || down) {
            selectedOption = (selectedOption + 1) % 2;
            selectSound.play();
        }

        boolean confirm = Gdx.input.isKeyJustPressed(Input.Keys.ENTER) || Gdx.input.isKeyJustPressed(Input.Keys.SPACE);
        if (confirm) {
            confirmSound.play();
            if (selectedOption == 0) {
                game.setScreen(new GameScreen(game));
                dispose();
            } else {
                Gdx.app.exit();
            }
        }

        boolean quit = Gdx.input.isKeyPressed(Input.Keys.ESCAPE) || Gdx.input.isKeyPressed(Input.Keys.BACK);
        if (quit) {
            Gdx.app.exit();
        }
    }

    @Override
    public void resize(int width, int height) {
        if (width <= 0 || height <= 0) return; // küçültme (minimize) durumu
        Gdx.gl.glViewport(0, 0, width, height);
        updateProjection(width, height);
        initParticles();
    }

    @Override public void show() { }
    @Override public void pause() { }
    @Override public void resume() { }
    @Override public void hide() { }

    @Override
    public void dispose() {
        batch.dispose();
        shapeRenderer.dispose();
    }
}