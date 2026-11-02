#pragma once

namespace coinrun {

enum class EndReason { None, TimeUp, Defeated };

// Score, health, time, combo and wave for one run. No engine types; driven by the Unreal layer.
class RunState {
public:
    RunState();

    void Reset();

    int Score() const { return score_; }
    int Health() const { return health_; }
    int Wave() const { return wave_; }
    int Combo() const { return combo_; }
    int CoinsThisWave() const { return coins_this_wave_; }
    float TimeLeft() const { return time_left_; }
    float InvulnerableLeft() const { return invulnerable_left_; }
    bool IsOver() const { return reason_ != EndReason::None; }
    EndReason Reason() const { return reason_; }
    bool IsInvulnerable() const { return invulnerable_left_ > 0.0f; }

    // Score multiplier from the current combo, 1..kMaxMultiplier.
    int Multiplier() const;

    // Collect a coin. Returns the points awarded; wave_advanced (may be null) is set when this coin finished a wave.
    int OnCoinCollected(bool* wave_advanced);

    // A drifter touched the player. Returns true if it cost health (false while dashing, invulnerable or over).
    bool OnDrifterHit(bool dashing);

    void Tick(float dt);

private:
    int score_ = 0;
    int health_ = 0;
    int wave_ = 1;
    int combo_ = 0;
    int coins_this_wave_ = 0;
    float time_left_ = 0.0f;
    float combo_timer_ = 0.0f;
    float invulnerable_left_ = 0.0f;
    EndReason reason_ = EndReason::None;
};

}  // namespace coinrun
