package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class CombatChecks {
    public static void main(String[] args) {
        MathUtils.random.setSeed(42);
        checkDamage();
        checkPlayer();
        checkShooting();
        checkProjectiles();
        checkAi();
        checkWaves();
        checkSpawnDistance();
        checkBoss();
        BossAttackChecks.run();
        CombatFeaturesChecks.run();
        SnakeChecks.run();
        ProgressionChecks.run();
        RoomCollisionChecks.run();
        MerchantChecks.run();
        FloorFinishChecks.run();
        LanguageChecks.run();
        WaveChecks.run();
        FeedbackChecks.run();
        System.out.println("Combat checks passed: elements, AI, waves, dual-element bosses and full heal");
    }

    private static void checkDamage() {
        int[][] expected = {{10, 5, 10, 20}, {20, 10, 5, 10}, {10, 20, 10, 5}, {5, 10, 20, 10}};
        int[][] contact = {{2, 1, 2, 3}, {3, 2, 1, 2}, {2, 3, 2, 1}, {1, 2, 3, 2}};
        for (int row = 0; row < 4; row++) {
            int favorable = 0, resistant = 0, neutral = 0;
            for (int column = 0; column < 4; column++) {
                int damage = DamageSystem.damage(DamageSystem.PLAYER_ELEMENTS[row], DamageSystem.ENEMY_ELEMENTS[column]);
                require(damage == expected[row][column], "Damage table");
                Player target = new Player(DamageSystem.PLAYER_ELEMENTS[column]);
                Enemy attacker = new Enemy(DamageSystem.ENEMY_ELEMENTS[row], 6, 6);
                attacker.x = target.x; attacker.y = target.y;
                attacker.update(0, target);
                require(target.getHp() == 20 - contact[row][column], "Elemental contact damage");
                require(attacker.isJumping(), "Elemental contact still triggers retreat");
                if (damage == 20) favorable++;
                if (damage == 5) resistant++;
                if (damage == 10) neutral++;
            }
            require(favorable == 1 && resistant == 1 && neutral == 2, "Matchup balance");
        }
    }

    private static void checkPlayer() {
        Player player = new Player(ElementType.FIRE);
        float spawnX = player.x, spawnY = player.y;
        require(player.x == ElMagicaGame.WORLD_WIDTH / 2f - 30 && player.y == 96 && player.getHp() == 20, "Bottom entrance spawn and HP");
        player.move(1, 1, 0.5f);
        require(Math.abs(new Vector2(player.x - spawnX, player.y - spawnY).len() - 100) < 0.01f, "Normalized movement");
        player.move(-1, -1, 100);
        require(player.x == 64 && player.y == 64, "Lower walls");
        player.move(1, 1, 100);
        require(player.x + Player.SIZE == (ElMagicaGame.WORLD_WIDTH - 64) && player.y + Player.SIZE == ElMagicaGame.WORLD_HEIGHT - 64, "Upper walls");
        player.takeDamage(2);
        require(player.getHp() == 18, "Contact damage");
        player.takeDamage(100);
        require(player.getHp() == 0 && !player.isAlive(), "Death and HP clamp");
        float x = player.x, y = player.y;
        player.move(-1, -1, 1);
        require(player.x == x && player.y == y, "Dead player cannot move");
    }

    private static void checkProjectiles() {
        Enemy first = new Enemy(ElementType.FIRE, 12, 8);
        Enemy second = new Enemy(ElementType.AIR, 16, 8);
        Projectile shot = new Projectile(350, first.y + 30, new Vector2(1, 0), ElementType.FIRE);
        shot.update(3);
        require(Float.isFinite(shot.hitTime(first)), "Swept hit across whole enemy");
        require(shot.hitTime(first) < shot.hitTime(second), "Nearest target");
        require(shot.outsideRoom(), "Projectile leaves room");
        first.takeDamage(first.getMaxHp());
        require(!Float.isFinite(shot.hitTime(first)), "Dead enemy ignored");
        Projectile miss = new Projectile(350, 150, new Vector2(1, 0), ElementType.FIRE);
        miss.update(1);
        require(!Float.isFinite(miss.hitTime(second)), "Shot misses body");
        Projectile vertical = new Projectile(second.x + 30, 200, new Vector2(0, 1), ElementType.WATER);
        vertical.update(1);
        require(Float.isFinite(vertical.hitTime(second)), "Vertical hit");
    }

    private static void checkShooting() {
        Player player = new Player(ElementType.FIRE);
        require(player.canShoot(), "First shot ready");
        player.shotFired();
        for (int i = 0; i < 49; i++) {
            player.updateShooting(0.01f);
            require(!player.canShoot(), "Cannot bypass cooldown by clicking");
        }
        player.updateShooting(0.011f);
        require(player.canShoot(), "Next shot after half a second");
        player.shotFired();
        require(!player.canShoot(), "Cooldown resets after each shot");
        player.updateShooting(5);
        require(player.canShoot(), "Long frame allows one shot");
        player.shotFired();
        require(!player.canShoot(), "No catch-up burst after lag");
        player.takeDamage(20);
        player.updateShooting(1);
        require(!player.canShoot(), "Dead player cannot shoot");
    }

    private static void checkAi() {
        Player player = new Player(ElementType.WATER);
        Enemy enemy = new Enemy(ElementType.FIRE, 12, 8);
        float before = Vector2.dst(enemy.x, enemy.y, player.x, player.y);
        enemy.update(1, player);
        require(Math.abs(before - Vector2.dst(enemy.x, enemy.y, player.x, player.y) - Enemy.SPEED) < 0.01f,
            "Enemy pursues at fixed speed");
        require(player.getHp() == 20, "No damage at a distance");
        enemy.x = player.x + 50;
        enemy.y = player.y;
        enemy.update(0, player);
        require(player.getHp() == 19 && enemy.isJumping(), "Weak touch triggers hit and jump");
        float jumpX = enemy.x, jumpY = enemy.y;
        enemy.update(0.01f, player);
        require(player.getHp() == 19, "No repeated damage during jump");
        enemy.update(1, player);
        float distance = Vector2.dst(jumpX, jumpY, enemy.x, enemy.y);
        require(Math.abs(distance - 128) < 0.01f || Math.abs(distance - 192) < 0.01f, "Jump is 2 or 3 tiles");
        require(!enemy.isJumping() && player.getHp() == 19, "Jump finishes without extra hit");
        enemy.update(10, player);
        require(player.getHp() == 18, "Enemy resumes pursuit and attacks again");
        enemy.takeDamage(enemy.getMaxHp());
        float deadX = enemy.x, deadY = enemy.y;
        enemy.update(100, player);
        require(!enemy.isAlive() && enemy.x == deadX && enemy.y == deadY && player.getHp() == 18,
            "Dead enemy cannot chase, attack or respawn");

        for (float x : new float[]{64, 322, (ElMagicaGame.WORLD_WIDTH - 124)}) {
            for (float y : new float[]{64, 322, (ElMagicaGame.WORLD_HEIGHT - 124)}) {
                for (int repeat = 0; repeat < 10; repeat++) {
                    Player cornerPlayer = new Player(ElementType.EARTH);
                    cornerPlayer.x = x;
                    cornerPlayer.y = y;
                    Enemy cornerEnemy = new Enemy(ElementType.AIR, 2, 2);
                    cornerEnemy.x = x;
                    cornerEnemy.y = y;
                    cornerEnemy.update(0, cornerPlayer);
                    cornerEnemy.update(1, cornerPlayer);
                    float jump = Vector2.dst(x, y, cornerEnemy.x, cornerEnemy.y);
                    require(Math.abs(jump - 128) < 0.01f || Math.abs(jump - 192) < 0.01f, "Full jump near walls");
                    require(cornerEnemy.x >= 64 && cornerEnemy.x + Enemy.SIZE <= (ElMagicaGame.WORLD_WIDTH - 64)
                        && cornerEnemy.y >= 64 && cornerEnemy.y + Enemy.SIZE <= ElMagicaGame.WORLD_HEIGHT - 64, "Jump stays inside walls");
                }
            }
        }
    }

    private static void checkWaves() {
        CombatSession session = new CombatSession();
        Enemy victim = new Enemy(ElementType.FIRE, 2, 2);
        session.hit(victim, ElementType.FIRE);
        require(session.getScore() == 0 && victim.getHp() == 20, "No score for nonlethal hit");
        session.hit(victim, ElementType.FIRE);
        session.hit(victim, ElementType.FIRE);
        require(session.getScore() == 1, "Exactly one point per death");
        for (int i = 1; i < 100; i++) {
            victim.reset();
            session.hit(victim, ElementType.WATER);
            session.hit(victim, ElementType.WATER);
        }
        require(session.getScore() == 100, "Score continues beyond 15");
        session.reset();
        require(session.getScore() == 0 && session.getWave() == 0, "Session reset");

        Array<Enemy> enemies = new Array<>();
        Player player = new Player(ElementType.WATER);
        java.util.HashSet<Integer> waveSizes = new java.util.HashSet<>();
        java.util.HashSet<ElementType> types = new java.util.HashSet<>();
        java.util.HashSet<String> positions = new java.util.HashSet<>();
        session.updateWaves(0, player, enemies);
        for (int wave = 1; wave <= 100; wave++) {
            require(session.getWave() == wave && enemies.size >= 1 && enemies.size <= session.getConcurrentLimit(), "Growing on-screen enemy limit");
            if (wave % CombatSession.BOSS_INTERVAL != 0) require(session.getFloorTotal() <= CombatSession.floorMaximum(wave)
                && session.getFloorTotal() >= CombatSession.floorMaximum(wave) - 2, "Growing floor total");
            for (Enemy enemy : enemies) {
                require(wave >= 4 || !enemy.isShooter(), "Shooter introduction");
                require(wave >= 2 || !enemy.isSnake(), "Snake introduction");
            }            if (wave % CombatSession.BOSS_INTERVAL == 0) require(enemies.size == 1 && enemies.first().isBoss(), "Solo boss every tenth wave");
            waveSizes.add(enemies.size);
            for (Enemy enemy : enemies) {
                types.add(enemy.element);
                positions.add(enemy.x + ":" + enemy.y);
                require(enemy.isBoss() == (wave % CombatSession.BOSS_INTERVAL == 0), "Boss only on tenth waves");
                require(enemy.getHp() == enemy.getMaxHp(), "Fresh enemy HP");
                if (enemy.isBoss()) require(enemy.element != enemy.secondElement, "Two distinct boss elements");
                require(enemy.x >= 64 && enemy.x + enemy.getSize() <= (ElMagicaGame.WORLD_WIDTH - 64)
                    && enemy.y >= 64 && enemy.y + enemy.getSize() <= ElMagicaGame.WORLD_HEIGHT - 64, "Spawn inside walls");
                require((enemy.x - 2) % 64 == 0 && (enemy.y - 2) % 64 == 0, "Spawn on tile");
                require(!overlaps(enemy, player.x, player.y), "Spawn avoids player");
                for (int index = 0; index < enemies.size; index++) {
                    Enemy other = enemies.get(index);
                    if (other != enemy) require(!overlaps(enemy, other.x, other.y), "Spawn avoids enemies");
                }
            }
            session.updateWaves(10, player, enemies);
            require(session.getWave() == wave, "No new wave while enemies live");
            WaveChecks.clearWave(session, player, enemies);
            session.updateWaves(0.5f, player, enemies);
            require(session.getWave() == wave && session.isExitOpen() && session.getCompletedFloors() == wave, "Clear opens exit and counts floor once");
            session.updateWaves(100, player, enemies);
            require(session.getWave() == wave && session.getCompletedFloors() == wave, "No automatic floors or repeated credit");
            require(session.advanceFloor(player, enemies), "Exit advances to next floor");
        }
        require(waveSizes.size() >= 4 && types.size() == 4 && positions.size() > 1, "Random sizes, types and positions");
        player.takeDamage(20);
        for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
        int wave = session.getWave();
        session.updateWaves(100, player, enemies);
        require(session.getWave() == wave, "No waves after death");
    }

    private static void checkBoss() {
        ElementType[] types = DamageSystem.ENEMY_ELEMENTS;
        int[][] expected = {
            {5, 20, 20, 5}, {10, 10, 10, 10}, {20, 20, 5, 5},
            {5, 5, 20, 20}, {10, 10, 10, 10}, {20, 5, 5, 20}
        };
        int[][] contact = {
            {3, 1, 1, 3}, {2, 2, 2, 2}, {1, 1, 3, 3},
            {3, 3, 1, 1}, {2, 2, 2, 2}, {1, 3, 3, 1}
        };
        int pair = 0;
        for (int first = 0; first < 4; first++) {
            for (int second = first + 1; second < 4; second++) {
                Enemy boss = new Enemy(types[first], types[second], 12, 8);
                require(boss.getHp() == Enemy.BOSS_HP && boss.getSize() == 124, "Boss HP and body");
                for (int attack = 0; attack < 4; attack++) {
                    require(DamageSystem.damage(types[attack], boss) == expected[pair][attack], "Boss matchup damage");
                    Enemy reversed = new Enemy(types[second], types[first], 12, 8);
                    require(DamageSystem.damage(types[attack], reversed) == expected[pair][attack], "Type order irrelevant");
                    require(DamageSystem.damageToPlayer(boss, types[attack]) == contact[pair][attack], "Dual-type contact damage");
                    require(DamageSystem.damageToPlayer(reversed, types[attack]) == contact[pair][attack], "Contact type order irrelevant");
                }
                pair++;
            }
        }
        Player player = new Player(ElementType.WATER);
        player.takeDamage(18);
        CombatSession session = new CombatSession();
        Enemy boss = new Enemy(ElementType.FIRE, ElementType.EARTH, 12, 8);
        for (int hit = 0; hit < Enemy.BOSS_HP / 10 - 1; hit++) session.hit(boss, player.element, player);
        require(boss.getHp() == 10 && player.getHp() == 2 && session.getScore() == 0, "Heal waits for boss death");
        session.hit(boss, player.element, player);
        require(!boss.isAlive() && player.getHp() == player.maxHp && session.getScore() == 5, "Boss death heals and awards five points");
        player.takeDamage(2);
        session.hit(boss, player.element, player);
        require(player.getHp() == player.maxHp - 2 && session.getScore() == 5, "Corpse gives no heal or points");
        Enemy normal = new Enemy(ElementType.FIRE, 12, 8);
        session.hit(normal, player.element, player);
        require(player.getHp() == player.maxHp - 2, "Normal kill does not heal");
        boss.reset();
        require(boss.getHp() == Enemy.BOSS_HP, "Boss reset preserves max HP");
        Projectile wideHit = new Projectile(350, boss.y + 100, new Vector2(1, 0), ElementType.WATER);
        wideHit.update(1);
        require(Float.isFinite(wideHit.hitTime(boss)), "Projectile hits expanded boss body");

        for (float x : new float[]{64, 322, (ElMagicaGame.WORLD_WIDTH - 124)}) {
            for (float y : new float[]{64, 322, (ElMagicaGame.WORLD_HEIGHT - 124)}) {
                Player cornerPlayer = new Player(ElementType.FIRE);
                cornerPlayer.x = x;
                cornerPlayer.y = y;
                Enemy cornerBoss = new Enemy(ElementType.AIR, ElementType.WATER, 2, 2);
                cornerBoss.x = Math.min(x, (ElMagicaGame.WORLD_WIDTH - 64) - cornerBoss.getSize());
                cornerBoss.y = Math.min(y, ElMagicaGame.WORLD_HEIGHT - 64 - cornerBoss.getSize());
                cornerBoss.update(0, cornerPlayer);
                float startX = cornerBoss.x, startY = cornerBoss.y;
                cornerBoss.update(1, cornerPlayer);
                float jump = Vector2.dst(startX, startY, cornerBoss.x, cornerBoss.y);
                require(Math.abs(jump - 128) < 0.01f || Math.abs(jump - 192) < 0.01f, "Boss full jump");
                require(cornerBoss.x >= 64 && cornerBoss.x + cornerBoss.getSize() <= (ElMagicaGame.WORLD_WIDTH - 64)
                    && cornerBoss.y >= 64 && cornerBoss.y + cornerBoss.getSize() <= ElMagicaGame.WORLD_HEIGHT - 64, "Boss stays inside walls");
            }
        }
    }

    private static void checkSpawnDistance() {
        for (float playerX : new float[]{64, 322, 640, (ElMagicaGame.WORLD_WIDTH - 124)}) {
            for (float playerY : new float[]{64, 322, (ElMagicaGame.WORLD_HEIGHT - 124)}) {
                Player player = new Player(ElementType.FIRE);
                player.x = playerX;
                player.y = playerY;
                Array<Enemy> enemies = new Array<>();
                for (int attempt = 0; attempt < 100; attempt++) {
                    enemies.clear();
                    Enemy enemy = new Enemy(ElementType.AIR, 2, 2);
                    if (attempt % 2 == 0) enemy = new Enemy(ElementType.AIR, ElementType.WATER, 2, 2);
                    require(EnemySpawner.spawn(enemy, player, enemies), "Spawn available near every wall");
                    float nearestX = Math.max(player.x, Math.min(enemy.x, player.x + Player.SIZE));
                    float nearestY = Math.max(player.y, Math.min(enemy.y, player.y + Player.SIZE));
                    float enemyX = Math.max(enemy.x, Math.min(nearestX, enemy.x + enemy.getSize()));
                    float enemyY = Math.max(enemy.y, Math.min(nearestY, enemy.y + enemy.getSize()));
                    require(Vector2.dst(nearestX, nearestY, enemyX, enemyY) >= 128,
                        "Normal enemy and boss spawn at least two tiles from player edges");
                }
            }
        }
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    private static boolean overlaps(Enemy enemy, float x, float y) {
        return enemy.x < x + 60 && enemy.x + enemy.getSize() > x
            && enemy.y < y + 60 && enemy.y + enemy.getSize() > y;
    }
}
