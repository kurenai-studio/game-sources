package com.elmagica.game;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.viewport.FitViewport;

public class ElMagicaGame extends ApplicationAdapter {
    public static final int TILE_SIZE = 64;
    public static final String VERSION_LABEL = "Build Beta1.0 (Endless Play/Mechanics Test)";
    public static final String AUTHOR_LABEL = "Created by: SA_Ton_";
    public static final String THANKS_LABEL = "Thanks to: OpenAI Codex (GPT-6.1 Sol)";
    public static final int GRID_COLUMNS = 30;
    public static final int GRID_ROWS = 17;
    public static final int WORLD_WIDTH = GRID_COLUMNS * TILE_SIZE;
    public static final int WORLD_HEIGHT = GRID_ROWS * TILE_SIZE;
    private ShapeRenderer shapes;
    private SpriteBatch textBatch;
    private BitmapFont font;
    private GameSprites sprites;
    private FitViewport viewport;
    private FitViewport uiViewport;
    private Player player;
    private final CombatSession session = new CombatSession();
    private final Array<Projectile> projectiles = new Array<>();
    private final Array<Enemy> enemies = new Array<>();
    private final Array<SpellImpact> impacts = new Array<>();
    private final Vector2 cursor = new Vector2();
    private boolean settingsOpen;
    private boolean pauseMenuOpen;
    private boolean endSessionPrompt;
    private boolean showParameters = true;
    private float hudScale = 1;
    private final Matrix4 hudTransform = new Matrix4();
    private Preferences preferences;
    private enum MenuPage { MAIN, ELEMENTS, CONTROLS, MECHANICS }
    private MenuPage menuPage = MenuPage.MAIN;
    private int mechanicsPage;
    private MenuGuide guide;
    private MenuCover cover;
    private RoomArt roomArt;
    private RoomDecor roomDecor;
    private MerchantArt merchantArt;
    private GameAudio audio;
    private CombatText combatText;
    private final RoomScene roomScene = new RoomScene();
    private float pickupTimer;

    @Override
    public void create() {
        shapes = new ShapeRenderer();
        textBatch = new SpriteBatch();
        font = PixelText.createFont();
        sprites = new GameSprites();
        roomArt = new RoomArt();
        roomDecor = new RoomDecor();
        merchantArt = new MerchantArt();
        cover = new MenuCover(shapes, textBatch, font);
        guide = new MenuGuide(shapes, textBatch, font, cover);
        viewport = new FitViewport(WORLD_WIDTH, WORLD_HEIGHT);
        viewport.update(Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), true);
        uiViewport = new FitViewport(1280, 720);
        uiViewport.update(Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), true);
        preferences = Gdx.app.getPreferences("ElMagica-settings");
        showParameters = preferences.getBoolean("showParameters", true);
        hudScale = MathUtils.clamp(preferences.getFloat("hudScale", 1), 0.75f, 1.25f);
        GameText.english = preferences.getString("language", "ru").equals("en");
        audio = new GameAudio();
        combatText = new CombatText();
        audio.setVolumes(preferences.getFloat("musicVolume", 0.35f), preferences.getFloat("effectsVolume", 0.65f));
    }

    @Override
    public void resize(int width, int height) {
        // Не растягиваем клетки при смене размера окна.
        viewport.update(width, height, true);
        uiViewport.update(width, height, true);
    }

    @Override
    public void render() {
        cursor.set(Gdx.input.getX(), Gdx.input.getY());
        uiViewport.unproject(cursor);
        boolean menuAction = handleInterface();
        if (menuAction && (Gdx.input.isButtonJustPressed(Input.Buttons.LEFT) || Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE))) GameAudio.play(GameAudio.Cue.CLICK);
        if (player != null && player.isAlive() && !settingsOpen && !pauseMenuOpen && session.getReward() == null && !menuAction) {
            updateCombat(Gdx.graphics.getDeltaTime());
        }
        audio.update(GameAudio.trackFor(player != null && player.isAlive(), session.merchant != null,
            session.getWave() > 0 && session.getWave() % CombatSession.BOSS_INTERVAL == 0 && !session.isExitOpen()));
        if (player != null && !pauseMenuOpen && !settingsOpen && session.getReward() == null) combatText.update(Gdx.graphics.getDeltaTime());
        cursor.set(Gdx.input.getX(), Gdx.input.getY());
        uiViewport.unproject(cursor);

        Gdx.gl.glClearColor(0.12f, 0.12f, 0.14f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        applyViewport(player == null ? uiViewport : viewport);
        if (player == null) {
            drawMenuBackground();
            if (menuPage == MenuPage.MAIN) drawMainMenu();
            if (menuPage == MenuPage.ELEMENTS) drawSelection();
            if (menuPage == MenuPage.CONTROLS) guide.drawControls();
            if (menuPage == MenuPage.MECHANICS) guide.drawMechanics(mechanicsPage);
            if (menuPage == MenuPage.CONTROLS || menuPage == MenuPage.MECHANICS) {
                drawButton("Назад", 500, 44, 280, 44, false);
            }
        }
        else {
            drawCombat();
            applyViewport(uiViewport);
            drawTowerHud();
            scaleHud(640, 32);
            if (session.merchant != null) drawMerchantHud();
            if (session.merchant == null && player.isAlive() && pickupTimer > 0 && session.pickupReward != null) drawPickupNotice();
            resetHudTransform();
            if (!player.isAlive()) drawGameOver();
        }
        if (!settingsOpen && !pauseMenuOpen && player != null && player.isAlive() && session.getReward() == null) {
            scaleHud(1256, 688);
            drawSettingsButton(1060, 660, 196, 28);
            resetHudTransform();
        }
        if (pauseMenuOpen && !settingsOpen) drawPauseMenu();
        if (settingsOpen) drawSettings();
        if (endSessionPrompt) drawEndSessionPrompt();
        if (session.getReward() != null) drawReward();
    }

    private boolean clicked(float x, float y, float width, float height) {
        return Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)
            && cursor.x >= x && cursor.x <= x + width && cursor.y >= y && cursor.y <= y + height;
    }

    private void applyViewport(FitViewport target) {
        target.apply();
        shapes.setProjectionMatrix(target.getCamera().combined);
        textBatch.setProjectionMatrix(target.getCamera().combined);
    }

    private void drawTowerHud() {
        scaleHud(28, 694);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        cover.panel(28, 650, 260, 40);
        cover.panel(28, 600, 260, 40);
        shapes.end();
        textBatch.begin();
        drawText("Этаж " + session.getWave(), 44, 677, 2, new Color(1, 0.91f, 0.70f, 1));
        drawText("Монеты: " + session.getCoins(), 44, 627, 2, new Color(1, 0.91f, 0.70f, 1));
        textBatch.end();
        resetHudTransform();
        if (session.isExitOpen() && player.isAlive()) {
            drawFloorBanner();
        }
        resetHudTransform();
        for (Enemy enemy : enemies) {
            if (!enemy.isAlive() || !enemy.isBoss()) continue;
            // Оставляем место под счётчики, даже когда ХУД увеличен.
            float left = 28 + 260 * hudScale + 16;
            float right = 1256 - 196 * hudScale - 16;
            float center = (left + right) / 2;
            float width = Math.min(600, (right - left) / hudScale);
            float x = center - width / 2;
            scaleHud(center, 694);
            shapes.begin(ShapeRenderer.ShapeType.Filled);
            cover.panel(x, 650, width, 44);
            drawHealthBar(x + 22, 658, width - 44, enemy.getHp(), enemy.getMaxHp());
            shapes.end();
            textBatch.begin();
            drawCenteredText(enemy.getLabel(), center, 688, GameText.tr(enemy.getLabel()).length() * 12 > width - 24 ? 1 : 2, new Color(1, 0.91f, 0.70f, 1));
            textBatch.end();
            resetHudTransform();
        }
        resetHudTransform();
    }

    private void drawFloorBanner() {
        float left = 28 + 260 * hudScale + 16;
        float right = 1256 - 196 * hudScale - 16;
        float center = uiViewport.getWorldWidth() / 2;
        float width = Math.min(480, 2 * Math.min(center - left, right - center) / hudScale);
        float x = center - width / 2;
        scaleHud(center, 694);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        cover.panel(x, 658, width, 36);
        shapes.setColor(0.88f, 0.65f, 0.32f, 1);
        if (session.merchant == null) {
            shapes.rect(x + 20, 668, 4, 10);
            shapes.triangle(x + 15, 676, x + 29, 676, x + 22, 683);
        } else {
            shapes.rect(x + 16, 670, 12, 12);
            shapes.setColor(1, 0.91f, 0.7f, 1);
            shapes.rect(x + 20, 673, 4, 6);
        }
        shapes.setColor(0.88f, 0.65f, 0.32f, 1);
        shapes.triangle(x + width - 24, 676, x + width - 18, 682, x + width - 12, 676);
        shapes.triangle(x + width - 24, 676, x + width - 18, 670, x + width - 12, 676);
        shapes.end();
        textBatch.begin();
        String label = session.merchant == null ? "Этаж пройден. Выход наверху" : "Этаж с торговцем, проход открыт";
        drawCenteredText(label, center + 1, 681, 2, new Color(0.02f, 0.015f, 0.04f, 1));
        drawCenteredText(label, center, 683, 2, new Color(1, 0.91f, 0.7f, 1));
        textBatch.end();
        resetHudTransform();
    }

    private void scaleHud(float anchorX, float anchorY) {
        // Масштабируем от края, чтобы панель не вылезала за экран.
        hudTransform.idt().translate(anchorX, anchorY, 0).scale(hudScale, hudScale, 1).translate(-anchorX, -anchorY, 0);
        shapes.setTransformMatrix(hudTransform);
        textBatch.setTransformMatrix(hudTransform);
    }
    private void resetHudTransform() {
        hudTransform.idt();
        shapes.setTransformMatrix(hudTransform);
        textBatch.setTransformMatrix(hudTransform);
    }
    private void changeHudScale(float change) {
        hudScale = MathUtils.clamp(Math.round((hudScale + change) * 100) / 100f, 0.75f, 1.25f);
        saveSettings();
    }
    private boolean hudMenuHover() {
        return cursor.x >= 1256 - 196 * hudScale && cursor.x <= 1256
            && cursor.y >= 688 - 28 * hudScale && cursor.y <= 688;
    }

    private void drawMerchantHud() {
        Merchant merchant = session.merchant;
        int target = merchant.nearest(player);
        String hint = "Подойди к товару или торговцу и нажми E";
        if (target == 3) hint = "E — поговорить с торговцем";
        if (target >= 0 && target < 3) {
            MerchantItem item = merchant.items[target];
            hint = item.sold ? "Продано" : item.description(player) + "  /  E — купить за " + item.price(player, session.getDifficulty());
            if (!item.sold && !item.available(player)) hint = "Этот параметр уже на пределе";
        }
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        cover.panel(280, 32, 720, 54);
        if (!merchant.getMessage().isEmpty()) cover.panel(280, 96, 720, 92);
        shapes.end();
        textBatch.begin();
        drawCenteredText(hint, 640, 65, 1, Color.GOLD);
        // Длинные советы переносим по словам.
        String line = ""; float y = 170;
        for (String word : merchant.getMessage().split(" ")) {
            if (line.length() + word.length() > 54) {
                drawCenteredText(line, 640, y, 2, Color.WHITE); y -= 24; line = "";
            }
            line += (line.isEmpty() ? "" : " ") + word;
        }
        if (!line.isEmpty()) drawCenteredText(line, 640, y, 2, Color.WHITE);
        textBatch.end();
    }

    private void drawEndSessionPrompt() {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0, 0, 0, 0.75f);
        shapes.rect(0, 0, 1280, 720);
        cover.panel(350, 248, 580, 228);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        cover.heading("Сдался или устал?", 434);
        textBatch.begin();
        drawCenteredText("Прогресс этого захода будет потерян", 640, 380, 2, Color.LIGHT_GRAY);
        textBatch.end();
        boolean yes = cursor.x >= 410 && cursor.x <= 630 && cursor.y >= 284 && cursor.y <= 332;
        boolean no = cursor.x >= 650 && cursor.x <= 870 && cursor.y >= 284 && cursor.y <= 332;
        cover.drawButton("Закончить", 410, 284, 220, 48, false, yes);
        cover.drawButton("Продолжить", 650, 284, 220, 48, true, no);
    }

    private boolean handleInterface() {
        if (endSessionPrompt) {
            if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE) || clicked(650, 284, 220, 48)) endSessionPrompt = false;
            if (clicked(410, 284, 220, 48)) resetSession();
            return true;
        }
        if (session.getReward() != null) {
            if (clicked(460, 220, 360, 56)) session.acceptReward();
            return true;
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            if (settingsOpen) settingsOpen = false;
            else if (player != null && player.isAlive()) pauseMenuOpen = !pauseMenuOpen;
            else if (player == null && menuPage != MenuPage.MAIN) menuPage = MenuPage.MAIN;
            else resetSession();
            return true;
        }
        if (settingsOpen) {
            if (clicked(410, 556, 72, 44)) changeVolume(true, -0.1f);
            if (clicked(798, 556, 72, 44)) changeVolume(true, 0.1f);
            if (clicked(410, 476, 72, 44)) changeVolume(false, -0.1f);
            if (clicked(798, 476, 72, 44)) changeVolume(false, 0.1f);
            if (clicked(410, 184, 460, 40)) {
                GameText.english = !GameText.english;
                saveSettings();
            }
            if (clicked(410, 350, 460, 60)) {
                showParameters = !showParameters;
                saveSettings();
            }
            if (clicked(410, 292, 72, 44)) changeHudScale(-0.05f);
            if (clicked(798, 292, 72, 44)) changeHudScale(0.05f);
            if (clicked(500, 238, 280, 48)) settingsOpen = false;
            return true;
        }
        if (pauseMenuOpen) {
            if (clicked(480, 400, 320, 52)) settingsOpen = true;
            if (clicked(480, 324, 320, 52)) endSessionPrompt = true;
            if (clicked(480, 248, 320, 52)) requestExit();
            if (clicked(480, 172, 320, 52)) pauseMenuOpen = false;
            return true;
        }
        if (player != null && player.isAlive() && session.merchant != null && Gdx.input.isKeyJustPressed(Input.Keys.E)) {
            session.merchant.interact(player, session);
            return true;
        }
        if (player != null && player.isAlive() && hudMenuHover() && Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)) {
            pauseMenuOpen = true;
            return true;
        }
        if (player == null && menuPage == MenuPage.MAIN && clicked(480, 198, 320, 52)) {
            settingsOpen = true;
            return true;
        }
        if (player == null) {
            if (menuPage == MenuPage.MAIN) {
                if (clicked(480, 122, 320, 52)) requestExit();
                if (clicked(480, 438, 320, 64)) menuPage = MenuPage.ELEMENTS;
                if (clicked(480, 358, 320, 52)) menuPage = MenuPage.CONTROLS;
                if (clicked(480, 278, 320, 52)) { menuPage = MenuPage.MECHANICS; mechanicsPage = 0; }
                return true;
            }
            if (menuPage == MenuPage.CONTROLS || menuPage == MenuPage.MECHANICS) {
                if (clicked(500, 44, 280, 44)) menuPage = MenuPage.MAIN;
                if (menuPage == MenuPage.MECHANICS) {
                    for (int i = 0; i < MenuGuide.PAGE_COUNT; i++) {
                        if (clicked(84 + i * MenuGuide.TAB_STEP, 560, MenuGuide.TAB_WIDTH, 42)) mechanicsPage = i;
                    }
                }
                return true;
            }
            if (clicked(500, 198, 280, 48)) { menuPage = MenuPage.MAIN; return true; }
            for (int i = 0; i < 4; i++) {
                if (clicked(148 + i * 252, 270, 220, 240)
                    || Gdx.input.isKeyJustPressed(Input.Keys.NUM_1 + i)
                    || Gdx.input.isKeyJustPressed(Input.Keys.NUMPAD_1 + i)) {
                    startSession(DamageSystem.PLAYER_ELEMENTS[i]);
                    return true;
                }
            }
        } else if (!player.isAlive() && clicked(490, 276, 300, 40)) {
            resetSession();
            return true;
        }
        return false;
    }

    protected void saveSettings() {
        preferences.putBoolean("showParameters", showParameters);
        preferences.putFloat("hudScale", hudScale);
        preferences.putString("language", GameText.english ? "en" : "ru");
        preferences.putFloat("musicVolume", audio.getMusicVolume());
        preferences.putFloat("effectsVolume", audio.getEffectsVolume());
        preferences.flush();
    }
    private void changeVolume(boolean music, float change) {
        float musicVolume = audio.getMusicVolume(), effectsVolume = audio.getEffectsVolume();
        if (music) musicVolume = Math.round((musicVolume + change) * 100) / 100f;
        else effectsVolume = Math.round((effectsVolume + change) * 100) / 100f;
        audio.setVolumes(musicVolume, effectsVolume);
        saveSettings();
    }

    protected void requestExit() {
        // LibGDX сам завершит цикл и вызовет dispose.
        Gdx.app.exit();
    }

    private void startSession(ElementType element) {
        resetSession();
        player = new Player(element);
        roomArt.newRoom();
        session.updateWaves(0, player, enemies);
    }

    private void resetSession() {
        combatText.clear();
        player = null;
        menuPage = MenuPage.MAIN;
        settingsOpen = false;
        pauseMenuOpen = false;
        endSessionPrompt = false;
        pickupTimer = 0;
        projectiles.clear();
        impacts.clear();
        clearBossAttacks();
        enemies.clear();
        session.reset();
    }

    private void updateCombat(float delta) {
        player.floorCleared = session.isExitOpen() && session.merchant == null;
        player.updateShooting(delta);
        for (int i = impacts.size - 1; i >= 0; i--) {
            impacts.get(i).update(delta);
            if (impacts.get(i).isFinished()) impacts.removeIndex(i);
        }
        float horizontal = 0;
        float vertical = 0;
        if (Gdx.input.isKeyPressed(Input.Keys.W)) vertical++;
        if (Gdx.input.isKeyPressed(Input.Keys.S)) vertical--;
        if (Gdx.input.isKeyPressed(Input.Keys.A)) horizontal--;
        if (Gdx.input.isKeyPressed(Input.Keys.D)) horizontal++;
        player.move(horizontal, vertical, delta);
        session.layout.updateNavigation(player);
        PlayerUpgrade oldPickup = session.pickupReward;
        session.updateLoot(delta, player);
        pickupTimer = Math.max(0, pickupTimer - delta);
        if (oldPickup != session.pickupReward) pickupTimer = 3;
        // Чистим снаряды, но кд выстрела не сбрасываем.
        if (!session.hasEnemiesRemaining(enemies)) {
            projectiles.clear();
            impacts.clear();
            clearBossAttacks();
        }
        session.updateWaves(delta, player, enemies);
        if (session.isExitOpen() && TowerDoors.atExit(player)) {
            if (session.advanceFloor(player, enemies)) {
                combatText.clear();
                roomArt.newRoom();
                pickupTimer = 0;
                return;
            }
        }
        for (int i = projectiles.size - 1; i >= 0; i--) {
            Projectile projectile = projectiles.get(i);
            projectile.update(delta);
            boolean keep = true;
            // Вода может пробить несколько врагов за кадр, каждого только раз.
            for (int pass = 0; pass < player.targetLimit(projectile.element); pass++) {
                Enemy target = closestTarget(projectile);
                if (target == null) break;
                impacts.add(new SpellImpact(projectile.element, target.x + target.getSize() / 2,
                    target.y + target.getSize() / 2, player.explosionRadius));
                keep = PlayerSpells.hit(projectile, target, enemies, session, player);
                // Чистим и после босса, и когда закончилась вся очередь врагов.
                if (session.getReward() != null || !session.hasEnemiesRemaining(enemies)) {
                    projectiles.clear();
                    impacts.clear();
                    clearBossAttacks();
                    session.checkFloorCleared(enemies);
                    return;
                }
                if (!keep || projectile.element == ElementType.AIR) break;
            }
            if (!keep || projectile.outsideRoom() || projectile.obstacleTime(session.layout) < 1) projectiles.removeIndex(i);
        }
        session.updateWaves(0, player, enemies);
        for (Enemy enemy : enemies) {
            enemy.update(delta, player);
            // Маг сдох — остальных врагов в этом кадре уже не обновляем.
            if (!player.isAlive()) {
                projectiles.clear();
                impacts.clear();
                clearBossAttacks();
                return;
            }
        }
        if (session.hasEnemiesRemaining(enemies) && Gdx.input.isButtonPressed(Input.Buttons.LEFT)
            && player.canShoot()) shoot();
    }

    private void shoot() {
        // Переводим курсор из экранных координат в игровые.
        cursor.set(Gdx.input.getX(), Gdx.input.getY());
        viewport.unproject(cursor);
        if (cursor.x < 0 || cursor.x >= WORLD_WIDTH || cursor.y < 0 || cursor.y >= WORLD_HEIGHT) return;
        float centerX = player.x + Player.SIZE / 2;
        float centerY = player.y + Player.SIZE / 2;
        cursor.sub(centerX, centerY);
        // Курсор в центре мага — направления для выстрела нет.
        if (!cursor.isZero(0.001f)) {
            player.aimAngle = cursor.angleDeg();
            projectiles.add(new Projectile(centerX, centerY, cursor, player.element, player.projectileSpeed));
            player.shotFired();
        }
    }

    private void clearBossAttacks() {
        for (Enemy enemy : enemies) {
            if (enemy.bossCombat != null) enemy.bossCombat.clear();
            if (enemy.shooterCombat != null) enemy.shooterCombat.clear();
            if (enemy.snakeCombat != null) enemy.snakeCombat.clear();
        }
    }

    private Enemy closestTarget(Projectile shot) {
        Enemy target = null;
        float closest = Float.POSITIVE_INFINITY;
        float wall = shot.obstacleTime(session.layout);
        for (Enemy enemy : enemies) {
            float time = shot.hitTime(enemy);
            if (time < closest && time < wall) { closest = time; target = enemy; }
        }
        return target;
    }

    private void drawMenuBackground() {
        if (menuPage == MenuPage.MAIN) {
            cover.drawBackground();
            return;
        }
        cover.drawNeutralBackground();
    }

    private void drawMainMenu() {
        cover.drawTitle();
        drawButton("Ехала", 480, 438, 320, 64, true);
        drawButton("Управление", 480, 358, 320, 52, false);
        drawButton("Механики", 480, 278, 320, 52, false);
        drawButton("Настройки", 480, 198, 320, 52, false);
        drawButton("Закрыть игру", 480, 122, 320, 52, false);
    }

    private void drawButton(String label, float x, float y, float width, float height, boolean primary) {
        boolean hover = cursor.x >= x && cursor.x <= x + width && cursor.y >= y && cursor.y <= y + height;
        cover.drawButton(label, x, y, width, height, primary, hover);
    }

    private void drawSelection() {
        String[][] details = {
            {"Взрыв при попадании", "Задевает врагов рядом"},
            {"Пробивает две цели", "Лови врагов в линию"},
            {"Толкает и замедляет", "Держи врагов подальше"},
            {"Рикошет в соседа", "До двух целей за раз"}
        };
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        for (int i = 0; i < 4; i++) {
            ElementType element = DamageSystem.PLAYER_ELEMENTS[i];
            float x = 148 + i * 252;
            cover.panel(x, 270, 220, 240);
            if (cursor.x >= x && cursor.x <= x + 220 && cursor.y >= 270 && cursor.y <= 510) {
                shapes.setColor(0.17f, 0.13f, 0.24f, 1);
                shapes.rect(x + 3, 273, 214, 234);
            }
            shapes.setColor(element.color);
            shapes.rect(x + 8, 501, 204, 3);
            shapes.setColor(element.color.r * 0.3f, element.color.g * 0.3f, element.color.b * 0.3f, 1);
            shapes.ellipse(x + 42, 347, 136, 24, 16);
            shapes.setColor(element.color);
            shapes.rect(x + 84, 346, 52, 2);
        }
        shapes.end();
        cover.heading("Выбери мага", 638);
        textBatch.begin();
        drawCenteredText("Один класс — четыре стихии", 640, 574, 2, Color.WHITE);
        drawCenteredText("20 ХП  /  2 выстрела в секунду  /  200 пикс/с", 640, 540, 2, Color.LIGHT_GRAY);
        for (int i = 0; i < 4; i++) {
            ElementType element = DamageSystem.PLAYER_ELEMENTS[i];
            float x = 148 + i * 252;
            drawCenteredText(element.label, x + 110, 485, 3, element.color);
            sprites.drawMage(textBatch, element, x + 55, 355, 110);
            drawCenteredText(details[i][0], x + 110, 323, 1, Color.WHITE);
            drawCenteredText(details[i][1], x + 110, 299, 1, Color.LIGHT_GRAY);
            drawText("" + (i + 1), x + 16, 478, 1, Color.LIGHT_GRAY);
        }
        drawCenteredText("Нажми на карточку или выбери клавишей 1-4", 640, 175, 1, Color.LIGHT_GRAY);
        drawCenteredText(VERSION_LABEL, 640, 70, 1, Color.LIGHT_GRAY);
        drawCenteredText(AUTHOR_LABEL, 640, 54, 1, Color.LIGHT_GRAY);
        drawCenteredText(THANKS_LABEL, 640, 38, 1, Color.LIGHT_GRAY);
        textBatch.end();
        boolean hover = cursor.x >= 500 && cursor.x <= 780 && cursor.y >= 198 && cursor.y <= 246;
        cover.drawButton("Назад", 500, 198, 280, 48, false, hover);
    }

    private void drawSettingsButton(float x, float y, float width, float height) {
        boolean hover = hudMenuHover();
        cover.drawButton("Меню", x, y, width, height, false, hover);
    }

    private void drawSettings() {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0, 0, 0, 0.6f);
        shapes.rect(0, 0, 1280, 720);
        cover.panel(370, 160, 540, 510);
        cover.panel(410, 350, 460, 60);
        shapes.setColor(0.88f, 0.65f, 0.32f, 1);
        shapes.rect(430, 368, 24, 24);
        shapes.setColor(0.035f, 0.025f, 0.07f, 1);
        shapes.rect(433, 371, 18, 18);
        if (showParameters) {
            shapes.setColor(1, 0.91f, 0.70f, 1);
            shapes.rect(436, 376, 4, 6);
            shapes.rect(440, 379, 7, 4);
        }
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        textBatch.begin();
        drawCenteredText("Настройки", 640, 634, 3, new Color(1, 0.91f, 0.70f, 1));
        drawCenteredText("Музыка: " + Math.round(audio.getMusicVolume() * 100) + "%", 640, 585, 2, Color.WHITE);
        drawCenteredText("Звуки: " + Math.round(audio.getEffectsVolume() * 100) + "%", 640, 505, 2, Color.WHITE);
        drawText("Параметры персонажа", 474, 391, 2, Color.WHITE);
        drawText(showParameters ? "Включены" : "Выключены", 474, 369, 1, Color.LIGHT_GRAY);
        drawCenteredText("ХП-бар над магом виден всегда", 640, 438, 2, Color.LIGHT_GRAY);
        drawCenteredText("Размер ХУДа: " + Math.round(hudScale * 100) + "%", 640, 321, 2, Color.WHITE);
        textBatch.end();
        boolean hover = cursor.x >= 500 && cursor.x <= 780 && cursor.y >= 238 && cursor.y <= 286;
        cover.drawButton("Назад", 500, 238, 280, 48, false, hover);
        cover.drawButton("-", 410, 292, 72, 44, false, cursor.x >= 410 && cursor.x <= 482 && cursor.y >= 292 && cursor.y <= 336);
        cover.drawButton("+", 798, 292, 72, 44, false, cursor.x >= 798 && cursor.x <= 870 && cursor.y >= 292 && cursor.y <= 336);
        cover.drawButton("Язык: Русский", 410, 184, 460, 40, false, cursor.x >= 410 && cursor.x <= 870 && cursor.y >= 184 && cursor.y <= 224);
        drawButton("-", 410, 556, 72, 44, false); drawButton("+", 798, 556, 72, 44, false);
        drawButton("-", 410, 476, 72, 44, false); drawButton("+", 798, 476, 72, 44, false);
    }

    private void drawPauseMenu() {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0, 0, 0, 0.7f);
        shapes.rect(0, 0, 1280, 720);
        cover.panel(436, 144, 408, 398);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        cover.heading("Меню", 512);
        String[] labels = {"Настройки", "Закончить сессию", "Закрыть игру", "Продолжить"};
        for (int i = 0; i < labels.length; i++) {
            float y = 400 - i * 76;
            boolean hover = cursor.x >= 480 && cursor.x <= 800 && cursor.y >= y && cursor.y <= y + 52;
            cover.drawButton(labels[i], 480, y, 320, 52, i == 3, hover);
        }
    }

    private void drawParameters() {
        if (!showParameters) return;
        scaleHud(1256, 640);
        float x = 914;
        float top = 640;
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        cover.panel(x, top - 314, 342, 314, 0.78f);
        shapes.setColor(player.element.color.r, player.element.color.g, player.element.color.b, 0.85f);
        shapes.rect(x, top - 314, 3, 314);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        textBatch.begin();
        drawText("Персонаж", x + 18, top - 18, 2, Color.WHITE);
        drawText("Стихия: " + player.element.label, x + 18, top - 52, 2, player.element.color);
        drawText("ХП: " + player.getHp() + "/" + player.maxHp, x + 18, top - 80, 2, Color.WHITE);
        drawText("Скорость: " + (int) player.getMoveSpeed() + " пикс/с", x + 18, top - 108, 2, Color.WHITE);
        drawText("Стрельба: " + decimal(1 / player.attackCooldown) + " выстр/с", x + 18, top - 136, 2, Color.WHITE);
        drawText("КД стрельбы: " + decimal(player.attackCooldown) + " с",
            x + 18, top - 164, 2, Color.WHITE);
        drawText("Пройдено: " + session.getCompletedFloors(), x + 18, top - 192, 2, Color.LIGHT_GRAY);
        drawText("Урон: " + decimal(player.baseDamage), x + 18, top - 220, 2, Color.WHITE);
        drawText("Снаряд: " + (int) player.projectileSpeed + " пикс/с", x + 18, top - 248, 2, Color.WHITE);
        drawText("Уклонение: " + Math.round(player.dodgeChance * 100) + "%", x + 18, top - 276, 2, Color.WHITE);
        drawText("Сложность: " + (session.getDifficulty() + 1), x + 18, top - 300, 1, Color.LIGHT_GRAY);
        textBatch.end();
        resetHudTransform();
    }


    private void drawCombat() {
        textBatch.begin();
        roomArt.draw(textBatch);
        roomDecor.draw(textBatch, session.layout, roomArt.getBiome(), session.isExitOpen(), session.drops);
        merchantArt.draw(textBatch, session.merchant, session.drops);
        textBatch.end();
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        drawProjectiles();
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        drawBossAttacks();
        textBatch.begin();
        roomScene.draw(textBatch, player, enemies, session, roomArt.getBiome(), sprites, roomDecor, merchantArt);
        if (session.merchant != null) {
            drawCenteredText("Торговец", Merchant.X, Merchant.Y + 94, 2, Color.GOLD);
            for (int i = 0; i < 3; i++) {
                MerchantItem item = session.merchant.items[i];
                drawCenteredText(item.sold ? "Продано" : item.name(), Merchant.itemX(i), Merchant.ITEM_Y - 58, 1, Color.GOLD);
                if (!item.sold) drawCenteredText(item.price(player, session.getDifficulty()) + " монет", Merchant.itemX(i), Merchant.ITEM_Y - 78, 1, Color.WHITE);
            }
        }
        textBatch.end();
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        // Вспышки рисуем поверх рук, полоски ХП — поверх вспышек.
        SpellVisuals.cast(shapes, player.element, player.x + Player.SIZE / 2,
            player.y + Player.SIZE / 2, player.aimAngle, player.getCastTimer());
        for (Enemy enemy : enemies) {
            if (enemy.isAlive() && enemy.shooterCombat != null) enemy.shooterCombat.drawCast(shapes);
        }
        for (Enemy enemy : enemies) {
            if (enemy.isAlive() && !enemy.isBoss()) {
                drawHealthBar(enemy.x, enemy.y + enemy.getSize() + 6, enemy.getSize(), enemy.getHp(), enemy.getMaxHp());
            }
        }
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        applyViewport(uiViewport);
        drawParameters();
        applyViewport(viewport);
        // ХП мага рисуем и при скрытой панели параметров.
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        drawHealthBar(player.x, player.y + Player.SIZE + 6, Player.SIZE, player.getHp(), player.maxHp);
        shapes.end();
        textBatch.begin(); combatText.draw(textBatch, font); textBatch.end();
    }

    private void drawBossAttacks() {
        // Обрезаем эффекты по внутренней части комнаты.
        float scaleX = viewport.getScreenWidth() / (float) WORLD_WIDTH;
        float scaleY = viewport.getScreenHeight() / (float) WORLD_HEIGHT;
        Gdx.gl.glEnable(GL20.GL_SCISSOR_TEST);
        Gdx.gl.glScissor(viewport.getScreenX() + Math.round(TILE_SIZE * scaleX),
            viewport.getScreenY() + Math.round(TILE_SIZE * scaleY),
            Math.round((WORLD_WIDTH - TILE_SIZE * 2) * scaleX),
            Math.round((WORLD_HEIGHT - TILE_SIZE * 2) * scaleY));
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        for (Enemy enemy : enemies) {
            if (!enemy.isAlive()) continue;
            if (enemy.bossCombat != null) {
                for (BossAttack attack : enemy.bossCombat.attacks) attack.draw(shapes);
            }
            if (enemy.shooterCombat != null) enemy.shooterCombat.draw(shapes);
            if (enemy.snakeCombat != null) enemy.snakeCombat.draw(shapes);
        }
        for (SpellImpact impact : impacts) impact.draw(shapes);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_SCISSOR_TEST);
        Gdx.gl.glDisable(GL20.GL_BLEND);
    }

    private void drawHealthBar(float x, float y, float width, int hp, int maxHp) {
        float health = hp / (float) maxHp;
        shapes.setColor(0.02f, 0.02f, 0.04f, 1);
        shapes.rect(x - 4, y - 4, width + 8, 16);
        shapes.setColor(0.72f, 0.51f, 0.25f, 1);
        shapes.rect(x - 2, y - 2, width + 4, 12);
        shapes.setColor(0.12f, 0.055f, 0.1f, 1);
        shapes.rect(x, y, width, 8);
        Color fill = new Color(0.25f, 0.72f, 0.39f, 1);
        if (health <= 0.5f) fill.set(0.92f, 0.66f, 0.22f, 1);
        if (health <= 0.25f) fill.set(0.85f, 0.18f, 0.26f, 1);
        shapes.setColor(fill);
        shapes.rect(x, y, width * health, 8);
        shapes.setColor(fill.lerp(Color.WHITE, 0.35f));
        shapes.rect(x, y + 6, width * health, 2);
        shapes.setColor(1, 0.85f, 0.5f, 1);
        shapes.rect(x - 3, y + 2, 2, 4);
        shapes.rect(x + width + 1, y + 2, 2, 4);
    }

    private String decimal(float value) {
        return String.format(java.util.Locale.ROOT, "%.2f", value).replace('.', ',');
    }

    private void drawPickupNotice() {
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        cover.panel(396, 74, 488, 84);
        shapes.end();
        textBatch.begin();
        drawCenteredText("Книга заклинаний", 640, 143, 2, player.element.color);
        drawCenteredText(session.pickupReward.title, 640, 115, 1, Color.WHITE);
        drawCenteredText(session.pickupReward.change, 640, 95, 1, Color.LIGHT_GRAY);
        textBatch.end();
    }

    private void drawReward() {
        PlayerUpgrade reward = session.getReward();
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0, 0, 0, 0.75f);
        shapes.rect(0, 0, 1280, 720);
        cover.panel(320, 184, 640, 352);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        cover.heading("Босс повержен", 498);
        textBatch.begin();
        drawCenteredText(reward.rare ? "Редкое улучшение" : "Маг стал сильнее", 640, 438, 2, Color.LIGHT_GRAY);
        drawCenteredText(reward.title, 640, 392, 3, player.element.color);
        drawCenteredText(reward.change, 640, 352, 2, Color.WHITE);
        drawCenteredText("Здоровье полностью восстановлено", 640, 318, 1, Color.LIGHT_GRAY);
        drawCenteredText("Враги станут сильнее", 640, 294, 2, new Color(1, 0.75f, 0.35f, 1));
        textBatch.end();
        boolean hover = cursor.x >= 460 && cursor.x <= 820 && cursor.y >= 220 && cursor.y <= 276;
        cover.drawButton("Ехала дальше", 460, 220, 360, 56, true, hover);
    }

    private void drawProjectiles() {
        for (Projectile projectile : projectiles) SpellVisuals.projectile(shapes, projectile, false);
    }
    private void drawText(String text, float x, float y, int scale, Color color) {
        text = GameText.tr(text);
        font.getData().setScale(scale);
        font.setColor(color);
        font.draw(textBatch, text, x, y);
    }

    private void drawCenteredText(String text, float centerX, float y, int scale, Color color) {
        text = GameText.tr(text);
        float width = (text.length() * 6 - 1) * scale;
        drawText(text, centerX - width / 2, y, scale, color);
    }

    private void drawGameOver() {
        Gdx.gl.glEnable(GL20.GL_BLEND);
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA);
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        shapes.setColor(0.015f, 0.005f, 0.03f, 0.8f);
        shapes.rect(0, 0, 1280, 720);
        cover.panel(320, 240, 640, 300);
        shapes.setColor(0.88f, 0.65f, 0.32f, 1);
        shapes.triangle(622, 448, 640, 467, 640, 448);
        shapes.triangle(640, 448, 658, 448, 640, 429);
        shapes.setColor(0.9f, 0.25f, 0.32f, 1);
        shapes.rect(637, 444, 6, 9);
        shapes.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);
        textBatch.begin();
        drawCenteredText("Потрачено", 642, 498, 5, new Color(0.035f, 0.025f, 0.07f, 1));
        drawCenteredText("Потрачено", 640, 500, 5, new Color(1, 0.3f, 0.38f, 1));
        drawCenteredText("Пройдено этажей: " + session.getCompletedFloors(), 640, 380, 2, new Color(1, 0.91f, 0.70f, 1));
        drawCenteredText("Новый заход — новый шанс", 640, 329, 1, Color.LIGHT_GRAY);
        textBatch.end();
        boolean hover = cursor.x >= 490 && cursor.x <= 790 && cursor.y >= 276 && cursor.y <= 316;
        cover.drawButton("Главное меню", 490, 276, 300, 40, true, hover);
    }

    @Override
    public void dispose() {
        combatText.dispose();
        audio.dispose();
        shapes.dispose();
        textBatch.dispose();
        font.dispose();
        sprites.dispose();
        cover.dispose();
        roomArt.dispose();
        roomDecor.dispose();
        merchantArt.dispose();
    }
}
