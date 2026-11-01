package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;

/**
 * Main Menu (first screen shown at launch). Presents the Moon Courier title,
 * the mission
 * introduction, and the Start and Exit options grouped together in one panel.
 * No gameplay happens
 * here. Start begins the Gameplay Scene; Exit closes the application.
 */
public final class MainMenuScreen extends BaseScreen {

    private static final float PX = 360f;
    private static final float PY = 150f;
    private static final float PW = 560f;
    private static final float PH = 480f;

    private final Button start;
    private final Button exit;

    public MainMenuScreen(MoonCourierGame game) {
        super(game);
        start = new Button(410f, 300f, 460f, 62f, "START MISSION",
                Palette.YELLOW, Palette.WHITE, Palette.DARK_TEXT);
        exit = new Button(410f, 222f, 460f, 62f, "EXIT GAME",
                Palette.PANEL_FILL_SOLID, Palette.PANEL_BORDER, Palette.WHITE);
    }

    @Override
    public void render(float delta) {
        clear(Palette.SPACE);
        Vector2 m = mouse();
        start.hovered = start.contains(m.x, m.y);
        exit.hovered = exit.contains(m.x, m.y);

        // ---- shape pass ----
        shape.begin(ShapeType.Filled);
        Draw.spaceBackground(shape, a);
        // Decorative ship on a small pad (left) and a cargo crate (right) on the
        // horizon.
        Draw.deliveryPad(shape, 150f, 96f, 60f);
        Draw.ship(shape, 150f, 104f, false);
        Draw.crate(shape, 1130f, 88f);
        // Menu panel.
        Draw.panel(shape, PX, PY, PW, PH, Palette.PANEL_FILL, Palette.PANEL_BORDER);
        // Mission intro subpanel.
        Draw.panel(shape, 392f, 398f, 496f, 74f, Palette.PANEL_FILL_SOLID, Palette.PANEL_BORDER);
        start.drawFace(shape);
        exit.drawFace(shape);
        shape.end();

        // ---- text pass ----
        GlyphLayout l = layout;
        batch.begin();
        Draw.textCentered(batch, a.fontTitle, l, "MOON", 640f, 612f, Palette.WHITE);
        Draw.textCentered(batch, a.fontTitle, l, "COURIER", 640f, 552f, Palette.YELLOW);

        Draw.textCentered(batch, a.fontSmall, l, "DELIVER CARGO.  SAVE FUEL.  GET IT DONE.",
                640f, 500f, Palette.LIGHT_GREY);

        Draw.textCentered(batch, a.fontSmall, l, "YOUR MISSION", 640f, 466f, Palette.YELLOW);

        Draw.textWrapped(batch, a.fontSmall, l,
                "Pick up the cargo from the depot and deliver it to the landing pad.",
                640f, 442f, 470f, Palette.WHITE);

        start.drawLabel(batch, a.fontHeading, l);
        exit.drawLabel(batch, a.fontHeading, l);

        Draw.textCentered(batch, a.fontSmall, l,
                "Move: WASD / Arrow Keys      Enter: Start      Esc: Exit",
                640f, 132f, Palette.DIM_GREY);
        batch.end();

        handleInput(m);
    }

    private void handleInput(Vector2 m) {
        boolean click = Gdx.input.isButtonJustPressed(Input.Buttons.LEFT);
        if ((click && start.contains(m.x, m.y))
                || Gdx.input.isKeyJustPressed(Input.Keys.ENTER)
                || Gdx.input.isKeyJustPressed(Input.Keys.NUMPAD_ENTER)
                || Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
            game.showGameplay();
            return;
        }
        if ((click && exit.contains(m.x, m.y)) || Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            Gdx.app.exit();
        }
    }
}
