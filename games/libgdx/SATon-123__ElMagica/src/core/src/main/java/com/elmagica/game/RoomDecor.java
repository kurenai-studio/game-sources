package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

public class RoomDecor {
    private final SpriteFiles files = new SpriteFiles();
    private final TextureRegion[][] props = new TextureRegion[4][RoomLayout.OBSTACLE_VARIANTS];
    private final TextureRegion[][] gates = new TextureRegion[4][2];
    private final TextureRegion[][] loot = new TextureRegion[4][2];
    public RoomDecor() {
        for (int row = 0; row < 4; row++) {
            String biome = RoomArt.BIOME_FILES[row];
            gates[row][0] = files.load("rooms/" + biome + "/gates/closed");
            gates[row][1] = files.load("rooms/" + biome + "/gates/open");
            loot[row][0] = files.load("items/" + biome + "/spellbook");
            loot[row][1] = files.load("items/" + biome + "/healing-potion");
            for (int column = 0; column < RoomLayout.OBSTACLE_VARIANTS; column++) {
                props[row][column] = files.load("rooms/" + biome + "/obstacles/variant-0" + (column + 1));
            }
        }
    }
    public void draw(SpriteBatch batch, RoomLayout room, int biome, boolean exitOpen, Array<LootDrop> drops) {
        batch.setColor(Color.WHITE);
        float gateX = ElMagicaGame.WORLD_WIDTH / 2f - 64;
        batch.draw(gates[biome][0], gateX, 0, 128, 64);
        batch.draw(gates[biome][exitOpen ? 1 : 0], gateX, ElMagicaGame.WORLD_HEIGHT - 64, 128, 64);
        for (LootDrop drop : drops) {
            if (drop.type == LootDrop.Type.COIN) continue;
            float lift = 2 + MathUtils.sin(drop.getAge() * 4) * 2;
            float size = 32 * drop.getScale();
            batch.draw(loot[biome][drop.type == LootDrop.Type.BOOK ? 0 : 1], drop.x - size / 2, drop.y - size / 2 + lift, size, size);
        }
    }
    public void drawObstacle(SpriteBatch batch, RoomLayout room, int biome, int x, int y) {
        batch.draw(props[biome][room.getObstacleVariant(x, y)], x * 64, y * 64, 64, 64);
    }
    public void dispose() { files.dispose(); }
}
