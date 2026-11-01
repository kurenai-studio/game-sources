package com.elmagica.game;

public class MerchantItem {
    // Номера апов те же, что в PlayerUpgrade; зелье идёт отдельно под 7.
    public static final int HEAL = 7;
    public final int upgrade;
    public boolean sold;
    public MerchantItem(int upgrade) { this.upgrade = upgrade; }
    public String name() {
        String[] names = {"Скорость", "Базовый урон", "Максимум ХП", "КД атаки", "Скорость снаряда",
            "Улучшение способности", "Магический щит", "Зелье лечения"};
        return names[upgrade];
    }
    public String description(Player player) {
        switch (upgrade) {
            case 0: return "+10% к скорости";
            case 1: return "+15% к базовому урону";
            case 2: return "+4 максимальных ХП";
            case 3: return "КД атаки меньше на 10%";
            case 4: return "Снаряды быстрее на 12%";
            case 5:
                if (player.element == ElementType.FIRE) return "+12 к радиусу взрыва";
                if (player.element == ElementType.WATER) return "+1 цель пробития";
                if (player.element == ElementType.AIR) return "+1 рикошет";
                return "Отбрасывание и замедление";
            case 6: return "+3% к шансу уклонения";
            default: return player.getHp() == player.maxHp ? "Здоровье уже полное"
                : "+" + healing(player) + " ХП";
        }
    }
    public boolean available(Player player) { return !sold && (upgrade == HEAL || PlayerUpgrade.canImprove(player, upgrade)); }
    public int price(Player player, int difficulty) {
        if (upgrade == HEAL) return Math.max(8, Math.round(player.maxHp * 0.5f)) + difficulty * 5;
        int level = level(player);
        if (upgrade == 5) return 45 + level * 25;
        if (upgrade == 6) return 60 + level * 30;
        return 18 + level * 10;
    }
    private int level(Player player) {
        // Считаем цену по текущему стату, апы из книг тоже учитываем.
        switch (upgrade) {
            case 0: return growth(player.speed / Player.SPEED, 1.1);
            case 1: return growth(player.baseDamage / 10, 1.15);
            case 2: return Math.max(0, (player.maxHp - Player.MAX_HP) / 4);
            case 3: return growth(Player.SHOT_COOLDOWN / player.attackCooldown, 1 / 0.9);
            case 4: return growth(player.projectileSpeed / Projectile.SPEED, 1.12);
            case 5:
                if (player.element == ElementType.FIRE) return Math.round((player.explosionRadius - 48) / 12);
                if (player.element == ElementType.WATER) return player.piercings - 2;
                if (player.element == ElementType.AIR) return player.ricochets - 1;
                return Math.round(Math.max((player.knockback - 64) / 16, (player.slowStrength - 0.5f) / 0.05f));
            case 6: return Math.round(player.dodgeChance / 0.03f);
            default: return 0;
        }
    }
    private int growth(float ratio, double step) { return Math.max(0, (int) Math.round(Math.log(ratio) / Math.log(step))); }
    public static int healing(Player player) { return Math.max(6, Math.round(player.maxHp * 0.3f)); }
}
