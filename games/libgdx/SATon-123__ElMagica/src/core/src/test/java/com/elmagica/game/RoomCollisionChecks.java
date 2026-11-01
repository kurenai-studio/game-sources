package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class RoomCollisionChecks {
    public static void run() {
        checkTemplates(); checkCollision(); checkNavigation(); checkBossApproach(); checkLoot();
        checkObstacleVariants();
        System.out.println("Room checks passed: 15 connected templates, collision, navigation, boss approach and loot");
    }
    private static void checkTemplates() {
        RoomLayout room = new RoomLayout();
        Player player = new Player(ElementType.FIRE);
        for (int template = 0; template < 15; template++) for (int flip = 0; flip < 4; flip++) {
            room.prepare(template, (flip & 1) != 0, (flip & 2) != 0);
            require(room.getTemplate() == template && room.isConnected(), "Every template and mirror stays connected");
            require(room.canStand(player.x, player.y, Player.SIZE), "Entrance fits player body");
            require(room.canStand(player.x, ElMagicaGame.WORLD_HEIGHT - 124, Player.SIZE), "Exit fits player body");
            Array<Enemy> enemies = new Array<>();
            for (int i = 0; i < 6; i++) {
                Enemy enemy = new Enemy(ElementType.WATER, 2, 2); enemy.room = room;
                require(EnemySpawner.spawn(enemy, player, enemies) && room.canStand(enemy.x, enemy.y, enemy.getSize()), "Spawn never inside obstacle");
                enemies.add(enemy);
            }
        }
        for (int i = 0; i < 100; i++) { room.generate(true); require(room.getTemplate() == -1, "Boss rooms always empty"); }
    }

    private static void checkObstacleVariants() {
        RoomLayout room = new RoomLayout();
        MathUtils.random.setSeed(145);
        room.prepare(0, false, false);
        int[][] first = new int[30][17];
        boolean[] seen = new boolean[RoomLayout.OBSTACLE_VARIANTS];
        for (int x = 1; x < 29; x++) for (int y = 1; y < 16; y++) {
            if (!room.isObstacle(x, y)) continue;
            int variant = room.getObstacleVariant(x, y);
            require(variant >= 0 && variant < 8, "Only biome's eight obstacle sprites are selected");
            seen[variant] = true; first[x][y] = variant;
            for (int frame = 0; frame < 100; frame++) require(room.getObstacleVariant(x, y) == variant, "Sprite choice stable while floor is active");
        }
        for (boolean variant : seen) require(variant, "All eight variants appear in dense layout");
        room.prepare(0, false, false);
        boolean changed = false;
        for (int x = 1; x < 29; x++) for (int y = 1; y < 16; y++) {
            if (room.isObstacle(x, y) && first[x][y] != room.getObstacleVariant(x, y)) changed = true;
        }
        require(changed && room.isConnected(), "New floor reshuffles art without affecting connectivity");
    }
    private static void checkCollision() {
        RoomLayout room = new RoomLayout(); room.prepare(0, false, false);
        Player player = new Player(ElementType.FIRE); player.room = room;
        player.x = 200; player.y = 4 * 64 + 2;
        player.move(1, 0, 4);
        require(player.x == 5 * 64 - Player.SIZE && room.canStand(player.x, player.y, Player.SIZE), "Player cannot cross barrel on long frame");
        Projectile shot = new Projectile(200, 4 * 64 + 32, new Vector2(1, 0), ElementType.WATER);
        shot.update(1);
        Enemy behind = new Enemy(ElementType.FIRE, 16, 5);
        require(shot.obstacleTime(room) < shot.hitTime(behind), "Wall is hit before enemy, even with piercing");
        Enemy enemy = new Enemy(ElementType.FIRE, 4, 5); enemy.room = room;
        enemy.knockBack(new Vector2(1, 0), 500);
        require(enemy.x + enemy.getSize() <= 5 * 64 + 0.01f && room.canStand(enemy.x, enemy.y, enemy.getSize()), "Knockback cannot cross obstacle");
        Enemy snake = Enemy.snake(ElementType.FIRE, 4, 5); snake.room = room;
        Player target = new Player(ElementType.WATER); target.x = 1000; target.y = snake.y;
        room.updateNavigation(target);
        snake.update(0.5f, target);
        require(room.canStand(snake.x, snake.y, snake.getSize()) && !snake.snakeCombat.isCharging(), "Snake navigates rather than charging through barrier");
        Enemy shooter = Enemy.shooter(ElementType.WATER, 4, 5); shooter.room = room;
        shooter.shooterCombat.shots.add(new Projectile(220, target.y + 30, new Vector2(1, 0), ElementType.WATER, 1000));
        shooter.shooterCombat.update(1, target, false);
        require(target.getHp() == 20 && shooter.shooterCombat.shots.isEmpty(), "Enemy bolt is stopped before player");
    }
    private static void checkNavigation() {
        RoomLayout room = new RoomLayout(); room.prepare(3, false, false);
        Player player = new Player(ElementType.WATER); player.x = 800; player.y = 450; player.maxHp = 1000; player.restoreHp();
        for (Enemy enemy : new Enemy[]{new Enemy(ElementType.FIRE, 5, 7), Enemy.snake(ElementType.FIRE, 5, 7), Enemy.shooter(ElementType.FIRE, 5, 7)}) {
            enemy.room = room;
            player.restoreHp();
            float start = Vector2.dst(enemy.x, enemy.y, player.x, player.y);
            boolean hit = false;
            for (int frame = 0; frame < 2400 && !hit; frame++) {
                room.updateNavigation(player); enemy.update(1f / 60, player);
                require(room.canStand(enemy.x, enemy.y, enemy.getSize()), "Pathfinding does not penetrate obstacles");
                hit = player.getHp() < player.maxHp;
            }
            require(start > 200 && hit, "Every enemy type routes around a long wall and can attack");
        }
    }
    private static void checkBossApproach() {
        for (ElementType first : DamageSystem.ENEMY_ELEMENTS) {
            Enemy boss = new Enemy(first, first == ElementType.EARTH ? ElementType.AIR : ElementType.EARTH, 27, 9);
            Player player = new Player(ElementType.WATER); player.x = 100; player.y = 500;
            boss.bossCombat.update(20, player, false);
            require(boss.bossCombat.getCurrent() == null, "Distant boss cannot prepare a useless attack");
            float old = boss.x;
            boss.update(0.5f, player); float firstStep = old - boss.x;
            old = boss.x; boss.update(0.5f, player);
            require(old - boss.x > firstStep, "Boss accelerates while approaching");
            boolean prepared = false;
            for (int i = 0; i < 1000 && !prepared; i++) {
                boss.update(1f / 60, player);
                prepared = boss.bossCombat.getCurrent() != null;
                if (prepared) require(!boss.bossCombat.needsApproach(player), "Player inside intended reach when preparation begins");
            }
            require(prepared, "Boss crosses arena and attacks instead of getting stuck");
        }
        Enemy water = new Enemy(ElementType.WATER, ElementType.EARTH, 27, 9);
        Player target = new Player(ElementType.FIRE); target.maxHp = 1000; target.restoreHp();
        target.x = water.x - 220; target.y = water.y;
        water.bossCombat.update(1.2f, target, false);
        water.bossCombat.update(1f, target, false);
        require(!water.bossCombat.isBusy(), "Between water bursts boss may move again");
        target.x = 100;
        float startX = water.x;
        water.update(0.5f, target);
        require(water.x < startX && water.bossCombat.getCurrent() == null, "Water series does not root a distant boss");
    }
    private static void checkLoot() {
        CombatSession session = new CombatSession();
        for (int roll = 0; roll < 100; roll++) session.rollDrop(960, 126, roll);
        int books = 0, potions = 0;
        for (LootDrop drop : session.drops) if (drop.type == LootDrop.Type.BOOK) books++; else potions++;
        require(books == 2 && potions == 6, "Drop rates 2% book, 6% potion");
        Player player = new Player(ElementType.FIRE);
        session.drops.clear(); session.drops.add(new LootDrop(LootDrop.Type.POTION, player.x + 30, player.y + 30));
        session.updateLoot(1, player);
        require(session.drops.isEmpty() && player.getHp() == player.maxHp, "Full HP consumes potion without overhealing");
        player.takeDamage(10);
        session.drops.add(new LootDrop(LootDrop.Type.POTION, player.x + 30, player.y + 30));
        session.updateLoot(1, player);
        require(player.getHp() == 16 && session.drops.isEmpty(), "Potion heals without exceeding max HP");
        session.drops.add(new LootDrop(LootDrop.Type.BOOK, player.x + 30, player.y + 30));
        MathUtils.random.setSeed(5); session.updateLoot(1, player);
        require(session.pickupReward != null && session.getReward() == null && session.getDifficulty() == 0
            && session.drops.isEmpty(), "Book grants upgrade once without boss scaling or pause");
        session.rollDrop(960, 126, 0); session.reset();
        require(session.drops.isEmpty() && session.pickupReward == null, "Reset clears loot");
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
