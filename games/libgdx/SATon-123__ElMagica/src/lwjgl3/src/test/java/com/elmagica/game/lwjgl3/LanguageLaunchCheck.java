package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.Preferences;
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

public class LanguageLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame, flushes; String savedLanguage = "ru";
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            void set(String name, Object value) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); f.set(this, value); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @SuppressWarnings({"unchecked", "rawtypes"}) void menu(String name) { set("menuPage", Enum.valueOf((Class) field("menuPage").getClass(), name)); }
            @Override public void create() {
                super.create(); GameText.english = false; set("settingsOpen", true); set("hudScale", 1f); set("showParameters", true);
                Preferences originalPreferences = (Preferences) field("preferences");
                set("preferences", Proxy.newProxyInstance(Preferences.class.getClassLoader(), new Class<?>[]{Preferences.class}, (proxy, method, values) -> {
                    if (method.getName().equals("putString")) { if (values[0].equals("language")) savedLanguage = (String) values[1]; return proxy; }
                    if (method.getName().startsWith("put")) return proxy;
                    if (method.getName().equals("flush")) { flushes++; return null; }
                    if (method.getName().equals("getString") && values[0].equals("language")) return savedLanguage;
                    return method.invoke(originalPreferences, values);
                }));
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    Vector2 point = ((FitViewport) field("uiViewport")).project(new Vector2(640, 204));
                    if (method.getName().equals("getX")) return Math.round(point.x);
                    if (method.getName().equals("getY")) return Gdx.graphics.getHeight() - Math.round(point.y);
                    if (method.getName().equals("isButtonJustPressed")) return frame == 5 || frame == 105 || frame == 110 || frame == 145;
                    if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
            }
            @Override @SuppressWarnings("unchecked") public void render() {
                if (frame == 10) set("settingsOpen", false);
                if (frame == 20) menu("ELEMENTS");
                if (frame == 30) menu("CONTROLS");
                if (frame == 40) menu("MECHANICS");
                if (frame >= 40 && frame <= 70 && frame % 10 == 0) set("mechanicsPage", (frame - 40) / 10);
                if (frame == 72 || frame == 76) set("mechanicsPage", 4);
                if (frame == 74 || frame == 78) set("mechanicsPage", 5);
                if (frame == 76) GameText.english = false;
                if (frame == 80) {
                    GameText.english = true;
                    try { var m = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class); m.setAccessible(true); m.invoke(this, ElementType.WATER); }
                    catch (Exception e) { throw new RuntimeException(e); }
                    CombatSession session = (CombatSession) field("session"); Player player = (Player) field("player");
                    ((Array<?>) field("enemies")).clear(); session.layout.prepare(-1, false, false);
                    session.merchant = new Merchant(player, 95); session.checkFloorCleared(new Array<Enemy>());
                    player.x = Merchant.X - 30; player.y = Merchant.Y - 90; session.merchant.interact(player, session);
                }
                if (frame == 90) set("pauseMenuOpen", true);
                if (frame == 100) set("settingsOpen", true);
                if (frame == 120) {
                    set("settingsOpen", false); set("pauseMenuOpen", false);
                    CombatSession session = (CombatSession) field("session"); Player player = (Player) field("player");
                    Enemy boss = new Enemy(ElementType.FIRE, ElementType.EARTH, 15, 9);
                    player.baseDamage = 10000; session.hit(boss, player.element, player);
                }
                if (frame == 130) {
                    ((CombatSession) field("session")).acceptReward();
                    Player player = (Player) field("player"); player.dodgeChance = 0; player.takeDamage(10000);
                }
                if (frame == 140) set("settingsOpen", true);
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Language rendering error");
                if ((frame == 6 || frame == 111) && (!GameText.english || !savedLanguage.equals("en"))) throw new AssertionError("English selection not saved");
                if ((frame == 106 || frame == 146) && (GameText.english || !savedLanguage.equals("ru"))) throw new AssertionError("Russian selection not saved");
                if (frame == 6 || frame == 11 || frame == 21 || frame == 31 || frame == 41 || frame == 51 || frame == 61
                    || frame == 71 || frame == 73 || frame == 75 || frame == 77 || frame == 79
                    || frame == 81 || frame == 91 || frame == 106 || frame == 121 || frame == 131) {
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/language-" + frame + ".png"), p, -1, true); p.dispose();
                }
                if (++frame == 150) {
                    if (flushes != 4) throw new AssertionError("Language preferences not flushed");
                    System.out.println("Hidden language check passed: RU/EN switching, saved selection, all menus, merchant, reward and death"); Gdx.app.exit();
                }
            }
        }, config);
    }
}
