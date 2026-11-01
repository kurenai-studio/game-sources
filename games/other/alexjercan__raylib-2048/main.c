#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

Color map_color(int number) {
    switch (number) {
        case 2: return BLUE;
        case 4: return PURPLE;
        case 8: return GREEN;
        case 16: return RED;
        case 32: return PINK;
        case 64: return ORANGE;
        case 128: return VIOLET;
        case 256: return BROWN;
        case 512: return BEIGE;
        case 1024: return LIME;
        case 2048: return GOLD;
        default: return LIGHTGRAY;
    }
}

const char *map_text(int number) {
    switch (number) {
        case 2: return "2";
        case 4: return "4";
        case 8: return "8";
        case 16: return "16";
        case 32: return "32";
        case 64: return "64";
        case 128: return "128";
        case 256: return "256";
        case 512: return "412";
        case 1024: return "1024";
        case 2048: return "2048";
        default: return "";
    }
}

#define GRID_SIZE 4
#define CELL_SIZE 128
#define CELL_PADDING 16
#define WINDOW_SIZE ((GRID_SIZE) * (CELL_SIZE) + ((GRID_SIZE) + 1) * (CELL_PADDING))
#define FONT_SIZE 50
#define WORLD_SIZE ((GRID_SIZE) * (GRID_SIZE))

int world[WORLD_SIZE];

void world_init() {
    int index1 = rand() % WORLD_SIZE;
    int index2 = rand() % WORLD_SIZE;

    for (int i = 0; i < WORLD_SIZE; i++) {
        world[i] = 0;
    }

    world[index1] = 2;
    world[index2] = 2;
}

void world_spawn_new() {
    int length = 0;
    for (int i = 0; i < WORLD_SIZE; i++) {
        if (world[i] == 0) {
            length++;
        }
    }

    if (length == 0) {
        return;
    }

    int index = rand() % length;
    int j = 0;
    for (int i = 0; i < WORLD_SIZE; i++) {
        if (world[i] == 0) {
            if (index == j) {
                world[i] = 2;
                break;
            }
            j++;
        }
    }
}

int is_game_win() {
    for (int i = 0; i < WORLD_SIZE; i++) {
         if (world[i] == 2048) {
            return 1;
         }
    }

    return 0;
}

int is_game_over() {
    for (int i = 0; i < WORLD_SIZE; i++) {
        if (world[i] == 0) {
            return 0;
        }
    }

    for (int col = 0; col < GRID_SIZE; col++) {
        for (int row = 0; row < GRID_SIZE - 1; row++) {
            int index = row * GRID_SIZE + col;
            int down = (row + 1) * GRID_SIZE + col;

            if (world[index] == world[down]) {
                return 0;
            }
        }
    }

    for (int row = 0; row < GRID_SIZE; row++) {
        for (int col = 0; col < GRID_SIZE - 1; col++) {
            int index = row * GRID_SIZE + col;
            int right = row * GRID_SIZE + col + 1;

            if (world[index] == world[right]) {
                return 0;
            }
        }
    }

    return 1;
}

void merge_slice(int slice[]) {
    for (int i = 0; i < GRID_SIZE - 1; i++) {
        if (slice[i] == slice[i + 1]) {
            slice[i] = slice[i] + slice[i + 1];
            for (int j = i + 1; j < GRID_SIZE - 1; j++) {
                slice[j] = slice[j + 1];
            }
            slice[GRID_SIZE - 1] = 0;
        }
    }
}

void slide_cells_down() {
    for (int col = 0; col < GRID_SIZE; col++) {
        int slice[GRID_SIZE] = {0};
        for (int row = GRID_SIZE - 1, i = 0; row >= 0; row--) {
            int index = row * GRID_SIZE + col;
            if (world[index] != 0) {
                slice[i++] = world[index];
            }
        }
        merge_slice(slice);
        for (int row = GRID_SIZE - 1, i = 0; row >= 0; row--) {
            int index = row * GRID_SIZE + col;
            world[index] = slice[i++];
        }
    }
}

void slide_cells_up() {
    for (int col = 0; col < GRID_SIZE; col++) {
        int slice[GRID_SIZE] = {0};
        for (int row = 0, i = 0; row < GRID_SIZE; row++) {
            int index = row * GRID_SIZE + col;
            if (world[index] != 0) {
                slice[i++] = world[index];
            }
        }
        merge_slice(slice);
        for (int row = 0, i = 0; row < GRID_SIZE; row++) {
            int index = row * GRID_SIZE + col;
            world[index] = slice[i++];
        }
    }
}

void slide_cells_right() {
    for (int row = 0; row < GRID_SIZE; row++) {
        int slice[GRID_SIZE] = {0};
        for (int col = GRID_SIZE - 1, i = 0; col >= 0; col--) {
            int index = row * GRID_SIZE + col;
            if (world[index] != 0) {
                slice[i++] = world[index];
            }
        }
        merge_slice(slice);
        for (int col = GRID_SIZE - 1, i = 0; col >= 0; col--) {
            int index = row * GRID_SIZE + col;
            world[index] = slice[i++];
        }
    }
}

void slide_cells_left() {
    for (int row = 0; row < GRID_SIZE; row++) {
        int slice[GRID_SIZE] = {0};
        for (int col = 0, i = 0; col < GRID_SIZE; col++) {
            int index = row * GRID_SIZE + col;
            if (world[index] != 0) {
                slice[i++] = world[index];
            }
        }
        merge_slice(slice);
        for (int col = 0, i = 0; col < GRID_SIZE; col++) {
            int index = row * GRID_SIZE + col;
            world[index] = slice[i++];
        }
    }
}

int main(void) {
    srand(time(NULL));

    InitWindow(WINDOW_SIZE, WINDOW_SIZE, "2048");

    world_init();
    while (!WindowShouldClose()) {
        if (IsKeyPressed(KEY_R)) {
            world_init();
        }

        if (IsKeyPressed(KEY_DOWN)) {
            slide_cells_down();
            world_spawn_new();
        } else if (IsKeyPressed(KEY_UP)) {
            slide_cells_up();
            world_spawn_new();
        } else if (IsKeyPressed(KEY_LEFT)) {
            slide_cells_left();
            world_spawn_new();
        } else if (IsKeyPressed(KEY_RIGHT)) {
            slide_cells_right();
            world_spawn_new();
        }

        if (is_game_win()) {
            printf("You WIN!\n");
            world_init();
        } else if (is_game_over()) {
            printf("You Lost!\n");
            world_init();
        }

        BeginDrawing();
        ClearBackground(DARKGRAY);
        for (int row = 0; row < GRID_SIZE; row++) {
            for (int col = 0; col < GRID_SIZE; col++) {
                int index = row * GRID_SIZE + col;
                int number = world[index];
                int pos_x = col * CELL_SIZE + (col + 1) * CELL_PADDING;
                int pos_y = row * CELL_SIZE + (row + 1) * CELL_PADDING;
                DrawRectangle(pos_x, pos_y, CELL_SIZE, CELL_SIZE, map_color(number));

                int width = MeasureText(map_text(number), FONT_SIZE);
                int text_x = pos_x + CELL_SIZE / 2 - width / 2;
                int text_y = pos_y + CELL_SIZE / 2 - FONT_SIZE / 2;
                DrawText(map_text(number), text_x, text_y, FONT_SIZE, RAYWHITE);
            }
        }
        EndDrawing();
    }

    CloseWindow();

    return 0;
}
