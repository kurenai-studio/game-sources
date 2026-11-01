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

public class AttackAnimationLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame; boolean[] fired = new boolean[4]; boolean[] mageCast = new boolean[4];
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            Vector2 mouse() { return ((FitViewport) field("viewport")).project(new Vector2(1400, 650)); }
            @Override public void create() {
                super.create(); Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    if (method.getName().equals("getX")) return Math.round(mouse().x);
                    if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - Math.round(mouse().y);
                    if (method.getName().equals("isButtonPressed")) return (int) values[0] == Input.Buttons.LEFT;
                    if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
            }
            @Override @SuppressWarnings("unchecked") public void render() {
                int type = frame / 150;
                if (frame % 150 == 0) {
                    try {
                        var method = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                        method.setAccessible(true); method.invoke(this, DamageSystem.PLAYER_ELEMENTS[type]);
                    } catch (Exception e) { throw new RuntimeException(e); }
                    CombatSession session = (CombatSession) field("session");
                    session.merchant = null; session.layout.prepare(-1, false, false);
                    Player player = (Player) field("player"); player.x = 700; player.y = 500;
                    player.maxHp = 10000; player.restoreHp();
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies"); enemies.clear();
                    Enemy shooter = Enemy.shooter(player.element, 16, 5); shooter.room = session.layout; enemies.add(shooter);
                }
                super.render();
                if (((Player) field("player")).getCastTimer() > 0) mageCast[type] = true;
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Attack animation GL error");
                Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                if (enemies.first().shooterCombat.getCastTimer() > 0 && !fired[type]) {
                    fired[type] = true;
                    Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/attack-animation-" + type + ".png"), picture, -1, true); picture.dispose();
                }
                if (++frame == 600) {
                    for (boolean shot : fired) if (!shot) throw new AssertionError("Shooter never fired");
                    for (boolean cast : mageCast) if (!cast) throw new AssertionError("Mage never cast");
                    System.out.println("Hidden animation check passed: mage and shooter attacks in all four elements"); Gdx.app.exit();
                }
            }
        }, config);
    }
}
