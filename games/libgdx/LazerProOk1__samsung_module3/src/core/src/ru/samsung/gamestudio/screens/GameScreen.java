package ru.samsung.gamestudio.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.ScreenUtils;
import ru.samsung.gamestudio.*;
import ru.samsung.gamestudio.components.*;
import ru.samsung.gamestudio.managers.ContactManager;
import ru.samsung.gamestudio.managers.MemoryManager;
import ru.samsung.gamestudio.objects.BulletObject;
import ru.samsung.gamestudio.objects.PowerUpObject;
import ru.samsung.gamestudio.objects.ShipObject;
import ru.samsung.gamestudio.objects.TrashObject;

import java.util.ArrayList;
import java.util.Random;

public class GameScreen extends ScreenAdapter {

    MyGdxGame myGdxGame;
    GameSession gameSession;
    ShipObject shipObject;

    ArrayList<TrashObject> trashArray;
    ArrayList<BulletObject> bulletArray;
    ArrayList<PowerUpObject> powerUpArray;

    ContactManager contactManager;

    MovingBackgroundView backgroundView;
    ImageView topBlackoutView;
    LiveView liveView;
    TextView scoreTextView;
    TextView activeEffectsTextView;
    TextView dangerTextView;
    ButtonView pauseButton;

    ImageView fullBlackoutView;
    TextView pauseTextView;
    ButtonView homeButton;
    ButtonView continueButton;

    TextView recordsTextView;
    RecordsListView recordsListView;
    ButtonView homeButton2;

    private static final int DOUBLE_BULLET_OFFSET = 22;
    private final Random random = new Random();

    private float damageFlashAlpha;
    private float shakeIntensity;
    private float shipDamageTintAlpha;
    private Texture redFlashTexture;
    private int previousLives;
    private GlyphLayout tempLayout;

    public GameScreen(MyGdxGame myGdxGame) {
        this.myGdxGame = myGdxGame;
        gameSession = new GameSession();

        contactManager = new ContactManager(myGdxGame.world);

        trashArray = new ArrayList<>();
        bulletArray = new ArrayList<>();
        powerUpArray = new ArrayList<>();

        shipObject = new ShipObject(
                GameSettings.SCREEN_WIDTH / 2, 150,
                GameSettings.SHIP_WIDTH, GameSettings.SHIP_HEIGHT,
                GameResources.SHIP_IMG_PATH,
                myGdxGame.world
        );

        backgroundView = new MovingBackgroundView(GameResources.BACKGROUND_IMG_PATH);
        topBlackoutView = new ImageView(0, 1180, GameResources.BLACKOUT_TOP_IMG_PATH);
        liveView = new LiveView(305, 1215);
        scoreTextView = new TextView(myGdxGame.commonWhiteFont, 50, 1215);
        activeEffectsTextView = new TextView(myGdxGame.commonWhiteFont, 50, 1175, "");
        dangerTextView = new TextView(myGdxGame.commonWhiteFont, 490, 1175, "");
        pauseButton = new ButtonView(
                605, 1200,
                46, 54,
                GameResources.PAUSE_IMG_PATH
        );

        fullBlackoutView = new ImageView(0, 0, GameResources.BLACKOUT_FULL_IMG_PATH);
        pauseTextView = new TextView(myGdxGame.largeWhiteFont, 282, 842, "Пауза");
        homeButton = new ButtonView(
                138, 695,
                200, 70,
                myGdxGame.commonBlackFont,
                GameResources.BUTTON_SHORT_BG_IMG_PATH,
                "Главная"
        );
        continueButton = new ButtonView(
                393, 695,
                200, 70,
                myGdxGame.commonBlackFont,
                GameResources.BUTTON_SHORT_BG_IMG_PATH,
                "Продолжить"
        );

        recordsListView = new RecordsListView(myGdxGame.commonWhiteFont, 690);
        recordsTextView = new TextView(myGdxGame.largeWhiteFont, 206, 842, "Рекорды");
        homeButton2 = new ButtonView(
                280, 365,
                160, 70,
                myGdxGame.commonBlackFont,
                GameResources.BUTTON_SHORT_BG_IMG_PATH,
                "Главная"
        );

        Pixmap rp = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        rp.setColor(1f, 0.07f, 0.07f, 1f);
        rp.fill();
        redFlashTexture = new Texture(rp);
        rp.dispose();

        tempLayout = new GlyphLayout();
        previousLives = 3;
    }

    @Override
    public void show() {
        restartGame();
    }

    @Override
    public void render(float delta) {

        handleInput();

        damageFlashAlpha   = Math.max(0, damageFlashAlpha   - delta * 2.5f);
        shakeIntensity     = Math.max(0, shakeIntensity     - delta * 60f);
        shipDamageTintAlpha = Math.max(0, shipDamageTintAlpha - delta * 3f);

        if (gameSession.state == GameState.PLAYING) {
            if (gameSession.shouldSpawnTrash()) {
                trashArray.add(new TrashObject(
                        GameSettings.TRASH_WIDTH, GameSettings.TRASH_HEIGHT,
                        GameResources.TRASH_IMG_PATH,
                        myGdxGame.world
                ));
            }

            if (gameSession.shouldSpawnPowerUp()) {
                PowerUpType[] types = PowerUpType.values();
                powerUpArray.add(new PowerUpObject(types[random.nextInt(types.length)], myGdxGame.world));
            }

            if (shipObject.needToShoot()) {
                spawnBullets();
                if (myGdxGame.audioManager.isSoundOn) myGdxGame.audioManager.shootSound.play();
            }

            int currentLives = shipObject.getLiveLeft();
            if (currentLives < previousLives) {
                damageFlashAlpha    = 0.38f;
                shakeIntensity      = 9f;
                shipDamageTintAlpha = 0.65f;
            }
            previousLives = currentLives;

            if (!shipObject.isAlive()) {
                gameSession.endGame();
                recordsListView.setRecords(MemoryManager.loadRecordsTable());
            }

            updateTrash();
            updateBullets();
            updatePowerUps();
            backgroundView.move();
            gameSession.updateScore();
            scoreTextView.setText("Счёт: " + gameSession.getScore());
            liveView.setLeftLives(shipObject.getLiveLeft());
            updateEffectsHud();
            dangerTextView.setText("Ур." + gameSession.getDangerLevel());

            myGdxGame.stepWorld();
        }

        draw();
    }

    private void spawnBullets() {
        if (shipObject.isDoubleShotActive()) {
            bulletArray.add(createBullet(shipObject.getX() - DOUBLE_BULLET_OFFSET));
            bulletArray.add(createBullet(shipObject.getX() + DOUBLE_BULLET_OFFSET));
        } else {
            bulletArray.add(createBullet(shipObject.getX()));
        }
    }

    private BulletObject createBullet(int x) {
        return new BulletObject(
                x, shipObject.getY() + shipObject.height / 2,
                GameSettings.BULLET_WIDTH, GameSettings.BULLET_HEIGHT,
                GameResources.BULLET_IMG_PATH,
                myGdxGame.world
        );
    }

    private void updateEffectsHud() {
        StringBuilder effects = new StringBuilder();
        if (shipObject.hasShield()) effects.append("[ ЩИТ ] ");
        if (shipObject.isDoubleShotActive()) effects.append("[ x2 ]");
        activeEffectsTextView.setText(effects.toString().trim());
    }

    private void handleInput() {
        if (Gdx.input.isTouched()) {
            myGdxGame.touch = myGdxGame.camera.unproject(new Vector3(Gdx.input.getX(), Gdx.input.getY(), 0));

            if (gameSession.state == GameState.PLAYING) {
                if (pauseButton.isHit(myGdxGame.touch.x, myGdxGame.touch.y)) {
                    gameSession.pauseGame();
                }
                shipObject.move(myGdxGame.touch);
            } else if (gameSession.state == GameState.PAUSED) {
                if (continueButton.isHit(myGdxGame.touch.x, myGdxGame.touch.y)) {
                    gameSession.resumeGame();
                }
                if (homeButton.isHit(myGdxGame.touch.x, myGdxGame.touch.y)) {
                    myGdxGame.setScreen(myGdxGame.menuScreen);
                }
            } else if (gameSession.state == GameState.ENDED) {
                if (homeButton2.isHit(myGdxGame.touch.x, myGdxGame.touch.y)) {
                    myGdxGame.setScreen(myGdxGame.menuScreen);
                }
            }
        }
    }

    private void draw() {

        float shakeX = shakeIntensity > 0 ? (random.nextFloat() * 2 - 1) * shakeIntensity : 0;
        float shakeY = shakeIntensity > 0 ? (random.nextFloat() * 2 - 1) * shakeIntensity : 0;
        myGdxGame.camera.position.set(
                GameSettings.SCREEN_WIDTH / 2f + shakeX,
                GameSettings.SCREEN_HEIGHT / 2f + shakeY, 0);
        myGdxGame.camera.update();
        myGdxGame.batch.setProjectionMatrix(myGdxGame.camera.combined);
        ScreenUtils.clear(Color.CLEAR);

        myGdxGame.batch.begin();

        backgroundView.draw(myGdxGame.batch);

        for (TrashObject trash : trashArray) trash.draw(myGdxGame.batch);

        for (PowerUpObject powerUp : powerUpArray) {
            powerUp.draw(myGdxGame.batch);
            myGdxGame.commonWhiteFont.draw(myGdxGame.batch,
                    labelFor(powerUp.getType()),
                    powerUp.getX() - 18f,
                    powerUp.getY() + 10f);
        }

        if (shipDamageTintAlpha > 0) {
            myGdxGame.batch.setColor(1f, 1f - shipDamageTintAlpha * 0.75f, 1f - shipDamageTintAlpha * 0.75f, 1f);
        }
        shipObject.draw(myGdxGame.batch);
        myGdxGame.batch.setColor(1f, 1f, 1f, 1f);

        for (BulletObject bullet : bulletArray) bullet.draw(myGdxGame.batch);

        topBlackoutView.draw(myGdxGame.batch);
        scoreTextView.draw(myGdxGame.batch);
        liveView.draw(myGdxGame.batch);
        dangerTextView.draw(myGdxGame.batch);
        if (!activeEffectsTextView.getText().isEmpty()) activeEffectsTextView.draw(myGdxGame.batch);
        pauseButton.draw(myGdxGame.batch);

        if (gameSession.state == GameState.PLAYING && gameSession.isComboActive()) {
            String comboText = "КОМБО x" + gameSession.getComboCount() + "!";
            tempLayout.setText(myGdxGame.largeWhiteFont, comboText);
            myGdxGame.largeWhiteFont.draw(myGdxGame.batch, comboText,
                    (GameSettings.SCREEN_WIDTH - tempLayout.width) / 2f,
                    680 + tempLayout.height);
        }

        if (damageFlashAlpha > 0) {
            myGdxGame.batch.setColor(1f, 0.07f, 0.07f, damageFlashAlpha);
            myGdxGame.batch.draw(redFlashTexture, 0, 0, GameSettings.SCREEN_WIDTH, GameSettings.SCREEN_HEIGHT);
            myGdxGame.batch.setColor(1f, 1f, 1f, 1f);
        }

        if (gameSession.state == GameState.PAUSED) {
            fullBlackoutView.draw(myGdxGame.batch);
            pauseTextView.draw(myGdxGame.batch);
            homeButton.draw(myGdxGame.batch);
            continueButton.draw(myGdxGame.batch);
        } else if (gameSession.state == GameState.ENDED) {
            fullBlackoutView.draw(myGdxGame.batch);
            recordsTextView.draw(myGdxGame.batch);
            recordsListView.draw(myGdxGame.batch);
            homeButton2.draw(myGdxGame.batch);
        }

        myGdxGame.batch.end();
    }

    private String labelFor(PowerUpType type) {
        if (type == PowerUpType.SHIELD)      return "ЩИТ";
        if (type == PowerUpType.DOUBLE_SHOT) return "x2";
        return "БОМ";
    }

    private void updateTrash() {
        for (int i = 0; i < trashArray.size(); i++) {
            boolean alive   = trashArray.get(i).isAlive();
            boolean inFrame = trashArray.get(i).isInFrame();

            if (!alive) {
                gameSession.destructionRegistration();
                if (myGdxGame.audioManager.isSoundOn) myGdxGame.audioManager.explosionSound.play(0.2f);
            }

            if (!alive || !inFrame) {
                myGdxGame.world.destroyBody(trashArray.get(i).body);
                trashArray.remove(i--);
            }
        }
    }

    private void updateBullets() {
        for (int i = 0; i < bulletArray.size(); i++) {
            if (bulletArray.get(i).hasToBeDestroyed()) {
                myGdxGame.world.destroyBody(bulletArray.get(i).body);
                bulletArray.remove(i--);
            }
        }
    }

    private void updatePowerUps() {
        for (int i = 0; i < powerUpArray.size(); i++) {
            PowerUpObject powerUp = powerUpArray.get(i);
            if (powerUp.hasToBeDestroyed()) {
                if (powerUp.wasCollected()) {
                    applyPowerUp(powerUp.getType());
                }
                myGdxGame.world.destroyBody(powerUp.body);
                powerUpArray.remove(i--);
            }
        }
    }

    private void applyPowerUp(PowerUpType type) {
        if (myGdxGame.audioManager.isSoundOn) myGdxGame.audioManager.shootSound.play(1.0f);
        if (type == PowerUpType.SHIELD) {
            shipObject.activateShield();
        } else if (type == PowerUpType.DOUBLE_SHOT) {
            shipObject.activateDoubleShot();
        } else if (type == PowerUpType.BOMB) {
            destroyAllTrash();
            shakeIntensity = 20f;
        }
    }

    private void destroyAllTrash() {
        for (int i = 0; i < trashArray.size(); i++) {
            gameSession.destructionRegistration();
            myGdxGame.world.destroyBody(trashArray.get(i).body);
            trashArray.remove(i--);
        }
        if (myGdxGame.audioManager.isSoundOn) myGdxGame.audioManager.explosionSound.play(1.0f);
    }

    private void restartGame() {

        for (int i = 0; i < trashArray.size(); i++) {
            myGdxGame.world.destroyBody(trashArray.get(i).body);
            trashArray.remove(i--);
        }

        for (int i = 0; i < bulletArray.size(); i++) {
            myGdxGame.world.destroyBody(bulletArray.get(i).body);
            bulletArray.remove(i--);
        }

        for (int i = 0; i < powerUpArray.size(); i++) {
            myGdxGame.world.destroyBody(powerUpArray.get(i).body);
            powerUpArray.remove(i--);
        }

        if (shipObject != null) {
            myGdxGame.world.destroyBody(shipObject.body);
        }

        shipObject = new ShipObject(
                GameSettings.SCREEN_WIDTH / 2, 150,
                GameSettings.SHIP_WIDTH, GameSettings.SHIP_HEIGHT,
                GameResources.SHIP_IMG_PATH,
                myGdxGame.world
        );

        damageFlashAlpha    = 0;
        shakeIntensity      = 0;
        shipDamageTintAlpha = 0;
        previousLives       = 3;

        gameSession.startGame();
    }
}
