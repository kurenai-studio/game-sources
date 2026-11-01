package com.elmagica.game;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class CombatFeaturesChecks {
    public static void run() {
        checkSpells();
        checkShooter();
        checkEnrage();
        System.out.println("Combat feature checks passed: elemental spells, shooter AI, shot cleanup and boss phase two");
    }

    private static void checkSpells() {
        Player player = new Player(ElementType.FIRE);
        CombatSession session = new CombatSession();
        Array<Enemy> enemies = new Array<>();
        Enemy first = new Enemy(ElementType.FIRE, 9, 6);
        Enemy nearby = new Enemy(ElementType.WATER, 9, 6);
        nearby.x += 40;
        Enemy far = new Enemy(ElementType.WATER, 15, 6);
        enemies.add(first); enemies.add(nearby); enemies.add(far);
        Projectile fire = new Projectile(100, 100, new Vector2(1, 0), ElementType.FIRE);
        require(!PlayerSpells.hit(fire, first, enemies, session, player), "Fire ends on impact");
        require(first.getHp() == 20 && nearby.getHp() == 25 && far.getHp() == 30, "Fire splash respects radius and elements");
        PlayerSpells.hit(fire, first, enemies, session, player);
        require(first.getHp() == 20 && nearby.getHp() == 25, "No repeated fire damage");

        first.reset(); nearby.reset();
        Projectile water = new Projectile(100, 100, new Vector2(1, 0), ElementType.WATER);
        require(PlayerSpells.hit(water, first, enemies, session, player), "Water pierces first target");
        require(!PlayerSpells.hit(water, nearby, enemies, session, player), "Water stops after second target");
        PlayerSpells.hit(water, far, enemies, session, player);
        require(far.getHp() == 30, "Water cannot hit third target");
        require(!Float.isFinite(water.hitTime(first)), "Water cannot hit same enemy twice");

        first.reset(); nearby.reset();
        Projectile air = new Projectile(100, 100, new Vector2(1, 0), ElementType.AIR);
        require(PlayerSpells.hit(air, first, enemies, session, player), "Air finds nearby ricochet");
        require(air.position.x == first.x + 30, "Ricochet begins at target");
        require(!PlayerSpells.hit(air, nearby, enemies, session, player), "One air ricochet maximum");

        first.reset();
        float x = first.x;
        Projectile earth = new Projectile(100, 100, new Vector2(1, 0), ElementType.EARTH);
        PlayerSpells.hit(earth, first, enemies, session, player);
        require(first.x == x + 64, "Earth knocks slime one tile back");
        Player distant = new Player(ElementType.WATER); distant.x = 1000; distant.y = first.y;
        float before = first.x;
        first.update(0.1f, distant);
        require(Math.abs(first.x - before - 6) < 0.01f, "Earth slows pursuit briefly");
        Enemy boss = new Enemy(ElementType.FIRE, ElementType.WATER, 9, 6);
        x = boss.x;
        boss.knockBack(new Vector2(1, 0), 64);
        require(boss.x == x + 16, "Boss resists knockback");
        player.shotFired();
        require(player.getCastTimer() > 0 && !player.canShoot(), "Cast animation keeps firing cooldown");
    }

    private static void checkShooter() {
        Enemy shooter = Enemy.shooter(ElementType.WATER, 9, 6);
        Player player = new Player(ElementType.FIRE);
        player.x = shooter.x + 250; player.y = shooter.y;
        shooter.shooterCombat.update(1.21f, player, false);
        require(shooter.shooterCombat.isAiming() && shooter.shooterCombat.shots.isEmpty(), "Shooter warns before firing");
        shooter.shooterCombat.update(0.59f, player, false);
        require(shooter.shooterCombat.shots.isEmpty(), "No early shot");
        shooter.shooterCombat.update(0.02f, player, false);
        require(shooter.shooterCombat.shots.size == 1, "Shooter fires one bolt");
        shooter.shooterCombat.update(1, player, false);
        require(player.getHp() == 14 && shooter.shooterCombat.shots.isEmpty(), "Bolt deals elemental damage once");
        shooter.reset();
        shooter.shooterCombat.update(2, player, false);
        player.y += 100;
        shooter.shooterCombat.update(0.61f, player, false);
        shooter.shooterCombat.update(2, player, false);
        require(player.getHp() == 14, "Locked aim can be dodged");
        shooter.takeDamage(20);
        require(shooter.shooterCombat.shots.isEmpty(), "Shooter death clears bolts");
        shooter.reset();
        player.x = shooter.x + 100; player.y = shooter.y;
        float distance = Vector2.dst(player.x, player.y, shooter.x, shooter.y);
        shooter.update(0.1f, player);
        require(Vector2.dst(player.x, player.y, shooter.x, shooter.y) > distance, "Shooter retreats when too close");
        shooter.reset();
        player.x = shooter.x + 500;
        distance = Vector2.dst(player.x, player.y, shooter.x, shooter.y);
        shooter.update(0.1f, player);
        require(Vector2.dst(player.x, player.y, shooter.x, shooter.y) < distance, "Shooter approaches when too far");
    }

    private static void checkEnrage() {
        Enemy boss = new Enemy(ElementType.EARTH, ElementType.FIRE, 9, 6);
        require(!boss.isEnraged(), "Boss starts in phase one");
        boss.takeDamage(boss.getMaxHp() / 2);
        require(boss.isEnraged(), "Phase two at half HP");
        Player player = new Player(ElementType.WATER); player.x = 750; player.y = boss.y;
        boss.bossCombat.update(2, player, false);
        require(boss.bossCombat.attacks.size == 3, "Enraged earth casts three delayed waves");
        BossAttack fire = new BossAttack(ElementType.FIRE, boss, player);
        require(fire.getWarningTime() == 0.5f, "Phase two keeps a readable warning");
        fire.update(0.56f, player);
        float start = fire.getAngle();
        fire.update(0.2f, player);
        require(fire.getAngle() > start, "Enraged fire cone sweeps");
        boss.takeDamage(boss.getMaxHp());
        require(boss.bossCombat.attacks.isEmpty(), "Phase two hazards clear on death");
    }

    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
}
