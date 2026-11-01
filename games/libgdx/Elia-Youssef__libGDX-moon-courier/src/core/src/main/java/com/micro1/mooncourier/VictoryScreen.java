package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;

/**
 * Victory Scene: shown when the cargo is delivered to the pad before fuel runs out. Reports the
 * success message, the mission results (cargo status, remaining fuel, score, time), and offers Play
 * Again (restart) and Main Menu, grouped in one result panel.
 */
public final class VictoryScreen extends BaseScreen {

    private static final float PX = 230f;
    private static final float PY = 95f;
    private static final float PW = 820f;
    private static final float PH = 550f;

    private static final float ROW_X = 258f;
    private static final float ROW_W = 372f;
    private static final float ROW_H = 52f;
    private static final float[] ROW_Y = {452f, 388f, 324f, 260f};

    private final MissionResult result;
    private final String[] labels;
    private final String[] values;
    private final Color[] valueColors;

    private final Button playAgain;
    private final Button mainMenu;

    public VictoryScreen(MoonCourierGame game, MissionResult result) {
        super(game);
        this.result = result;
        labels = new String[]{"CARGO STATUS", "FUEL REMAINING", "SCORE", "TIME TAKEN"};
        values = new String[]{
            "DELIVERED",
            result.fuelPercent + "%",
            Integer.toString(result.score),
            MissionResult.formatTime(result.timeSeconds)
        };
        valueColors = new Color[]{Palette.GREEN, Palette.BLUE, Palette.YELLOW, Palette.PURPLE};

        playAgain = new Button(270f, 150f, 300f, 60f, "PLAY AGAIN",
            Palette.GREEN, Palette.WHITE, Palette.DARK_TEXT);
        mainMenu = new Button(610f, 150f, 300f, 60f, "MAIN MENU",
            Palette.BLUE, Palette.WHITE, Palette.WHITE);
    }

    @Override
    public void render(float delta) {
        clear(Palette.SPACE);
        Vector2 m = mouse();
        playAgain.hovered = playAgain.contains(m.x, m.y);
        mainMenu.hovered = mainMenu.contains(m.x, m.y);

        // ---- shape pass ----
        shape.begin(ShapeType.Filled);
        Draw.spaceBackground(shape, a);
        Draw.panel(shape, PX, PY, PW, PH, Palette.PANEL_FILL, Palette.GREEN);
        for (float ry : ROW_Y) {
            Draw.panel(shape, ROW_X, ry, ROW_W, ROW_H, Palette.PANEL_FILL_SOLID, Palette.PANEL_BORDER);
        }
        // Decorative delivered ship resting on the pad (right side).
        Draw.deliveryPad(shape, 830f, 340f, 78f);
        Draw.ship(shape, 830f, 352f, false);
        playAgain.drawFace(shape);
        mainMenu.drawFace(shape);
        shape.end();

        // ---- text pass ----
        GlyphLayout l = layout;
        batch.begin();
        Draw.textCentered(batch, a.fontTitle, l, "DELIVERY SUCCESSFUL!", 640f, 610f, Palette.GREEN);
        Draw.textCentered(batch, a.fontLabel, l, "Cargo delivered safely to the lunar pad.",
            640f, 552f, Palette.WHITE);
        for (int i = 0; i < labels.length; i++) {
            float ty = ROW_Y[i] + 35f;
            Draw.textLeft(batch, a.fontLabel, labels[i], ROW_X + 18f, ty, Palette.LIGHT_GREY);
            Draw.textRight(batch, a.fontLabel, l, values[i], ROW_X + ROW_W - 18f, ty, valueColors[i]);
        }
        playAgain.drawLabel(batch, a.fontHeading, l);
        mainMenu.drawLabel(batch, a.fontHeading, l);
        Draw.textCentered(batch, a.fontSmall, l, "Enter: Play Again      M / Esc: Main Menu",
            640f, 126f, Palette.LIGHT_GREY);
        Draw.textCentered(batch, a.fontSmall, l, "THANK YOU FOR DELIVERING WITH MOON COURIER!",
            640f, 74f, Palette.DIM_GREY);
        batch.end();

        handleInput(m);
    }

    private void handleInput(Vector2 m) {
        boolean click = Gdx.input.isButtonJustPressed(Input.Buttons.LEFT);
        if ((click && playAgain.contains(m.x, m.y))
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
