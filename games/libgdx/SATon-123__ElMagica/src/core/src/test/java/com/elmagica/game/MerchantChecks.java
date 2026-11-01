package com.elmagica.game;

public class MerchantChecks {
    public static void run() {
        int[] outcomes = new int[4];
        for (int roll = 0; roll < 100; roll++) outcomes[CombatSession.coinAmount(roll)]++;
        require(outcomes[1] == 50 && outcomes[3] == 25 && outcomes[0] == 25 && outcomes[2] == 0, "Exact coin probabilities");
        MerchantSchedule schedule = new MerchantSchedule();
        for (int floor = 1; floor <= 7; floor++) require(!schedule.isMerchantFloor(floor), "No merchant before first boss");
        int doubles = 0;
        for (int block = 1; block <= 2000; block++) {
            int count = 0, previous = -2;
            for (int offset = 1; offset <= 6; offset++) {
                int floor = block * 7 + offset;
                boolean visit = schedule.isMerchantFloor(floor);
                require(schedule.isMerchantFloor(floor) == visit, "Schedule is stable within interval");
                if (visit) {
                    require(floor - previous > 1, "Merchant visits are not consecutive");
                    previous = floor; count++;
                }
            }
            require(count == 1 || count == 2, "One guaranteed visit, at most two");
            if (count == 2) doubles++;
            require(!schedule.isMerchantFloor((block + 1) * 7), "Boss floors never have merchants");
        }
        require(doubles > 30 && doubles < 180, "Second visits are rare");
        schedule.reset();
        require(!schedule.isMerchantFloor(1), "Schedule reset keeps early floors merchant-free");
        CombatSession tower = new CombatSession();
        Player climber = new Player(ElementType.FIRE);
        climber.baseDamage = 100000;
        com.badlogic.gdx.utils.Array<Enemy> enemies = new com.badlogic.gdx.utils.Array<>();
        tower.updateWaves(0, climber, enemies);
        int visits = 0, previousVisit = -2;
        for (int floor = 1; floor <= 28; floor++) {
            if (tower.merchant != null) {
                require(floor > 7 && floor - previousVisit > 1, "Actual merchant floors unlock after boss and never repeat consecutively");
                visits++; previousVisit = floor;
            }
            while (tower.hasEnemiesRemaining(enemies)) {
                for (Enemy enemy : enemies) tower.hit(enemy, climber.element, climber);
                tower.acceptReward();
                tower.updateWaves(0, climber, enemies);
            }
            tower.checkFloorCleared(enemies);
            if (floor % 7 == 0 && floor > 7) {
                require(visits >= 1 && visits <= 2, "Actual interval contains scheduled merchant visits");
                visits = 0;
            }
            if (floor < 28) require(tower.advanceFloor(climber, enemies), "Tower can advance after merchant and combat floors");
        }
        for (int i = 0; i < 100; i++) {
            CombatSession bossSession = new CombatSession();
            Player killer = new Player(ElementType.FIRE); killer.baseDamage = 10000;
            Enemy boss = new Enemy(ElementType.WATER, ElementType.EARTH, 12, 8);
            bossSession.hit(boss, killer.element, killer);
            require(bossSession.drops.size == 1 && bossSession.drops.first().type == LootDrop.Type.COIN
                && bossSession.drops.first().amount >= 10 && bossSession.drops.first().amount <= 20, "Boss guarantees 10-20 coins");
            bossSession.hit(boss, killer.element, killer);
            require(bossSession.drops.size == 1, "Boss corpse gives no extra coins");
        }
        Player player = new Player(ElementType.FIRE);
        for (int roll = 0; roll < 100; roll++) {
            Merchant shop = new Merchant(player, roll);
            require(shop.items.length == 3, "Three goods");
            if (roll < 80 || roll >= 95) require(shop.items[2].upgrade == 7, "Potion stock");
            if (roll >= 80 && roll < 95) require(shop.items[2].upgrade < 5 && shop.items[0].upgrade != shop.items[1].upgrade
                && shop.items[2].upgrade != shop.items[0].upgrade && shop.items[2].upgrade != shop.items[1].upgrade, "Three distinct common upgrades");
            if (roll >= 95) require(shop.items[1].upgrade == (roll == 99 ? 6 : 5), "Rare stock");
        }
        for (int stat = 0; stat < 7; stat++) {
            Player fresh = new Player(ElementType.FIRE);
            MerchantItem item = new MerchantItem(stat);
            int before = item.price(fresh, 0);
            PlayerUpgrade.apply(fresh, stat);
            require(item.price(fresh, 0) > before, "Price includes existing upgrades " + stat);
        }
        CombatSession session = new CombatSession();
        session.merchant = new Merchant(player, 0);
        Merchant shop = session.merchant;
        player.x = Merchant.itemX(0) - 30; player.y = Merchant.ITEM_Y - 30;
        require(!shop.buy(0, player, session), "Cannot buy without coins");
        session.addCoins(1000);
        int price = shop.items[0].price(player, 0);
        require(shop.buy(0, player, session) && session.getCoins() == 1000 - price, "Buy once");
        long coins = session.getCoins();
        require(!shop.buy(0, player, session) && session.getCoins() == coins, "Sold item cannot charge again");
        player.x = Merchant.itemX(2) - 30;
        require(shop.buy(2, player, session) && player.getHp() == player.maxHp, "Full-health potion consumed");
        MerchantItem heal = new MerchantItem(7);
        int old = heal.price(player, 0); player.maxHp += 4;
        require(heal.price(player, 1) > old, "Healing scales with HP and difficulty");
        session.drops.add(new LootDrop(LootDrop.Type.COIN, player.x + 30, player.y + 30, 3));
        coins = session.getCoins(); session.updateLoot(1, player);
        require(session.getCoins() == coins + 3 && session.drops.isEmpty(), "Coin pickup");
        player.x = Merchant.X - 30; player.y = Merchant.Y - 30;
        shop.interact(player, session); String advice = shop.getMessage(); shop.interact(player, session);
        require(!advice.isEmpty() && !advice.equals(shop.getMessage()), "NPC advice changes");
        require(shop.isTalking(), "Advice starts talking animation");
        shop.update(2.6f); require(!shop.isTalking() && !shop.getMessage().isEmpty(), "Speech ends while readable text remains");
        RoomLayout room = new RoomLayout(); room.addMerchantObjects();
        for (int object = 0; object < 4; object++) {
            float center = object == 3 ? Merchant.X : Merchant.itemX(object);
            float bottom = object == 3 ? Merchant.Y - 45 : Merchant.ITEM_Y - 47;
            float half = object == 3 ? 52 : 37;
            float top = bottom + (object == 3 ? 126 : 99);
            require(!room.canStand(center - 30, bottom, 60), "Merchant object is solid");
            com.badlogic.gdx.math.Vector2 below = room.move(center - 30, bottom - 200, 60, 0, 400);
            require(below.y == bottom - 60, "Cannot walk through object from below");
            com.badlogic.gdx.math.Vector2 above = room.move(center - 30, top + 100, 60, 0, -400);
            require(above.y == top, "Cannot walk through object from above");
            com.badlogic.gdx.math.Vector2 left = room.move(center - half - 200, bottom + 10, 60, 400, 0);
            require(left.x == center - half - 60, "Cannot walk through object from side");
            player.x = center - 30; player.y = below.y;
            require(shop.nearest(player) == object, "E reachable at physical boundary");
            require(room.shotTime(new com.badlogic.gdx.math.Vector2(center, bottom - 100),
                new com.badlogic.gdx.math.Vector2(center, top + 100), 6) < 1, "Object blocks projectiles");
        }
        room.prepare(-1, false, false); require(room.canStand(Merchant.X - 30, Merchant.Y, 60), "Next room clears shop colliders");
        session.reset(); require(session.getCoins() == 0 && session.merchant == null, "Reset shop and wallet");
        System.out.println("Merchant checks passed: stock, prices, purchases, advice and coins");
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
