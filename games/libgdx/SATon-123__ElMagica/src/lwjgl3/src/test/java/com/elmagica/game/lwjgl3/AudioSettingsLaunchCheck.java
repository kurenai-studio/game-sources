package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.elmagica.game.*;
import java.lang.reflect.Proxy;
import java.util.HashMap;

public class AudioSettingsLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false); config.disableAudio(true);
        config.setForegroundFPS(60); config.setIdleFPS(60);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame; GameAudio audio; HashMap<String, Float> saved = new HashMap<>();
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            void set(String name, Object value) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); f.set(this, value); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @Override public void create() {
                super.create(); set("settingsOpen", true); GameText.english = false;
                audio = (GameAudio) field("audio"); audio.setVolumes(0.35f, 0.65f);
                set("preferences", Proxy.newProxyInstance(Preferences.class.getClassLoader(), new Class<?>[]{Preferences.class}, (proxy, method, values) -> {
                    if (method.getName().equals("putFloat")) { saved.put((String) values[0], (Float) values[1]); return proxy; }
                    if (method.getName().startsWith("put")) return proxy;
                    return null;
                }));
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    boolean effects = frame == 10 || frame >= 40 && frame <= 59;
                    float x = frame == 10 || frame >= 20 && frame <= 39 ? 446 : 834;
                    Vector2 point = ((FitViewport) field("uiViewport")).project(new Vector2(x, effects ? 498 : 578));
                    if (method.getName().equals("getX")) return Math.round(point.x);
                    if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - Math.round(point.y);
                    if (method.getName().equals("isButtonJustPressed")) return frame == 5 || frame == 10 || frame >= 20 && frame <= 59;
                    if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
            }
            @Override public void render() {
                super.render();
                if (frame == 6 && (Math.abs(audio.getMusicVolume() - 0.45f) > 0.001f || audio.getEffectsVolume() != 0.65f)) throw new AssertionError("Music volume independence");
                if (frame == 11 && (Math.abs(audio.getEffectsVolume() - 0.55f) > 0.001f || Math.abs(audio.getMusicVolume() - 0.45f) > 0.001f)) throw new AssertionError("Effects volume independence");
                if (frame == 61) {
                    if (audio.getMusicVolume() != 0 || audio.getEffectsVolume() != 1 || saved.get("musicVolume") != 0 || saved.get("effectsVolume") != 1) throw new AssertionError("Volume limits or saved preferences");
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080); PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/audio-settings.png"), p, -1, true); p.dispose();
                }
                if (++frame == 65) { System.out.println("Hidden audio settings check passed: separate buttons, mute, limits and persistence"); Gdx.app.exit(); }
            }
        }, config);
    }
}
