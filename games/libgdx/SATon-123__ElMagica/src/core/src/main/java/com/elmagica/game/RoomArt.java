package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;

public class RoomArt {
    public static final String[] BIOMES = {"Древние руины", "Заросший храм", "Вулкан", "Ледяной склеп"};
    public static final String[] BIOME_FILES = {"ruins", "temple", "volcano", "ice"};
    private final SpriteFiles files = new SpriteFiles();
    private final TextureRegion[][] tiles = new TextureRegion[4][6];
    private final int[][] room = new int[ElMagicaGame.GRID_COLUMNS][ElMagicaGame.GRID_ROWS];
    private int biome = -1;
    public int getBiome() { return biome; }

    public RoomArt() {
        String[] names = {"floor-plain", "floor-cracked", "floor-pattern", "wall-plain", "wall-rune", "wall-medallion"};
        for (int row = 0; row < 4; row++) {
            for (int column = 0; column < 6; column++) {
                tiles[row][column] = files.load("rooms/" + BIOME_FILES[row] + "/tiles/" + names[column]);
            }
        }
    }

    public void newRoom() {
        int next = MathUtils.random(biome < 0 ? 3 : 2);
        if (biome >= 0 && next >= biome) next++;
        prepare(next);
    }

    public void prepare(int biome) {
        if (biome < 0 || biome >= BIOMES.length) throw new IllegalArgumentException("Unknown biome");
        this.biome = biome;
        for (int x = 0; x < room.length; x++) {
            for (int y = 0; y < room[x].length; y++) {
                boolean wall = x == 0 || y == 0 || x == room.length - 1 || y == room[x].length - 1;
                int roll = MathUtils.random(99);
                // Приглушаем узор пола, чтобы атаки не терялись.
                room[x][y] = wall ? 3 + (roll < 75 ? 0 : roll < 90 ? 1 : 2)
                    : roll < 72 ? 0 : roll < 95 ? 1 : 2;
            }
        }
    }

    public void draw(SpriteBatch batch) {
        for (int x = 0; x < room.length; x++) {
            for (int y = 0; y < room[x].length; y++) {
                boolean wall = room[x][y] >= 3;
                batch.setColor(wall ? 1 : 0.78f, wall ? 1 : 0.78f, wall ? 1 : 0.78f, 1);
                // Рисуем пол встык, размер игровой клетки от этого не меняется.
                batch.draw(tiles[biome][room[x][y]], x * 64, y * 64, 64, 64);
            }
        }
        batch.setColor(Color.WHITE);
    }

    public void dispose() {
        files.dispose();
    }
}
