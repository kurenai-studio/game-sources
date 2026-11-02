package com.lowvoltagegames.pong.ai;

import com.lowvoltagegames.pong.entity.GameObject;

/**
 * AiObserver attaches to an object to provide information to a controller
 */
public class AiObserver {
    private GameObject object;

    /**
     * Attach to an object
     * @param object object to be observed
     */
    public void attach(GameObject object) {
        this.object = object;
    }

    /**
     * Returns the object being observed
     * @return object being observed
     */
    public GameObject getObject() {
        return object;
    }
}
