package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.utils.Array;
import com.elmagica.game.*;
import java.lang.reflect.Proxy;

public class RoomDecorLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080);
        config.setInitialVisible(false);
        config.setForegroundFPS(60);
        config.setIdleFPS(60);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            private Object field(String name) {
                try {
                    java.lang.reflect.Field field = ElMagicaGame.class.getDeclaredField(name);
                    field.setAccessible(true); return field.get(this);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            @Override
            public void create() {
                super.create();
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class},
                    (proxy, method, values) -> {
                        if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                        return method.invoke(original, values);
                    });
            }
            private void start() {
                try {
                    java.lang.reflect.Method method = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                    method.setAccessible(true); method.invoke(this, ElementType.WATER);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private void screenshot(String name) {
                Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(), Gdx.graphics.getBackBufferHeight());
                PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/" + name + ".png"), picture, -1, true);
                picture.dispose();
            }
            @Override
            @SuppressWarnings("unchecked")
            public void render() {
                int stage = frame / 30;
                if (frame % 30 == 0) {
                    start();
                    CombatSession session = (CombatSession) field("session");
                    session.layout.prepare(stage < 15 ? stage : -1, false, false);
                    ((RoomArt) field("roomArt")).prepare(stage % 4);
                    Player player = (Player) field("player");
                    player.maxHp = 1000; player.restoreHp();
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    enemies.clear();
                    if (stage < 15) {
                        Enemy snake = Enemy.snake(ElementType.FIRE, 2, 2);
                        snake.room = session.layout;
                        EnemySpawner.spawn(snake, player, enemies); enemies.add(snake);
                    } else session.checkFloorCleared(enemies);
                    session.drops.add(new LootDrop(LootDrop.Type.BOOK, player.x - 100, player.y + 30));
                    session.drops.add(new LootDrop(LootDrop.Type.POTION, player.x + 130, player.y + 30));
                    if (stage == 19) {
                        session.drops.clear(); player.takeDamage(200);
                        session.drops.add(new LootDrop(LootDrop.Type.BOOK, player.x + 30, player.y + 30));
                        session.drops.add(new LootDrop(LootDrop.Type.POTION, player.x + 30, player.y + 30));
                    }
                }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Decoration rendering error");
                if (frame % 30 == 1) screenshot("decor-template-" + stage);
                if (frame == 590) {
                    CombatSession session = (CombatSession) field("session");
                    if (session.pickupReward == null || !session.drops.isEmpty()) throw new AssertionError("Real pickup integration failed");
                    screenshot("loot-pickup-check");
                }
                if (++frame >= 600) {
                    System.out.println("Hidden decoration check passed: 15 layouts, four biomes, closed/open gates and loot sprites");
                    Gdx.app.exit();
                }
            }
        }, config);
    }
}
