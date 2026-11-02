#include "Rules/Dash.h"

#include "Rules/Tuning.h"

namespace coinrun {

void Dash::Reset() {
    active_left_ = 0.0f;
    cooldown_left_ = 0.0f;
}

bool Dash::TryStart() {
    if (IsActive() || cooldown_left_ > 0.0f) return false;
    active_left_ = tuning::kDashDuration;
    cooldown_left_ = tuning::kDashCooldown;
    return true;
}

void Dash::Tick(float dt) {
    if (active_left_ > 0.0f) {
        active_left_ -= dt;
        if (active_left_ < 0.0f) active_left_ = 0.0f;
    }
    if (cooldown_left_ > 0.0f) {
        cooldown_left_ -= dt;
        if (cooldown_left_ < 0.0f) cooldown_left_ = 0.0f;
    }
}

}  // namespace coinrun
