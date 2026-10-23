#include "game.h"
#include "constants.h"
#include <raylib.h>
#include <raymath.h>

void update(Player& player, Map& map) {
    if (IsKeyPressed(KEY_RIGHT))
        player.tryMove(map, Direction::Right);

    if (IsKeyPressed(KEY_LEFT))
        player.tryMove(map, Direction::Left);

    if (IsKeyPressed(KEY_UP))
        player.tryMove(map, Direction::Up);

    if (IsKeyPressed(KEY_DOWN))
        player.tryMove(map, Direction::Down);

    player.pos.x = Clamp(player.pos.x, 0, map.width - 1);
    player.pos.y = Clamp(player.pos.y, 0, map.height - 1);
}

void draw(Player player, Map map, int xOffset, int yOffset) {
    BeginDrawing();
    ClearBackground(BLACK);

    for (int y = 0; y < map.height; y++) {
        for (int x = 0; x < map.width; x++) {
            int mapTile = map.layout[y][x];

            if (mapTile == 0)
                continue;

            int localTileId = mapTile - 1;

            int tilesetColumns = map.texture.width / TILE_SIZE;

            int tileX = localTileId % tilesetColumns;
            int tileY = localTileId / tilesetColumns;

            Rectangle source = {
                tileX * TILE_SIZE,
                tileY * TILE_SIZE,
                TILE_SIZE,
                TILE_SIZE
            };

            Rectangle destination = {
                xOffset + x * SCREEN_TILE_SIZE,
                yOffset + y * SCREEN_TILE_SIZE,
                SCREEN_TILE_SIZE,
                SCREEN_TILE_SIZE
            };

            DrawTexturePro(
                map.texture,
                source,
                destination,
                {0, 0},
                0,
                WHITE
            );
        }
    }

    for (int i = 0; i < map.boxCount; i++) {
        Box box = map.boxes[i];

        Rectangle source = {
            0 * TILE_SIZE,
            4 * TILE_SIZE,
            TILE_SIZE,
            TILE_SIZE
        };

        Rectangle destination = {
            xOffset + box.pos.x * SCREEN_TILE_SIZE,
            yOffset + box.pos.y * SCREEN_TILE_SIZE,
            SCREEN_TILE_SIZE,
            SCREEN_TILE_SIZE
        };

        DrawTexturePro(
            map.texture,
            source,
            destination,
            {0, 0},
            0,
            WHITE
        );
    }

    Rectangle source = {
        0,
        0,
        PLAYER_SPRITE_SIZE,
        PLAYER_SPRITE_SIZE
    };

    Rectangle destination = {
        xOffset + player.pos.x * SCREEN_TILE_SIZE,
        yOffset + player.pos.y * SCREEN_TILE_SIZE,
        SCREEN_TILE_SIZE,
        SCREEN_TILE_SIZE
    };

    DrawTexturePro(
        player.texture,
        source,
        destination,
        {0, 0},
        0,
        WHITE
    );

    EndDrawing();
}
