#include "../include/NativeRoguelikeCore.h"
#include <vector>
#include <random>
#include <cmath>
#include <algorithm>

NATIVE_API int Native_GetVersion() {
    return 100; // Version 1.0.0
}

NATIVE_API void Native_Dungeon_GenerateCave(int width, int height, float wallProb, int smoothSteps, int* outGrid) {
    if (width <= 2 || height <= 2 || !outGrid) return;

    std::vector<int> currentMap(width * height, 0);
    std::vector<int> nextMap(width * height, 0);

    // Pseudorandom init
    std::mt19937 rng(1337);
    std::uniform_real_distribution<float> dist(0.0f, 1.0f);

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int idx = y * width + x;
            if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
                currentMap[idx] = 1; // Solid border
            } else {
                currentMap[idx] = (dist(rng) < wallProb) ? 1 : 0;
            }
        }
    }

    // Cellular Automata Smoothing (4-5 rule)
    for (int step = 0; step < smoothSteps; ++step) {
        for (int y = 1; y < height - 1; ++y) {
            for (int x = 1; x < width - 1; ++x) {
                int wallCount = 0;
                for (int ny = -1; ny <= 1; ++ny) {
                    for (int nx = -1; nx <= 1; ++nx) {
                        if (currentMap[(y + ny) * width + (x + nx)] == 1) {
                            wallCount++;
                        }
                    }
                }

                int idx = y * width + x;
                nextMap[idx] = (wallCount >= 5) ? 1 : 0;
            }
        }
        currentMap = nextMap;
    }

    for (int i = 0; i < width * height; ++i) {
        outGrid[i] = currentMap[i];
    }
}

NATIVE_API int Native_Dungeon_FindSafeSpawnPoints(
    const int* grid,
    int width,
    int height,
    float playerX,
    float playerY,
    float minPlayerDist,
    int maxPoints,
    float* outPointsX,
    float* outPointsY
) {
    if (!grid || width <= 2 || height <= 2 || maxPoints <= 0 || !outPointsX || !outPointsY) {
        return 0;
    }

    float minPlayerDistSq = minPlayerDist * minPlayerDist;
    int found = 0;

    // Scan floor cells with 3x3 clearance
    for (int y = 2; y < height - 2 && found < maxPoints; ++y) {
        for (int x = 2; x < width - 2 && found < maxPoints; ++x) {
            int idx = y * width + x;
            if (grid[idx] != 0) continue; // Not floor

            // Check surrounding 3x3 clearance
            bool isClear = true;
            for (int ny = -1; ny <= 1; ++ny) {
                for (int nx = -1; nx <= 1; ++nx) {
                    if (grid[(y + ny) * width + (x + nx)] != 0) {
                        isClear = false;
                        break;
                    }
                }
                if (!isClear) break;
            }

            if (!isClear) continue;

            float worldX = static_cast<float>(x - width / 2);
            float worldY = static_cast<float>(y - height / 2);

            float dx = worldX - playerX;
            float dy = worldY - playerY;
            if (dx * dx + dy * dy < minPlayerDistSq) continue;

            outPointsX[found] = worldX;
            outPointsY[found] = worldY;
            found++;
        }
    }

    return found;
}
