package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;

public class BossAttackChecks {
    public static void run() {
        MathUtils.random.setSeed(123);
        for (ElementType type : DamageSystem.ENEMY_ELEMENTS) {
            Enemy boss = boss(type);
            Player player = target(boss, type == ElementType.WATER ? ElementType.FIRE : ElementType.AIR);
            BossAttack attack = new BossAttack(type, boss, player);
            if (type == ElementType.EARTH) {
                require(attack.range == 318 || attack.range == 382, "Earth reaches 4-5 tiles beyond body");
            }
            if (type == ElementType.FIRE) require(attack.range == 320 || attack.range == 384, "Fire reaches 5-6 tiles");
            attack.update(0.64f, player);
            require(player.getHp() == 20, "Warning deals no damage");
            attack.update(0.5f, player);
            if (type != ElementType.AIR) {
                require(player.getHp() == 20 - boss.attackDamage(type, player.element), "Elemental ability damage");
                int hp = player.getHp();
                attack.update(10, player);
                require(player.getHp() == hp, "Wave, jet and cone hit only once");
            }
            attack.update(10, player);
            require(attack.isFinished(), "Attack expires with large delta");
        }

        Enemy fireBoss = boss(ElementType.FIRE);
        Player target = target(fireBoss, ElementType.AIR);
        BossAttack cone = new BossAttack(ElementType.FIRE, fireBoss, target);
        target.x = cone.x - 30;
        target.y = cone.y + 130;
        cone.update(2, target);
        require(target.getHp() == 20, "Outside 60-degree cone is safe");
        BossAttack behind = new BossAttack(ElementType.FIRE, fireBoss, target(fireBoss, ElementType.AIR));
        target.x = behind.x - 180;
        target.y = behind.y - 30;
        behind.update(2, target);
        require(target.getHp() == 20, "Behind fire cone is safe");

        Enemy waterBoss = boss(ElementType.WATER);
        Player dodge = target(waterBoss, ElementType.FIRE);
        BossAttack jet = new BossAttack(ElementType.WATER, waterBoss, dodge);
        dodge.y += 100;
        jet.update(2, dodge);
        require(dodge.getHp() == 20, "Water aim locks during warning and can be dodged");

        Enemy earthBoss = boss(ElementType.EARTH);
        Player outside = target(earthBoss, ElementType.WATER);
        BossAttack wave = new BossAttack(ElementType.EARTH, earthBoss, outside);
        outside.x = wave.x + wave.range + 40;
        wave.update(2, outside);
        require(outside.getHp() == 20, "Outside earth wave is safe");

        Enemy airBoss = boss(ElementType.AIR);
        Player airTarget = target(airBoss, ElementType.FIRE);
        BossAttack spirals = new BossAttack(ElementType.AIR, airBoss, airTarget);
        spirals.update(1.2f, airTarget);
        require(airTarget.getHp() < 20, "Curving air projectiles collide with player");
        airTarget.x = ElMagicaGame.WORLD_WIDTH - 124;
        airTarget.y = ElMagicaGame.WORLD_HEIGHT - 124;
        int hp = airTarget.getHp();
        spirals.update(10, airTarget);
        require(airTarget.getHp() == hp, "Distant player avoids remaining spirals");

        Enemy seriesBoss = boss(ElementType.WATER);
        Player seriesTarget = new Player(ElementType.FIRE);
        seriesTarget.maxHp = 1000;
        seriesTarget.restoreHp();
        seriesTarget.x = seriesBoss.x + 220;
        seriesTarget.y = seriesBoss.y;
        int waterCount = 0;
        BossAttack previous = null;
        boolean earthStarted = false;
        for (int frame = 0; frame < 400; frame++) {
            seriesBoss.bossCombat.update(0.05f, seriesTarget, false);
            BossAttack current = seriesBoss.bossCombat.getCurrent();
            if (current != null && current != previous) {
                if (current.element == ElementType.WATER) waterCount++;
                else {
                    earthStarted = true;
                    break;
                }
            }
            previous = current;
        }
        require(waterCount == 3 && earthStarted, "Water burst then second element");
        seriesBoss.takeDamage(seriesBoss.getMaxHp());
        require(seriesBoss.bossCombat.attacks.isEmpty(), "Boss death cancels hazards immediately");
        seriesBoss.bossCombat.update(10, seriesTarget, false);
        require(seriesBoss.bossCombat.attacks.isEmpty(), "Dead boss cannot start attacks");
        Enemy deadPlayerBoss = boss(ElementType.FIRE);
        Player deadPlayer = target(deadPlayerBoss, ElementType.WATER);
        deadPlayerBoss.bossCombat.update(2, deadPlayer, false);
        deadPlayer.takeDamage(20);
        deadPlayerBoss.bossCombat.update(1, deadPlayer, false);
        require(deadPlayerBoss.bossCombat.attacks.isEmpty(), "Player death cancels hazards");
        System.out.println("Boss attack checks passed: ranges, warnings, collisions, bursts, dodging and cleanup");
    }

    private static Enemy boss(ElementType first) {
        ElementType second = ElementType.EARTH;
        if (first == second) second = ElementType.WATER;
        return new Enemy(first, second, 9, 5);
    }

    private static Player target(Enemy boss, ElementType element) {
        Player player = new Player(element);
        player.x = boss.x + boss.getSize() / 2 + 120;
        player.y = boss.y + boss.getSize() / 2 - Player.SIZE / 2;
        return player;
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
}
