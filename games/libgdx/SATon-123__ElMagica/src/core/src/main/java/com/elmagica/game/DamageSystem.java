package com.elmagica.game;

public final class DamageSystem {
    public static final ElementType[] PLAYER_ELEMENTS = {
        ElementType.FIRE, ElementType.WATER, ElementType.EARTH, ElementType.AIR
    };
    public static final ElementType[] ENEMY_ELEMENTS = {
        ElementType.FIRE, ElementType.WATER, ElementType.EARTH, ElementType.AIR
    };

    // Строка — кто бьёт, столбец — кого. Порядок стихий задан выше.
    private static final int[][] DAMAGE = {
        {10, 5, 10, 20},
        {20, 10, 5, 10},
        {10, 20, 10, 5},
        {5, 10, 20, 10}
    };

    private DamageSystem() {}

    public static int damageToPlayer(ElementType attack, ElementType player) {
        int matchup = damage(attack, player);
        // По магу считаем через тот же круг стихий.
        if (matchup == 20) return 3;
        if (matchup == 5) return 1;
        return 2;
    }

    public static int damageToPlayer(Enemy enemy, ElementType player) {
        int first = damageToPlayer(enemy.element, player);
        if (!enemy.isBoss()) return first;
        int second = damageToPlayer(enemy.secondElement, player);
        int weaker = Math.min(first, second);
        int stronger = Math.max(first, second);
        // Порядок двух стихий босса на урон не влияет.
        if (weaker == 2 && stronger == 3) return 3;
        if (weaker == 1 && stronger == 2) return 1;
        return 2;
    }

    public static int damage(ElementType attack, Enemy enemy) {
        int first = damage(attack, enemy.element);
        if (!enemy.isBoss()) return first;
        int second = damage(attack, enemy.secondElement);
        int weaker = Math.min(first, second);
        int stronger = Math.max(first, second);
        // Противоположные эффекты стихий здесь гасят друг друга.
        if (weaker == 10 && stronger == 20) return 20;
        if (weaker == 5 && stronger == 10) return 5;
        return 10;
    }

    public static int damage(ElementType player, ElementType enemy) {
        for (int row = 0; row < PLAYER_ELEMENTS.length; row++) {
            for (int column = 0; column < ENEMY_ELEMENTS.length; column++) {
                if (PLAYER_ELEMENTS[row] == player && ENEMY_ELEMENTS[column] == enemy) {
                    return DAMAGE[row][column];
                }
            }
        }
        throw new IllegalArgumentException("Invalid player/enemy elements");
    }
}
