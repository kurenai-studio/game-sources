package com.jgarivera.blitzbit.input.action;

public interface ActionListener {

    boolean onActionEntered(ActionType action);

    boolean onActionExited(ActionType action);
}
