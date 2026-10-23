import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Screen;

import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Json;


public class GameScreen implements Screen {
    GameConfig config;
    private final Jgame game;
    private BitmapFont font;
    private Player player;
    private Sound shootSound;
    private Sound popSound;
    private Sound woodSound;
    private Texture bulletTex;
    private Texture enemyTex;
    private Texture bloodTex;
    private Texture heartTex;
    private Texture heartEmptyTex;
    private GameTickManager.TickTimer shootCooldown;
    private GameTickManager.TickTimer hitCooldown;
    private GameTickManager.TickTimer slowdownTimer;
    private GameTickManager.TickTimer deathTimer;
    private float renk1;
    private float renk2;
    private float renk3;

    private Array<Bullet> bullets = new Array<>();
    private Array<Enemy> enemies = new Array<>();
    private Array<BloodParticle> bloods = new Array<>();
    private int lastSpawnTick = 0;
    private float baseSpawnInterval = 1.0f;
    private float minSpawnInterval = 0.1f;
    private int shootCooldownTicks = 16;
    private int hitCooldownTicks = 16;
    private int slowdownTicks = 40;
    private int deathDelayTicks = 20;
    private int score = 0;
    private boolean isSlowed = false;
    private boolean deathTimerStarted = false;
    private int fpsTickCounter = 0;
    private SpriteBatch batch = new SpriteBatch();
    private GameTickManager tickManager = new GameTickManager();

    private boolean switchingScreen = false;

    public GameScreen(Jgame game) {
        this.game = game;
        this.renk1 = game.renk1;
        this.renk2 = game.renk2;
        this.renk3 = game.renk3;
        this.font = game.font;
        this.tickManager.addListener(new GameTickManager.TickListener() { // from class: GameScreen.1
            @Override // GameTickManager.TickListener
            public void onTick(int currentTick) {
                GameScreen.this.handleTick(currentTick);
            }
        });
        this.shootCooldown = new GameTickManager.TickTimer(this.shootCooldownTicks);
        this.hitCooldown = new GameTickManager.TickTimer(this.hitCooldownTicks);
        this.slowdownTimer = new GameTickManager.TickTimer(this.slowdownTicks);
        this.deathTimer = new GameTickManager.TickTimer(this.deathDelayTicks);
        loadAssets();
        loadConfig();
        spawnPlayer();
    }

    private void loadAssets() {
        this.shootSound = Assets.getSound(Assets.Sounds.SHOOT);
        this.popSound = Assets.getSound(Assets.Sounds.POP);
        this.woodSound = Assets.getSound(Assets.Sounds.WOOD);
        this.bulletTex = Assets.getTexture(Assets.Textures.BULLET);
        this.enemyTex = Assets.getTexture(Assets.Textures.ENEMY);
        this.bloodTex = Assets.getTexture(Assets.Textures.BLOOD);
        this.heartTex = Assets.getTexture(Assets.Textures.HEART);
        this.heartEmptyTex = Assets.getTexture(Assets.Textures.HEART_EMPTY);
    }

    private void loadConfig() {
        Json json = new Json();
        this.config = (GameConfig) json.fromJson(GameConfig.class, Gdx.files.internal("config.json"));

    }

    private void spawnPlayer() {
        int width = Gdx.graphics.getWidth();
        int height = Gdx.graphics.getHeight();
        float x = this.game.rnd.nextInt(width - 200) + 100;
        float y = this.game.rnd.nextInt(height - 200) + 100;
        Texture playerTex = Assets.getTexture(Assets.Textures.PLAYER);
        Assets.getTexture(Assets.Textures.GUN);
        this.player = new Player(x, y, playerTex, 0);
        this.player = new Player(x, y, playerTex, 0);
        this.player.setHitCooldown(this.hitCooldown);
        this.player.setWeapon(new Weapons(Weapons.WeaponType.PISTOL));
        this.player.setHitCooldown(this.hitCooldown);
    }

    private void handleTick(int currentTick) {
        this.fpsTickCounter++;
        if (this.fpsTickCounter >= 20) {
            System.out.println("FPS: " + Gdx.graphics.getFramesPerSecond());
            this.fpsTickCounter = 0;
        }
        handleEnemySpawn(currentTick);
        checkAndStopTimers(currentTick);
    }

    private void checkAndStopTimers(int currentTick) {
        if (this.deathTimer.isRunning() && this.deathTimer.isFinished(currentTick)) {
            this.deathTimer.stop();
            this.switchingScreen = true;
            this.game.setScreen(new DeathScreen(this.game, this.score));
            dispose();
            return;
        }
        if (this.slowdownTimer.isRunning() && this.slowdownTimer.isFinished(currentTick)) {
            this.player.resetSpeed();
            this.isSlowed = false;
            this.slowdownTimer.stop();
        }
        if (this.shootCooldown.isRunning() && this.shootCooldown.isFinished(currentTick)) {
            this.shootCooldown.stop();
        }
        if (this.hitCooldown.isRunning() && this.hitCooldown.isFinished(currentTick)) {
            this.hitCooldown.stop();
        }
    }

    private void spawnEnemy() {
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        boolean left = Math.random() < 0.5d;
        float spawnY = (float) (Math.random() * ((double) h));
        float spawnX = left ? -40.0f : w + 40.0f;
        this.enemies.add(new Enemy(spawnX, spawnY));
    }

    private void handleEnemySpawn(int currentTick) {
        float currentSpawnInterval = Math.max(this.minSpawnInterval, this.baseSpawnInterval - (this.score * 0.1f));
        int spawnIntervalTicks = (int) (currentSpawnInterval * 20.0f);
        if (this.tickManager.hasTicksPassed(this.lastSpawnTick, spawnIntervalTicks)) {
            spawnEnemy();
            this.lastSpawnTick = currentTick;
        }
    }

    @Override
    public void render(float delta) {
        this.tickManager.update(delta);
        if (this.switchingScreen) {
            return;
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            this.game.setScreen(new PauseScreen(this.game, this));
            return;
        }
        if (Gdx.input.isKeyPressed(45)) {
            Gdx.app.exit();
        }
        this.player.update(delta);
        handleShooting();
        updateBloodParticles(delta);
        updateBullets(delta);
        updateEnemies(delta);
        handleCollisions();
        cleanupDeadObjects();
        renderGame();
    }

    private void handleShooting() {
        Weapons w;
        boolean zIsButtonJustPressed;
        if (this.player.dead || (w = this.player.getWeapon()) == null) {
            return;
        }
        if (w.isAutomatic()) {
            zIsButtonJustPressed = Gdx.input.isButtonPressed(0);
        } else {
            zIsButtonJustPressed = Gdx.input.isButtonJustPressed(0);
        }
        boolean shootInput = zIsButtonJustPressed;
        if (shootInput && !this.shootCooldown.isRunning()) {
            float baseAngle = this.player.getAngleToMouse();
            for (int i = 0; i < w.getBulletCount(); i++) {
                float spread = MathUtils.random(-w.getBulletSpread(), w.getBulletSpread());
                this.bullets.add(new Bullet(this.player.getCenterX(), this.player.getCenterY(), baseAngle + spread));
            }
            this.shootSound.play(0.7f);
            this.shootCooldown = new GameTickManager.TickTimer(w.getFireRateTicks());
            this.shootCooldown.start(this.tickManager.getCurrentTick());
        }
    }

    private void updateBloodParticles(float delta) {
        Array.ArrayIterator<BloodParticle> it = this.bloods.iterator();
        while (it.hasNext()) {
            BloodParticle blood = it.next();
            blood.update(delta);
        }
    }

    private void updateBullets(float delta) {
        Array.ArrayIterator<Bullet> it = this.bullets.iterator();
        while (it.hasNext()) {
            Bullet b = it.next();
            b.update(delta);
        }
    }

    private void updateEnemies(float delta) {
        Array.ArrayIterator<Enemy> it = this.enemies.iterator();
        while (it.hasNext()) {
            Enemy e = it.next();
            e.update(delta, this.player.x, this.player.y);
        }
    }

    private void handleCollisions() {
        handleBulletEnemyCollision();
        handlePlayerEnemyCollision();
        handlePlayerBloodCollision();
    }

    private void handleBulletEnemyCollision() {
        Array.ArrayIterator<Enemy> it = this.enemies.iterator();
        while (it.hasNext()) {
            Enemy e = it.next();
            Array.ArrayIterator<Bullet> it2 = this.bullets.iterator();
            while (it2.hasNext()) {
                Bullet b = it2.next();
                if (!e.dead) {
                    float dist = Vector2.dst(e.x + 32.0f, e.y + 32.0f, b.x + 4.0f, b.y + 4.0f);
                    if (dist < 32.0f + 4.0f) {
                        for (int i = 0; i < 8; i++) {
                            this.bloods.add(new BloodParticle(e.x + 32.0f, e.y + 32.0f, this.bloodTex));
                        }
                        this.popSound.play(0.7f);
                        this.score++;
                        e.dead = true;
                    }
                }
            }
        }
    }

    private void handlePlayerEnemyCollision() {
        if (this.player.dead || this.hitCooldown.isRunning()) {
            return;
        }
        Array.ArrayIterator<Enemy> it = this.enemies.iterator();
        while (it.hasNext()) {
            Enemy e = it.next();
            if (!e.dead) {
                float dist = Vector2.dst(e.x + 32.0f, e.y + 32.0f, this.player.getCenterX(), this.player.getCenterY());
                if (dist < 32.0f * 2.0f) {
                    for (int i = 0; i < 50; i++) {
                        this.bloods.add(new BloodParticle(this.player.x + 32.0f, this.player.y + 32.0f, this.bloodTex));
                    }
                    this.player.damage(1);
                    this.woodSound.play(0.9f);
                    this.hitCooldown.start(this.tickManager.getCurrentTick());
                    if (this.player.dead && !this.deathTimerStarted) {
                        this.deathTimerStarted = true;
                        this.deathTimer.start(this.tickManager.getCurrentTick());
                        return;
                    }
                    return;
                }
            }
        }
    }

    private void handlePlayerBloodCollision() {
        if (this.player.dead || this.hitCooldown.isRunning()) {
            return;
        }
        Array.ArrayIterator<BloodParticle> it = this.bloods.iterator();
        while (it.hasNext()) {
            BloodParticle b = it.next();
            if (!b.dead) {
                float dist = Vector2.dst(b.x + 4.0f, b.y + 4.0f, this.player.getCenterX(), this.player.getCenterY());
                if (dist < 4.0f + 32.0f) {
                    this.isSlowed = true;
                    this.slowdownTimer.start(this.tickManager.getCurrentTick());
                    this.player.slowDown(300.0f);
                    b.dead = true;
                    this.popSound.play(0.3f);
                }
            }
        }
    }

    private void cleanupDeadObjects() {
        for (int i = this.enemies.size - 1; i >= 0; i--) {
            if (this.enemies.get(i).dead) {
                this.enemies.removeIndex(i);
            }
        }
        for (int i2 = this.bullets.size - 1; i2 >= 0; i2--) {
            if (this.bullets.get(i2).dead) {
                this.bullets.removeIndex(i2);
            }
        }
        for (int i3 = this.bloods.size - 1; i3 >= 0; i3--) {
            if (this.bloods.get(i3).dead) {
                this.bloods.removeIndex(i3);
            }
        }
    }

    private void renderGame() {
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        Gdx.gl.glClearColor(this.renk1, this.renk2, this.renk3, 1.0f);
        Gdx.gl.glClear(16384);
        this.batch.begin();
        renderUI(w, h);
        renderHearts(w, h);
        this.player.draw(this.batch);
        Array.ArrayIterator<Bullet> it = this.bullets.iterator();
        while (it.hasNext()) {
            Bullet b = it.next();
            this.batch.draw(this.bulletTex, b.x, b.y);
        }
        Array.ArrayIterator<Enemy> it2 = this.enemies.iterator();
        while (it2.hasNext()) {
            Enemy e = it2.next();
            this.batch.draw(this.enemyTex, e.x, e.y);
        }
        Array.ArrayIterator<BloodParticle> it3 = this.bloods.iterator();
        while (it3.hasNext()) {
            BloodParticle blood = it3.next();
            this.batch.draw(this.bloodTex, blood.x, blood.y);
        }
        this.player.drawGun(this.batch);
        this.batch.end();
    }

    private void renderUI(float w, float h) {
        this.font.setColor(Color.WHITE);
        if (this.isSlowed) {
            this.font.getData().setScale(0.8f);
            float remaining = this.slowdownTimer.getRemainingSeconds(this.tickManager.getCurrentTick());
            this.font.draw(this.batch, "Slowed Down! " + String.format("%.1f", Float.valueOf(remaining)), 512.0f, h - 20.0f);
            this.font.getData().setScale(1.0f);
        }
        this.font.getData().setScale(0.6f);

        this.font.getData().setScale(0.9f);
        this.font.draw(this.batch, "Score " + this.score, 512.0f, h - 730.0f);
        this.font.getData().setScale(1.0f);
    }

    private void renderHearts(float w, float h) {
        float startY = h - 58.0f;
        int i = 0;
        while (i < 3) {
            Texture heart = i < this.player.getHp() ? this.heartTex : this.heartEmptyTex;
            this.batch.draw(heart, 20.0f + (i * (64.0f + 5.0f)), startY, 64.0f, 64.0f);
            i++;
        }
    }

    @Override // com.badlogic.gdx.Screen
    public void show() {
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
    }

    @Override // com.badlogic.gdx.Screen, com.badlogic.gdx.utils.Disposable
    public void dispose() {
        this.batch.dispose();
    }
}