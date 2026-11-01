package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.utils.Array;
import com.elmagica.game.ElMagicaGame;
import com.elmagica.game.CombatSession;
import com.elmagica.game.ElementType;
import com.elmagica.game.Enemy;
import com.elmagica.game.Player;
import com.elmagica.game.GameSprites;
import com.elmagica.game.DamageSystem;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.viewport.FitViewport;
import java.lang.reflect.Proxy;

public class CombatLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка интерфейса");
        config.setWindowedMode(1280, 704);
        config.setInitialVisible(true);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            float deathX, deathY;
            long deathScore;
            boolean attackSaved;

            private Object field(String name) {
                try {
                    java.lang.reflect.Field field = ElMagicaGame.class.getDeclaredField(name);
                    field.setAccessible(true);
                    return field.get(this);
                } catch (ReflectiveOperationException exception) {
                    throw new RuntimeException(exception);
                }
            }

            @Override
            public void create() {
                super.create();
                com.badlogic.gdx.graphics.g2d.BitmapFont font = (com.badlogic.gdx.graphics.g2d.BitmapFont) field("font");
                for (char letter : "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя".toCharArray()) {
                    if (font.getData().getGlyph(letter) == null) throw new AssertionError("Missing Russian letter: " + letter);
                }
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class},
                    (proxy, method, values) -> {
                        int phase = frame / 30 % 5;
                        int element = frame / 150;
                        boolean firstFrame = frame % 30 == 0;
                        if (frame < 600 && method.getName().equals("isButtonJustPressed")) return frame % 150 == 15;
                        if (frame < 600 && frame % 150 == 15 && method.getName().equals("getX")) return 640;
                        if (frame < 600 && frame % 150 == 15 && method.getName().equals("getY")) return Gdx.graphics.getHeight() - 470;
                        if (frame >= 1560) {
                            if (method.getName().equals("isKeyJustPressed")) return false;
                            if (method.getName().equals("isKeyPressed")) return (int) values[0] == Input.Keys.W && frame % 120 < 25;
                            if (method.getName().equals("isButtonPressed")) return true;
                            if (method.getName().equals("getX")) return 660;
                            if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - 352;
                        }
                        if (frame >= 840 && (method.getName().equals("isKeyJustPressed")
                            || method.getName().equals("isKeyPressed") || method.getName().equals("isButtonPressed"))) return false;
                        if (method.getName().equals("isKeyJustPressed")) {
                            int key = (int) values[0];
                            return firstFrame && ((phase == 1 && element < 4 && key == Input.Keys.NUM_1 + element)
                                || (phase == 4 && key == Input.Keys.ESCAPE));
                        }
                        if (method.getName().equals("isButtonPressed")) return phase == 2;
                        if (method.getName().equals("isKeyPressed")) return phase == 3 && (int) values[0] == Input.Keys.D;
                        if (method.getName().equals("getX")) return 900;
                        if (method.getName().equals("getY")) return 200;
                        return method.invoke(original, values);
                    });
            }

            @Override
            @SuppressWarnings("unchecked")
            public void render() {
                if (frame >= 1560) {
                    showNewCombat();
                    if (++frame >= 2040) {
                        System.out.println("Visible new combat check passed: mage/slime animations, elemental spells and shooter");
                        Gdx.app.exit();
                    }
                    return;
                }
                if (frame >= 840) {
                    showBossAttack();
                    if (++frame >= 1560) {
                        System.out.println("Visible boss animation check passed: all four attacks and movement");
                    }
                    return;
                }
                if (frame >= 600) {
                    drawGallery();
                    if (++frame >= 840) {
                        System.out.println("Visible sprite check passed: four mages, four slimes and all six bosses");
                    }
                    return;
                }
                int phase = frame / 30 % 5;
                boolean firstFrame = frame % 30 == 0;
                CombatSession session = (CombatSession) field("session");
                if (phase == 2 && firstFrame) {
                    Enemy victim = new Enemy(ElementType.FIRE, 2, 2);
                    for (int i = 0; i < 20; i++) {
                        victim.reset();
                        session.hit(victim, ElementType.WATER);
                        session.hit(victim, ElementType.WATER);
                    }
                    Player player = (Player) field("player");
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    while (session.getWave() < 10) {
                        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
                        session.updateWaves(1.01f, player, enemies);
                    }
                    if (enemies.size != 1 || !enemies.first().isBoss() || enemies.first().getHp() != Enemy.BOSS_HP) {
                        throw new AssertionError("Wave 10 is not a solo boss");
                    }
                    enemies.first().x = 900;
                    enemies.first().y = 300;
                    player.takeDamage(player.getHp() - 8);
                }
                if (phase == 2 && frame % 30 == 29) {
                    Player player = (Player) field("player");
                    Enemy boss = ((Array<Enemy>) field("enemies")).first();
                    while (boss.isAlive()) session.hit(boss, player.element, player);
                    if (player.getHp() != player.maxHp) throw new AssertionError("Boss kill did not heal player");
                    session.acceptReward();
                }
                if (phase == 3 && firstFrame) {
                    Player player = (Player) field("player");
                    player.takeDamage(player.getHp() - 1);
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    if (enemies.isEmpty()) enemies.add(new Enemy(ElementType.FIRE, 2, 2));
                    Enemy enemy = enemies.first();
                    enemy.reset();
                    enemy.x = player.x;
                    enemy.y = player.y;
                }
                super.render();
                if (frame == 0) {
                    Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                        Gdx.graphics.getBackBufferHeight());
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/menu-check.png"), screenshot, -1, true);
                    screenshot.dispose();
                }
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("OpenGL error");
                if (phase == 2 && session.getScore() < 20) throw new AssertionError("Score still capped");
                if (phase == 2 && firstFrame && frame / 150 == 0) {
                    Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                        Gdx.graphics.getBackBufferHeight());
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/boss-check.png"), screenshot, -1, true);
                    screenshot.dispose();
                }
                if (phase == 3) {
                    Player player = (Player) field("player");
                    if (player.isAlive()) throw new AssertionError("Contact did not kill player");
                    if (firstFrame) {
                        deathX = player.x;
                        deathY = player.y;
                        deathScore = session.getScore();
                        if (frame / 150 == 0) {
                            Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                                Gdx.graphics.getBackBufferHeight());
                            PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/gameover-check.png"), screenshot, -1, true);
                            screenshot.dispose();
                        }
                    } else if (player.x != deathX || player.y != deathY || session.getScore() != deathScore) {
                        throw new AssertionError("Game advances after death");
                    }
                    if (!((Array<?>) field("projectiles")).isEmpty()) throw new AssertionError("Shots remain after death");
                }
                if (phase == 4 && (field("player") != null || session.getScore() != 0
                    || !((Array<?>) field("enemies")).isEmpty())) throw new AssertionError("ESC did not reset session");
                if (++frame >= 600) {
                    System.out.println("Visible desktop check passed: wave 10 boss, full heal, all elements, death and ESC");
                }
            }

            @SuppressWarnings("unchecked")
            private void showNewCombat() {
                int stage = (frame - 1560) / 120;
                if ((frame - 1560) % 120 == 0) {
                    try {
                        java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                        start.setAccessible(true);
                        start.invoke(this, DamageSystem.PLAYER_ELEMENTS[stage]);
                    } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    enemies.clear();
                    Enemy first = new Enemy(ElementType.WATER, 10, 6);
                    Enemy second = new Enemy(ElementType.EARTH, 11, 6);
                    Enemy shooter = Enemy.shooter(ElementType.AIR, 16, 6);
                    enemies.add(first); enemies.add(second); enemies.add(shooter);
                    first.knockBack(new com.badlogic.gdx.math.Vector2(0, 0), 0);
                }
                Player player = (Player) field("player");
                player.restoreHp();
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("New combat rendering error");
                if ((frame - 1560) % 120 == 90) {
                    Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                        Gdx.graphics.getBackBufferHeight());
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/new-combat-" + stage + ".png"), screenshot, -1, true);
                    screenshot.dispose();
                }
            }

            @SuppressWarnings("unchecked")
            private void showBossAttack() {
                int stage = (frame - 840) / 180;
                ElementType[] order = {ElementType.EARTH, ElementType.WATER, ElementType.FIRE, ElementType.AIR};
                if ((frame - 840) % 180 == 0) {
                    try {
                        java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                        start.setAccessible(true);
                        start.invoke(this, ElementType.WATER);
                    } catch (ReflectiveOperationException exception) {
                        throw new RuntimeException(exception);
                    }
                    Player player = (Player) field("player");
                    player.x = 760;
                    player.y = 322;
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    enemies.clear();
                    ElementType second = order[stage] == ElementType.EARTH ? ElementType.WATER : ElementType.EARTH;
                    Enemy boss = new Enemy(order[stage], second, 10, 6);
                    boss.takeDamage(boss.getMaxHp() / 2);
                    enemies.add(boss);
                    boss.bossCombat.update(1.51f, player, false);
                    attackSaved = false;
                }
                Player player = (Player) field("player");
                player.restoreHp();
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Boss attack rendering error");
                Enemy boss = ((Array<Enemy>) field("enemies")).first();
                com.elmagica.game.BossAttack attack = boss.bossCombat.getCurrent();
                if (!attackSaved && attack != null && !attack.isWarning()) {
                    Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                        Gdx.graphics.getBackBufferHeight());
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/attack-" + stage + ".png"), screenshot, -1, true);
                    screenshot.dispose();
                    attackSaved = true;
                }
                if ((frame - 840) % 180 == 179 && !attackSaved) throw new AssertionError("Attack never became active");
            }

            private void drawGallery() {
                Gdx.gl.glClearColor(0.06f, 0.08f, 0.12f, 1);
                Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
                FitViewport viewport = (FitViewport) field("viewport");
                viewport.apply();
                SpriteBatch batch = (SpriteBatch) field("textBatch");
                BitmapFont font = (BitmapFont) field("font");
                GameSprites sprites = (GameSprites) field("sprites");
                batch.setProjectionMatrix(viewport.getCamera().combined);
                batch.begin();
                font.getData().setScale(2);
                font.setColor(Color.WHITE);
                font.draw(batch, "ElMagica — маги, слизни и боссы", 430, 684);
                for (int i = 0; i < 4; i++) {
                    ElementType type = DamageSystem.ENEMY_ELEMENTS[i];
                    float x = 130 + i * 280;
                    sprites.drawMage(batch, type, x, 540, 60);
                    font.draw(batch, type.label, x, 622);
                    Enemy slime = new Enemy(type, 2, 2);
                    slime.x = x;
                    slime.y = 448;
                    sprites.drawEnemy(batch, slime);
                }
                int pair = 0;
                for (int first = 0; first < 4; first++) {
                    for (int second = first + 1; second < 4; second++) {
                        Enemy boss = new Enemy(DamageSystem.ENEMY_ELEMENTS[first], DamageSystem.ENEMY_ELEMENTS[second], 2, 2);
                        boss.x = 130 + pair % 3 * 400;
                        boss.y = 258 - pair / 3 * 200;
                        sprites.drawEnemy(batch, boss);
                        font.draw(batch, boss.element.label + "+" + boss.secondElement.label, boss.x, boss.y + 152);
                        pair++;
                    }
                }
                batch.end();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Sprite rendering error");
                if (frame == 600) {
                    Pixmap screenshot = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(),
                        Gdx.graphics.getBackBufferHeight());
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/sprites-check.png"), screenshot, -1, true);
                    screenshot.dispose();
                }
            }
        }, config);
    }
}
