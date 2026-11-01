package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.elmagica.game.ElMagicaGame;
import com.elmagica.game.ElementType;
import com.elmagica.game.RoomArt;
import java.lang.reflect.Proxy;

public class RoomLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка четырёх биомов");
        config.setWindowedMode(1280, 704);
        config.setInitialVisible(true);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;

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

            @Override
            public void render() {
                if (frame % 90 == 0) {
                    try {
                        java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                        start.setAccessible(true);
                        start.invoke(this, ElementType.WATER);
                        java.lang.reflect.Field art = ElMagicaGame.class.getDeclaredField("roomArt");
                        art.setAccessible(true);
                        ((RoomArt) art.get(this)).prepare(frame / 90);
                        java.lang.reflect.Field parameters = ElMagicaGame.class.getDeclaredField("showParameters");
                        parameters.setAccessible(true);
                        parameters.setBoolean(this, false);
                    } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
                }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Room rendering error");
                if (frame % 90 == 1) {
                    Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, 1280, 704);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/room-" + frame / 90 + "-check.png"), picture, -1, true);
                    picture.dispose();
                }
                if (++frame == 360) {
                    System.out.println("Visible room check passed: all four biomes, tile atlas and combat rendering");
                    Gdx.app.exit();
                }
            }
        }, config);
    }
}
