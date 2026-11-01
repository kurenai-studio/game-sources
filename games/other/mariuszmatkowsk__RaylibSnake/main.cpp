#include "Fruit.hpp"
#include "Snake.hpp"

#include <print>

#include <raylib.h>

constexpr int CELL_SIZE = 25;
constexpr int CELL_COUNT = 30;
constexpr const char* WINDOW_TITLE = "Raylib Snake";
constexpr int OFFSET = 75;

double last_update_time{0.};

bool should_move_snake(double interval) {
    double current_time = GetTime();
    if (current_time - last_update_time >= interval) {
        last_update_time = current_time;
        return true;
    }
    return false;
}

constexpr Color BOARD_COLOR{172, 202, 96, 255};
constexpr Color SNAKE_COLOR{40, 55, 20, 255};
constexpr Color FRUIT_COLOR{30, 70, 20, 255};

int main(int argc, char** argv) {

    InitWindow(OFFSET * 2 + CELL_SIZE * CELL_COUNT,
               OFFSET * 2 + CELL_SIZE * CELL_COUNT, WINDOW_TITLE);
    SetTargetFPS(60);

    Snake snake{SNAKE_COLOR, CELL_SIZE, CELL_COUNT, CELL_COUNT, OFFSET};
    Fruit fruit{FRUIT_COLOR, CELL_SIZE, CELL_COUNT,
                CELL_COUNT,  OFFSET,    snake.get_occupied_positions()};

    unsigned score{0};

    while (!WindowShouldClose()) {
        BeginDrawing();

        if (should_move_snake(0.2)) {
            snake.update();
            if (snake.is_collision()) {
                snake.reset();
                fruit.next(snake.get_occupied_positions());
                score = 0;
            }
            if (snake.can_eat_food(fruit.get_pos())) {
                snake.eat_food();
                fruit.next(snake.get_occupied_positions());
                score++;
            }
        }

        ClearBackground(BOARD_COLOR);
        if (IsKeyPressed(KEY_A)) {
            snake.move_left();
        }
        if (IsKeyPressed(KEY_D)) {
            snake.move_right();
        }
        if (IsKeyPressed(KEY_S)) {
            snake.move_down();
        }
        if (IsKeyPressed(KEY_W)) {
            snake.move_up();
        }

        DrawText("Raylib Snake", OFFSET, 20, 35, BLACK);
        DrawRectangleLinesEx(Rectangle{.x = OFFSET - 5,
                                       .y = OFFSET - 5,
                                       .width = CELL_SIZE * CELL_COUNT + 10,
                                       .height = CELL_SIZE * CELL_COUNT + 10},
                             3, BLACK);
        fruit.draw();
        snake.draw();

        DrawText(std::format("Score: {}", score).c_str(), OFFSET,
                 CELL_SIZE * CELL_COUNT + OFFSET + 20, 30, BLACK);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
