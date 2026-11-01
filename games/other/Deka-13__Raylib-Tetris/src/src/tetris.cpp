#include "tetris.hpp"
#include "user_config.hpp"

// TetrisGrid Class Functions
void TetrisGrid::Rotate() {
    // 1. Check if there is tetromino on a grid
    if (!is_tetromino) return;

    // 2. Square pieces (O-tetromino) do not rotate
    bool is_square = true;
    const auto square_offsets = GetOffsets(TetrominoType::O);
    for (std::size_t i = 0; i < offsets.size(); ++i) {
        if (offsets[i].x != square_offsets[i].x || offsets[i].y != square_offsets[i].y) {
            is_square = false;
            break;
        }
    }
    if (is_square) {
        return; // Square doesn't change, no need to redraw or clear
    }

    // 3. Backup old pivot
    Point old_pivot = pivot;

    // 4. Apply standard rotation transformation (90 degrees clockwise: (x, y) -> (-y, x))
    auto temp_offsets = offsets;
    for (auto& offset : temp_offsets) {
        int x = offset.x;
        int y = offset.y;
        offset.x = -y;
        offset.y = x;
    }

    // 5. Define potential kick adjustments (test normal first, then nudge left, right, or up)
    constexpr std::array<Point, 4> kick_tests = {{
        {0, 0},   // No shift (standard rotation check)
        {1, 0},   // Shift right
        {-1, 0},  // Shift left
        {0, -1}   // Shift up (crucial for floor rotations)
    }};

    bool successful_rotation = false;
    Point final_pivot = old_pivot;

    for (const auto& kick : kick_tests) {
        Point test_pivot = { old_pivot.x + kick.x, old_pivot.y + kick.y };

        bool collision = false;
        for (const auto& offset : temp_offsets) {
            // Compute coordinates using the temporary pivot and rotated offsets
            Point cell_pos = { test_pivot.x + offset.x, test_pivot.y + offset.y };
            auto index = GetIndex(cell_pos.x, cell_pos.y);

            // Check out of bounds or colliding with a locked block
            if (!index.has_value() || grid[static_cast<std::size_t>(index.value())].state_cell == Cell::State::Locked) {
                collision = true;
                break;
            }
        }

        if (!collision) {
            successful_rotation = true;
            final_pivot = test_pivot;
            break;
        }
    }

    // 6. If all kicks failed, rotation is invalid. Do nothing and exit.
    if (!successful_rotation) {
        return;
    }

    // 7. ONLY NOW that rotation is proven safe, clear old falling positions from the grid
    for (auto& cell : grid) {
        if (cell.state_cell == Cell::State::Falling) {
            cell.state_cell = Cell::State::Empty;
        }
    }

    // 8. Apply the successful rotation state and redraw
    offsets = temp_offsets;
    pivot = final_pivot;
    SetTetromino();
}

void TetrisGrid::SetTetromino(){    
    for (auto& offset : offsets) {
        Point cell_pos = GetOffsetCoordinates(offset.x, offset.y);
        auto index = GetIndex(cell_pos.x, cell_pos.y);
        if (index.has_value()) {
            GetCell(static_cast<std::size_t>(index.value())).state_cell = Cell::State::Falling;
        }
    }
}

// Fixed: Removed 'static' keyword out-of-line definition
std::array<Point, 4> TetrisGrid::GetOffsets(TetrominoType type) {
    switch (type) {
        case TetrominoType::I: return {{{-1, 0}, {0, 0}, {1, 0}, {2, 0}}};
        case TetrominoType::O: return {{{0, 0}, {1, 0}, {0, -1}, {1, -1}}};
        case TetrominoType::T: return {{{-1, 0}, {0, 0}, {1, 0}, {0, -1}}};
        case TetrominoType::L: return {{{-1, 0}, {0, 0}, {1, 0}, {1, -1}}};
        case TetrominoType::S: return {{{-1, 0}, {0, 0}, {0, -1}, {1, -1}}};
        case TetrominoType::J: return {{{-1, 0}, {0, 0}, {1, 0}, {-1, -1}}};
        case TetrominoType::Z: return {{{-1, -1}, {0, -1}, {0, 0}, {1, 0}}};
    }
    return {{{0, 0}, {0, 0}, {0, 0}, {0, 0}}};
}

// Random Tetromino Creation Logic Function
void TetrisGrid::SetRandomTetromino() {
    if (IsGameOver()) return;

    static std::array<TetrominoType, 7> bag = {
        TetrominoType::I,
        TetrominoType::O,
        TetrominoType::T,
        TetrominoType::L,
        TetrominoType::J,
        TetrominoType::S,
        TetrominoType::Z
    };

    static std::size_t index = bag.size();

    // Refill and shuffle the bag when empty
    if (index >= bag.size()) {
        // Fisher-Yates shuffle
        for (std::size_t i = bag.size() - 1; i > 0; --i) {
            int j = GetRandomValue(0, static_cast<int>(i));
            std::swap(bag[i], bag[j]);
        }

        index = 0;
    }

    offsets = GetOffsets(bag[index++]); // assign offsets according to shuffled type
    pivot = start;
    is_tetromino = true;
    SetTetromino();
}

void TetrisGrid::DoFallStep() {
    bool all_locked = true;
    for (auto& cell : grid) {
        if (cell.state_cell == Cell::State::Falling) {
            all_locked = false;
        }
    }
    
    if (all_locked) {
        SetRandomTetromino();
        return;
    }

    // Check if any falling block will collide with the floor or a locked block below it.
    bool will_collide = false;
    for (std::size_t i = grid.size(); i > 0; --i) {
        std::size_t t = i - 1;
        if (grid[t].state_cell == Cell::State::Falling) {
            // Check if it's on the bottom row or if the cell directly below is locked
            if (((grid.size() - GRID_WIDTH) <= t) || (grid[t + GRID_WIDTH].state_cell == Cell::State::Locked)) {
                will_collide = true;
                break;
            }
        }
    }

    // Act based on collision status
    if (will_collide) {
        // Lock all falling blocks simultaneously so they stop immediately together
        for (auto& cell : grid) {
            if (cell.state_cell == Cell::State::Falling) {
                cell.state_cell = Cell::State::Locked;
            }
        }
        is_tetromino = false;
        CheckIfFullRow();
    } else {
        // Safe to move all falling blocks down by one row.
        // Must iterate backwards (bottom to top) to prevent overwriting falling cells below.
        for (std::size_t i = grid.size(); i > 0; --i) {
            std::size_t t = i - 1;
            if (grid[t].state_cell == Cell::State::Falling) {
                grid[t].state_cell = Cell::State::Empty;
                grid[t + GRID_WIDTH].state_cell = Cell::State::Falling;
            }
        }
        ++pivot.y;
        SetTetromino();
    }
}

void TetrisGrid::CheckIfFullRow() {
    for (std::size_t row = 0; row < grid.size(); row += GRID_WIDTH) {
        bool is_full_row = true;
        for (std::size_t t = 0; t < GRID_WIDTH; ++t) {
            if (grid[row + t].state_cell == Cell::State::Empty) {
                is_full_row = false;
                break;
            }
        }

        if (is_full_row) {
            // 1. Clear the full row
            for (std::size_t t = 0; t < GRID_WIDTH; ++t) {
                grid[row + t].state_cell = Cell::State::Empty;
                score = score + GRID_WIDTH * 10;
            }

            // 2. Shift all rows above this cleared row down by one row width
            // Must loop upwards from the cleared row toward the top of the grid (index 0)
            for (std::ptrdiff_t current_row = static_cast<std::ptrdiff_t>(row); current_row > 0; current_row -= GRID_WIDTH) {
                for (std::size_t t = 0; t < GRID_WIDTH; ++t) {
                    std::size_t dest_idx = static_cast<std::size_t>(current_row) + t;
                    std::size_t src_idx = dest_idx - GRID_WIDTH;
                    
                    // Copy the state from the row above
                    grid[dest_idx].state_cell = grid[src_idx].state_cell;
                }
            }

            // 3. Clear the very top row since nothing is above it to shift down
            for (std::size_t t = 0; t < GRID_WIDTH; ++t) {
                grid[t].state_cell = Cell::State::Empty;
            }
        }
    }
}

void TetrisGrid::MovePivot(int dx) {
    if (!is_tetromino) return;

    // 2. Backup old pivot
    Point old_pivot = pivot;

    // 3. Tentatively move pivot by dx (-1 for left, 1 for right)
    pivot.x += dx;

    // 4. Check for collisions with walls or locked blocks BEFORE clearing the grid
    bool collision = false;
    for (const auto& offset : offsets) {
        Point cell_pos = GetOffsetCoordinates(offset.x, offset.y);
        auto index = GetIndex(cell_pos.x, cell_pos.y);

        if (!index.has_value() || grid[static_cast<std::size_t>(index.value())].state_cell == Cell::State::Locked) {
            collision = true;
            break;
        }
    }

    // 5. If collision occurred, revert the pivot change immediately and exit
    if (collision) {
        pivot = old_pivot;
        return; 
    }

    // 6. Only now that the move is verified safe, clear old falling positions
    for (auto& cell : grid) {
        if (cell.state_cell == Cell::State::Falling) {
            cell.state_cell = Cell::State::Empty;
        }
    }

    // 7. Redraw the tetromino at its new valid position
    SetTetromino();
}

void TetrisGrid::MovePivotLeft() {
    MovePivot(-1);
}

void TetrisGrid::MovePivotRight() {
    MovePivot(1);
}

bool TetrisGrid::IsGameOver() {
    // Check if any locked blocks exist in the top row (or the spawn row area)
    // Here we check the hidden and the top row (from index 0 up to GRID_WIDTH * 2)
    // The function will be updated later
    for (std::size_t i = 0; i < GRID_WIDTH * 2; ++i) {
        if (grid[i].state_cell == Cell::State::Locked) {
            return true;
        }
    }
    return false;
}
