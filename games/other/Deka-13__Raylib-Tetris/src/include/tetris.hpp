#ifndef TETRIS_GRID_HPP
#define TETRIS_GRID_HPP

#include <array>
#include "raylib.h"
#include "game_config.hpp"
#include <optional>

// Tetromino
struct Point { int x; int y; };

// Tetris Grid
class TetrisGrid {
private:
    struct Cell {
        enum class State { Empty, Locked, Falling };

        State state_cell = State::Empty;
    };

    std::array<Cell, GRID_SIZE> grid{};

    enum class TetrominoType { I, O, T, L, J, S, Z };

    Point start = {GRID_WIDTH / 2, 1};
    Point pivot = start;
    std::array<Point, 4> offsets;

    int score = 0;
    bool is_tetromino = false;

    static std::array<Point, 4> GetOffsets(TetrominoType type);

    void SetTetromino();

    void CheckIfFullRow();

    void MovePivot(int dx);

public:
    TetrisGrid() { SetRandomTetromino(); }

    Cell& GetCell(std::size_t index) {
        return grid[index];
    }

    bool IsGameOver();

    Point GetOffsetCoordinates(int x, int y) const {
        return { pivot.x + x, pivot.y + y };
    }

    bool IsCellEmpty(int index) const {
        return grid[index].state_cell == Cell::State::Empty;
    }
    
    constexpr std::optional<int> GetIndex(int x, int y) const {
        if (x < 0 || x >= GRID_WIDTH || y < 0 || y >= GRID_HEIGHT) {
            return std::nullopt;
        }
        return y * GRID_WIDTH + x;
    }

    int GetScore() const {
        return score;
    }

    bool IsTetromino() const {
        return is_tetromino;
    }

    void SetRandomTetromino();

    void Rotate();
    void MovePivotLeft();
    void MovePivotRight();

    // Function for blocks to fall to level below
    void DoFallStep();
};

#endif // TETRIS_GRID_HPP
