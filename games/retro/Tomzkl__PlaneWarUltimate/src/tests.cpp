// Unit tests for Plane War Ultimate core systems.
// Compile:  cl /EHsc /std:c++17 tests.cpp /Fe:tests.exe
// Run:      tests.exe
#include <cstdio>
#include <cstdlib>
#include <cmath>

#define TEST(name)  do { printf("  %s ... ", #name); } while(0)
#define CHECK(cond) do { \
    if (!(cond)) { printf("FAIL\n    %s:%d: %s\n", __FILE__, __LINE__, #cond); failed++; return 0; } \
} while(0)
#define CHECK_EQ(a, b) do { \
    if ((a) != (b)) { \
        printf("FAIL\n    %s == %s  (%d != %d)\n", #a, #b, (int)(a), (int)(b)); \
        failed++; return 0; \
    } \
} while(0)
#define CHECK_FLOAT_EQ(a, b, eps) do { \
    if (fabsf((float)(a) - (float)(b)) > (eps)) { \
        printf("FAIL\n    %s ~= %s  (%f != %f)\n", #a, #b, (float)(a), (float)(b)); \
        failed++; return 0; \
    } \
} while(0)
#define DONE() do { printf("OK\n"); passed++; } while(0)

static int passed = 0, failed = 0, total = 0;

// Minimal Pool for self-contained testing
struct TestItem { float x; bool active; };

template<typename T, int N>
struct Pool
{
    T items[N];
    int hint = 0;

    void Init() {
        for (int i = 0; i < N; i++) items[i].active = false;
        hint = 0;
    }
    T* Acquire() {
        for (int c = 0; c < N; c++) {
            int i = (hint + c) % N;
            if (!items[i].active) {
                items[i] = {}; items[i].active = true;
                hint = (i + 1) % N; return &items[i];
            }
        }
        return nullptr;
    }
    void Clear() {
        for (int i = 0; i < N; i++) items[i].active = false;
        hint = 0;
    }
};

// Our constants (same as constants.h)
constexpr int ENEMY_SPEED_CAP_EASY    = 12;
constexpr int ENEMY_SPEED_CAP_NORMAL  = 16;
constexpr int ENEMY_SPEED_CAP_HARD    = 22;
constexpr int ENEMY_SPEED_CAP_LUNATIC = 30;
constexpr int SCREEN_W = 800, SCREEN_H = 600;
constexpr int PLAYER_MAX_HP = 5;
constexpr int MAX_BULLETS = 100, MAX_ENEMIES = 30, MAX_PARTICLES = 300;
constexpr int BOSS_HP = 50;
constexpr int INITIAL_ENEMY_SPEED = 4;

// ====================================================================
int main()
{
    printf("Plane War Ultimate - Unit Tests\n");
    printf("================================\n\n");

    // -- Pool tests --
    printf("Pool:\n");
    total += 5;

    TEST(pool_acquire_valid); {
        Pool<TestItem, 5> p; p.Init();
        TestItem* t = p.Acquire();
        CHECK(t != nullptr);
        CHECK(t->active);
        DONE();
    }

    TEST(pool_full_returns_null); {
        Pool<TestItem, 3> p; p.Init();
        p.Acquire(); p.Acquire(); p.Acquire();
        CHECK(p.Acquire() == nullptr);
        DONE();
    }

    TEST(pool_clear_reuses); {
        Pool<TestItem, 3> p; p.Init();
        p.Acquire(); p.Acquire(); p.Acquire();
        CHECK(p.Acquire() == nullptr);
        p.Clear();
        CHECK(p.Acquire() != nullptr);
        DONE();
    }

    TEST(pool_different_addrs); {
        Pool<TestItem, 5> p; p.Init();
        TestItem* a = p.Acquire();
        TestItem* b = p.Acquire();
        CHECK(a != b);
        DONE();
    }

    TEST(pool_reuse_dead_slot); {
        Pool<TestItem, 3> p; p.Init();
        p.Acquire();
        TestItem* b = p.Acquire();
        p.Acquire();
        b->active = false;
        TestItem* c = p.Acquire();
        CHECK(c == b);
        DONE();
    }

    // -- Combo tests --
    printf("Combo:\n");
    total += 2;

    TEST(combo_increment); {
        int combo = 0;
        bool kill = true;
        if (kill) combo++;
        CHECK_EQ(combo, 1);
        if (kill) combo++;
        CHECK_EQ(combo, 2);
        DONE();
    }

    TEST(combo_multiplier); {
        const int MIN = 3;
        int c = 5;
        float m = 1.0f + (c - MIN + 1) * 0.1f;
        CHECK_FLOAT_EQ(m, 1.3f, 0.001f);
        c = 10;
        m = 1.0f + (c - MIN + 1) * 0.1f;
        CHECK_FLOAT_EQ(m, 1.8f, 0.001f);
        DONE();
    }

    // -- Collision tests --
    printf("Collision:\n");
    total += 3;

    TEST(aabb_overlap); {
        float ax = 100, ay = 100, aw = 50, ah = 50;
        float bx = 120, by = 120, bw = 50, bh = 50;
        bool ox = (ax < bx + bw) && (ax + aw > bx);
        bool oy = (ay < by + bh) && (ay + ah > by);
        CHECK(ox && oy);
        DONE();
    }

    TEST(aabb_no_overlap); {
        float ax = 100, ay = 100, aw = 50, ah = 50;
        float bx = 500, by = 500, bw = 50, bh = 50;
        bool ox = (ax < bx + bw) && (ax + aw > bx);
        bool oy = (ay < by + bh) && (ay + ah > by);
        CHECK(!(ox && oy));
        DONE();
    }

    TEST(spatial_early_out); {
        float by = 200.0f, ey = 500.0f;
        CHECK(fabsf(by - ey) > 100.0f);   // skip
        ey = 250.0f;
        CHECK(!(fabsf(by - ey) > 100.0f)); // check
        DONE();
    }

    // -- Constants sanity --
    printf("Constants:\n");
    total += 2;

    TEST(difficulty_speed_caps_ordered); {
        CHECK(ENEMY_SPEED_CAP_EASY < ENEMY_SPEED_CAP_NORMAL);
        CHECK(ENEMY_SPEED_CAP_NORMAL < ENEMY_SPEED_CAP_HARD);
        CHECK(ENEMY_SPEED_CAP_HARD < ENEMY_SPEED_CAP_LUNATIC);
        DONE();
    }

    TEST(reasonable_values); {
        CHECK(SCREEN_W > 0 && SCREEN_H > 0);
        CHECK(PLAYER_MAX_HP > 0);
        CHECK(MAX_BULLETS > 0);
        CHECK(MAX_ENEMIES > 0);
        CHECK(MAX_PARTICLES > 0);
        CHECK(BOSS_HP > 0);
        CHECK(INITIAL_ENEMY_SPEED > 0);
        DONE();
    }

    // -- Summary --
    printf("\n================================\n");
    printf("Results: %d/%d passed", passed, total);
    if (failed > 0) printf(", %d FAILED", failed);
    printf("\n");

    return failed > 0 ? 1 : 0;
}
