#pragma once
#include "constants.h"
#include "types.h"
#include <vector>
#include <string>
#ifdef _MSC_VER
#pragma warning(disable: 4244)
#endif

namespace pwu {

struct SpawnCmd  { EnemyKind kind; int count; float xOffset, spacing, delay; };
struct WaveDef   { std::vector<SpawnCmd> commands; float restAfter; bool isBossWave; };

class WaveManager
{
public:
    void Restart();

    // Load from JSON; returns true on success. Falls back to built-in waves.
    bool LoadFromJSON(const char* filepath);

    bool ShouldSpawnNow(float dt, int enemyCount, float& outX, float& outY,
                        EnemyKind& outKind);
    void OnWaveCleared();

    bool IsResting()       const { return resting; }
    bool BossTriggered()   const { return bossPending; }
    void ClearBossTrigger()      { bossPending = false; }
    int  CurrentWave()     const { return waveIndex + 1; }

private:
    void NextWave();

    std::vector<WaveDef> waves;     // loaded from JSON (or empty = use built-in)

    int  waveIndex    = 0;
    int  cmdIndex     = 0;
    int  spawnCount   = 0;
    float spawnTimer  = 0;
    float restTimer   = 0;
    bool  resting     = true;
    bool  bossPending = false;
    bool  allDone     = false;
};

} // namespace pwu
