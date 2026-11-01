package com.elmagica.game.lwjgl3;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.elmagica.game.ElMagicaGame;
import com.elmagica.game.Player;
import java.lang.reflect.Proxy;

public class SettingsLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка настроек");
        config.setWindowedMode(1280, 720);
        config.setInitialVisible(false);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            int saves;
            int exits;
            int pauseHp;
            float pauseX, pauseY;

            private java.lang.reflect.Field field(String name) {
                try {
                    java.lang.reflect.Field field = ElMagicaGame.class.getDeclaredField(name);
                    field.setAccessible(true);
                    return field;
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private Object value(String name) {
                try { return field(name).get(this); }
                catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }
            private boolean clickFrame() {
                return frame == 30 || frame == 60 || frame == 90 || frame == 105 || frame == 120
                    || frame == 180 || frame == 210 || frame == 240 || frame == 330 || frame == 360
                    || frame == 390 || frame == 420 || frame == 450 || frame == 480 || frame == 510
                    || frame == 540 || frame == 570 || frame == 195 || frame == 255 || frame == 315 || frame == 318 || frame == 585;
            }
            private int mouseX() {
                if (frame == 120) return 258;
                if (frame == 180) return 1158;
                if (frame == 318) return 520;
                if (frame == 420) return 498;
                if (frame == 450) return 780;
                if (frame == 480) return 1062;
                return 640;
            }
            private int mouseY() {
                int worldY = 0;
                if (frame == 30) worldY = 222;
                if (frame == 60 || frame == 210) worldY = 380;
                if (frame == 90 || frame == 240) worldY = 262;
                if (frame == 120) worldY = 400;
                if (frame == 180) worldY = 674;
                if (frame == 195) worldY = 426;
                if (frame == 255) worldY = 198;
                if (frame == 315) worldY = 350;
                if (frame == 318) worldY = 308;
                if (frame == 585) worldY = 148;
                if (frame == 105 || frame == 540) worldY = 470;
                if (frame == 330) worldY = 384;
                if (frame == 390) worldY = 304;
                if (frame == 360 || frame == 510) worldY = 66;
                if (frame == 420 || frame == 450 || frame == 480) worldY = 581;
                if (frame == 570) worldY = 222;
                return 720 - worldY;
            }

            @Override
            protected void saveSettings() {
                saves++;
            }

            @Override
            protected void requestExit() { exits++; }

            @Override
            public void create() {
                super.create();
                try { field("showParameters").setBoolean(this, true); }
                catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
                Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class},
                    (proxy, method, values) -> {
                        if (method.getName().equals("getX")) return mouseX();
                        if (method.getName().equals("getY")) return mouseY();
                        if (method.getName().equals("isButtonJustPressed")) return clickFrame();
                        if (method.getName().equals("isKeyJustPressed")) {
                            return (frame == 300 && (int) values[0] == Input.Keys.ESCAPE)
                                || (frame == 15 && (int) values[0] == Input.Keys.NUM_1);
                        }
                        if (method.getName().equals("isKeyPressed")
                            || method.getName().equals("isButtonPressed")) return false;
                        return method.invoke(original, values);
                    });
            }

            private void screenshot(String name) {
                Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, Gdx.graphics.getBackBufferWidth(), Gdx.graphics.getBackBufferHeight());
                PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/" + name + ".png"), picture, -1, true);
                picture.dispose();
            }

            @Override
            public void render() {
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Settings rendering error");
                boolean open = (boolean) value("settingsOpen");
                boolean shown = (boolean) value("showParameters");
                if (frame == 0) screenshot("menu-check");
                if (frame == 15 && value("player") != null) throw new AssertionError("Element key bypasses Start");
                if (frame == 30 && !open) throw new AssertionError("Menu settings button failed");
                if (frame == 60) {
                    if (shown) throw new AssertionError("Toggle did not hide parameters");
                    screenshot("settings-check");
                }
                if (frame == 90 && open) throw new AssertionError("Back button failed");
                if (frame == 120 && value("player") == null) throw new AssertionError("Element card click failed");
                if (frame == 150) {
                    if (shown) throw new AssertionError("Visibility reset on combat start");
                    screenshot("parameters-hidden-check");
                }
                if (frame == 180) {
                    if (!(boolean) value("pauseMenuOpen") || open) throw new AssertionError("Combat menu button failed");
                    screenshot("pause-menu-check");
                    Player player = (Player) value("player");
                    pauseX = player.x; pauseY = player.y; pauseHp = player.getHp();
                }
                if (frame > 180 && frame < 240) {
                    Player player = (Player) value("player");
                    if (player.x != pauseX || player.y != pauseY || player.getHp() != pauseHp) {
                        throw new AssertionError("Combat did not pause in settings");
                    }
                }
                if (frame == 210 && !shown) throw new AssertionError("Toggle did not enable parameters");
                if (frame == 240 && (!(boolean) value("pauseMenuOpen") || open)) throw new AssertionError("Settings must return to pause menu");
                if (frame == 255 && (boolean) value("pauseMenuOpen")) throw new AssertionError("Resume failed");
                if (frame == 300 && !(boolean) value("pauseMenuOpen")) throw new AssertionError("Escape must pause");
                if (frame == 315 && (!(boolean) value("endSessionPrompt") || value("player") == null)) throw new AssertionError("End session confirmation missing");
                if (frame == 318 && value("player") != null) throw new AssertionError("End session failed");
                if (frame == 270) screenshot("parameters-visible-check");
                if (frame == 330) {
                    if (!value("menuPage").toString().equals("CONTROLS")) throw new AssertionError("Controls navigation");
                    screenshot("controls-check");
                }
                if (frame == 390) {
                    if (!value("menuPage").toString().equals("MECHANICS")) throw new AssertionError("Mechanics navigation");
                    screenshot("mechanics-circle-check");
                }
                if (frame == 420 || frame == 450 || frame == 480) {
                    int expected = (frame - 390) / 30;
                    if ((int) value("mechanicsPage") != expected) throw new AssertionError("Mechanics tab navigation");
                    screenshot("mechanics-" + expected + "-check");
                }
                if (frame == 540) {
                    if (!value("menuPage").toString().equals("ELEMENTS")) throw new AssertionError("Start opens element selection");
                    screenshot("selection-check");
                }
                if (++frame >= 600) {
                    if (saves != 2 || open || !shown || exits != 1) throw new AssertionError("Settings or exit state");
                    if (value("player") != null || !value("menuPage").toString().equals("MAIN")) throw new AssertionError("Return to main menu");
                    System.out.println("Visible menu check passed: Start gate, controls, all mechanics tabs, settings and combat pause");
                    Gdx.app.exit();
                }
            }
        }, config);
    }
}
