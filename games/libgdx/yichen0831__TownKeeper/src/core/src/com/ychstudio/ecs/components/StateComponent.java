package com.ychstudio.ecs.components;

import com.badlogic.ashley.core.Component;

public class StateComponent implements Component {

    private float stateTime;
    private int currentState;

    public StateComponent(int currentState) {
        this.currentState = currentState;
        stateTime = 0;
    }

    public void setState(int currentState) {
        if (this.currentState != currentState) {
            resetStateTime();
            this.currentState = currentState;
        }
    }

    public int getState() {
        return currentState;
    }

    public float getStateTime() {
        return stateTime;
    }

    public void addStateTime(float delta) {
        stateTime += delta;
    }

    public void resetStateTime() {
        stateTime = 0;
    }
}
