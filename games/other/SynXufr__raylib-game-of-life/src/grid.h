//
// Created by synx on 8/19/25.
//

#ifndef GRID_H
#define GRID_H
#include <vector>

enum CellType {
    ALIVE,
    DEAD,
    WALL
};

typedef std::vector<std::vector<CellType>> grid_t;

grid_t initGrid(unsigned int width, unsigned int height);

void fillGridRandom(grid_t &grid);

#endif //GRID_H