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

public class SnakeLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка змей");
        config.setWindowedMode(1280, 704);
        config.setInitialVisible(true);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            boolean charged, dashed, hit;
            private Object field(String name) {
                try {
                    java.lang.reflect.Field field = ElMagicaGame.class.getDeclaredField(name);
                    field.setAccessible(true);
                    return field.get(this);
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
                int stage = frame / 120;
                if (frame % 120 == 0) {
                    try {
                        java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                        start.setAccessible(true);
                        start.invoke(this, ElementType.FIRE);
                    } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
                    Player player = (Player) field("player");
                    player.x = 760; player.y = 322;
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                    enemies.clear();
                    enemies.add(Enemy.snake(DamageSystem.ENEMY_ELEMENTS[stage], 10, 6));
                    charged = false; dashed = false; hit = false;
                }
                super.render();
                Enemy snake = ((Array<Enemy>) field("enemies")).first();
                Player player = (Player) field("player");
                if (snake.snakeCombat.isCharging() && !charged && frame % 120 >= 10) {
                    screenshot("snake-charge-" + stage);
                    charged = true;
                }
                if (snake.snakeCombat.isDashing() && !dashed) {
                    screenshot("snake-dash-" + stage);
                    dashed = true;
                }
                if (player.getHp() < 20) hit = true;
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Snake rendering error");
                if (frame % 120 == 119 && (!charged || !dashed || !hit)) throw new AssertionError("Snake did not complete its attack");
                if (++frame >= 480) {
                    System.out.println("Visible snake check passed: all four colors, charge, dash animation and elemental hits");
                    Gdx.app.exit();
                }
            }
        }, config);
    }
}
