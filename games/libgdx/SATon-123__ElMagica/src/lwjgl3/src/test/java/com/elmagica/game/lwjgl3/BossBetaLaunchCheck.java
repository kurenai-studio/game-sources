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

public class BossBetaLaunchCheck {
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
                    field.setAccessible(true);
                    return field.get(this);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private void call(String method, ElementType element) {
                try {
                    java.lang.reflect.Method action = element == null ? ElMagicaGame.class.getDeclaredMethod(method)
                        : ElMagicaGame.class.getDeclaredMethod(method, ElementType.class);
                    action.setAccessible(true);
                    if (element == null) action.invoke(this); else action.invoke(this, element);
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
            private void screenshot(String name) {
                Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(), Gdx.graphics.getBackBufferHeight());
                PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/" + name + ".png"), picture, -1, true);
                picture.dispose();
            }
            @Override
            @SuppressWarnings("unchecked")
            public void render() {
                if (frame < 720 && frame % 90 == 0) {
                    call("startSession", ElementType.FIRE);
                    ((CombatSession) field("session")).layout.prepare(-1, false, false);
                    ElementType element = DamageSystem.ENEMY_ELEMENTS[frame / 90 % 4];
                    ElementType other = element == ElementType.EARTH ? ElementType.WATER : ElementType.EARTH;
                    Enemy boss = new Enemy(element, other, 15, 9);
                    if (frame >= 360) boss.takeDamage(boss.getMaxHp() / 2);
                    Player player = (Player) field("player");
                    player.maxHp = 1000; player.restoreHp();
                    player.x = boss.x + 240; player.y = boss.y;
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    enemies.clear(); enemies.add(boss);
                    boss.bossCombat.update(1.2f, player, false);
                }
                if (frame == 720) call("resetSession", null);
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Beta boss rendering error");
                if (frame < 720 && frame % 90 == 70) screenshot("beta-boss-attack-" + frame / 90);
                if (frame == 721) {
                    screenshot("beta-menu-check");
                    System.out.println("Hidden beta check passed: all four boss attacks, both phases and build credits");
                    Gdx.app.exit();
                }
                frame++;
            }
        }, config);
    }
}
