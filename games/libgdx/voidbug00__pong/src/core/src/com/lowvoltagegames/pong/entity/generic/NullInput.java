package com.lowvoltagegames.pong.entity.generic;

import com.lowvoltagegames.pong.entity.GameObject;
import com.lowvoltagegames.pong.entity.InputComponent;

/**
 * InputComponent that does not handle input
 */
public class NullInput implements InputComponent {
    /**
     * Do not handle input
     * @param obj object to be updated
     */
    @Override
    public void update(GameObject obj) {

    }
}
