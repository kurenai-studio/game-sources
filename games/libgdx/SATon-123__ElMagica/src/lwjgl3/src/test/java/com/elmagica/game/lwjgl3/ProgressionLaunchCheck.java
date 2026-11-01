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
import com.elmagica.game.*;
import java.lang.reflect.Proxy;

public class ProgressionLaunchCheck {
    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("ElMagica — проверка прогрессии и награды");
        config.setWindowedMode(1280, 720);
        config.setInitialVisible(false);
        config.setForegroundFPS(60);
        config.useVsync(true);
        config.disableAudio(true);
        new Lwjgl3Application(new ElMagicaGame() {
            int frame;
            int frozenWave;
            float frozenCooldown;
            float frozenX;
            boolean rewarded;

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
                        if (method.getName().equals("getX")) return 640;
                        if (method.getName().equals("getY")) return 720 - (frame == 320 ? 296 : 248);
                        if (method.getName().equals("isButtonJustPressed")) return frame == 180 || frame == 320;
                        if (method.getName().equals("isKeyPressed")) return frame > 60 && frame < 180 && (int) values[0] == Input.Keys.D;
                        if (method.getName().startsWith("isKey") || method.getName().startsWith("isButton")) return false;
                        return method.invoke(original, values);
                    });
                try {
                    java.lang.reflect.Method start = ElMagicaGame.class.getDeclaredMethod("startSession", ElementType.class);
                    start.setAccessible(true);
                    start.invoke(this, ElementType.WATER);
                } catch (ReflectiveOperationException exception) { throw new RuntimeException(exception); }
            }

            private void screenshot(String name) {
                Pixmap picture = Pixmap.createFromFrameBuffer(0, 0, 1280, 720);
                PixmapIO.writePNG(Gdx.files.local("../lwjgl3/build/" + name + ".png"), picture, -1, true);
                picture.dispose();
            }

            @Override
            @SuppressWarnings("unchecked")
            public void render() {
                Player player = (Player) field("player");
                CombatSession session = (CombatSession) field("session");
                Array<Enemy> enemies = (Array<Enemy>) field("enemies");
                Array<Projectile> shots = (Array<Projectile>) field("projectiles");
                if (frame == 0) {
                    enemies.clear();
                    enemies.add(new Enemy(ElementType.EARTH, 12, 8));
                    enemies.add(Enemy.snake(ElementType.WATER, 15, 6));
                    enemies.add(Enemy.shooter(ElementType.FIRE, 14, 3));
                }
                if (frame == 30) {
                    enemies.clear();
                    Enemy boss = new Enemy(ElementType.FIRE, ElementType.AIR, 10, 6);
                    boss.x = player.x + 250; boss.y = player.y;
                    boss.takeDamage(boss.getMaxHp() - 20);
                    enemies.add(boss);
                    player.takeDamage(10);
                    player.shotFired();
                    shots.add(new Projectile(player.x + 30, player.y + 30, new Vector2(1, 0), player.element));
                }
                if (frame == 282) {
                    player.dodgeChance = 0;
                    player.takeDamage(player.getHp());
                }
                if (frame == 200) {
                    player.x = ElMagicaGame.WORLD_WIDTH / 2f - 30;
                    player.y = ElMagicaGame.WORLD_HEIGHT - 124;
                }
                super.render();
                if (Gdx.gl.glGetError() != GL20.GL_NO_ERROR) throw new AssertionError("Progression rendering error");
                if (frame == 1) screenshot("new-health-bars-check");
                if (session.getReward() != null && !rewarded) {
                    rewarded = true;
                    frozenWave = session.getWave();
                    frozenCooldown = player.getCastTimer();
                    frozenX = player.x;
                    if (session.getScore() != 5 || session.getDifficulty() != 1 || !shots.isEmpty()
                        || player.getHp() != player.maxHp) throw new AssertionError("Boss reward and cleanup failed");
                    screenshot("boss-reward-check");
                }
                if (rewarded && frame < 180) {
                    if (session.getWave() != frozenWave || player.x != frozenX || player.getCastTimer() != frozenCooldown
                        || session.getReward() == null) throw new AssertionError("Reward did not freeze combat");
                }
                if (frame == 180 && session.getReward() != null) throw new AssertionError("Continue did not acknowledge reward");
                if (frame == 280) {
                    if (!rewarded || session.getWave() <= frozenWave || enemies.isEmpty()
                        || enemies.first().getHp() != enemies.first().getMaxHp()) throw new AssertionError("Next wave failed");
                    screenshot("progression-next-wave-check");
                }
                if (frame == 285) screenshot("gameover-redesign-check");
                if (frame == 320) {
                    if (field("player") != null || session.getScore() != 0 || session.getDifficulty() != 0)
                        throw new AssertionError("Game over return did not reset session");
                    System.out.println("Visible progression check passed: boss reward, health bars, pause, continue, death screen and main menu reset");
                    Gdx.app.exit();
                }
                frame++;
            }
        }, config);
    }
}
