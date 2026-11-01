package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.elmagica.game.*;
import java.lang.reflect.Proxy;

public class TowerLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка башни");
        config.setWindowedMode(1920, 1080);
        config.setFullscreenMode(Lwjgl3ApplicationConfiguration.getDisplayMode());
        config.setInitialVisible(false);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            int firstBiome;
            boolean rewardSeen;

            private Object field(Object owner, Class<?> type, String name) {
                try {
                    java.lang.reflect.Field field = type.getDeclaredField(name);
                    field.setAccessible(true);
                    return field.get(owner);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private Object field(String name) { return field(this, ElMagicaGame.class, name); }
            private void start() {
                try {
                    java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                    start.setAccessible(true);
                    start.invoke(this, ElementType.WATER);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private Vector2 mouse() {
                if (frame == 5) {
                    Enemy target = ((Array<Enemy>) field("enemies")).first();
                    return ((FitViewport) field("viewport")).project(new Vector2(target.x + 30, target.y + 30));
                }
                float x = 640, y = 248;
                if (frame == 180) { x = 1158; y = 674; }
                if (frame == 195 || frame == 225) y = 350;
                if (frame == 210) { x = 760; y = 308; }
                if (frame == 240) { x = 520; y = 308; }
                if (frame == 280) y = 296;
                return ((FitViewport) field("uiViewport")).project(new Vector2(x, y));
            }
            @Override
            public void create() {
                super.create();
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class},
                    (proxy, method, values) -> {
                        if (method.getName().equals("getX")) return Math.round(mouse().x);
                        if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - Math.round(mouse().y);
                        if (method.getName().equals("isButtonJustPressed")) return frame == 140 || frame == 180
                            || frame == 195 || frame == 210 || frame == 225 || frame == 240 || frame == 280;
                        if (method.getName().equals("isButtonPressed")) return frame == 5;
                        if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                        return method.invoke(original, values);
                    });
                start();
            }
            private void screenshot(String name) {
                Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(), Gdx.graphics.getBackBufferHeight());
                PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/" + name + ".png"), picture, -1, true);
                picture.dispose();
            }
            private void exitPosition(Player player) {
                player.x = ElMagicaGame.WORLD_WIDTH / 2f - 30;
                player.y = ElMagicaGame.WORLD_HEIGHT - 124;
            }
            @Override
            @SuppressWarnings("unchecked")
            public void render() {
                Player player = (Player) field("player");
                CombatSession session = (CombatSession) field("session");
                Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                RoomArt art = (RoomArt) field("roomArt");
                if (frame == 0) {
                    firstBiome = (int) field(art, RoomArt.class, "biome");
                    enemies.first().x = player.x + 400;
                    enemies.first().y = player.y;
                }
                if (frame == 20) exitPosition(player);
                if (frame == 30 || (frame >= 60 && frame <= 65)) {
                    while (session.hasEnemiesRemaining(enemies)) {
                        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
                        session.updateWaves(0, player, enemies);
                    }
                    player.enterFloor();
                }
                if (frame == 45 || (frame >= 61 && frame <= 65)) {
                    session.checkFloorCleared(enemies);
                    exitPosition(player);
                }
                if (frame == 69) {
                    if (session.getWave() != 7 || enemies.size != 1 || !enemies.first().isBoss()) throw new AssertionError("Seventh floor boss");
                    enemies.clear();
                    Enemy boss = new Enemy(ElementType.WATER, ElementType.FIRE, 18, 10);
                    enemies.add(boss);
                }
                if (frame == 90) {
                    Enemy boss = enemies.first();
                    boss.x = player.x + 250; boss.y = player.y;
                    boss.takeDamage(boss.getMaxHp() - 20);
                    ((Array<Projectile>) field("projectiles")).add(new Projectile(player.x + 30, player.y + 30, new Vector2(1, 0), player.element));
                }
                if (frame == 150) exitPosition(player);
                if (frame == 260) {
                    start();
                    player = (Player) field("player");
                    while (session.hasEnemiesRemaining(enemies)) {
                        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
                        session.updateWaves(0, player, enemies);
                    }
                    session.checkFloorCleared(enemies);
                    player.takeDamage(player.getHp());
                }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Tower rendering error");
                if (frame == 1) screenshot("tower-floor-check");
                if (frame == 5) {
                    Array<Projectile> shots = (Array<Projectile>) field("projectiles");
                    if (shots.isEmpty() || shots.first().getDirection().x < 0.99f) throw new AssertionError("Mouse world aim broken at fullscreen");
                }
                if (frame == 20 && session.getWave() != 1) throw new AssertionError("Closed exit allowed transition");
                if (frame == 31) {
                    if (!session.isExitOpen() || session.getCompletedFloors() != 1 || session.getWave() != 1) throw new AssertionError("Floor clear did not open exit");
                    screenshot("tower-exit-check");
                }
                if (frame == 45) {
                    if (session.getWave() != 2 || session.isExitOpen() || player.y != 96
                        || firstBiome == (int) field(art, RoomArt.class, "biome")) throw new AssertionError("New floor did not regenerate and reset entrance");
                }
                if (frame == 70) screenshot("tower-boss-bar-check");
                if (session.getReward() != null && !rewardSeen) {
                    rewardSeen = true;
                    if (session.getCompletedFloors() != 7 || !session.isExitOpen()) throw new AssertionError("Boss floor not counted");
                    screenshot("tower-reward-check");
                }
                if (frame == 150 && (session.getWave() != 8 || session.getDifficulty() != 1 || enemies.size < 3)) throw new AssertionError("Floor after boss");
                if (frame == 195 || frame == 225) {
                    if (!(boolean) field("endSessionPrompt")) throw new AssertionError("Missing end session prompt");
                    screenshot("end-session-prompt-check");
                }
                if (frame == 210 && ((boolean) field("endSessionPrompt") || field("player") == null)) throw new AssertionError("Cancel destroyed session");
                if (frame == 240 && (field("player") != null || session.getCompletedFloors() != 0)) throw new AssertionError("Confirm did not reset session");
                if (frame == 261) screenshot("tower-gameover-check");
                if (frame == 280) {
                    if (field("player") != null || !rewardSeen) throw new AssertionError("Death screen return");
                    System.out.println("Visible tower check passed: fullscreen, doors, regeneration, floor 10 boss bar, rewards, confirmation and death screen");
                    Gdx.app.exit();
                }
                frame++;
            }
        }, config);
    }
}
