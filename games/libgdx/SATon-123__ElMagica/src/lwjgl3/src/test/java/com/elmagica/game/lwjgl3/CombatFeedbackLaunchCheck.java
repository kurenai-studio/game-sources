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

public class CombatFeedbackLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false); config.disableAudio(true);
        config.setForegroundFPS(60); config.setIdleFPS(60);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame; Player player; CombatSession session; Array<Enemy> enemies;
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
                player = (Player) field("player"); session = (CombatSession) field("session"); enemies = (Array<Enemy>) field("enemies");
                session.layout.prepare(-1, false, false); player.x = 400; player.y = 450; player.takeDamage(10);
                ((CombatText) field("combatText")).clear(); enemies.clear();
                enemies.add(new Enemy(ElementType.FIRE, 12, 8)); enemies.add(new Enemy(ElementType.WATER, 15, 8)); enemies.add(new Enemy(ElementType.AIR, 18, 8));
            }
            @Override public void render() {
                if (frame == 5) for (Enemy enemy : enemies) session.hit(enemy, player.element, player);
                if (frame == 15) { player.takeDamage(3, 3); player.heal(6); }
                if (frame == 25) { player.dodgeChance = 1; player.takeDamage(5, 2); player.dodgeChance = 0; }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Combat text rendering error");
                if (frame == 27) {
                    CombatText text = (CombatText) field("combatText");
                    boolean[] kinds = new boolean[5];
                    for (CombatText.Label label : text.labels) if (label.kind.ordinal() < 5) kinds[label.kind.ordinal()] = true;
                    for (boolean seen : kinds) if (!seen) throw new AssertionError("Missing effect color");
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080); PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/combat-feedback.png"), p, -1, true); p.dispose();
                }
                if (++frame == 65) { System.out.println("Hidden combat feedback check passed: weak/normal/strong hits, healing and dodge"); Gdx.app.exit(); }
            }
        }, config);
    }
}
