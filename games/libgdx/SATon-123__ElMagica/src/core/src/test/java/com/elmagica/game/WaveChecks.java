package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

public class WaveChecks {
    public static void clearWave(CombatSession session, Player player, Array<Enemy> enemies) {
        while (session.hasEnemiesRemaining(enemies)) {
            for (Enemy enemy : enemies) enemy.takeDamage(enemy.getMaxHp());
            session.updateWaves(0, player, enemies);
        }
    }
    public static void run() {
        MathUtils.random.setSeed(331);
        require(CombatSession.floorMaximum(1000000) > CombatSession.floorMaximum(1000)
            && CombatSession.screenMaximum(1000000) > CombatSession.screenMaximum(1000), "No fixed growth cap");
        CombatSession session = new CombatSession(); Player player = new Player(ElementType.FIRE);
        Array<Enemy> enemies = new Array<>(); session.updateWaves(0, player, enemies);
        require(enemies.size == 3 && session.getEnemiesWaiting() > 0, "Partial initial wave");
        long total = session.getFloorTotal(), waiting = session.getEnemiesWaiting();
        Enemy survivor = enemies.get(1);
        enemies.first().takeDamage(enemies.first().getMaxHp());
        session.checkFloorCleared(enemies);
        require(!session.isExitOpen(), "Single kill does not clear floor");
        try {
            var field = RoomLayout.class.getDeclaredField("blocked"); field.setAccessible(true);
            boolean[][] blocked = (boolean[][]) field.get(session.layout);
            for (boolean[] column : blocked) java.util.Arrays.fill(column, true);
            session.updateWaves(0, player, enemies);
            require(session.getEnemiesWaiting() == waiting && enemies.size == 2 && !session.isExitOpen(), "No free spawn cell preserves queue");
            session.layout.prepare(-1, false, false);
        } catch (ReflectiveOperationException e) { throw new RuntimeException(e); }
        session.updateWaves(0, player, enemies);
        require(enemies.size == 3 && enemies.contains(survivor, true) && session.getEnemiesWaiting() == waiting - 1,
            "One death refills one slot without replacing survivors");
        int killed = 1;
        while (session.hasEnemiesRemaining(enemies)) {
            Enemy victim = enemies.first(); victim.takeDamage(victim.getMaxHp()); killed++;
            session.updateWaves(0, player, enemies);
            require(enemies.size <= session.getConcurrentLimit(), "No overfill");
            if (session.hasEnemiesRemaining(enemies)) require(!session.isExitOpen(), "Queue holds exit shut");
        }
        require(killed == total && session.isExitOpen() && session.getCompletedFloors() == 1, "Exactly the floor budget spawns");
        for (int floor = 2; floor <= 7; floor++) {
            require(session.advanceFloor(player, enemies), "Next floor");
            if (floor == 7) require(enemies.size == 1 && enemies.first().isBoss() && session.getEnemiesWaiting() == 0
                && session.getFloorTotal() == 1, "Boss floor has no normal reinforcements");
            clearWave(session, player, enemies);
        }
        session.reset(); require(session.getEnemiesWaiting() == 0 && session.getFloorTotal() == 0, "Reset clears queue");
        System.out.println("Wave queue checks passed: increasing budgets, one-for-one refill, survivors, full clear and solo bosses");
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
