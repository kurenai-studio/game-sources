package dev.meowpow.boxbot.render.menu;

/**
 * Labels displayed by the main menu.
 */
public enum MainMenuLabel implements MenuLabel {
    NEW_GAME("NEW GAME"),
    CONTINUE("CONTINUE"),
    SETTINGS("SETTINGS"),
    EXIT("EXIT");

    private final String text;

    MainMenuLabel(String text) {
        this.text = text;
    }

    @Override
    public String text() {
        return text;
    }
}
