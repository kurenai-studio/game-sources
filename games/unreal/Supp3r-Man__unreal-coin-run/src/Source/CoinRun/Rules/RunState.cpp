#include "Rules/RunState.h"

#include <algorithm>

#include "Rules/Tuning.h"

namespace coinrun {

RunState::RunState() { Reset(); }

void RunState::Reset() {
    score_ = 0;
    health_ = tuning::kStartHealth;
    wave_ = 1;
    combo_ = 0;
    coins_this_wave_ = 0;
    time_left_ = tuning::kStartTime;
    combo_timer_ = 0.0f;
    invulnerable_left_ = 0.0f;
    reason_ = EndReason::None;
}

int RunState::Multiplier() const {
    return std::max(1, std::min(combo_, tuning::kMaxMultiplier));
}

int RunState::OnCoinCollected(bool* wave_advanced) {
    if (wave_advanced != nullptr) *wave_advanced = false;
    if (IsOver()) return 0;

    // A new chain starts if the previous one timed out.
    if (combo_timer_ <= 0.0f) combo_ = 0;
    ++combo_;
    combo_timer_ = tuning::kComboWindow;

    const int points = tuning::kCoinPoints * Multiplier();
    score_ += points;
    time_left_ = std::min(tuning::kMaxTime, time_left_ + tuning::kCoinTimeBonus);
    ++coins_this_wave_;

    if (coins_this_wave_ >= tuning::kCoinsPerWave) {
        coins_this_wave_ = 0;
        ++wave_;
        score_ += tuning::kWaveBonusPerWave * wave_;
        if (wave_advanced != nullptr) *wave_advanced = true;
    }
    return points;
}

bool RunState::OnDrifterHit(bool dashing) {
    if (IsOver() || dashing || IsInvulnerable()) return false;
    --health_;
    combo_ = 0;
    combo_timer_ = 0.0f;
    invulnerable_left_ = tuning::kInvulnerableSeconds;
    if (health_ <= 0) {
        health_ = 0;
        reason_ = EndReason::Defeated;
    }
    return true;
}

void RunState::Tick(float dt) {
    if (IsOver()) return;

    time_left_ -= dt;
    if (time_left_ <= 0.0f) {
        time_left_ = 0.0f;
        reason_ = EndReason::TimeUp;
        return;
    }
    if (combo_timer_ > 0.0f) {
        combo_timer_ -= dt;
        if (combo_timer_ <= 0.0f) {
            combo_timer_ = 0.0f;
            combo_ = 0;
        }
    }
    if (invulnerable_left_ > 0.0f) {
        invulnerable_left_ -= dt;
        if (invulnerable_left_ < 0.0f) invulnerable_left_ = 0.0f;
    }
}

}  // namespace coinrun
