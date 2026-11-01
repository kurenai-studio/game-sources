package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;

/**
 * Game Over Scene: shown when fuel reaches zero before the cargo is delivered. Reports the failure
 * message, explains that fuel was depleted, lists the mission results, and offers Retry (restart) and
 * Main Menu, grouped in one result panel.
 */
public final class GameOverScreen extends BaseScreen {

    private static final float PX = 230f;
    private static final float PY = 95f;
    private static final float PW = 820f;
    private static final float PH = 550f;

    private static final float ROW_X = 258f;
    private static final float ROW_W = 372f;
    private static final float ROW_H = 50f;
    private static final float[] ROW_Y = {402f, 344f, 286f, 228f};

    private static final Color WARN_FILL = new Color(0.22f, 0.05f, 0.05f, 0.9f);

    private final MissionResult result;
    private final String[] labels;
    private final String[] values;
    private final Color[] valueColors;

    private final Button retry;
    private final Button mainMenu;

    public GameOverScreen(MoonCourierGame game, MissionResult result) {
        super(game);
        this.result = result;
        labels = new String[]{"FUEL REMAINING", "CARGO STATUS", "SCORE", "TIME TAKEN"};
        values = new String[]{
            result.fuelPercent + "%",
            "NOT DELIVERED",
            Integer.toString(result.score),
            MissionResult.formatTime(result.timeSeconds)
        };
        valueColors = new Color[]{Palette.RED, Palette.RED, Palette.YELLOW, Palette.PURPLE};

        retry = new Button(270f, 150f, 300f, 60f, "RETRY MISSION",
            Palette.RED, Palette.WHITE, Palette.WHITE);
        mainMenu = new Button(610f, 150f, 300f, 60f, "MAIN MENU",
            Palette.BLUE, Palette.WHITE, Palette.WHITE);
    }

    @Override
    public void render(float delta) {
        clear(Palette.SPACE);
        Vector2 m = mouse();
        retry.hovered = retry.contains(m.x, m.y);
        mainMenu.hovered = mainMenu.contains(m.x, m.y);

        // ---- shape pass ----
        shape.begin(ShapeType.Filled);
        Draw.spaceBackground(shape, a);
        Draw.panel(shape, PX, PY, PW, PH, Palette.PANEL_FILL, Palette.RED);
        // Warning banner.
        Draw.panel(shape, 340f, 462f, 600f, 60f, WARN_FILL, Palette.RED);
        for (float ry : ROW_Y) {
            Draw.panel(shape, ROW_X, ry, ROW_W, ROW_H, Palette.PANEL_FILL_SOLID, Palette.PANEL_BORDER);
        }
        // Decorative downed ship on the surface (right side).
        Draw.ship(shape, 830f, 300f, false);
        Draw.crate(shape, 910f, 262f);
        retry.drawFace(shape);
        mainMenu.drawFace(shape);
        shape.end();

        // ---- text pass ----
        GlyphLayout l = layout;
        batch.begin();
        Draw.textCentered(batch, a.fontTitle, l, "MISSION FAILED", 640f, 615f, Palette.RED);
        Draw.textCentered(batch, a.fontHeading, l, "YOU RAN OUT OF FUEL", 640f, 552f, Palette.LIGHT_GREY);
        Draw.textWrapped(batch, a.fontSmall, l,
            "Your fuel level reached zero before the cargo could be delivered.",
            640f, 506f, 560f, Palette.WHITE);
        for (int i = 0; i < labels.length; i++) {
            float ty = ROW_Y[i] + 34f;
            Draw.textLeft(batch, a.fontLabel, labels[i], ROW_X + 18f, ty, Palette.LIGHT_GREY);
            Draw.textRight(batch, a.fontLabel, l, values[i], ROW_X + ROW_W - 18f, ty, valueColors[i]);
        }
        retry.drawLabel(batch, a.fontHeading, l);
        mainMenu.drawLabel(batch, a.fontHeading, l);
        Draw.textCentered(batch, a.fontSmall, l, "Enter: Retry      M / Esc: Main Menu",
            640f, 126f, Palette.LIGHT_GREY);
        Draw.textCentered(batch, a.fontSmall, l,
            "TIP: AVOID OBSTACLES TO CONSERVE FUEL AND REACH THE DELIVERY PAD.",
            640f, 74f, Palette.DIM_GREY);
        batch.end();

        handleInput(m);
    }

    private void handleInput(Vector2 m) {
        boolean click = Gdx.input.isButtonJustPressed(Input.Buttons.LEFT);
        if ((click && retry.contains(m.x, m.y))
            || Gdx.input.isKeyJustPressed(Input.Keys.ENTER)
            || Gdx.input.isKeyJustPressed(Input.Keys.NUMPAD_ENTER)) {
            game.showGameplay();
            return;
        }
        if ((click && mainMenu.contains(m.x, m.y))
            || Gdx.input.isKeyJustPressed(Input.Keys.M)
            || Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            game.showMainMenu();
        }
    }
}
