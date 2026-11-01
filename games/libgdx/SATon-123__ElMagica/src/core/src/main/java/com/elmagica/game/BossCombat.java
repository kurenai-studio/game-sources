package com.elmagica.game;

import com.badlogic.gdx.utils.Array;

public class BossCombat {
    public final Array<BossAttack> attacks = new Array<>();
    private final Enemy boss;
    private BossAttack current;
    private float wait = 1.1f;
    private boolean second;
    private int waterShots;

    public BossCombat(Enemy boss) { this.boss = boss; }
    public boolean isBusy() { return current != null; }
    public BossAttack getCurrent() { return current; }
    private ElementType nextElement() { return second ? boss.secondElement : boss.element; }
    public boolean needsApproach(Player player) {
        float dx = player.x + 30 - boss.x - boss.getSize() / 2;
        float dy = player.y + 30 - boss.y - boss.getSize() / 2;
        ElementType element = nextElement();
        float reach = element == ElementType.EARTH ? boss.getSize() / 2 + 4 * 64 * boss.rangeScale() - 16
            : element == ElementType.FIRE ? 5 * 64 * boss.rangeScale() - 20
            : element == ElementType.AIR ? 420 : 480;
        return dx * dx + dy * dy > reach * reach;
    }

    public void update(float delta, Player player, boolean jumping) {
        if (!boss.isAlive() || !player.isAlive()) {
            clear();
            return;
        }
        for (int i = attacks.size - 1; i >= 0; i--) {
            BossAttack attack = attacks.get(i);
            attack.update(delta, player);
            if (attack.isFinished()) attacks.removeIndex(i);
        }
        if (!player.isAlive()) return;
        if (current != null) {
            if (!current.isFinished()) return;
            current = null;
            if (waterShots > 0) wait = 0.12f;
            else {
                second = !second;
                wait = boss.isEnraged() ? 0.8f : 1.2f;
            }
            return;
        }
        if (jumping) return;
        wait -= delta * boss.attackRate();
        if (wait > 0) return;
        ElementType element = second ? boss.secondElement : boss.element;
        // Сначала подходим, чтобы босс не бил по воздуху.
        if (needsApproach(player)) return;
        // Воду запускаем серией залпов.
        if (element == ElementType.WATER && waterShots == 0) waterShots = boss.isEnraged() ? 4 : 3;
        current = new BossAttack(element, boss, player);
        GameAudio.play(GameAudio.Cue.BOSS);
        attacks.add(current);
        // Следующие волны земли идут с задержкой.
        if (element == ElementType.EARTH) {
            current = new BossAttack(element, boss, player, 0.28f);
            attacks.add(current);
            if (boss.isEnraged()) {
                current = new BossAttack(element, boss, player, 0.56f);
                attacks.add(current);
            }
        }
        if (element == ElementType.WATER) waterShots--;
    }

    public void clear() {
        attacks.clear();
        current = null;
        waterShots = 0;
        wait = 1.1f;
        second = false;
    }
}
