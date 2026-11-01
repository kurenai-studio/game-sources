package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import java.util.Locale;

public class PlayerUpgrade {
    public final String title;
    public final String change;
    public final boolean rare;

    private PlayerUpgrade(String title, String change, boolean rare) {
        this.title = title;
        this.change = change;
        this.rare = rare;
    }

    public static PlayerUpgrade random(Player player) {
        int roll = MathUtils.random(99);
        return apply(player, roll < 90 ? MathUtils.random(4) : roll < 98 ? 5 : 6);
    }

    public static PlayerUpgrade apply(Player p, int choice) {
        switch (choice) {
            case 0:
                if (p.speed >= 400) return apply(p, 2);
                float speed = p.speed;
                p.speed = Math.min(400, p.speed * 1.1f);
                return reward("Скорость движения", speed, p.speed, " пикс/с", false);
            case 1:
                float damage = p.baseDamage;
                p.baseDamage *= 1.15f;
                return reward("Базовый урон", damage, p.baseDamage, "", false);
            case 2:
                int hp = p.maxHp;
                p.maxHp += 4;
                return reward("Максимум ХП", hp, p.maxHp, "", false);
            case 3:
                if (p.attackCooldown <= 0.12f) return apply(p, 2);
                float cooldown = p.attackCooldown;
                p.attackCooldown = Math.max(0.12f, p.attackCooldown * 0.9f);
                return reward("Перезарядка атаки", cooldown, p.attackCooldown, " с", false);
            case 4:
                if (p.projectileSpeed >= 1400) return apply(p, 2);
                float projectile = p.projectileSpeed;
                p.projectileSpeed = Math.min(1400, p.projectileSpeed * 1.12f);
                return reward("Скорость снаряда", projectile, p.projectileSpeed, " пикс/с", false);
            case 5:
                if (p.element == ElementType.FIRE) {
                    if (p.explosionRadius >= 128) return apply(p, 2);
                    float radius = p.explosionRadius;
                    p.explosionRadius = Math.min(128, radius + 12);
                    return reward("Радиус взрыва", radius, p.explosionRadius, " пикс", true);
                }
                if (p.element == ElementType.WATER) {
                    if (p.piercings >= 8) return apply(p, 2);
                    int count = p.piercings++;
                    return reward("Целей за выстрел", count, p.piercings, "", true);
                }
                if (p.element == ElementType.AIR) {
                    if (p.ricochets >= 8) return apply(p, 2);
                    int count = p.ricochets++;
                    return reward("Количество рикошетов", count, p.ricochets, "", true);
                }
                if (p.knockback >= 192 && p.slowStrength >= 0.8f) return apply(p, 2);
                float distance = p.knockback;
                p.knockback = Math.min(192, p.knockback + 16);
                p.slowStrength = Math.min(0.8f, p.slowStrength + 0.05f);
                p.slowDuration = Math.min(2, p.slowDuration + 0.15f);
                return new PlayerUpgrade("Сила земли", number(distance) + " > " + number(p.knockback)
                    + " пикс / замедление " + Math.round(p.slowStrength * 100) + "%", true);
            case 6:
                if (p.dodgeChance >= 0.3f) return apply(p, 2);
                float dodge = p.dodgeChance;
                p.dodgeChance = Math.min(0.3f, p.dodgeChance + 0.03f);
                return reward("Шанс уклонения", dodge * 100, p.dodgeChance * 100, "%", true);
            default: throw new IllegalArgumentException("Unknown upgrade");
        }
    }

    public static boolean canImprove(Player p, int choice) {
        switch (choice) {
            case 0: return p.speed < 400;
            case 1: case 2: return true;
            case 3: return p.attackCooldown > 0.12f;
            case 4: return p.projectileSpeed < 1400;
            case 5:
                if (p.element == ElementType.FIRE) return p.explosionRadius < 128;
                if (p.element == ElementType.WATER) return p.piercings < 8;
                if (p.element == ElementType.AIR) return p.ricochets < 8;
                return p.knockback < 192 || p.slowStrength < 0.8f;
            case 6: return p.dodgeChance < 0.3f;
            default: return false;
        }
    }

    private static PlayerUpgrade reward(String title, float before, float after, String unit, boolean rare) {
        return new PlayerUpgrade(title, number(before) + " > " + number(after) + unit, rare);
    }

    private static String number(float value) {
        return String.format(Locale.ROOT, value < 1 ? "%.2f" : "%.1f", value).replace('.', ',');
    }
}
