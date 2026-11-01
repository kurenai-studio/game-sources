//
// Created by synx on 8/19/25.
//

#include "grid.h"
#include <random>

grid_t initGrid(const unsigned int width, const unsigned int height) {
    grid_t grid(height, std::vector<CellType>(width, DEAD));
    return grid;
}

void fillGridRandom(grid_t &grid) {
    std::random_device rd;
    std::mt19937 mt(rd());
    std::uniform_int_distribution<int> dist(0, 1);

    for (auto & y : grid) {
        for (auto & x : y) {
            switch (int val = dist(mt)) {
                case 0: x = DEAD;
                    break;
                case 1: x = ALIVE;
                    break;
                default: break;
            }
        }
    }
}
