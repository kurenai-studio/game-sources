import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;


public class LoadingScreen implements Screen {
    private final Jgame game;
    private SpriteBatch batch;
    private ShapeRenderer shapeRenderer;
    private BitmapFont font;
    private float animTimer = 0.0f;

    public LoadingScreen(Jgame game) {
        this.game = game;
    }

    @Override // com.badlogic.gdx.Screen
    public void show() {
        this.batch = new SpriteBatch();
        this.shapeRenderer = new ShapeRenderer();
        this.font = this.game.font;
        Assets.load();
    }

    @Override // com.badlogic.gdx.Screen
    public void render(float delta) {
        this.animTimer += delta;
        Gdx.gl.glClearColor(0.1f, 0.1f, 0.15f, 1.0f);
        Gdx.gl.glClear(16384);
        float progress = Assets.getProgress();
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        float barX = (w - 400.0f) / 2.0f;
        float barY = h / 2.0f;
        this.shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        this.shapeRenderer.setColor(0.3f, 0.3f, 0.3f, 1.0f);
        this.shapeRenderer.rect(barX, barY, 400.0f, 30.0f);
        float hue = (this.animTimer * 0.5f) % 1.0f;
        Color progressColor = new Color();
        progressColor.fromHsv(hue * 360.0f, 0.7f, 0.9f);
        this.shapeRenderer.setColor(progressColor);
        this.shapeRenderer.rect(barX + 2.0f, barY + 2.0f, (400.0f - 4.0f) * progress, 30.0f - 4.0f);
        this.shapeRenderer.end();
        this.batch.begin();
        this.font.setColor(Color.WHITE);
        String loadingText = "Loading... %" + ((int) (progress * 100.0f));
        this.font.draw(this.batch, loadingText, (w / 2.0f) - 100.0f, barY + 30.0f + 50.0f);
        this.font.getData().setScale(0.6f);
        this.font.setColor(0.7f, 0.7f, 0.7f, 1.0f);
        this.font.draw(this.batch, "Texture'lar vs. yükleniyor. Bu ekranı sadece bir defa göreceksiniz \n çünkü bu oyunda bethesda logosu yok...", (w / 2.0f) - 250.0f, barY - 30.0f);
        this.font.getData().setScale(1.0f);
        this.batch.end();
        if (Assets.update()) {
            this.game.setScreen(new MainMenuScreen(this.game));
        }
    }

    @Override // com.badlogic.gdx.Screen
    public void resize(int width, int height) {
    }

    @Override // com.badlogic.gdx.Screen
    public void pause() {
    }

    @Override // com.badlogic.gdx.Screen
    public void resume() {
    }

    @Override // com.badlogic.gdx.Screen
    public void hide() {
        dispose();
    }

    @Override // com.badlogic.gdx.Screen, com.badlogic.gdx.utils.Disposable
    public void dispose() {
        if (this.batch != null) {
            this.batch.dispose();
        }
        if (this.shapeRenderer != null) {
            this.shapeRenderer.dispose();
        }
    }
}
