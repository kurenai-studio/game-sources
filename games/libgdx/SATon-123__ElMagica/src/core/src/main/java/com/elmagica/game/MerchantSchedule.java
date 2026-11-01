package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;

public class MerchantSchedule {
    private int interval = -1;
    private int first;
    private int second;

    public void reset() { interval = -1; first = 0; second = 0; }

    public boolean isMerchantFloor(int floor) {
        if (floor <= CombatSession.BOSS_INTERVAL || floor % CombatSession.BOSS_INTERVAL == 0) return false;
        int bossFloor = (floor - 1) / CombatSession.BOSS_INTERVAL * CombatSession.BOSS_INTERVAL;
        if (interval != bossFloor) {
            interval = bossFloor;
            first = bossFloor + MathUtils.random(1, 6);
            second = 0;
            // Иногда торговец заходит дважды, но не на соседних этажах.
            if (MathUtils.random(99) < 5) {
                int[] choices = new int[6];
                int count = 0;
                for (int offset = 1; offset <= 6; offset++) {
                    int candidate = bossFloor + offset;
                    if (Math.abs(candidate - first) > 1) choices[count++] = candidate;
                }
                second = choices[MathUtils.random(count - 1)];
            }
        }
        return floor == first || floor == second;
    }
}
