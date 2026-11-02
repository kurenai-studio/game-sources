package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;

public class LifeComponent implements Component {

    private int maxHp;
    private int hp;

    private float recoveryWaitTime; // the time to start recover after being
                                    // damaged
    private float timeToRecovery; // the count down to start recover

    private float recoveryInterval = 1f; // the interval between every
                                         // recoveryHp
    private float recoveryCountDown; // count down for next recoveryHp

    public LifeComponent(int maxHp) {
        this(maxHp, 10f);
    }

    public LifeComponent(int maxHp, float recoveryWaitTime) {
        this.maxHp = maxHp;
        this.recoveryWaitTime = recoveryWaitTime;
        hp = maxHp;
        timeToRecovery = 0;
        recoveryCountDown = 0;
    }

    public boolean isDead() {
        return hp <= 0;
    }

    public boolean isFullHp() {
        return hp >= maxHp;
    }

    public void takeDamage(int damage) {
        hp -= damage;
        resetTimeToRecovery();
        resetRecoveryCountDown();
    }

    public void recoverHp(int recovery) {
        hp += recovery;
    }

    public boolean canStartRecover() {
        return timeToRecovery <= 0;
    }

    public void resetTimeToRecovery() {
        timeToRecovery = recoveryWaitTime;
    }

    public boolean canDoRecovery() {
        return recoveryCountDown <= 0 && !isFullHp();
    }

    public void resetRecoveryCountDown() {
        recoveryCountDown = recoveryInterval;
    }

    public void update(float delta) {
        timeToRecovery -= delta;
        recoveryCountDown -= delta;
    }

}
