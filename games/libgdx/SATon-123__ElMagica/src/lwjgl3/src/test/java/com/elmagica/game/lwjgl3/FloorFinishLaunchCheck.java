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

public class FloorFinishLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame, floor; CombatSession session; Player player; Array<Enemy> enemies; LootDrop coin;
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @Override @SuppressWarnings("unchecked") public void create() {
                super.create(); Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
                try { var m = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class); m.setAccessible(true); m.invoke(this, ElementType.WATER); }
                catch (Exception e) { throw new RuntimeException(e); }
                session = (CombatSession) field("session"); player = (Player) field("player"); enemies = (Array<Enemy>) field("enemies");
                while (session.merchant != null) session.advanceFloor(player, enemies);
                floor = session.getWave(); session.layout.prepare(3, false, false);
                player.x = 800; player.y = 450; player.takeDamage(10);
                enemies.clear(); Enemy enemy = new Enemy(ElementType.WATER, 2, 2); enemy.room = session.layout; enemies.add(enemy);
                coin = new LootDrop(LootDrop.Type.COIN, 300, 480, 3); session.drops.add(coin);
                session.drops.add(new LootDrop(LootDrop.Type.BOOK, 320, 520));
                session.drops.add(new LootDrop(LootDrop.Type.POTION, 280, 440));
            }
            @Override public void render() {
                if (frame == 30) {
                    if (coin.x != 300 || player.floorCleared) throw new AssertionError("Early attraction or speed boost");
                    while (session.hasEnemiesRemaining(enemies)) {
                        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
                        session.updateWaves(0, player, enemies);
                    }
                    session.checkFloorCleared(enemies);
                }
                if (frame == 110) { player.x = ElMagicaGame.WORLD_WIDTH / 2f - 30; player.y = ElMagicaGame.WORLD_HEIGHT - 124; }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Flying loot rendering error");
                if (frame == 35 && (!player.floorCleared || coin.getScale() <= 1 || coin.x <= 300)) throw new AssertionError("No flying loot or boost");
                if (frame == 100 && (!session.drops.isEmpty() || session.getCoins() != 3 || session.pickupReward == null || player.getHp() <= 10)) throw new AssertionError("Loot was not collected");
                if (frame == 111 && (session.getWave() != floor + 1 || player.floorCleared || session.getCoins() != 3)) throw new AssertionError("Exit reset or carryover failed");
                if (frame == 35 || frame == 100) {
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/floor-finish-" + frame + ".png"), p, -1, true); p.dispose();
                }
                if (++frame == 120) { System.out.println("Hidden floor finish check passed: loot through obstacles, growth, collection, speed and next floor"); Gdx.app.exit(); }
            }
        }, config);
    }
}
