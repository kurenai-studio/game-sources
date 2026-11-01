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

public class HudScaleLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame, saves;
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            void set(String name, Object value) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); f.set(this, value); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @Override protected void saveSettings() { saves++; }
            Vector2 mouse() {
                float x = frame == 20 || frame >= 45 && frame <= 64 ? 446 : 834;
                float y = 314;
                if (frame == 90) { x = 1020; y = 665; }
                if (frame == 100) { x = 640; y = 426; }
                return ((FitViewport) field("uiViewport")).project(new Vector2(x, y));
            }
            @Override public void create() {
                super.create(); set("hudScale", 1f); set("settingsOpen", true); set("showParameters", true);
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    if (method.getName().equals("getX")) return Math.round(mouse().x);
                    if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - Math.round(mouse().y);
                    if (method.getName().equals("isButtonJustPressed")) return frame == 10 || frame == 20 || frame >= 30 && frame <= 39 || frame >= 45 && frame <= 64 || frame == 90 || frame == 100;
                    if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
            }
            @Override @SuppressWarnings("unchecked") public void render() {
                if (frame == 80) {
                    try { var m = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class); m.setAccessible(true); m.invoke(this, ElementType.FIRE); }
                    catch (Exception e) { throw new RuntimeException(e); }
                    set("hudScale", 1.25f);
                    CombatSession session = (CombatSession) field("session"); session.merchant = null;
                    Array<Enemy> enemies = (Array<Enemy>) field("enemies"); enemies.clear();
                    enemies.add(new Enemy(ElementType.WATER, ElementType.FIRE, 15, 9));
                }
                if (frame == 110) {
                    set("settingsOpen", false); set("pauseMenuOpen", false); set("hudScale", 0.75f);
                    CombatSession session = (CombatSession) field("session");
                    ((Array<?>) field("enemies")).clear(); session.merchant = new Merchant((Player) field("player"), 0);
                    session.checkFloorCleared(new Array<Enemy>());
                }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("HUD scale rendering error");
                if (frame == 11 && Math.abs((float) field("hudScale") - 1.05f) > 0.001f) throw new AssertionError("Plus button");
                if (frame == 21 && (float) field("hudScale") != 1) throw new AssertionError("Minus button");
                if (frame == 40 && (float) field("hudScale") != 1.25f) throw new AssertionError("Maximum scale");
                if (frame == 65 && ((float) field("hudScale") != 0.75f || saves != 32)) throw new AssertionError("Minimum scale or save");
                if (frame == 91 && !(boolean) field("pauseMenuOpen")) throw new AssertionError("Scaled menu hitbox");
                if (frame == 101 && !(boolean) field("settingsOpen")) throw new AssertionError("In-game settings");
                if (frame == 40 || frame == 81 || frame == 111) {
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/hud-scale-" + frame + ".png"), p, -1, true); p.dispose();
                }
                if (++frame == 120) { System.out.println("Hidden HUD scale check passed: controls, limits, save calls, scaled menu click and merchant text"); Gdx.app.exit(); }
            }
        }, config);
    }
}
