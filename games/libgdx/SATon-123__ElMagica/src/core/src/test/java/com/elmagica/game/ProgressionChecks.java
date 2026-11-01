package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class ProgressionChecks {
    public static void run() {
        checkRoles();
        checkUpgrades();
        checkBossReward();
        checkSpellGrowth();
        checkDodge();
        System.out.println("Progression checks passed: roles, scaling, boss rewards, cooldown, upgraded spells and dodge");
    }

    private static void checkRoles() {
        Enemy slime = new Enemy(ElementType.FIRE, 5, 5);
        Enemy snake = Enemy.snake(ElementType.FIRE, 5, 5);
        Enemy shooter = Enemy.shooter(ElementType.FIRE, 5, 5);
        Enemy boss = new Enemy(ElementType.FIRE, ElementType.EARTH, 5, 5);
        require(slime.getHp() == 30 && snake.getHp() == 20 && shooter.getHp() == 12 && boss.getHp() == 180, "Enemy role HP");
        require(slime.contactDamage(ElementType.FIRE) == 2 && snake.contactDamage(ElementType.FIRE) == 3
            && shooter.contactDamage(ElementType.FIRE) == 4 && boss.attackDamage(ElementType.FIRE, ElementType.FIRE) == 5, "Enemy role damage");
        require(shooter.attackDamage(ElementType.FIRE, ElementType.AIR) == 6
            && shooter.attackDamage(ElementType.FIRE, ElementType.WATER) == 2, "Shooter elemental multiplier");
        for (Enemy enemy : new Enemy[]{slime, snake, shooter, boss}) {
            int hp = enemy.getMaxHp();
            int damage = enemy.contactDamage(ElementType.FIRE);
            enemy.scaleDifficulty(10);
            require(enemy.getHp() == Math.round(hp * 1.8f), "HP scaling");
            require(enemy.contactDamage(ElementType.FIRE) > damage, "Damage scaling");
            require(enemy.speedScale() > 1 && enemy.attackRate() > 1 && enemy.rangeScale() > 1, "AI scaling");
        }
        Enemy later = new Enemy(ElementType.FIRE, 5, 5);
        later.scaleDifficulty(0, 101);
        require(later.getHp() == 78 && later.contactDamage(ElementType.FIRE) == 4, "Floor progression without boss rewards");
        require(later.speedScale() > 1 && later.attackRate() > 1, "Floors strengthen enemy movement and attacks");
        require(CombatSession.floorMaximum(4) == 7 && CombatSession.floorMaximum(3) == 6, "Total grows every three floors");
        require(CombatSession.screenMaximum(10) == 3 && CombatSession.screenMaximum(11) == 4, "Active limit grows every ten floors");
        Player player = new Player(ElementType.WATER);
        player.x = snake.x + 200; player.y = snake.y;
        snake.update(0, player);
        snake.update(0.49f, player);
        require(snake.snakeCombat.isCharging(), "Difficulty preserves snake windup time");
        snake.update(0.02f, player);
        require(snake.snakeCombat.isDashing(), "Snake still dashes after half a second");
        shooter.shooterCombat.update(1, player, false);
        shooter.shooterCombat.update(0.59f, player, false);
        require(shooter.shooterCombat.isAiming() && shooter.shooterCombat.shots.isEmpty(), "Difficulty preserves shooter aim time");
        shooter.shooterCombat.update(0.02f, player, false);
        require(shooter.shooterCombat.shots.size == 1, "Shooter fires after full aim delay");
    }

    private static void checkUpgrades() {
        Player player = new Player(ElementType.FIRE);
        for (int choice = 0; choice < 7; choice++) PlayerUpgrade.apply(player, choice);
        require(player.speed > 200 && player.baseDamage > 10 && player.maxHp == 24
            && player.attackCooldown < 0.5f && player.projectileSpeed > 600
            && player.explosionRadius == 60 && player.dodgeChance > 0, "All upgrade choices work");
        player.shotFired();
        player.updateShooting(player.attackCooldown - 0.001f);
        require(!player.canShoot(), "Upgraded cooldown still cannot be spammed");
        player.updateShooting(0.002f);
        require(player.canShoot(), "Upgraded cooldown expires");
        Player fresh = new Player(ElementType.FIRE);
        require(fresh.maxHp == 20 && fresh.baseDamage == 10 && fresh.dodgeChance == 0, "New session starts fresh");
        for (int i = 0; i < 100; i++) {
            PlayerUpgrade.apply(player, 0); PlayerUpgrade.apply(player, 3); PlayerUpgrade.apply(player, 4);
            PlayerUpgrade.apply(player, 5); PlayerUpgrade.apply(player, 6);
        }
        require(player.speed <= 400 && player.attackCooldown >= 0.12f && player.projectileSpeed <= 1400
            && player.dodgeChance <= 0.3f && player.explosionRadius <= 128, "Progression caps stay playable");
    }

    private static void checkBossReward() {
        MathUtils.random.setSeed(73);
        Player player = new Player(ElementType.WATER);
        player.takeDamage(15);
        CombatSession session = new CombatSession();
        Enemy boss = new Enemy(ElementType.FIRE, ElementType.EARTH, 10, 6);
        while (boss.isAlive()) session.hit(boss, player.element, player);
        PlayerUpgrade reward = session.getReward();
        require(reward != null && session.getDifficulty() == 1 && session.getScore() == 5
            && player.getHp() == player.maxHp, "Boss grants one upgrade, heal and difficulty level");
        session.hit(boss, player.element, player);
        require(session.getReward() == reward && session.getDifficulty() == 1, "Corpse cannot reward again");
        Array<Enemy> enemies = new Array<>();
        session.updateWaves(100, player, enemies);
        require(enemies.isEmpty() && session.getWave() == 0, "Reward stops spawning until confirmed");
        session.acceptReward();
        session.updateWaves(0, player, enemies);
        require(!enemies.isEmpty() && enemies.first().getHp() > Enemy.MAX_HP, "Next enemies use new difficulty");
        session.reset();
        require(session.getReward() == null && session.getDifficulty() == 0 && session.getScore() == 0, "Session clears progression");
        Player strong = new Player(ElementType.FIRE);
        PlayerUpgrade.apply(strong, 1);
        Enemy target = new Enemy(ElementType.FIRE, 8, 6);
        session.hit(target, strong.element, strong);
        require(target.getHp() == 18, "Base damage upgrade affects real hits and rounding");
    }

    private static void checkSpellGrowth() {
        CombatSession session = new CombatSession();
        Player water = new Player(ElementType.WATER);
        PlayerUpgrade.apply(water, 5);
        Array<Enemy> enemies = new Array<>();
        for (int i = 0; i < 4; i++) enemies.add(new Enemy(ElementType.WATER, 6 + i, 6));
        Projectile shot = new Projectile(200, 200, new Vector2(1, 0), water.element);
        require(PlayerSpells.hit(shot, enemies.get(0), enemies, session, water), "Upgraded water first pierce");
        require(PlayerSpells.hit(shot, enemies.get(1), enemies, session, water), "Upgraded water second pierce");
        require(!PlayerSpells.hit(shot, enemies.get(2), enemies, session, water), "Upgraded water stops at third");
        PlayerSpells.hit(shot, enemies.get(3), enemies, session, water);
        require(enemies.get(3).getHp() == 30, "Water has finite target limit");
        Player air = new Player(ElementType.AIR); PlayerUpgrade.apply(air, 5);
        for (Enemy enemy : enemies) enemy.reset();
        shot = new Projectile(200, 200, new Vector2(1, 0), air.element, 720);
        require(PlayerSpells.hit(shot, enemies.get(0), enemies, session, air), "Air first bounce");
        require(PlayerSpells.hit(shot, enemies.get(1), enemies, session, air), "Upgraded air second bounce");
        float x = shot.position.x, y = shot.position.y;
        shot.update(0.1f);
        require(Math.abs(Vector2.dst(x, y, shot.position.x, shot.position.y) - 72) < 0.01f, "Ricochet preserves projectile speed");
        require(!PlayerSpells.hit(shot, enemies.get(2), enemies, session, air), "Air ends at finite limit");
        Player fire = new Player(ElementType.FIRE); PlayerUpgrade.apply(fire, 5);
        Enemy first = new Enemy(ElementType.FIRE, 6, 6);
        Enemy near = new Enemy(ElementType.FIRE, 6, 6); near.x = first.x + 85;
        enemies.clear(); enemies.add(first); enemies.add(near);
        PlayerSpells.hit(new Projectile(0, 0, new Vector2(1, 0), fire.element), first, enemies, session, fire);
        require(near.getHp() == 20, "Expanded explosion hits beyond old radius");
        Player earth = new Player(ElementType.EARTH); PlayerUpgrade.apply(earth, 5);
        first.reset(); float before = first.x;
        PlayerSpells.hit(new Projectile(0, 0, new Vector2(1, 0), earth.element), first, enemies, session, earth);
        require(first.x == before + 80 && first.slowScale() < 0.5f, "Earth grows knockback and slow");
    }

    private static void checkDodge() {
        MathUtils.random.setSeed(901);
        Player player = new Player(ElementType.FIRE);
        for (int i = 0; i < 10; i++) PlayerUpgrade.apply(player, 6);
        int dodges = 0;
        for (int i = 0; i < 1000; i++) {
            player.restoreHp(); player.takeDamage(5);
            if (player.getHp() == player.maxHp) dodges++;
        }
        require(dodges > 240 && dodges < 360, "Dodge chance avoids complete hits at expected rate");
    }

    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
}
