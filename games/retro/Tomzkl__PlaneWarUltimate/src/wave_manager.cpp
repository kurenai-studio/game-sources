#include "wave_manager.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace pwu {

// ====================================================================
//  Minimal JSON parser - enough for waves.json
// ====================================================================

static const char* skipWS(const char* p) {
    while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
    return p;
}

static const char* skipString(const char* p) {
    if (*p != '"') return p;
    p++;
    while (*p && *p != '"') { if (*p == '\\') p++; p++; }
    if (*p == '"') p++;
    return p;
}

static const char* skipValue(const char* p) {
    p = skipWS(p);
    if (*p == '"') return skipString(p);
    if (*p == '{' || *p == '[') { int d=1; p++; while (*p && d) { if (*p=='{'||*p=='[') d++; if (*p=='}'||*p==']') d--; p++; } return p; }
    while (*p && *p != ',' && *p != '}' && *p != ']') p++;
    return p;
}

static bool readString(const char*& p, char* out, int maxLen) {
    p = skipWS(p);
    if (*p != '"') return false;
    p++;
    int i = 0;
    while (*p && *p != '"' && i < maxLen-1) {
        if (*p == '\\') p++;
        out[i++] = *p++;
    }
    out[i] = 0;
    if (*p == '"') p++;
    return true;
}

static float readNumber(const char*& p) {
    p = skipWS(p);
    char* end;
    float v = (float)strtod(p, &end);
    if (end != p) p = end;
    return v;
}

static EnemyKind parseEnemyKind(const char* s) {
    if      (strcmp(s, "SMALL")  == 0) return EnemyKind::SMALL;
    else if (strcmp(s, "MEDIUM") == 0) return EnemyKind::MEDIUM;
    else if (strcmp(s, "LARGE")  == 0) return EnemyKind::LARGE;
    return EnemyKind::SMALL;
}

bool WaveManager::LoadFromJSON(const char* filepath)
{
    // Read entire file
    FILE* f = fopen(filepath, "rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0 || sz > 65536) { fclose(f); return false; }
    char* buf = new char[sz + 1];
    fread(buf, 1, sz, f);
    buf[sz] = 0;
    fclose(f);

    const char* p = buf;
    waves.clear();

    // Find "waves" array
    p = skipWS(p);
    if (*p != '{') { delete[] buf; return false; }

    // Navigate to "waves" key
    bool found = false;
    while (*p && !found) {
        p = skipWS(p); if (*p == '}') break; if (*p == ',') p++;
        char key[64];
        if (!readString(p, key, 64)) break;
        p = skipWS(p);
        if (*p != ':') break; p++;
        if (strcmp(key, "waves") == 0) { found = true; break; }
        p = skipValue(p);  // skip other keys
    }
    if (!found) { delete[] buf; return false; }

    p = skipWS(p);
    if (*p != '[') { delete[] buf; return false; }
    p++;

    // Parse each wave object
    while (*p) {
        p = skipWS(p);
        if (*p == ']') break;
        if (*p == ',') { p++; continue; }
        if (*p != '{') break;

        WaveDef wd;
        wd.restAfter  = 3.0f;
        wd.isBossWave = false;
        p++; // skip '{'

        while (*p) {
            p = skipWS(p);
            if (*p == '}') break;
            if (*p == ',') { p++; continue; }

            char key[64];
            if (!readString(p, key, 64)) break;
            p = skipWS(p);
            if (*p != ':') break; p++;

            if (strcmp(key, "restAfter") == 0) {
                wd.restAfter = readNumber(p);
            }
            else if (strcmp(key, "isBossWave") == 0) {
                p = skipWS(p);
                wd.isBossWave = (strncmp(p, "true", 4) == 0);
                p = skipValue(p);
            }
            else if (strcmp(key, "commands") == 0) {
                p = skipWS(p);
                if (*p != '[') break; p++;
                while (*p) {
                    p = skipWS(p);
                    if (*p == ']') break;
                    if (*p == ',') { p++; continue; }
                    if (*p != '{') break;

                    SpawnCmd cmd;
                    cmd.kind    = EnemyKind::SMALL;
                    cmd.count   = 1;
                    cmd.xOffset = 0;
                    cmd.spacing = 60;
                    cmd.delay   = 0;
                    p++;

                    while (*p) {
                        p = skipWS(p);
                        if (*p == '}') break;
                        if (*p == ',') { p++; continue; }

                        char fld[32];
                        if (!readString(p, fld, 32)) break;
                        p = skipWS(p);
                        if (*p != ':') break; p++;

                        if      (strcmp(fld, "kind")    == 0) { char v[16]; readString(p, v, 16); cmd.kind    = parseEnemyKind(v); }
                        else if (strcmp(fld, "count")   == 0) { cmd.count   = (int)readNumber(p); }
                        else if (strcmp(fld, "xOffset") == 0) { cmd.xOffset = readNumber(p); }
                        else if (strcmp(fld, "spacing") == 0) { cmd.spacing = readNumber(p); }
                        else if (strcmp(fld, "delay")   == 0) { cmd.delay   = readNumber(p); }
                        else { p = skipValue(p); }
                    }
                    if (*p == '}') p++;
                    wd.commands.push_back(cmd);
                }
                if (*p == ']') p++;
            }
            else if (strcmp(key, "name") == 0) {
                p = skipValue(p);  // skip name - for humans only
            }
            else {
                p = skipValue(p);
            }
        }
        if (*p == '}') p++;
        if (!wd.commands.empty()) waves.push_back(wd);
    }

    delete[] buf;
    return !waves.empty();
}

// ====================================================================
//  Built-in wave definitions (fallback when JSON is missing)
// ====================================================================

static void buildBuiltinWaves(std::vector<WaveDef>& out)
{
    out.clear();
    auto add = [&](std::initializer_list<SpawnCmd> cmds, float rest, bool boss) {
        WaveDef wd;
        wd.commands.assign(cmds);
        wd.restAfter  = rest;
        wd.isBossWave = boss;
        out.push_back(wd);
    };

    add({{EnemyKind::SMALL,  5, -100, 50, 0}},  3.0f, false);
    add({{EnemyKind::MEDIUM, 3, -80,  80, 0}},  3.0f, false);
    add({{EnemyKind::SMALL,  4, -90,  60, 0},
         {EnemyKind::MEDIUM, 2, -50, 100, 1.0f}}, 3.5f, false);
    add({{EnemyKind::SMALL,  6, -150, 60, 0}},  2.5f, false);
    add({{EnemyKind::MEDIUM, 3, -60,  60, 0},
         {EnemyKind::LARGE,  1,   0,   0, 1.5f}}, 2.0f, true);
    add({{EnemyKind::SMALL,  3, -120, 80, 0},
         {EnemyKind::SMALL,  3, -40,  80, 0.3f},
         {EnemyKind::MEDIUM, 2, -80,  80, 1.0f}}, 3.0f, false);
    add({{EnemyKind::LARGE,  1,   0,   0, 0},
         {EnemyKind::SMALL,  4, -100, 66, 0.8f}}, 3.5f, false);
    add({{EnemyKind::MEDIUM, 4, -120, 80, 0},
         {EnemyKind::MEDIUM, 4, -100, 66, 1.5f}}, 3.0f, false);
    add({{EnemyKind::LARGE,  2, -80, 160, 0},
         {EnemyKind::MEDIUM, 3, -60,  60, 1.0f},
         {EnemyKind::SMALL,  5, -130, 65, 1.5f}}, 2.5f, false);
    add({{EnemyKind::MEDIUM, 4, -90,  60, 0},
         {EnemyKind::LARGE,  2, -70, 140, 1.0f}}, 2.0f, true);
}

// ====================================================================
//  WaveManager implementation
// ====================================================================

void WaveManager::Restart()
{
    if (waves.empty()) buildBuiltinWaves(waves);
    waveIndex   = 0;
    cmdIndex    = 0;
    spawnCount  = 0;
    spawnTimer  = 0;
    restTimer   = 1.5f;
    resting     = true;
    bossPending = false;
    allDone     = false;
}

bool WaveManager::ShouldSpawnNow(float dt, int enemyCount,
                                 float& outX, float& outY, EnemyKind& outKind)
{
    if (waves.empty()) buildBuiltinWaves(waves);
    if (allDone) return false;

    if (resting) {
        restTimer -= dt;
        if (restTimer <= 0) { resting = false; spawnTimer = 0; cmdIndex = 0; spawnCount = 0; }
        return false;
    }

    if (waveIndex >= (int)waves.size()) { allDone = true; return false; }

    const WaveDef& wave = waves[waveIndex];

    if (cmdIndex >= (int)wave.commands.size()) {
        if (enemyCount == 0) {
            if (wave.isBossWave) bossPending = true;
            OnWaveCleared();
        }
        return false;
    }

    const SpawnCmd& cmd = wave.commands[cmdIndex];
    if (spawnTimer < cmd.delay) { spawnTimer += dt; return false; }

    if (spawnCount < cmd.count) {
        outKind = cmd.kind;
        outX = (float)SCREEN_W / 2.0f + cmd.xOffset + (float)spawnCount * cmd.spacing;
        outY = -80.0f;
        spawnCount++;
        if (spawnCount >= cmd.count) { cmdIndex++; spawnCount = 0; spawnTimer = 0; }
        return true;
    }
    return false;
}

void WaveManager::OnWaveCleared()
{
    if (waveIndex >= (int)waves.size()) return;
    restTimer = waves[waveIndex].restAfter;
    resting   = true;
    waveIndex++;
    if (waveIndex >= (int)waves.size()) waveIndex = 4; // loop from boss wave
}

void WaveManager::NextWave()
{
    cmdIndex = 0; spawnCount = 0; spawnTimer = 0; resting = false;
}

} // namespace pwu
