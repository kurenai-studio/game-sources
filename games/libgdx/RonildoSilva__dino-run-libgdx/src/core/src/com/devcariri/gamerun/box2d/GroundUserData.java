package com.devcariri.gamerun.box2d;

import com.devcariri.gamerun.enums.UserDataType;

/**
 * Created by ronildo on 05/01/17.
 */

public class GroundUserData extends UserData {

    public GroundUserData(float width, float height) {
        super(width, height);
        userDataType = UserDataType.GROUND;
    }

}
