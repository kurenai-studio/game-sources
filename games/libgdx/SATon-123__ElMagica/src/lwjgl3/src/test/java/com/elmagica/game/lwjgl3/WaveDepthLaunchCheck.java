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
import com.elmagica.game.*;
import java.lang.reflect.Proxy;

public class WaveDepthLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame; long waiting; Player player; CombatSession session; Array<Enemy> enemies; Array<Projectile> shots;
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
                try { var m = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class); m.setAccessible(true); m.invoke(this, ElementType.FIRE); }
                catch (Exception e) { throw new RuntimeException(e); }
                player = (Player) field("player"); session = (CombatSession) field("session");
                enemies = (Array<Enemy>) field("enemies"); shots = (Array<Projectile>) field("projectiles");
                waiting = session.getEnemiesWaiting();
                shots.add(new Projectile(player.x + 30, player.y + 30, new Vector2(1, 0), player.element, 0));
            }
            @Override public void render() {
                if (frame == 10) enemies.first().takeDamage(enemies.first().getMaxHp());
                if (frame == 20) {
                    while (session.hasEnemiesRemaining(enemies)) {
                        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
                        session.updateWaves(0, player, enemies);
                    }
                }
                if (frame == 30) { session.merchant = new Merchant(player, 0); session.layout.prepare(-1, false, false); }
                if (frame == 30) { player.x = Merchant.X - 30; player.y = Merchant.Y - 25; }
                if (frame == 45) player.y = Merchant.Y - 65;
                if (frame == 60) { player.x = Merchant.itemX(0) - 30; player.y = Merchant.ITEM_Y - 35; }
                if (frame == 75) player.y = Merchant.ITEM_Y - 65;
                if (frame == 90) player.y = Merchant.ITEM_Y - 86;
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Wave/depth rendering error");
                if (frame == 11 && (session.getEnemiesWaiting() != waiting - 1 || enemies.size != 3 || shots.isEmpty() || session.isExitOpen())) throw new AssertionError("Refill or projectile preservation failed");
                if (frame == 21 && (!shots.isEmpty() || !session.isExitOpen())) throw new AssertionError("Full queue clear did not clean projectiles");
                if (frame == 31 || frame == 46 || frame == 61 || frame == 76 || frame == 91) {
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/depth-" + frame + ".png"), p, -1, true); p.dispose();
                }
                if (++frame == 105) { System.out.println("Hidden wave/depth check passed: replenishment, projectile lifecycle and front/back merchant scenes"); Gdx.app.exit(); }
            }
        }, config);
    }
}
