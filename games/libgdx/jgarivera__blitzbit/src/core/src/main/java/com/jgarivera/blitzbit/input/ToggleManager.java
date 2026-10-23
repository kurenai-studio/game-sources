package com.jgarivera.blitzbit.input;

import java.util.HashMap;

public class ToggleManager {
    public static final String DEBUG_MODE = "debug";

    public ToggleManager() {
        toggles = new HashMap<>();
        registerToggles();
    }

    protected void registerToggles() {
        setToggle(DEBUG_MODE, false);
    }

    private final HashMap<String, Boolean> toggles;

    public void setToggle(String name, boolean value) {
        toggles.put(name, value);
    }

    public boolean getToggle(String name) {
        return toggles.get(name);
    }
}
