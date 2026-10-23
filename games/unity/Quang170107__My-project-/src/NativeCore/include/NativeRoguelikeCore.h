#pragma once

#ifdef _WIN32
  #define NATIVE_API extern "C" __declspec(dllexport)
#else
  #define NATIVE_API extern "C" __attribute__((visibility("default")))
#endif

NATIVE_API int Native_GetVersion();

// ── Spatial Hash Grid API ──────────────────────────────────────────────────
NATIVE_API void Native_SpatialGrid_Init(float minX, float minY, float maxX, float maxY, float cellSize);
NATIVE_API void Native_SpatialGrid_Clear();
NATIVE_API void Native_SpatialGrid_Insert(int id, float x, float y, float radius, int typeTag);
NATIVE_API int Native_SpatialGrid_QueryRadius(float x, float y, float radius, int* outIds, float* outDistSq, int maxCount);
NATIVE_API int Native_SpatialGrid_FindNearest(float x, float y, float maxRadius, int filterTag, int* outId, float* outDist);

// ── High-Performance Swarm Steering API ────────────────────────────────────
NATIVE_API void Native_Steering_ComputeSwarm(
    const float* inPositionsX,
    const float* inPositionsY,
    const float* inVelocitiesX,
    const float* inVelocitiesY,
    int count,
    float targetX,
    float targetY,
    float targetSpeed,
    float separationRadius,
    float separationWeight,
    float* outVelocitiesX,
    float* outVelocitiesY
);

// ── Procedural Dungeon & Cave Generator API ────────────────────────────────
NATIVE_API void Native_Dungeon_GenerateCave(int width, int height, float wallProb, int smoothSteps, int* outGrid);
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
);
