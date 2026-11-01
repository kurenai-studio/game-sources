package com.elmagica.game;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.Array;

public class RoomScene {
    public void draw(SpriteBatch batch, Player player, Array<Enemy> enemies, CombatSession session,
        int biome, GameSprites sprites, RoomDecor decor, MerchantArt merchantArt) {
        // Порядок отрисовки фиксированный, по высоте ничего не сортируем.
        for (int x = 1; x < 29; x++) for (int y = 1; y < 16; y++) {
            if (session.layout.isObstacle(x, y)) decor.drawObstacle(batch, session.layout, biome, x, y);
        }
        if (session.merchant != null) {
            merchantArt.drawMerchant(batch, session.merchant);
            for (int i = 0; i < 3; i++) merchantArt.drawPedestal(batch, session.merchant, i);
        }
        for (Enemy enemy : enemies) if (enemy.isAlive()) sprites.drawEnemy(batch, enemy);
        sprites.drawMage(batch, player);
    }
}
