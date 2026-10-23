#include <iostream>
#include <raylib.h>
#include "constants.h"
#include "game.h"
#include "map.h"
#include "player.h"

int main(void) {
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Sokoban");
    SetTargetFPS(60);

    Texture2D tilesetTexture = LoadTexture("assets/tilesets/map.png");
    Texture2D playerTexture = LoadTexture("assets/sprites/player-idle.png");

    Map map;
    if (!map.loadFromFile("assets/levels/level0.tmj")) {
        std::cout << "Failed to load map\n";
        return 1;
    }

    Box boxes[] = {
        {4, 4},
        {3, 2},
        {4, 8},
        {8, 8}
    };

    map.loadBoxes(boxes, 4);
    map.texture = tilesetTexture;

    Player player = {{map.width / 2, map.height / 2}, playerTexture};

    const int xOffset = (SCREEN_WIDTH - map.width * SCREEN_TILE_SIZE) / 2;
    const int yOffset = (SCREEN_HEIGHT - map.height * SCREEN_TILE_SIZE) / 2;

    while (!WindowShouldClose()) {
        update(player, map);
        draw(player, map, xOffset, yOffset);
    }

    CloseWindow();

    return 0;
}
