package com.jgarivera.blitzbit.input;

import com.jgarivera.blitzbit.input.action.Action;
import com.jgarivera.blitzbit.input.action.ActionType;
import com.jgarivera.blitzbit.input.actions.CameraZoomIn;
import com.jgarivera.blitzbit.input.actions.CameraZoomOut;
import com.jgarivera.blitzbit.input.actions.CameraZoomReset;
import com.jgarivera.blitzbit.input.actions.MoveDown;
import com.jgarivera.blitzbit.input.actions.MoveLeft;
import com.jgarivera.blitzbit.input.actions.MoveRight;
import com.jgarivera.blitzbit.input.actions.MoveUp;
import com.jgarivera.blitzbit.input.actions.SpawnMinion;
import com.jgarivera.blitzbit.input.actions.ToggleDebugMode;

public enum ActionTypes implements ActionType {
    MOVE_UP(new MoveUp()),
    MOVE_DOWN(new MoveDown()),
    MOVE_LEFT(new MoveLeft()),
    MOVE_RIGHT(new MoveRight()),
    SPAWN_MINION(new SpawnMinion()),
    STOP_FOLLOW_CAMERA(null),
    TOGGLE_DEBUG_MODE(new ToggleDebugMode()),
    ZOOM_IN(new CameraZoomIn()),
    ZOOM_OUT(new CameraZoomOut()),
    ZOOM_RESET(new CameraZoomReset());

    private final Action action;

    ActionTypes(Action action) {
        this.action = action;
    }

    @Override
    public Action getAction() {
        return action;
    }
}
