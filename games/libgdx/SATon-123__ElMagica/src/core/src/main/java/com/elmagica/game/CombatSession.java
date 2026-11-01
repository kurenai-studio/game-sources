package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

public class CombatSession {
    public static final int BOSS_INTERVAL = 7;
    private final MerchantSchedule merchantSchedule = new MerchantSchedule();
    private long score;
    private int wave;
    private int difficulty;
    private PlayerUpgrade reward;
    private int completedFloors;
    private boolean exitOpen;
    private boolean spawnPending = true;
    private long enemiesWaiting;
    private long floorTotal;
    private int concurrentLimit;
    public static long floorMaximum(int floor) { return 6L + (floor - 1) / 3; }
    public static int screenMaximum(int floor) { return 3 + (floor - 1) / 10; }
    public long getEnemiesWaiting() { return enemiesWaiting; }
    public long getFloorTotal() { return floorTotal; }
    public int getConcurrentLimit() { return concurrentLimit; }
    public boolean hasEnemiesRemaining(Array<Enemy> enemies) { return (merchant == null && enemiesWaiting > 0) || hasLivingEnemies(enemies); }
    public final RoomLayout layout = new RoomLayout();
    public final Array<LootDrop> drops = new Array<>();
    public PlayerUpgrade pickupReward;
    private long coins;
    public Merchant merchant;
    public static int coinAmount(int roll) { return roll < 50 ? 1 : roll < 75 ? 3 : 0; }
    public long getCoins() { return coins; }
    public void addCoins(int amount) { if (amount > 0) coins += amount; }
    public boolean spendCoins(int amount) {
        if (amount <= 0 || coins < amount) return false;
        coins -= amount; return true;
    }
    public int getCompletedFloors() { return completedFloors; }
    public boolean isExitOpen() { return exitOpen; }
    public boolean advanceFloor(Player player, Array<Enemy> enemies) {
        if (!player.isAlive() || !exitOpen || reward != null) return false;
        // Забираем и тот лут, который ещё не успел долететь.
        for (LootDrop drop : drops) collect(drop, player);
        enemies.clear();
        drops.clear();
        pickupReward = null;
        merchant = null;
        exitOpen = false;
        spawnPending = true;
        player.enterFloor();
        updateWaves(0, player, enemies);
        GameAudio.play(GameAudio.Cue.FLOOR);
        return true;
    }
    public void checkFloorCleared(Array<Enemy> enemies) {
        if (wave > 0 && !spawnPending && !exitOpen && (enemiesWaiting == 0 || merchant != null) && !hasLivingEnemies(enemies)) {
            completedFloors++;
            exitOpen = true;
        }
    }
    public int getDifficulty() { return difficulty; }
    public PlayerUpgrade getReward() { return reward; }
    public void acceptReward() { reward = null; }

    public long getScore() { return score; }
    public int getWave() { return wave; }
    public boolean hasLivingEnemies(Array<Enemy> enemies) {
        for (Enemy enemy : enemies) {
            if (enemy.isAlive()) return true;
        }
        return false;
    }
    public void reset() {
        score = 0;
        wave = 0;
        difficulty = 0;
        merchantSchedule.reset();
        reward = null;
        completedFloors = 0;
        exitOpen = false;
        spawnPending = true;
        enemiesWaiting = 0;
        floorTotal = 0;
        concurrentLimit = 0;
        drops.clear();
        pickupReward = null;
        coins = 0;
        merchant = null;
        layout.prepare(-1, false, false);
    }

    public void updateWaves(float delta, Player player, Array<Enemy> enemies) {
        if (!player.isAlive() || reward != null) return;
        if (!spawnPending) {
            fillSlots(player, enemies);
            checkFloorCleared(enemies);
            player.floorCleared = exitOpen && merchant == null;
            return;
        }
        // Сюда попадаем после входа в верхнюю дверь.
        enemies.clear();
        boolean bossWave = (wave + 1) % BOSS_INTERVAL == 0;
        boolean shop = difficulty > 0 && merchantSchedule.isMerchantFloor(wave + 1);
        layout.generate(bossWave || shop);
        player.room = layout;
        if (shop) {
            layout.addMerchantObjects();
            enemiesWaiting = 0; floorTotal = 0; concurrentLimit = 0;
            merchant = new Merchant(player);
            wave++; spawnPending = false;
            checkFloorCleared(enemies);
            return;
        }
        wave++;
        spawnPending = false;
        concurrentLimit = bossWave ? 1 : screenMaximum(wave);
        floorTotal = bossWave ? 1 : floorMaximum(wave) - MathUtils.random(2);
        enemiesWaiting = floorTotal;
        fillSlots(player, enemies);
    }

    private void fillSlots(Player player, Array<Enemy> enemies) {
        if (merchant != null || exitOpen) return;
        // Убираем трупы, чтобы список не пух на длинных этажах.
        for (int i = enemies.size - 1; i >= 0; i--) if (!enemies.get(i).isAlive()) enemies.removeIndex(i);
        while (enemiesWaiting > 0 && enemies.size < concurrentLimit) {
            Enemy enemy;
            if (wave % BOSS_INTERVAL == 0) {
                int first = MathUtils.random(3), second = MathUtils.random(2);
                if (second >= first) second++;
                enemy = new Enemy(DamageSystem.ENEMY_ELEMENTS[first], DamageSystem.ENEMY_ELEMENTS[second], 2, 2);
            } else {
                ElementType element = DamageSystem.ENEMY_ELEMENTS[MathUtils.random(3)];
                int role = MathUtils.random(99);
                enemy = wave >= 4 && role < 30 ? Enemy.shooter(element, 2, 2)
                    : wave >= 2 && role < 60 ? Enemy.snake(element, 2, 2) : new Enemy(element, 2, 2);
            }
            enemy.scaleDifficulty(difficulty, wave);
            enemy.room = layout;
            // Места нет — ждём, врага из очереди не теряем.
            if (!EnemySpawner.spawn(enemy, player, enemies)) return;
            enemies.add(enemy);
            enemiesWaiting--;
        }
    }
    public void hit(Enemy enemy, ElementType attack) {
        hit(enemy, attack, null);
    }

    public void hit(Enemy enemy, ElementType attack, Player player) {
        if (!enemy.isAlive()) return;
        int damage = DamageSystem.damage(attack, enemy);
        if (player != null) damage = Math.max(1, Math.round(damage * player.baseDamage / 10));
        enemy.takeDamage(damage, DamageSystem.damage(attack, enemy));
        GameAudio.play(GameAudio.Cue.HIT);
        // Награду выдаём только за свежее убийство.
        if (!enemy.isAlive()) {
            int coinCount = player == null ? 0 : enemy.isBoss() ? MathUtils.random(10, 20) : coinAmount(MathUtils.random(99));
            if (coinCount > 0) drops.add(new LootDrop(LootDrop.Type.COIN, enemy.x + enemy.getSize() / 2,
                enemy.y + enemy.getSize() / 2, coinCount));
            if (enemy.isBoss()) {
                score += 5;
            } else {
                score++;
            }
            if (enemy.isBoss() && player != null) {
                enemiesWaiting = 0;
                difficulty++;
                reward = PlayerUpgrade.random(player);
                player.restoreHp();
            } else if (!enemy.isBoss() && player != null) {
                rollDrop(enemy.x + enemy.getSize() / 2, enemy.y + enemy.getSize() / 2, MathUtils.random(99));
            }
        }
    }

    public void rollDrop(float x, float y, int roll) {
        if (roll < 2) drops.add(new LootDrop(LootDrop.Type.BOOK, x, y));
        else if (roll < 8) drops.add(new LootDrop(LootDrop.Type.POTION, x, y));
    }
    public void updateLoot(float delta, Player player) {
        for (int i = drops.size - 1; i >= 0; i--) {
            LootDrop drop = drops.get(i);
            drop.update(delta);
            if (exitOpen) drop.flyTo(player, delta);
            if (!drop.canPickUp(player)) continue;
            collect(drop, player);
            drops.removeIndex(i);
        }
        if (merchant != null) merchant.update(delta);
    }
    private void collect(LootDrop drop, Player player) {
        GameAudio.play(GameAudio.Cue.PICKUP);
        if (drop.type == LootDrop.Type.COIN) {
            addCoins(drop.amount);
            CombatText.add("+" + drop.amount, CombatText.Kind.COIN, player.x + 30, player.y + Player.SIZE + 42);
        }
        else if (drop.type == LootDrop.Type.POTION) player.heal(MerchantItem.healing(player));
        else pickupReward = PlayerUpgrade.random(player);
    }
}
