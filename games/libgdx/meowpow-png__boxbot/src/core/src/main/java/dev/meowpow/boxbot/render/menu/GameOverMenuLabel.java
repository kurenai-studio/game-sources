package dev.meowpow.boxbot.render.menu;

/**
 * Labels displayed by the game-over menu.
 */
public enum GameOverMenuLabel implements MenuLabel {
    TRY_AGAIN("TRY AGAIN"),
    MAIN_MENU("MAIN MENU");

    private final String text;

    GameOverMenuLabel(String text) {
        this.text = text;
    }

    @Override
    public String text() {
        return text;
    }
}
