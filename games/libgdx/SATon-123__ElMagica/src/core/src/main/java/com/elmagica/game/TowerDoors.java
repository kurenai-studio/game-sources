package com.elmagica.game;

public class TowerDoors {
    public static boolean atExit(Player player) {
        float center = player.x + Player.SIZE / 2;
        return center >= ElMagicaGame.WORLD_WIDTH / 2f - 64
            && center <= ElMagicaGame.WORLD_WIDTH / 2f + 64
            && player.y + Player.SIZE >= ElMagicaGame.WORLD_HEIGHT - 66;
    }

}
