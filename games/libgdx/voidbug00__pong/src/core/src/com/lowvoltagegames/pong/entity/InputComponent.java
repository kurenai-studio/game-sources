package com.lowvoltagegames.pong.entity;

/**
 * Component representing objects behaviour to input each tick
 */
public interface InputComponent {
    /**
     * Poll input and update object each tick
     * @param obj object to be updated
     */
    void update(GameObject obj);
}
