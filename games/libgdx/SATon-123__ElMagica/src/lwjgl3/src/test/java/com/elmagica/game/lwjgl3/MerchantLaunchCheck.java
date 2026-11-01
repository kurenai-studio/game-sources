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

public class MerchantLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setWindowedMode(1920, 1080); config.setInitialVisible(false);
        config.setForegroundFPS(60); config.setIdleFPS(60); config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame; Player player; CombatSession session; long paid; int healedHp;
            Object field(String name) {
                try { var f = ElMagicaGame.class.getDeclaredField(name); f.setAccessible(true); return f.get(this); }
                catch (Exception e) { throw new RuntimeException(e); }
            }
            @Override public void create() {
                super.create(); Input original = Gdx.input;
                Gdx.input = (Input) Proxy.newProxyInstance(Input.class.getClassLoader(), new Class<?>[]{Input.class}, (proxy, method, values) -> {
                    if (method.getName().equals("isKeyJustPressed")) return (int) values[0] == Input.Keys.E && (frame == 30 || frame == 90 || frame == 150 || frame == 210);
                    if (method.getName().equals("isKeyPressed")) return (int) values[0] == Input.Keys.E;
                    if (method.getName().startsWith("isButton")) return false;
                    return method.invoke(original, values);
                });
                try { var m = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class); m.setAccessible(true); m.invoke(this, ElementType.FIRE); }
                catch (Exception e) { throw new RuntimeException(e); }
                player = (Player) field("player"); session = (CombatSession) field("session");
                ((Array<?>) field("enemies")).clear(); session.layout.prepare(-1, false, false);
                session.layout.addMerchantObjects();
                session.merchant = new Merchant(player, 95); session.addCoins(500); session.checkFloorCleared(new Array<Enemy>());
                player.x = Merchant.itemX(0) - 30; player.y = Merchant.ITEM_Y - 107;
            }
            @Override public void render() {
                if (frame == 60) { player.x = Merchant.X - 30; player.y = Merchant.Y - 105; }
                if (frame == 120) { player.x = Merchant.itemX(1) - 30; player.y = Merchant.ITEM_Y - 107; }
                if (frame == 180) { player.takeDamage(10); healedHp = Math.min(player.maxHp, player.getHp() + MerchantItem.healing(player)); player.x = Merchant.itemX(2) - 30; }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Merchant GL error");
                if (frame == 31) {
                    if (!session.merchant.items[0].sold || session.getCoins() != 482) throw new AssertionError("E purchase failed");
                    paid = session.getCoins();
                }
                if (frame == 59 && session.getCoins() != paid) throw new AssertionError("Held E repeated purchase");
                if (frame == 91 && session.merchant.getMessage().isEmpty()) throw new AssertionError("Advice failed");
                if (frame == 91 && (!session.merchant.isTalking() || !session.layout.canStand(player.x, player.y, Player.SIZE))) throw new AssertionError("Physical talk interaction failed");
                if (frame == 151 && player.explosionRadius != 60) throw new AssertionError("Ability purchase failed");
                if (frame == 211 && player.getHp() != healedHp) throw new AssertionError("Heal purchase failed");
                if (frame == 1 || frame == 91 || frame == 151) {
                    Pixmap p = Pixmap.createFromFrameBuffer(0, 0, 1920, 1080);
                    PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/merchant-" + frame + ".png"), p, -1, true); p.dispose();
                }
                if (++frame == 240) { System.out.println("Hidden merchant launch passed: rendering, E purchases, held key, advice, ability and heal"); Gdx.app.exit(); }
            }
        }, config);
    }
}
