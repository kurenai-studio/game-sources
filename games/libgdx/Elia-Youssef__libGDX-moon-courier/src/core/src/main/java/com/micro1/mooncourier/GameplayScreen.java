package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;

/**
 * Gameplay Scene: the thin render/input shell around {@link MissionWorld}. Each frame it reads the
 * movement keys (WASD or arrow keys), advances the world, draws the lunar surface, ship, crate,
 * obstacles, delivery pad, and the HUD (fuel, cargo, objective, score, time, controls, minimap), and
 * hands off to the Victory or Game Over screen when the mission ends. It holds no game rules of its
 * own - those live in the world.
 */
public final class GameplayScreen extends BaseScreen {

    private final MissionWorld world;

    public GameplayScreen(MoonCourierGame game) {
        super(game);
        this.world = new MissionWorld();
    }

    /** Exposed so the QA capture path can seed a specific gameplay state. */
    public MissionWorld getWorld() {
        return world;
    }

    @Override
    public void render(float delta) {
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            game.showMainMenu();
            return;
        }

        // ---- input ----
        boolean up = Gdx.input.isKeyPressed(Input.Keys.W) || Gdx.input.isKeyPressed(Input.Keys.UP);
        boolean down = Gdx.input.isKeyPressed(Input.Keys.S) || Gdx.input.isKeyPressed(Input.Keys.DOWN);
        boolean left = Gdx.input.isKeyPressed(Input.Keys.A) || Gdx.input.isKeyPressed(Input.Keys.LEFT);
        boolean right = Gdx.input.isKeyPressed(Input.Keys.D) || Gdx.input.isKeyPressed(Input.Keys.RIGHT);
        boolean moving = up != down || left != right;

        // ---- simulate ----
        world.update(delta, up, down, left, right);
        if (world.getState() == GameState.WON) {
            game.showVictory(MissionResult.from(world));
            return;
        }
        if (world.getState() == GameState.LOST) {
            game.showGameOver(MissionResult.from(world));
            return;
        }

        // ---- draw ----
        clear(Palette.REGOLITH);
        drawWorld(moving);
        drawHudText();
    }

    private void drawWorld(boolean moving) {
        shape.begin(ShapeType.Filled);
        Draw.moonSurface(shape, a);
        for (Obstacle o : world.getObstacles()) {
            Draw.obstacle(shape, o);
        }
        Draw.deliveryPad(shape, MissionWorld.PAD_X, MissionWorld.PAD_Y, MissionWorld.PAD_RADIUS);
        if (!world.isCargoCollected()) {
            Draw.crate(shape, MissionWorld.CRATE_X, MissionWorld.CRATE_Y);
        }
        Draw.ship(shape, world.getShipX(), world.getShipY(), moving);

        // HUD panels.
        Draw.panel(shape, 16f, 596f, 380f, 108f, Palette.PANEL_FILL, Palette.PANEL_BORDER);   // fuel/cargo
        Draw.panel(shape, 470f, 612f, 340f, 92f, Palette.PANEL_FILL, Palette.PANEL_BORDER);   // objective
        Draw.panel(shape, 1050f, 612f, 214f, 92f, Palette.PANEL_FILL, Palette.PANEL_BORDER);  // score/time
        Draw.panel(shape, 16f, 16f, 252f, 168f, Palette.PANEL_FILL, Palette.PANEL_BORDER);    // controls
        Draw.panel(shape, 1044f, 16f, 220f, 200f, Palette.PANEL_FILL, Palette.PANEL_BORDER);  // minimap
        if (statusMessage() != null) {
            Color border = world.isPenaltyFlashing() ? Palette.RED : Palette.YELLOW;
            Draw.panel(shape, 330f, 92f, 620f, 54f, Palette.PANEL_FILL_SOLID, border);
        }
        Draw.fuelBar(shape, 112f, 664f, 214f, 16f, world.getFuelPercent());
        Draw.minimap(shape, 1054f, 26f, 200f, 150f, world);
        shape.end();
    }

    private void drawHudText() {
        GlyphLayout l = layout;
        batch.begin();

        // World-object labels.
        if (!world.isCargoCollected()) {
            Draw.textCentered(batch, a.fontSmall, l, "CARGO",
                MissionWorld.CRATE_X, MissionWorld.CRATE_Y + 52f, Palette.YELLOW);
        }
        Draw.textCentered(batch, a.fontSmall, l, "DELIVERY PAD",
            MissionWorld.PAD_X, MissionWorld.PAD_Y + 86f, Palette.GREEN);
        Draw.textCentered(batch, a.fontHeading, l, "H",
            MissionWorld.PAD_X, MissionWorld.PAD_Y + 16f, Palette.PAD_MARK);

        // Fuel / cargo HUD.
        Draw.textLeft(batch, a.fontLabel, "FUEL", 34f, 686f, Palette.WHITE);
        int pct = world.getFuelPercent();
        Color pctColor = pct > 50 ? Palette.FUEL_GREEN
            : pct > 25 ? Palette.FUEL_YELLOW : Palette.FUEL_RED;
        Draw.textRight(batch, a.fontLabel, l, pct + "%", 384f, 688f, pctColor);
        Draw.textLeft(batch, a.fontLabel, "CARGO", 34f, 636f, Palette.WHITE);
        if (world.isCargoCollected()) {
            Draw.textLeft(batch, a.fontLabel, "COLLECTED", 150f, 636f, Palette.GREEN);
        } else {
            Draw.textLeft(batch, a.fontLabel, "NOT COLLECTED", 150f, 636f, Palette.YELLOW);
        }

        // Objective.
        Draw.textCentered(batch, a.fontSmall, l, "OBJECTIVE", 640f, 696f, Palette.YELLOW);
        Draw.textWrapped(batch, a.fontSmall, l,
            world.isCargoCollected()
                ? "Cargo secured. Deliver it to the highlighted landing pad."
                : "Pick up the cargo and deliver it to the landing pad.",
            640f, 672f, 312f, Palette.WHITE);

        // Score / time.
        Draw.textLeft(batch, a.fontLabel, "SCORE  " + pad6(world.getScore()), 1066f, 690f, Palette.WHITE);
        Draw.textLeft(batch, a.fontLabel, "TIME   " + MissionResult.formatTime(world.getElapsed()),
            1066f, 650f, Palette.LIGHT_GREY);

        // Controls.
        Draw.textLeft(batch, a.fontLabel, "CONTROLS", 32f, 172f, Palette.WHITE);
        Draw.textLeft(batch, a.fontSmall, "W / Up      Move Up", 32f, 142f, Palette.LIGHT_GREY);
        Draw.textLeft(batch, a.fontSmall, "S / Down    Move Down", 32f, 114f, Palette.LIGHT_GREY);
        Draw.textLeft(batch, a.fontSmall, "A / Left    Move Left", 32f, 86f, Palette.LIGHT_GREY);
        Draw.textLeft(batch, a.fontSmall, "D / Right   Move Right", 32f, 58f, Palette.LIGHT_GREY);
        Draw.textLeft(batch, a.fontSmall, "Esc         Main Menu", 32f, 34f, Palette.DIM_GREY);

        // Minimap heading.
        Draw.textLeft(batch, a.fontSmall, "RADAR", 1058f, 208f, Palette.DIM_GREY);

        String status = statusMessage();
        if (status != null) {
            Draw.textCentered(batch, a.fontLabel, l, status, 640f, 127f,
                world.isPenaltyFlashing() ? Palette.RED : Palette.YELLOW);
        }

        batch.end();
    }

    private static String pad6(int score) {
        String s = Integer.toString(Math.max(0, score));
        return s.length() >= 6 ? s : "000000".substring(s.length()) + s;
    }

    private String statusMessage() {
        if (world.isPenaltyFlashing()) {
            return "-8% FUEL  (OBSTACLE HIT)";
        }
        if (world.isOnPadWithoutCargo()) {
            return "COLLECT THE CARGO FIRST";
        }
        return null;
    }
}
