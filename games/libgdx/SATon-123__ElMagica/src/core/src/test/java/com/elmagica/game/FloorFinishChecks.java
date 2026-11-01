package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

public class FloorFinishChecks {
    public static void run() {
        checkBeam();
        checkFinish();
        System.out.println("Floor finish checks passed: beam edges, diagonal misses, swept shots, speed boost and flying loot");
    }
    private static void checkBeam() {
        for (int angle : new int[]{0, 30, 45, 90, 135, 180, 225, 270, 315}) {
            for (float side : new float[]{33, 35, -33, -35}) {
                Enemy boss = new Enemy(ElementType.WATER, ElementType.EARTH, 8, 6);
                float x = boss.x + boss.getSize() / 2, y = boss.y + boss.getSize() / 2;
                float dx = MathUtils.cosDeg(angle), dy = MathUtils.sinDeg(angle);
                Player player = new Player(ElementType.FIRE);
                player.x = x + dx * 500 - 30; player.y = y + dy * 500 - 30;
                BossAttack attack = new BossAttack(ElementType.WATER, boss, player);
                player.x -= dy * side; player.y += dx * side;
                attack.update(attack.getWarningTime() + 0.02f, player);
                require((player.getHp() < 20) == (Math.abs(side) < 34), "Beam visible edge at angle " + angle + " offset " + side);
                int hp = player.getHp(); attack.update(1, player);
                require(player.getHp() == hp, "Beam hits once");
            }
        }
        Player player = new Player(ElementType.FIRE); player.x = 500; player.y = 500;
        Projectile miss = new Projectile(400, 503, new Vector2(1, 0), ElementType.WATER);
        miss.update(1);
        require(!Float.isFinite(miss.hitTime(player)), "Projectile misses empty edge of sprite square");
        Projectile hit = new Projectile(400, 530, new Vector2(1, 0), ElementType.WATER);
        hit.update(1);
        require(Float.isFinite(hit.hitTime(player)), "Swept projectile still hits body on long frame");
    }
    private static void checkFinish() {
        MathUtils.random.setSeed(77);
        CombatSession session = new CombatSession();
        Player player = new Player(ElementType.FIRE);
        Array<Enemy> enemies = new Array<>(); session.updateWaves(0, player, enemies);
        while (session.merchant != null) session.advanceFloor(player, enemies);
        session.layout.prepare(0, false, false);
        LootDrop coin = new LootDrop(LootDrop.Type.COIN, 1500, 900, 3);
        session.drops.add(coin);
        session.updateLoot(0.3f, player);
        require(coin.x == 1500 && coin.y == 900 && coin.getScale() == 1, "Loot waits during battle");
        float speed = player.speed;
        WaveChecks.clearWave(session, player, enemies);
        session.updateWaves(0, player, enemies);
        require(player.floorCleared && player.getMoveSpeed() == speed * 1.8f && player.speed == speed, "Temporary floor speed boost");
        float oldDistance = Vector2.dst(coin.x, coin.y, player.x + 30, player.y + 30);
        session.updateLoot(0.1f, player);
        require(Vector2.dst(coin.x, coin.y, player.x + 30, player.y + 30) < oldDistance && coin.getScale() > 1 && coin.getScale() <= 1.35f, "Loot flies and grows");
        session.layout.prepare(-1, false, false);
        player.room = session.layout;
        float before = player.x; player.move(1, 0, 0.1f);
        require(Math.abs(player.x - before - speed * 1.8f * 0.1f) < 0.01f, "Movement actually uses boost");
        player.takeDamage(10);
        session.drops.add(new LootDrop(LootDrop.Type.POTION, 1500, 900));
        session.drops.add(new LootDrop(LootDrop.Type.BOOK, 1500, 900));
        for (int i = 0; i < 200; i++) session.updateLoot(0.02f, player);
        require(session.drops.isEmpty() && session.getCoins() == 3 && player.getHp() == 10 + MerchantItem.healing(player)
            && session.pickupReward != null, "All loot reaches player and applies, including HP upgrade before potion");
        session.layout.prepare(3, false, false);
        player.x = 800; player.y = 450;
        LootDrop throughWall = new LootDrop(LootDrop.Type.COIN, 300, 480, 1);
        require(session.layout.shotTime(new Vector2(300, 480), new Vector2(player.x + 30, player.y + 30), 0) < 1, "Obstacle between loot and player");
        session.drops.add(throughWall);
        for (int i = 0; i < 100; i++) session.updateLoot(0.02f, player);
        require(session.drops.isEmpty() && session.getCoins() == 4, "Loot crosses solid obstacle");
        session.drops.add(new LootDrop(LootDrop.Type.COIN, 1800, 900, 3));
        require(session.advanceFloor(player, enemies) && session.getCoins() == 7 && !player.floorCleared && player.getMoveSpeed() == player.speed, "Exit preserves flying loot and resets boost");
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
