package com.jgarivera.blitzbit.input;

import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.jgarivera.blitzbit.input.action.ActionListener;
import com.jgarivera.blitzbit.input.action.ActionType;

import java.util.ArrayList;
import java.util.HashMap;

public class ActionManager extends InputAdapter {

    private final ArrayList<ActionListener> actionListeners;

    private final HashMap<Integer, ActionType> keyboardActionTypes;
    private final HashMap<Integer, ActionType> mouseActionTypes;
    private final ArrayList<ActionType> scrollInActionTypes;
    private final ArrayList<ActionType> scrollOutActionTypes;

    public ActionManager() {
        actionListeners = new ArrayList<>();
        keyboardActionTypes = new HashMap<>();
        mouseActionTypes = new HashMap<>();
        scrollInActionTypes = new ArrayList<>();
        scrollOutActionTypes = new ArrayList<>();

        registerActions();
    }

    private void registerActions() {
        registerKeyboardActions();
        registerMouseActions();
    }

    private void registerKeyboardActions() {
        keyboardActionTypes.put(Input.Keys.W, ActionTypes.MOVE_UP);
        keyboardActionTypes.put(Input.Keys.S, ActionTypes.MOVE_DOWN);
        keyboardActionTypes.put(Input.Keys.A, ActionTypes.MOVE_LEFT);
        keyboardActionTypes.put(Input.Keys.D, ActionTypes.MOVE_RIGHT);
        keyboardActionTypes.put(Input.Keys.O, ActionTypes.TOGGLE_DEBUG_MODE);
        keyboardActionTypes.put(Input.Keys.P, ActionTypes.SPAWN_MINION);
    }

    private void registerMouseActions() {
        mouseActionTypes.put(Input.Buttons.MIDDLE, ActionTypes.ZOOM_RESET);
        scrollInActionTypes.add(ActionTypes.ZOOM_IN);
        scrollOutActionTypes.add(ActionTypes.ZOOM_OUT);
    }

    /**
     * Recently subscribed listener gets top priority.
     *
     * @param listener - action listener
     */
    public void subscribe(ActionListener listener) {
        actionListeners.add(0, listener);
    }

    public void unsubscribe(ActionListener listener) {
        actionListeners.remove(listener);
    }

    @Override
    public boolean keyDown(int keycode) {
        if (keyboardActionTypes.containsKey(keycode)) {
            return notifyListenersToEnter(keyboardActionTypes.get(keycode));
        } else {
            return false;
        }
    }

    @Override
    public boolean keyUp(int keycode) {
        if (keyboardActionTypes.containsKey(keycode)) {
            return notifyListenersToExit(keyboardActionTypes.get(keycode));
        } else {
            return false;
        }
    }

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        if (mouseActionTypes.containsKey(button)) {
            return notifyListenersToEnter(mouseActionTypes.get(button));
        } else {
            return false;
        }
    }

    @Override
    public boolean touchUp(int screenX, int screenY, int pointer, int button) {
        if (mouseActionTypes.containsKey(button)) {
            return notifyListenersToExit(mouseActionTypes.get(button));
        } else {
            return false;
        }
    }

    @Override
    public boolean scrolled(float amountX, float amountY) {
        if (amountY < 0) {
            for (ActionType actionType : scrollInActionTypes) {
                notifyListenersToEnter(actionType);
            }
        } else {
            for (ActionType actionType : scrollOutActionTypes) {
                notifyListenersToEnter(actionType);
            }
        }

        return true;
    }

    private boolean notifyListenersToEnter(ActionType actionType) {
        boolean isProcessed = false;

        for (ActionListener listener : actionListeners) {
            if (!isProcessed && listener.onActionEntered(actionType)) {
                isProcessed = true;
            }
        }

        return isProcessed;
    }

    private boolean notifyListenersToExit(ActionType actionType) {
        boolean isProcessed = false;

        for (ActionListener listener : actionListeners) {
            if (!isProcessed && listener.onActionExited(actionType)) {
                isProcessed = true;
            }
        }

        return isProcessed;
    }
}
