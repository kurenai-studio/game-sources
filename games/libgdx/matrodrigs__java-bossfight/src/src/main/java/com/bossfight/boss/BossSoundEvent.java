package com.bossfight.boss;

public enum BossSoundEvent {
    VINE_CHARGE(false),
    VINE_STRIKE(true),
    MAGIC_CHARGE(false),
    MAGIC_VOLLEY(true),
    POLLEN_CHARGE(false),
    POLLEN_DROP(true),
    STAGGER(true),
    CHAIN_WARNING(false),
    FINAL_RAGE(true),
    PHASE_ROAR(true),
    PHASE_SHOCKWAVE(true);

    private final boolean triggersActionImpulse;

    BossSoundEvent(boolean triggersActionImpulse) {
        this.triggersActionImpulse = triggersActionImpulse;
    }

    boolean triggersActionImpulse() {
        return triggersActionImpulse;
    }
}
