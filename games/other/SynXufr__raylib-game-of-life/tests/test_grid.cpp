#include "grid.h"
#include <cassert>
#include <iostream>

void TestInitGrid() {
    unsigned int width = 3;
    unsigned int height = 5;
    grid_t grid = initGrid(width, height);

    assert(grid.size() == height);
    for (const auto &row : grid) {
        assert(row.size() == width);
        for (const auto cell : row) {
            assert(cell == DEAD);
        }
    }
}

void TestFillGridRandom() {
    unsigned int width = 10;
    unsigned int height = 10;
    grid_t grid = initGrid(width, height);

    fillGridRandom(grid);

    int aliveCount = 0;
    int deadCount = 0;

    for (const auto &row : grid) {
        for (const auto cell : row) {
            switch (cell) {
                case ALIVE:
                    ++aliveCount;
                    break;
                case DEAD:
                    ++deadCount;
                    break;
                default:
                    assert(false && "Cell should only be ALIVE or DEAD");
            }
        }
    }

    assert(aliveCount > 0);
    assert(deadCount > 0);
    assert(aliveCount + deadCount == static_cast<int>(width * height));
}

int main() {
    TestInitGrid();
    TestFillGridRandom();
    std::cout << "All tests passed\n";
    return 0;
}

