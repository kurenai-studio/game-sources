// Dependency-free tests for the engine-free game rules in Source/CoinRun/Rules.
// Exit code 0 = all passed, 1 = at least one failed.
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

#include "Rules/Dash.h"
#include "Rules/HighScore.h"
#include "Rules/Motion.h"
#include "Rules/Rng.h"
#include "Rules/RunState.h"
#include "Rules/Spawner.h"
#include "Rules/Tuning.h"
#include "Rules/Vec2.h"

using namespace coinrun;

namespace {

struct TestCase {
    const char* name;
    void (*fn)();
};

std::vector<TestCase>& Registry() {
    static std::vector<TestCase> registry;
    return registry;
}

int g_failures_in_test = 0;

struct Registrar {
    Registrar(const char* name, void (*fn)()) { Registry().push_back({name, fn}); }
};

}  // namespace

#define TEST(name)                          \
    static void name();                     \
    static Registrar registrar_##name(#name, &name); \
    static void name()

#define EXPECT(cond)                                                          \
    do {                                                                      \
        if (!(cond)) {                                                        \
            std::printf("  FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);     \
            ++g_failures_in_test;                                             \
        }                                                                     \
    } while (0)

#define EXPECT_EQ(a, b)                                                                         \
    do {                                                                                        \
        const long long va_ = static_cast<long long>(a);                                        \
        const long long vb_ = static_cast<long long>(b);                                        \
        if (va_ != vb_) {                                                                       \
            std::printf("  FAIL %s:%d: %s == %s (%lld vs %lld)\n", __FILE__, __LINE__, #a, #b, va_, vb_); \
            ++g_failures_in_test;                                                               \
        }                                                                                       \
    } while (0)

#define EXPECT_NEAR(a, b, eps)                                                                  \
    do {                                                                                        \
        const double va_ = static_cast<double>(a);                                              \
        const double vb_ = static_cast<double>(b);                                              \
        if (std::fabs(va_ - vb_) > static_cast<double>(eps)) {                                  \
            std::printf("  FAIL %s:%d: %s ~= %s (%f vs %f)\n", __FILE__, __LINE__, #a, #b, va_, vb_); \
            ++g_failures_in_test;                                                               \
        }                                                                                       \
    } while (0)

namespace {

bool Collect(RunState& s) {
    bool advanced = false;
    s.OnCoinCollected(&advanced);
    return advanced;
}

}  // namespace

// ---- Rng ----

TEST(rng_same_seed_same_sequence) {
    Rng a(42), b(42);
    for (int i = 0; i < 100; ++i) EXPECT_EQ(a.NextUInt(), b.NextUInt());
}

TEST(rng_different_seeds_differ) {
    Rng a(1), b(2);
    bool differ = false;
    for (int i = 0; i < 10; ++i) differ = differ || a.NextUInt() != b.NextUInt();
    EXPECT(differ);
}

TEST(rng_seed_zero_is_not_stuck) {
    Rng r(0);
    const uint32_t first = r.NextUInt();
    EXPECT(first != 0u);
    EXPECT(r.NextUInt() != first);
}

TEST(rng_survives_the_one_seed_that_mixes_to_a_zero_state) {
    // state = seed * K + C (mod 2^32) is zero for exactly one seed; solve for it with the modular inverse of K.
    const uint32_t k = 2654435761u, c = 0x9E3779B9u;
    uint32_t inv = k;
    for (int i = 0; i < 6; ++i) inv = inv * (2u - k * inv);
    const uint32_t bad_seed = (0u - c) * inv;
    EXPECT(bad_seed * k + c == 0u);  // test setup check
    Rng r(static_cast<int32_t>(bad_seed));
    const uint32_t a = r.NextUInt(), b = r.NextUInt();
    EXPECT(a != 0u && b != 0u && a != b);
}

TEST(rng_float_in_unit_interval) {
    Rng r(7);
    for (int i = 0; i < 5000; ++i) {
        const float f = r.NextFloat();
        EXPECT(f >= 0.0f && f < 1.0f);
    }
}

TEST(rng_float_range_bounds) {
    Rng r(8);
    for (int i = 0; i < 5000; ++i) {
        const float f = r.RangeF(-3.0f, 5.0f);
        EXPECT(f >= -3.0f && f < 5.0f);
    }
}

TEST(rng_int_range_covers_all_values_in_bounds) {
    Rng r(9);
    bool seen[4] = {false, false, false, false};
    for (int i = 0; i < 500; ++i) {
        const int v = r.RangeI(0, 4);
        EXPECT(v >= 0 && v < 4);
        if (v >= 0 && v < 4) seen[v] = true;
    }
    for (int i = 0; i < 4; ++i) EXPECT(seen[i]);
}

TEST(rng_int_range_degenerate_returns_min) {
    Rng a(1), b(1);
    EXPECT_EQ(5, a.RangeI(5, 5));
    EXPECT_EQ(5, b.RangeI(5, 2));
}

TEST(rng_roughly_uniform) {
    Rng r(10);
    double sum = 0.0;
    const int n = 20000;
    for (int i = 0; i < n; ++i) sum += static_cast<double>(r.NextFloat());
    EXPECT_NEAR(0.5, sum / n, 0.02);
}

// ---- Vec2 ----

TEST(vec2_length_and_normalize) {
    EXPECT_NEAR(5.0f, Vec2(3.0f, 4.0f).Length(), 1e-5);
    EXPECT_NEAR(1.0f, Vec2(3.0f, 4.0f).Normalized().Length(), 1e-5);
}

TEST(vec2_normalize_zero_stays_zero) {
    const Vec2 z = Vec2(0.0f, 0.0f).Normalized();
    EXPECT(z.x == 0.0f && z.y == 0.0f);
}

TEST(vec2_distance_and_arithmetic) {
    EXPECT_NEAR(5.0f, Distance(Vec2(0.0f, 0.0f), Vec2(3.0f, 4.0f)), 1e-5);
    const Vec2 v = Vec2(1.0f, 2.0f) + Vec2(3.0f, 4.0f) - Vec2(1.0f, 1.0f);
    EXPECT_NEAR(3.0f, v.x, 1e-6);
    EXPECT_NEAR(5.0f, v.y, 1e-6);
    EXPECT_NEAR(2.0f, Dot(Vec2(1.0f, 2.0f), Vec2(2.0f, 0.0f)), 1e-6);
}

// ---- Tuning ----

TEST(tuning_is_monotonic_and_capped) {
    for (int w = 1; w < 40; ++w) {
        EXPECT(tuning::DrifterSpeed(w + 1) >= tuning::DrifterSpeed(w));
        EXPECT(tuning::DrifterTurnRate(w + 1) >= tuning::DrifterTurnRate(w));
        EXPECT(tuning::MaxDrifters(w + 1) >= tuning::MaxDrifters(w));
        EXPECT(tuning::DrifterSpawnInterval(w + 1) <= tuning::DrifterSpawnInterval(w));
    }
    EXPECT_NEAR(520.0f, tuning::DrifterSpeed(999), 1e-4);
    EXPECT_NEAR(2.6f, tuning::DrifterTurnRate(999), 1e-4);
    EXPECT_EQ(12, tuning::MaxDrifters(999));
    EXPECT_NEAR(0.9f, tuning::DrifterSpawnInterval(999), 1e-4);
}

TEST(tuning_wave_one_values) {
    EXPECT_NEAR(220.0f, tuning::DrifterSpeed(1), 1e-4);
    EXPECT_NEAR(3.5f, tuning::DrifterSpawnInterval(1), 1e-4);
    EXPECT_EQ(3, tuning::MaxDrifters(1));
}

TEST(tuning_drifters_are_always_slower_than_the_player) {
    for (int w = 1; w < 200; ++w) EXPECT(tuning::DrifterSpeed(w) < tuning::kPlayerSpeed);
    EXPECT(tuning::kDashSpeed > tuning::kPlayerSpeed);
}

// ---- Dash ----

TEST(dash_starts_and_is_active) {
    Dash d;
    EXPECT(!d.IsActive());
    EXPECT(d.TryStart());
    EXPECT(d.IsActive());
}

TEST(dash_cannot_restart_while_active) {
    Dash d;
    d.TryStart();
    EXPECT(!d.TryStart());
}

TEST(dash_ends_after_its_duration_but_cooldown_continues) {
    Dash d;
    d.TryStart();
    d.Tick(tuning::kDashDuration - 0.01f);
    EXPECT(d.IsActive());
    d.Tick(0.02f);
    EXPECT(!d.IsActive());
    EXPECT(d.CooldownLeft() > 0.0f);
    EXPECT(!d.TryStart());
}

TEST(dash_cooldown_runs_from_the_start_of_the_dash) {
    Dash d;
    d.TryStart();
    d.Tick(tuning::kDashCooldown - 0.01f);
    EXPECT(!d.TryStart());
    d.Tick(0.02f);
    EXPECT(d.TryStart());
}

TEST(dash_timers_never_go_negative) {
    Dash d;
    d.TryStart();
    d.Tick(100.0f);
    EXPECT_NEAR(0.0f, d.CooldownLeft(), 1e-6);
    EXPECT(!d.IsActive());
}

TEST(dash_reset_clears_everything) {
    Dash d;
    d.TryStart();
    d.Reset();
    EXPECT(!d.IsActive());
    EXPECT_NEAR(0.0f, d.CooldownLeft(), 1e-6);
    EXPECT(d.TryStart());
}

// ---- RunState ----

TEST(state_starts_fresh) {
    RunState s;
    EXPECT_EQ(0, s.Score());
    EXPECT_EQ(tuning::kStartHealth, s.Health());
    EXPECT_EQ(1, s.Wave());
    EXPECT_NEAR(tuning::kStartTime, s.TimeLeft(), 1e-6);
    EXPECT(!s.IsOver() && !s.IsInvulnerable());
}

TEST(state_first_coin_scores_base_points_and_starts_combo) {
    RunState s;
    bool advanced = true;
    EXPECT_EQ(10, s.OnCoinCollected(&advanced));
    EXPECT_EQ(1, s.Combo());
    EXPECT(!advanced);
}

TEST(state_combo_multiplier_grows_then_caps) {
    RunState s;
    const int expected[] = {10, 20, 30, 40, 40, 40};
    for (int e : expected) EXPECT_EQ(e, s.OnCoinCollected(nullptr));
}

TEST(state_combo_expires_after_the_window) {
    RunState s;
    s.OnCoinCollected(nullptr);
    s.Tick(tuning::kComboWindow + 0.01f);
    EXPECT_EQ(0, s.Combo());
    EXPECT_EQ(10, s.OnCoinCollected(nullptr));
}

TEST(state_combo_survives_inside_the_window) {
    RunState s;
    s.OnCoinCollected(nullptr);
    s.Tick(tuning::kComboWindow - 0.1f);
    EXPECT_EQ(20, s.OnCoinCollected(nullptr));
}

TEST(state_collecting_refreshes_the_combo_timer) {
    RunState s;
    s.OnCoinCollected(nullptr);
    s.Tick(2.0f);
    s.OnCoinCollected(nullptr);
    s.Tick(2.0f);
    EXPECT_EQ(2, s.Combo());
}

TEST(state_coin_adds_time_up_to_the_cap) {
    RunState s;
    const float before = s.TimeLeft();
    s.OnCoinCollected(nullptr);
    EXPECT_NEAR(before + tuning::kCoinTimeBonus, s.TimeLeft(), 1e-5);
    for (int i = 0; i < 50; ++i) s.OnCoinCollected(nullptr);
    EXPECT(s.TimeLeft() <= tuning::kMaxTime + 1e-4f);
    EXPECT_NEAR(tuning::kMaxTime, s.TimeLeft(), 1e-4);
}

TEST(state_wave_advances_after_kCoinsPerWave_with_bonus) {
    RunState s;
    for (int i = 0; i < tuning::kCoinsPerWave - 1; ++i) EXPECT(!Collect(s));
    const int before = s.Score();
    bool advanced = false;
    const int points = s.OnCoinCollected(&advanced);
    EXPECT(advanced);
    EXPECT_EQ(2, s.Wave());
    EXPECT_EQ(0, s.CoinsThisWave());
    EXPECT_EQ(before + points + tuning::kWaveBonusPerWave * 2, s.Score());
}

TEST(state_drifter_hit_costs_health_and_resets_combo) {
    RunState s;
    s.OnCoinCollected(nullptr);
    EXPECT(s.OnDrifterHit(false));
    EXPECT_EQ(tuning::kStartHealth - 1, s.Health());
    EXPECT_EQ(0, s.Combo());
    EXPECT(s.IsInvulnerable());
}

TEST(state_no_second_hit_while_invulnerable) {
    RunState s;
    s.OnDrifterHit(false);
    EXPECT(!s.OnDrifterHit(false));
    EXPECT_EQ(tuning::kStartHealth - 1, s.Health());
}

TEST(state_invulnerability_ends_after_its_duration) {
    RunState s;
    s.OnDrifterHit(false);
    s.Tick(tuning::kInvulnerableSeconds - 0.1f);
    EXPECT(s.IsInvulnerable());
    s.Tick(0.2f);
    EXPECT(!s.IsInvulnerable());
    EXPECT(s.OnDrifterHit(false));
}

TEST(state_dashing_ignores_hits_without_side_effects) {
    RunState s;
    s.OnCoinCollected(nullptr);
    EXPECT(!s.OnDrifterHit(true));
    EXPECT_EQ(tuning::kStartHealth, s.Health());
    EXPECT_EQ(1, s.Combo());
    EXPECT(!s.IsInvulnerable());
}

TEST(state_defeated_at_zero_health) {
    RunState s;
    for (int i = 0; i < tuning::kStartHealth; ++i) {
        s.OnDrifterHit(false);
        s.Tick(tuning::kInvulnerableSeconds + 0.1f);
    }
    EXPECT(s.IsOver());
    EXPECT(s.Reason() == EndReason::Defeated);
    EXPECT_EQ(0, s.Health());
}

TEST(state_time_up_ends_the_run) {
    RunState s;
    s.Tick(tuning::kStartTime + 1.0f);
    EXPECT(s.IsOver());
    EXPECT(s.Reason() == EndReason::TimeUp);
    EXPECT_NEAR(0.0f, s.TimeLeft(), 1e-6);
}

TEST(state_is_inert_after_game_over) {
    RunState s;
    s.Tick(tuning::kStartTime + 1.0f);
    const int score = s.Score();
    bool advanced = true;
    EXPECT_EQ(0, s.OnCoinCollected(&advanced));
    EXPECT(!advanced);
    EXPECT_EQ(score, s.Score());
    EXPECT(!s.OnDrifterHit(false));
    EXPECT_EQ(tuning::kStartHealth, s.Health());
}

TEST(state_reset_restores_a_clean_state) {
    RunState s;
    Collect(s);
    s.OnDrifterHit(false);
    s.Tick(tuning::kStartTime + 1.0f);
    s.Reset();
    EXPECT_EQ(0, s.Score());
    EXPECT_EQ(tuning::kStartHealth, s.Health());
    EXPECT_EQ(0, s.Combo());
    EXPECT(!s.IsOver() && !s.IsInvulnerable());
    EXPECT_NEAR(tuning::kStartTime, s.TimeLeft(), 1e-6);
}

TEST(state_null_wave_pointer_is_allowed) {
    RunState s;
    for (int i = 0; i < tuning::kCoinsPerWave; ++i) s.OnCoinCollected(nullptr);
    EXPECT_EQ(2, s.Wave());
}

// ---- HighScore ----

TEST(highscore_parse_handles_junk) {
    EXPECT_EQ(0, highscore::Parse(""));
    EXPECT_EQ(0, highscore::Parse("abc"));
    EXPECT_EQ(0, highscore::Parse("-5"));
    EXPECT_EQ(0, highscore::Parse("12x"));
    EXPECT_EQ(0, highscore::Parse("99999999999999"));
    EXPECT_EQ(0, highscore::Parse("2147483648"));
    EXPECT_EQ(INT_MAX, highscore::Parse("2147483647"));
    EXPECT_EQ(1234, highscore::Parse("1234"));
}

TEST(highscore_format_round_trips) {
    EXPECT_EQ(777, highscore::Parse(highscore::Format(777)));
    EXPECT(highscore::Format(-3) == "0");
}

TEST(highscore_update_only_on_strictly_higher) {
    bool is_new = true;
    EXPECT_EQ(100, highscore::Update(100, 100, &is_new));
    EXPECT(!is_new);
    EXPECT_EQ(150, highscore::Update(100, 150, &is_new));
    EXPECT(is_new);
    EXPECT_EQ(100, highscore::Update(100, 40, &is_new));
    EXPECT(!is_new);
    EXPECT_EQ(150, highscore::Update(100, 150, nullptr));
}

// ---- Motion ----

TEST(motion_clamp_keeps_circle_inside_on_every_side) {
    const float half = 1500.0f, r = 40.0f;
    EXPECT_NEAR(half - r, ClampToArena(Vec2(9999.0f, 0.0f), half, r).x, 1e-3);
    EXPECT_NEAR(-(half - r), ClampToArena(Vec2(-9999.0f, 0.0f), half, r).x, 1e-3);
    EXPECT_NEAR(half - r, ClampToArena(Vec2(0.0f, 9999.0f), half, r).y, 1e-3);
    EXPECT_NEAR(-(half - r), ClampToArena(Vec2(0.0f, -9999.0f), half, r).y, 1e-3);
    const Vec2 inside = ClampToArena(Vec2(10.0f, -20.0f), half, r);
    EXPECT_NEAR(10.0f, inside.x, 1e-6);
    EXPECT_NEAR(-20.0f, inside.y, 1e-6);
}

TEST(motion_clamp_survives_an_arena_smaller_than_the_player) {
    const Vec2 p = ClampToArena(Vec2(30.0f, 30.0f), 20.0f, 50.0f);
    EXPECT_NEAR(0.0f, p.x, 1e-6);
    EXPECT_NEAR(0.0f, p.y, 1e-6);
}

TEST(motion_direction_normalises_input) {
    const Vec2 d = MoveDirection(Vec2(1.0f, 1.0f), Vec2(0.0f, 0.0f), false);
    EXPECT_NEAR(1.0f, d.Length(), 1e-5);
}

TEST(motion_no_input_and_no_dash_means_standing_still) {
    const Vec2 d = MoveDirection(Vec2(0.0f, 0.0f), Vec2(1.0f, 0.0f), false);
    EXPECT(d.x == 0.0f && d.y == 0.0f);
}

TEST(motion_dash_without_input_keeps_the_last_direction) {
    const Vec2 d = MoveDirection(Vec2(0.0f, 0.0f), Vec2(0.0f, -3.0f), true);
    EXPECT_NEAR(0.0f, d.x, 1e-6);
    EXPECT_NEAR(-1.0f, d.y, 1e-6);
}

TEST(motion_input_beats_last_direction_during_a_dash) {
    const Vec2 d = MoveDirection(Vec2(1.0f, 0.0f), Vec2(0.0f, -1.0f), true);
    EXPECT_NEAR(1.0f, d.x, 1e-6);
    EXPECT_NEAR(0.0f, d.y, 1e-6);
}

TEST(motion_step_moves_at_speed) {
    const Vec2 p = StepPlayer(Vec2(0.0f, 0.0f), Vec2(1.0f, 0.0f), 600.0f, 0.5f, 1500.0f, 40.0f);
    EXPECT_NEAR(300.0f, p.x, 1e-3);
    EXPECT_NEAR(0.0f, p.y, 1e-3);
}

TEST(motion_diagonal_is_not_faster_than_straight) {
    const Vec2 p = StepPlayer(Vec2(0.0f, 0.0f), Vec2(1.0f, 1.0f), 600.0f, 1.0f, 5000.0f, 40.0f);
    EXPECT_NEAR(600.0f, p.Length(), 1e-2);
}

TEST(motion_partial_direction_is_not_boosted) {
    const Vec2 p = StepPlayer(Vec2(0.0f, 0.0f), Vec2(0.5f, 0.0f), 600.0f, 1.0f, 5000.0f, 40.0f);
    EXPECT_NEAR(300.0f, p.x, 1e-3);
}

TEST(motion_step_stays_inside_the_arena) {
    const Vec2 p = StepPlayer(Vec2(1450.0f, 0.0f), Vec2(1.0f, 0.0f), 1600.0f, 1.0f, 1500.0f, 40.0f);
    EXPECT_NEAR(1460.0f, p.x, 1e-3);
}

TEST(motion_circles_overlap_at_exactly_touching_distance) {
    EXPECT(Overlaps(Vec2(0.0f, 0.0f), 50.0f, Vec2(100.0f, 0.0f), 50.0f));
}

TEST(motion_circles_apart_do_not_overlap) {
    EXPECT(!Overlaps(Vec2(0.0f, 0.0f), 50.0f, Vec2(100.5f, 0.0f), 50.0f));
}

TEST(motion_overlap_is_symmetric) {
    const Vec2 a(10.0f, 30.0f), b(60.0f, 10.0f);
    EXPECT(Overlaps(a, 30.0f, b, 20.0f) == Overlaps(b, 20.0f, a, 30.0f));
}

TEST(steer_turns_by_at_most_max_turn) {
    const Vec2 d = SteerToward(Vec2(1.0f, 0.0f), Vec2(0.0f, 1.0f), 0.1f);
    EXPECT_NEAR(std::atan2(d.y, d.x), 0.1f, 1e-4);
    EXPECT_NEAR(1.0f, d.Length(), 1e-5);
}

TEST(steer_reaches_the_target_when_the_turn_is_big_enough) {
    const Vec2 d = SteerToward(Vec2(1.0f, 0.0f), Vec2(0.0f, 1.0f), 3.0f);
    EXPECT_NEAR(0.0f, d.x, 1e-4);
    EXPECT_NEAR(1.0f, d.y, 1e-4);
}

TEST(steer_takes_the_shorter_way_round) {
    const Vec2 d = SteerToward(Vec2(1.0f, 0.0f), Vec2(0.0f, -1.0f), 0.1f);
    EXPECT(d.y < 0.0f);
    EXPECT_NEAR(std::atan2(d.y, d.x), -0.1f, 1e-4);
}

TEST(steer_opposite_direction_still_turns_without_nan) {
    const Vec2 d = SteerToward(Vec2(1.0f, 0.0f), Vec2(-1.0f, 0.0f), 0.2f);
    EXPECT(std::isfinite(d.x) && std::isfinite(d.y));
    EXPECT_NEAR(1.0f, d.Length(), 1e-4);
    EXPECT(std::fabs(std::atan2(d.y, d.x)) > 0.15f);
}

TEST(steer_zero_heading_snaps_to_target_and_zero_target_keeps_heading) {
    const Vec2 snapped = SteerToward(Vec2(0.0f, 0.0f), Vec2(0.0f, 5.0f), 0.1f);
    EXPECT_NEAR(1.0f, snapped.y, 1e-5);
    const Vec2 kept = SteerToward(Vec2(0.0f, 1.0f), Vec2(0.0f, 0.0f), 0.1f);
    EXPECT_NEAR(1.0f, kept.y, 1e-5);
}

// ---- Spawner ----

TEST(spawner_coin_spawns_immediately_when_none_are_active) {
    Spawner sp(1);
    EXPECT(sp.ShouldSpawnCoin(0.0f, 0));
}

TEST(spawner_coin_spawn_is_capped) {
    Spawner sp(1);
    for (int i = 0; i < 100; ++i) EXPECT(!sp.ShouldSpawnCoin(10.0f, tuning::kMaxCoins));
}

TEST(spawner_coin_waits_for_its_timer) {
    Spawner sp(1);
    sp.ShouldSpawnCoin(0.0f, 0);  // arms the timer at 1.5..3.0 s
    EXPECT(!sp.ShouldSpawnCoin(0.1f, 1));
    EXPECT(sp.ShouldSpawnCoin(5.0f, 1));
}

TEST(spawner_drifter_has_a_grace_period_then_spawns_on_interval) {
    Spawner sp(1);
    EXPECT(!sp.ShouldSpawnDrifter(1.9f, 1, 0));
    EXPECT(sp.ShouldSpawnDrifter(0.2f, 1, 0));
    EXPECT(!sp.ShouldSpawnDrifter(0.1f, 1, 1));
}

TEST(spawner_drifter_cap_blocks_spawns_and_frees_up_immediately) {
    Spawner sp(1);
    const int cap = tuning::MaxDrifters(1);
    EXPECT(!sp.ShouldSpawnDrifter(10.0f, 1, cap));
    EXPECT(sp.ShouldSpawnDrifter(0.01f, 1, cap - 1));
}

TEST(spawner_coin_positions_stay_inside_and_away_from_the_player) {
    Spawner sp(3);
    const Vec2 player(100.0f, 100.0f);
    const float limit = tuning::kArenaHalfExtent - tuning::kCoinMargin;
    for (int i = 0; i < 500; ++i) {
        const Vec2 p = sp.NextCoinPosition(player, tuning::kArenaHalfExtent, tuning::kMinCoinDistance);
        EXPECT(std::fabs(p.x) <= limit + 1e-3f);
        EXPECT(std::fabs(p.y) <= limit + 1e-3f);
        EXPECT(Distance(p, player) >= tuning::kMinCoinDistance - 1e-3f);
    }
}

TEST(spawner_coin_falls_back_to_a_far_corner_in_a_tiny_arena) {
    Spawner sp(3);
    const Vec2 p = sp.NextCoinPosition(Vec2(50.0f, 50.0f), 200.0f, 5000.0f);
    EXPECT(p.x < 0.0f && p.y < 0.0f);
}

TEST(spawner_drifters_start_on_an_edge_far_from_the_player_heading_at_them) {
    Spawner sp(4);
    const Vec2 player(0.0f, 0.0f);
    for (int i = 0; i < 500; ++i) {
        const DrifterSpawn d = sp.NextDrifter(player, tuning::kArenaHalfExtent, 1);
        const float limit = tuning::kArenaHalfExtent - d.radius - 10.0f;
        const bool on_edge = std::fabs(std::fabs(d.position.x) - limit) < 1e-2f ||
                             std::fabs(std::fabs(d.position.y) - limit) < 1e-2f;
        EXPECT(on_edge);
        EXPECT(std::fabs(d.position.x) <= limit + 1e-2f && std::fabs(d.position.y) <= limit + 1e-2f);
        EXPECT(Distance(d.position, player) >= tuning::kMinDrifterSpawnDistance - 1e-2f);
        EXPECT(Dot(d.direction, (player - d.position).Normalized()) > 0.999f);
        EXPECT_NEAR(1.0f, d.direction.Length(), 1e-4);
    }
}

TEST(spawner_drifter_radius_is_in_range) {
    Spawner sp(6);
    for (int i = 0; i < 500; ++i) {
        const float r = sp.NextDrifter(Vec2(0.0f, 0.0f), tuning::kArenaHalfExtent, 1).radius;
        EXPECT(r >= tuning::kDrifterMinRadius && r < tuning::kDrifterMaxRadius);
    }
}

TEST(spawner_drifter_fallback_in_a_tiny_arena_is_finite_and_far) {
    Spawner sp(7);
    const DrifterSpawn d = sp.NextDrifter(Vec2(10.0f, 10.0f), 300.0f, 1);
    EXPECT(std::isfinite(d.position.x) && std::isfinite(d.position.y));
    EXPECT(d.position.x < 0.0f && d.position.y < 0.0f);
}

TEST(spawner_same_seed_gives_the_same_spawns) {
    Spawner a(11), b(11);
    for (int i = 0; i < 50; ++i) {
        const DrifterSpawn da = a.NextDrifter(Vec2(0.0f, 0.0f), 1500.0f, 3);
        const DrifterSpawn db = b.NextDrifter(Vec2(0.0f, 0.0f), 1500.0f, 3);
        EXPECT(da.position.x == db.position.x && da.position.y == db.position.y);
    }
}

// ---- Whole-run simulation, mirroring what the Unreal layer does each tick ----

namespace {

struct SimDrifter {
    Vec2 pos;
    Vec2 dir;
    float radius;
};

struct Sim {
    RunState state;
    Dash dash;
    Spawner spawner;
    Vec2 player;
    std::vector<Vec2> coins;
    std::vector<SimDrifter> drifters;
    float elapsed = 0.0f;
    int coins_collected = 0;
    float max_drifter_excursion = 0.0f;

    explicit Sim(int seed) : spawner(seed) {}

    // One frame. move_dir is what the "player" wants; want_dash requests a dash.
    void Step(float dt, Vec2 move_dir, bool want_dash) {
        if (state.IsOver()) return;
        dash.Tick(dt);
        if (want_dash) dash.TryStart();
        const Vec2 dir = MoveDirection(move_dir, Vec2(1.0f, 0.0f), dash.IsActive());
        const float speed = dash.IsActive() ? tuning::kDashSpeed : tuning::kPlayerSpeed;
        player = StepPlayer(player, dir, speed, dt, tuning::kArenaHalfExtent, tuning::kPlayerRadius);
        state.Tick(dt);

        if (spawner.ShouldSpawnCoin(dt, static_cast<int>(coins.size()))) {
            coins.push_back(spawner.NextCoinPosition(player, tuning::kArenaHalfExtent, tuning::kMinCoinDistance));
        }
        if (spawner.ShouldSpawnDrifter(dt, state.Wave(), static_cast<int>(drifters.size()))) {
            const DrifterSpawn s = spawner.NextDrifter(player, tuning::kArenaHalfExtent, state.Wave());
            drifters.push_back({s.position, s.direction, s.radius});
        }

        for (size_t i = coins.size(); i-- > 0;) {
            if (Overlaps(player, tuning::kPlayerRadius, coins[i], tuning::kCoinRadius)) {
                state.OnCoinCollected(nullptr);
                ++coins_collected;
                coins.erase(coins.begin() + static_cast<std::ptrdiff_t>(i));
            }
        }
        for (SimDrifter& d : drifters) {
            const Vec2 to_player = (player - d.pos).Normalized();
            d.dir = SteerToward(d.dir, to_player, tuning::DrifterTurnRate(state.Wave()) * dt);
            d.pos = ClampToArena(d.pos + d.dir * (tuning::DrifterSpeed(state.Wave()) * dt),
                                 tuning::kArenaHalfExtent, d.radius);
            const float excursion = std::max(std::fabs(d.pos.x), std::fabs(d.pos.y)) + d.radius;
            if (excursion > max_drifter_excursion) max_drifter_excursion = excursion;
            if (Overlaps(player, tuning::kPlayerRadius, d.pos, d.radius)) state.OnDrifterHit(dash.IsActive());
        }
        elapsed += dt;
    }

    Vec2 NearestCoinDirection() const {
        if (coins.empty()) return Vec2(0.0f, 0.0f);
        size_t best = 0;
        for (size_t i = 1; i < coins.size(); ++i) {
            if (Distance(coins[i], player) < Distance(coins[best], player)) best = i;
        }
        return (coins[best] - player).Normalized();
    }
};

}  // namespace

TEST(sim_a_player_who_never_moves_is_defeated_quickly) {
    Sim sim(99);
    const float dt = 1.0f / 60.0f;
    while (!sim.state.IsOver() && sim.elapsed < 120.0f) sim.Step(dt, Vec2(0.0f, 0.0f), false);
    EXPECT(sim.state.IsOver());
    EXPECT(sim.state.Reason() == EndReason::Defeated);
    EXPECT(sim.elapsed < 30.0f);
    EXPECT_EQ(0, sim.coins_collected);
}

TEST(sim_a_coin_chaser_scores_and_wins_time) {
    Sim sim(5);
    const float dt = 1.0f / 60.0f;
    while (!sim.state.IsOver() && sim.elapsed < 60.0f) sim.Step(dt, sim.NearestCoinDirection(), false);
    EXPECT(sim.coins_collected >= 5);
    EXPECT(sim.state.Score() > 0);
}

TEST(sim_drifters_never_leave_the_arena) {
    Sim sim(21);
    const float dt = 1.0f / 60.0f;
    while (!sim.state.IsOver() && sim.elapsed < 60.0f) sim.Step(dt, Vec2(0.0f, 0.0f), false);
    EXPECT(sim.max_drifter_excursion <= tuning::kArenaHalfExtent + 1e-2f);
}

TEST(sim_is_deterministic_for_a_seed) {
    int scores[2] = {0, 0};
    int coins[2] = {0, 0};
    for (int run = 0; run < 2; ++run) {
        Sim sim(1234);
        const float dt = 1.0f / 60.0f;
        while (!sim.state.IsOver() && sim.elapsed < 60.0f) sim.Step(dt, sim.NearestCoinDirection(), false);
        scores[run] = sim.state.Score();
        coins[run] = sim.coins_collected;
    }
    EXPECT_EQ(scores[0], scores[1]);
    EXPECT_EQ(coins[0], coins[1]);
}

TEST(sim_dashing_through_a_drifter_costs_no_health) {
    Sim sim(1);
    sim.drifters.push_back({Vec2(100.0f, 0.0f), Vec2(-1.0f, 0.0f), 45.0f});
    sim.Step(1.0f / 60.0f, Vec2(1.0f, 0.0f), true);
    EXPECT_EQ(tuning::kStartHealth, sim.state.Health());
}

TEST(sim_touching_a_drifter_without_dashing_costs_health) {
    Sim sim(1);
    sim.drifters.push_back({Vec2(60.0f, 0.0f), Vec2(-1.0f, 0.0f), 45.0f});
    sim.Step(1.0f / 60.0f, Vec2(0.0f, 0.0f), false);
    EXPECT_EQ(tuning::kStartHealth - 1, sim.state.Health());
}

// ---- Runner ----

int main() {
    int passed = 0;
    int failed = 0;
    for (const TestCase& test : Registry()) {
        g_failures_in_test = 0;
        test.fn();
        if (g_failures_in_test == 0) {
            ++passed;
        } else {
            ++failed;
            std::printf("FAIL %s\n", test.name);
        }
    }
    std::printf("%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
