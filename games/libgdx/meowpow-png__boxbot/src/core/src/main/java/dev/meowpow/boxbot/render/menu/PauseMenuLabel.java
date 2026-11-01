package dev.meowpow.boxbot.render.menu;

/**
 * Labels displayed by the in-game pause menu.
 */
public enum PauseMenuLabel implements MenuLabel {
    RESUME("RESUME"),
    SETTINGS("SETTINGS"),
    MAIN_MENU("MAIN MENU"),
    EXIT("EXIT");

    private final String text;

    PauseMenuLabel(String text) {
        this.text = text;
    }

    @Override
    public String text() {
        return text;
    }
}
