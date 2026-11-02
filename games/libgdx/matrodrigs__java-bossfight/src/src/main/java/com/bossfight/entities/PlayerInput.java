package com.bossfight.entities;

public record PlayerInput(
        boolean moveLeft,
        boolean moveRight,
        boolean jumpPressed,
        boolean dashPressed
) {
    public static final PlayerInput NONE = new PlayerInput(false, false, false, false);
}
