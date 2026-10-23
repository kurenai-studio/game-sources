import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import java.util.Random;

public class PauseScreen implements Screen {
    private static final int PARTICLE_COUNT = 50;

    final Jgame game;
    private final Screen previousScreen;
    BitmapFont font;
    String titleText;

    private float titleScale = 1.0f;
    private float titlePulse = 0.0f;
    private float menuAlpha = 0.0f;
    private int selectedOption = 0;
    private float selectionBlink = 0.0f;

    private float[] particleX = new float[PARTICLE_COUNT];
    private float[] particleY = new float[PARTICLE_COUNT];
    private float[] particleSpeed = new float[PARTICLE_COUNT];
    private float[] particleSize = new float[PARTICLE_COUNT];

    SpriteBatch batch = new SpriteBatch();
    ShapeRenderer shapeRenderer = new ShapeRenderer();

    private Sound selectSound;
    private Sound confirmSound;

    public PauseScreen(Jgame game, Screen previousScreen) {
        this.game = game;
        this.previousScreen = previousScreen;
        this.font = game.font;
        this.titleText = "  Paused";
        initParticles();
        loadAssets();
    }

    private void initParticles() {
        Random rand = new Random();
        for (int i = 0; i < PARTICLE_COUNT; i++) {
            this.particleX[i] = rand.nextFloat() * Gdx.graphics.getWidth();
            this.particleY[i] = rand.nextFloat() * Gdx.graphics.getHeight();
            this.particleSpeed[i] = 10.0f + (rand.nextFloat() * 20.0f);
            this.particleSize[i] = 1.5f + (rand.nextFloat() * 3.0f);
        }
    }

    private void loadAssets() {
        this.selectSound = Assets.getSound(Assets.Sounds.SELECT);
        this.confirmSound = Assets.getSound(Assets.Sounds.CONFIRM);
    }

    @Override // com.badlogic.gdx.Screen
    public void render(float delta) {
        updateAnimations(delta);

        Color bgColor = new Color();
        bgColor.fromHsv(220.0f, 0.35f, 0.10f + (0.03f * this.titleScale));
        Gdx.gl.glClearColor(bgColor.r, bgColor.g, bgColor.b, 1.0f);
        Gdx.gl.glClear(16384);

        int w = Gdx.graphics.getWidth();
        int h = Gdx.graphics.getHeight();
        drawDecorations(w, h);
        drawParticles(delta);

        this.batch.begin();
        this.font.getData().setScale(2.2f + (this.titleScale * 0.12f));
        this.font.setColor(1.0f, 1.0f, 1.0f, 1.0f);
        this.font.draw(this.batch, this.titleText, (w / 2.0f) - 200f, h / 2.0f + 150);
        this.font.getData().setScale(1.0f);

        drawOption("Continue", 0, w, (h / 2.0f) + 20.0f);
        drawOption("Main Menu", 1, w, (h / 2.0f) - 30.0f);
        drawOption("Exit", 2, w, (h / 2.0f) - 80.0f);

        this.font.setColor(0.7f, 0.7f, 0.7f, this.menuAlpha * 0.6f);
        this.font.getData().setScale(0.7f);
        this.font.draw(this.batch, "powered by LibGDX and LWJGL | " + Jgame.Version, 10.0f, 20.0f);
        this.font.getData().setScale(1.0f);
        this.batch.end();

        handleInput();
    }

    private void drawOption(String label, int index, float w, float y) {
        if (this.selectedOption == index) {
            this.font.setColor(1.0f, 1.0f, 0.0f, this.menuAlpha * this.selectionBlink);
            this.font.draw(this.batch, "> " + label + " <", (w / 2.0f) - 120.0f, y);
        } else {
            this.font.setColor(1.0f, 1.0f, 1.0f, this.menuAlpha);
            this.font.draw(this.batch, "  " + label, (w / 2.0f) - 120.0f, y);
        }
    }

    private void updateAnimations(float delta) {
        this.titlePulse += delta * 2.5f;
        this.titleScale = (MathUtils.sin(this.titlePulse) * 0.5f) + 0.5f;
        this.menuAlpha = Math.min(this.menuAlpha + (delta * 2.0f), 1.0f);
        this.selectionBlink += delta * 4.0f;
        this.selectionBlink = (MathUtils.sin(this.selectionBlink) * 0.3f) + 0.7f;
    }

    private void drawParticles(float delta) {
        this.shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        for (int i = 0; i < PARTICLE_COUNT; i++) {
            float[] fArr = this.particleY;
            int r1 = i;
            fArr[r1] = fArr[r1] - (this.particleSpeed[i] * delta);
            if (this.particleY[i] < -10.0f) {
                this.particleY[i] = Gdx.graphics.getHeight() + 10;
                this.particleX[i] = new Random().nextFloat() * Gdx.graphics.getWidth();
            }
            this.shapeRenderer.setColor(0.6f, 0.65f, 0.8f, 0.25f);
            this.shapeRenderer.circle(this.particleX[i], this.particleY[i], this.particleSize[i]);
        }
        this.shapeRenderer.end();
    }

    private void drawDecorations(int w, int h) {
        this.shapeRenderer.begin(ShapeRenderer.ShapeType.Line);
        this.shapeRenderer.setColor(1.0f, 1.0f, 1.0f, 0.2f);
        this.shapeRenderer.rect(30.0f, 30.0f, w - (30.0f * 2.0f), h - (30.0f * 2.0f));
        this.shapeRenderer.line(30.0f, h - 30.0f, 30.0f + 20.0f, h - 30.0f);
        this.shapeRenderer.line(30.0f, h - 30.0f, 30.0f, (h - 30.0f) - 20.0f);
        this.shapeRenderer.line(w - 30.0f, h - 30.0f, (w - 30.0f) - 20.0f, h - 30.0f);
        this.shapeRenderer.line(w - 30.0f, h - 30.0f, w - 30.0f, (h - 30.0f) - 20.0f);
        this.shapeRenderer.line(30.0f, 30.0f, 30.0f + 20.0f, 30.0f);
        this.shapeRenderer.line(30.0f, 30.0f, 30.0f, 30.0f + 20.0f);
        this.shapeRenderer.line(w - 30.0f, 30.0f, (w - 30.0f) - 20.0f, 30.0f);
        this.shapeRenderer.line(w - 30.0f, 30.0f, w - 30.0f, 30.0f + 20.0f);
        this.shapeRenderer.end();
    }

    private void handleInput() {
        boolean up = Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W);
        boolean down = Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S);
        if (up) {
            this.selectedOption = ((this.selectedOption - 1) + 3) % 3;
            this.selectSound.play();
        }
        if (down) {
            this.selectedOption = (this.selectedOption + 1) % 3;
            this.selectSound.play();
        }

        boolean confirm = Gdx.input.isKeyJustPressed(Input.Keys.ENTER) || Gdx.input.isKeyJustPressed(Input.Keys.SPACE);
        if (confirm) {
            this.confirmSound.play();
            applySelection();
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            resumeGame();
        }
    }

    private void applySelection() {
        switch (this.selectedOption) {
            case 0:
                resumeGame();
                break;
            case 1:
                this.previousScreen.dispose();
                this.game.setScreen(new MainMenuScreen(this.game));
                dispose();
                break;
            default:
                Gdx.app.exit();
                break;
        }
    }

    private void resumeGame() {
        this.game.setScreen(this.previousScreen);
        dispose();
    }

    @Override // com.badlogic.gdx.Screen
    public void show() {
    }

    @Override // com.badlogic.gdx.Screen
    public void resize(int width, int height) {
        initParticles();
    }

    @Override // com.badlogic.gdx.Screen
    public void pause() {
    }

    @Override // com.badlogic.gdx.Screen
    public void resume() {
    }

    @Override // com.badlogic.gdx.Screen
    public void hide() {
    }

    @Override // com.badlogic.gdx.Screen, com.badlogic.gdx.utils.Disposable
    public void dispose() {
        this.batch.dispose();
        this.shapeRenderer.dispose();
    }
}