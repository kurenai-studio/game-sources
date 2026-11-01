package com.elmagica.game;

import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class ShooterCombat {
    public static final float AIM_TIME = 0.6f;
    public final Array<Projectile> shots = new Array<>();
    private final Enemy owner;
    private final Vector2 direction = new Vector2();
    private float wait = 1.2f;
    private float charge;
    private boolean aiming;
    private float castTimer;
    public float getCastTimer() { return castTimer; }
    public float getAngle() { return direction.angleDeg(); }
    public ShooterCombat(Enemy owner) { this.owner = owner; }
    public boolean isAiming() { return aiming; }
    public float getCharge() { return charge; }

    public void update(float delta, Player player, boolean jumping) {
        castTimer = Math.max(0, castTimer - delta);
        if (!owner.isAlive() || !player.isAlive()) { clear(); return; }
        for (int i = shots.size - 1; i >= 0; i--) {
            Projectile shot = shots.get(i);
            shot.update(delta);
            float wall = shot.obstacleTime(owner.room);
            float hit = shot.hitTime(player);
            if (wall < 1 && wall <= hit) {
                shots.removeIndex(i);
            } else if (Float.isFinite(hit)) {
                player.takeDamage(owner.attackDamage(owner.element, player.element), DamageSystem.damageToPlayer(owner.element, player.element));
                shots.removeIndex(i);
                if (!player.isAlive()) { clear(); return; }
            } else if (shot.outsideRoom()) shots.removeIndex(i);
        }
        if (jumping) return;
        if (aiming) {
            charge += delta;
            if (charge >= AIM_TIME) {
                shots.add(new Projectile(owner.x + owner.getSize() / 2, owner.y + owner.getSize() / 2,
                    direction, owner.element, 280 * owner.speedScale()));
                castTimer = Player.CAST_TIME;
                GameAudio.play(GameAudio.Cue.ENEMY_SHOT);
                aiming = false;
                charge = 0;
                wait = 1.8f;
            }
            return;
        }
        wait -= delta * owner.attackRate();
        if (wait <= 0) {
            if (owner.room != null && owner.room.shotTime(new Vector2(owner.x + 30, owner.y + 30),
                new Vector2(player.x + 30, player.y + 30), Projectile.HALF_SIZE) < 1) return;
            // Фиксируем прицел заранее, чтобы от выстрела можно было уйти.
            direction.set(player.x + Player.SIZE / 2 - owner.x - owner.getSize() / 2,
                player.y + Player.SIZE / 2 - owner.y - owner.getSize() / 2).nor();
            if (direction.isZero()) direction.set(1, 0);
            aiming = true;
            charge = 0;
        }
    }

    public void draw(ShapeRenderer shapes) {
        // Подготовку не подсвечиваем, рисуем уже выпущенную атаку.
        for (Projectile shot : shots) SpellVisuals.projectile(shapes, shot, true);
    }
    public void drawCast(ShapeRenderer shapes) {
        SpellVisuals.cast(shapes, owner.element, owner.x + owner.getSize() / 2,
            owner.y + owner.getSize() / 2, getAngle(), castTimer);
    }

    public void clear() { shots.clear(); aiming = false; charge = 0; castTimer = 0; wait = 1.2f; }
}
