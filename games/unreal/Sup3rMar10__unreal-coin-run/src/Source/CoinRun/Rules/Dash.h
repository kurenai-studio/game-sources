#pragma once

namespace coinrun {

// Short speed burst with a cooldown. The cooldown starts when the dash starts, not when it ends.
class Dash {
public:
    void Reset();

    // True if a dash started; false while one is active or the cooldown is running.
    bool TryStart();

    void Tick(float dt);

    bool IsActive() const { return active_left_ > 0.0f; }
    float CooldownLeft() const { return cooldown_left_; }

private:
    float active_left_ = 0.0f;
    float cooldown_left_ = 0.0f;
};

}  // namespace coinrun
