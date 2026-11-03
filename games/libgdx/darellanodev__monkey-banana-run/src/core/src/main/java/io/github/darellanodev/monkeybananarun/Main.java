package io.github.darellanodev.monkeybananarun;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;

/** {@link com.badlogic.gdx.ApplicationListener} implementation shared by all platforms. */
public class Main extends ApplicationAdapter {
    private SpriteBatch batch;
    private SpriteBatch uiBatch;
    private FitViewport viewport;

    private Music music;

    private Texture backgroundTexture;
    private Texture bananaTexture;
    private Sound pickUpBananaSound;
    private Sound jumpSound;
    private Sound fallSound;
    private Sound dieSound;
    private Rectangle bananaRectangle;
    private Array<Banana> bananaSprites;

    private Monkey monkey;
    private Texture monkeyRunTexture;
    private Texture monkeyIdleTexture;
    private Texture monkeyBurnedTexture;

    private Texture coreFullTexture;
    private Texture coreEmptyTexture;

    private Texture fireTexture;
    private Fire fire;

    private Menu menu;
    private Texture menuTexture;
    private boolean shouldDisplayMenu;
    private boolean isGameOver = false;

    private BitmapFont font;
    private GlyphLayout layout;

    private float reinitTime = 0f;
    private final float reinitMaxTime = 3f;
    private final float reinitTimeFactor = 3f;

    @Override
    public void create() {
        shouldDisplayMenu = true;
        batch = new SpriteBatch();
        uiBatch = new SpriteBatch();
        viewport = new FitViewport(Config.WORLD_WIDTH, Config.WORLD_HEIGHT);

        createTextures();
        createFonts();
        createSounds();
        createMusic();

        menu = new Menu(menuTexture);
        monkey = new Monkey(monkeyRunTexture, monkeyIdleTexture, monkeyBurnedTexture, jumpSound, fallSound);
        fire = new Fire(fireTexture, 11f, 2f);
        bananaSprites = new Array<>();
        bananaRectangle = new Rectangle();
        createBananas();
    }

    private void createFonts() {
        font = new BitmapFont();
        font.getData().setScale(3f);
        font.setColor(1,1,1,1);
        layout = new GlyphLayout();
    }

    private void createSounds() {
        pickUpBananaSound = Gdx.audio.newSound(Gdx.files.internal("pickup_banana.wav"));
        jumpSound = Gdx.audio.newSound(Gdx.files.internal("jump.wav"));
        fallSound = Gdx.audio.newSound(Gdx.files.internal("fall.wav"));
        dieSound = Gdx.audio.newSound(Gdx.files.internal("die.wav"));
    }

    private void createTextures() {
        monkeyRunTexture = new Texture("monkey_run.png");
        monkeyIdleTexture = new Texture("monkey_idle.png");
        monkeyBurnedTexture = new Texture("monkey_burned.png");
        bananaTexture = new Texture("banana.png");
        backgroundTexture = new Texture("background.png");
        menuTexture = new Texture("menu.png");
        fireTexture = new Texture("fire.png");
        coreFullTexture = new Texture("core_full.png");
        coreEmptyTexture = new Texture("core_empty.png");
    }

    private void createMusic() {
        music = Gdx.audio.newMusic(Gdx.files.internal("music.mp3"));
        music.setLooping(true);
        music.setVolume(.5f);
        //music.play();
    }

    @Override
    public void render() {
        float delta = Gdx.graphics.getDeltaTime();
        if (monkey.hasLives()) {
            monkey.update(delta);
        }
        fire.update(delta);
        menu.update(delta);

        logic(delta);
        draw();
    }

    private void logic(float deltaTime) {
        menuLogic();
        fireLogic();
        bananasLogic();
        reinitLogic(deltaTime);
    }

    private void menuLogic() {
        if (shouldDisplayMenu && menu.isStartGame()) {
            shouldDisplayMenu = false;
        }
    }

    private void reinitLogic(float deltaTime) {
        if (monkey.getState() != Monkey.State.BURNED) {
            return;
        }
        if (Gdx.input.isKeyPressed(Input.Keys.ENTER) || (Gdx.input.isKeyPressed(Input.Keys.SPACE))) {
            reinitTime = reinitMaxTime;
        }
        if (reinitTime < reinitMaxTime) {
           reinitTime += deltaTime * reinitTimeFactor;
           return;
        }

        monkey.reinit();
    }

    private void removeLive() {
        monkey.removeLive();
        reinitTime = 0;
        if (!monkey.hasLives()) {
            isGameOver = true;
            reinitTime = reinitMaxTime;
        }
    }

    private void fireLogic() {
        if (shouldDisplayMenu) {
            return;
        }

        if (monkey.getState() == Monkey.State.BURNED) {
            return;
        }

        if(monkey.getHitBounds().overlaps(fire.getBounds())){
            monkey.burn();
            dieSound.play();
            removeLive();
        }
    }

    private void bananasLogic() {
        if (shouldDisplayMenu) {
            return;
        }
        for (int i = bananaSprites.size - 1; i >= 0; i--) {
            checkIfMonkeyCollidesWithBanana(i);
        }
    }

    private void checkIfMonkeyCollidesWithBanana(int i) {
        Banana banana = bananaSprites.get(i);
        bananaRectangle.set(banana.getBounds());
        if (bananaRectangle.overlaps(monkey.getItemBounds())) {
            bananaSprites.removeIndex(i);
            pickUpBananaSound.play();
        }
    }

    private void draw() {
        ScreenUtils.clear(0.15f, 0.15f, 0.2f, 1f);
        viewport.apply();
        batch.setProjectionMatrix(viewport.getCamera().combined);

        batch.begin();
        drawAll();
        batch.end();
    }

    private void drawAll() {
        drawMenu();
        drawGame();
        drawGameOver();
    }

    private void drawGameOver() {
        if (!isGameOver) {
           return;
        }

        batch.end();
        uiBatch.begin();

        layout.setText(font, "GAME OVER");

        float x = (Gdx.graphics.getWidth() - layout.width) / 2f;
        float y = (Gdx.graphics.getHeight() + layout.height) / 2f;

        font.draw(uiBatch, layout, x, y);

        uiBatch.end();
        batch.begin();
    }

    private void drawMenu() {
        if (shouldDisplayMenu) {
            menu.draw(batch);
        }
    }

    private void drawGame() {
        if (shouldDisplayMenu) {
            return;
        }
        drawBackground();
        drawLives();
        drawMonkey();
        drawGameObjects();
    }

    private void drawBackground() {
        batch.draw(backgroundTexture, 0, 0, viewport.getWorldWidth(), viewport.getWorldHeight());
    }

    private void drawMonkey() {
        if (!monkey.hasLives()) {
            return;
        }
        monkey.draw(batch);

    }

    private void drawGameObjects() {
        fire.draw(batch);
        for (Banana banana: bananaSprites) {
            banana.draw(batch);
        }
    }

    private void drawLives() {
        for(int i = 0; i < monkey.getLives(); i++) {
            batch.draw(coreFullTexture, 1f + i,7.6f, 1f, 1f);
        }
        if (monkey.getLives() < 3) {
            for(int i = monkey.getLives(); i < monkey.maxLives; i++) {
                batch.draw(coreEmptyTexture, 1f + i,7.6f, 1f, 1f);
            }
        }
    }

    private void createBananas() {
        addBanana(7f, 3f);
        addBanana(9f, 3f);
        addBanana(11f, 5f);
    }

    private void addBanana(float x, float y) {
        bananaSprites.add(new Banana(bananaTexture, x, y));
    }

    @Override
    public void dispose() {
        batch.dispose();
        disposeTextures();
        disposeFonts();
        disposeSounds();
        disposeMusic();
    }

    private void disposeMusic() {
        music.dispose();
    }

    private void disposeTextures() {
        monkeyRunTexture.dispose();
        monkeyIdleTexture.dispose();
        monkeyBurnedTexture.dispose();
        bananaTexture.dispose();
        backgroundTexture.dispose();
        fireTexture.dispose();
        menuTexture.dispose();
        coreFullTexture.dispose();
        coreEmptyTexture.dispose();
    }

    private void disposeFonts() {
        font.dispose();
    }

    private void disposeSounds() {
        pickUpBananaSound.dispose();
        jumpSound.dispose();
        fallSound.dispose();
        dieSound.dispose();
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true);
    }
}
