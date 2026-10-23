#include "../include/NativeRoguelikeCore.h"
#include <vector>
#include <cmath>
#include <algorithm>
#include <cstdint>

struct SpatialEntity {
    int id;
    float x;
    float y;
    float radius;
    int typeTag;
};

class SpatialHashGrid {
public:
    float minX = -30.0f;
    float minY = -20.0f;
    float maxX = 30.0f;
    float maxY = 20.0f;
    float cellSize = 2.0f;
    float invCellSize = 0.5f;

    int cols = 30;
    int rows = 20;

    std::vector<SpatialEntity> entities;
    std::vector<std::vector<int>> grid;

    void init(float min_x, float min_y, float max_x, float max_y, float cell_size) {
        minX = min_x;
        minY = min_y;
        maxX = max_x;
        maxY = max_y;
        cellSize = (cell_size > 0.1f) ? cell_size : 2.0f;
        invCellSize = 1.0f / cellSize;

        cols = std::max(1, static_cast<int>(std::ceil((maxX - minX) * invCellSize)));
        rows = std::max(1, static_cast<int>(std::ceil((maxY - minY) * invCellSize)));

        entities.clear();
        entities.reserve(256);
        grid.resize(cols * rows);
        for (auto& cell : grid) {
            cell.clear();
        }
    }

    void clear() {
        entities.clear();
        for (auto& cell : grid) {
            cell.clear();
        }
    }

    int getCellIndex(int cx, int cy) const {
        if (cx < 0 || cx >= cols || cy < 0 || cy >= rows) return -1;
        return cy * cols + cx;
    }

    void insert(int id, float x, float y, float radius, int typeTag) {
        int index = static_cast<int>(entities.size());
        entities.push_back({id, x, y, radius, typeTag});

        int minCx = std::max(0, static_cast<int>((x - radius - minX) * invCellSize));
        int maxCx = std::min(cols - 1, static_cast<int>((x + radius - minX) * invCellSize));
        int minCy = std::max(0, static_cast<int>((y - radius - minY) * invCellSize));
        int maxCy = std::min(rows - 1, static_cast<int>((y + radius - minY) * invCellSize));

        for (int cy = minCy; cy <= maxCy; ++cy) {
            for (int cx = minCx; cx <= maxCx; ++cx) {
                int cellIdx = cy * cols + cx;
                grid[cellIdx].push_back(index);
            }
        }
    }

    int queryRadius(float qx, float qy, float radius, int* outIds, float* outDistSq, int maxCount) {
        if (maxCount <= 0 || !outIds) return 0;

        float radSq = radius * radius;
        int minCx = std::max(0, static_cast<int>((qx - radius - minX) * invCellSize));
        int maxCx = std::min(cols - 1, static_cast<int>((qx + radius - minX) * invCellSize));
        int minCy = std::max(0, static_cast<int>((qy - radius - minY) * invCellSize));
        int maxCy = std::min(rows - 1, static_cast<int>((qy + radius - minY) * invCellSize));

        int found = 0;
        // Temporary visited bitset / vector to prevent duplicates
        std::vector<bool> visited(entities.size(), false);

        for (int cy = minCy; cy <= maxCy; ++cy) {
            for (int cx = minCx; cx <= maxCx; ++cx) {
                int cellIdx = cy * cols + cx;
                const auto& cell = grid[cellIdx];

                for (int entIdx : cell) {
                    if (visited[entIdx]) continue;
                    visited[entIdx] = true;

                    const auto& e = entities[entIdx];
                    float dx = e.x - qx;
                    float dy = e.y - qy;
                    float dSq = dx * dx + dy * dy;
                    float totalR = radius + e.radius;

                    if (dSq <= totalR * totalR) {
                        outIds[found] = e.id;
                        if (outDistSq) outDistSq[found] = dSq;
                        found++;
                        if (found >= maxCount) return found;
                    }
                }
            }
        }
        return found;
    }

    int findNearest(float qx, float qy, float maxRadius, int filterTag, int* outId, float* outDist) {
        float maxRadSq = maxRadius * maxRadius;
        int bestId = -1;
        float bestDistSq = maxRadSq;

        int minCx = std::max(0, static_cast<int>((qx - maxRadius - minX) * invCellSize));
        int maxCx = std::min(cols - 1, static_cast<int>((qx + maxRadius - minX) * invCellSize));
        int minCy = std::max(0, static_cast<int>((qy - maxRadius - minY) * invCellSize));
        int maxCy = std::min(rows - 1, static_cast<int>((qy + maxRadius - minY) * invCellSize));

        std::vector<bool> visited(entities.size(), false);

        for (int cy = minCy; cy <= maxCy; ++cy) {
            for (int cx = minCx; cx <= maxCx; ++cx) {
                int cellIdx = cy * cols + cx;
                const auto& cell = grid[cellIdx];

                for (int entIdx : cell) {
                    if (visited[entIdx]) continue;
                    visited[entIdx] = true;

                    const auto& e = entities[entIdx];
                    if (filterTag >= 0 && e.typeTag != filterTag) continue;

                    float dx = e.x - qx;
                    float dy = e.y - qy;
                    float dSq = dx * dx + dy * dy;

                    if (dSq < bestDistSq) {
                        bestDistSq = dSq;
                        bestId = e.id;
                    }
                }
            }
        }

        if (bestId != -1) {
            if (outId) *outId = bestId;
            if (outDist) *outDist = std::sqrt(bestDistSq);
            return 1;
        }
        return 0;
    }
};

static SpatialHashGrid g_spatialGrid;

NATIVE_API void Native_SpatialGrid_Init(float minX, float minY, float maxX, float maxY, float cellSize) {
    g_spatialGrid.init(minX, minY, maxX, maxY, cellSize);
}

NATIVE_API void Native_SpatialGrid_Clear() {
    g_spatialGrid.clear();
}

NATIVE_API void Native_SpatialGrid_Insert(int id, float x, float y, float radius, int typeTag) {
    g_spatialGrid.insert(id, x, y, radius, typeTag);
}

NATIVE_API int Native_SpatialGrid_QueryRadius(float x, float y, float radius, int* outIds, float* outDistSq, int maxCount) {
    return g_spatialGrid.queryRadius(x, y, radius, outIds, outDistSq, maxCount);
}

NATIVE_API int Native_SpatialGrid_FindNearest(float x, float y, float maxRadius, int filterTag, int* outId, float* outDist) {
    return g_spatialGrid.findNearest(x, y, maxRadius, filterTag, outId, outDist);
}
