package com.micro1.mooncourier;

import com.badlogic.gdx.graphics.Color;

/** Central colour palette so every screen shares one lunar-courier look. */
public final class Palette {

    private Palette() {
    }

    // Space + surface
    public static final Color SPACE = new Color(0.03f, 0.04f, 0.08f, 1f);
    public static final Color REGOLITH = new Color(0.30f, 0.30f, 0.33f, 1f);
    public static final Color REGOLITH_DARK = new Color(0.22f, 0.22f, 0.25f, 1f);
    public static final Color REGOLITH_LIGHT = new Color(0.40f, 0.40f, 0.43f, 1f);
    public static final Color CRATER_PIT = new Color(0.15f, 0.15f, 0.18f, 1f);
    public static final Color CRATER_RIM = new Color(0.45f, 0.45f, 0.48f, 1f);
    public static final Color ROCK = new Color(0.34f, 0.34f, 0.37f, 1f);
    public static final Color ROCK_SHADE = new Color(0.24f, 0.24f, 0.27f, 1f);

    // HUD / panels
    public static final Color PANEL_FILL = new Color(0.05f, 0.09f, 0.15f, 0.82f);
    public static final Color PANEL_FILL_SOLID = new Color(0.06f, 0.10f, 0.16f, 1f);
    public static final Color PANEL_BORDER = new Color(0.24f, 0.58f, 0.78f, 1f);

    // Text
    public static final Color WHITE = new Color(0.96f, 0.97f, 1f, 1f);
    public static final Color LIGHT_GREY = new Color(0.72f, 0.76f, 0.82f, 1f);
    public static final Color DIM_GREY = new Color(0.62f, 0.66f, 0.72f, 1f);
    public static final Color DARK_TEXT = new Color(0.08f, 0.09f, 0.11f, 1f);

    // Accents
    public static final Color YELLOW = new Color(0.96f, 0.76f, 0.16f, 1f);
    public static final Color GREEN = new Color(0.46f, 0.86f, 0.32f, 1f);
    public static final Color RED = new Color(0.88f, 0.26f, 0.24f, 1f);
    public static final Color BLUE = new Color(0.28f, 0.62f, 0.95f, 1f);
    public static final Color PURPLE = new Color(0.62f, 0.52f, 0.92f, 1f);

    // Fuel bar
    public static final Color FUEL_GREEN = new Color(0.36f, 0.86f, 0.36f, 1f);
    public static final Color FUEL_YELLOW = new Color(0.92f, 0.80f, 0.24f, 1f);
    public static final Color FUEL_RED = new Color(0.90f, 0.30f, 0.26f, 1f);
    public static final Color FUEL_EMPTY = new Color(0.16f, 0.20f, 0.26f, 1f);

    // Ship
    public static final Color SHIP_BODY = new Color(0.90f, 0.92f, 0.96f, 1f);
    public static final Color SHIP_SHADE = new Color(0.66f, 0.70f, 0.76f, 1f);
    public static final Color SHIP_STRIPE = new Color(0.82f, 0.22f, 0.20f, 1f);
    public static final Color SHIP_COCKPIT = new Color(0.20f, 0.34f, 0.52f, 1f);
    public static final Color FLAME = new Color(0.40f, 0.68f, 1f, 1f);
    public static final Color FLAME_CORE = new Color(0.80f, 0.92f, 1f, 1f);

    // Cargo crate
    public static final Color CRATE = new Color(0.80f, 0.72f, 0.46f, 1f);
    public static final Color CRATE_DARK = new Color(0.52f, 0.46f, 0.28f, 1f);
    public static final Color CRATE_STRAP = new Color(0.34f, 0.30f, 0.18f, 1f);

    // Delivery pad
    public static final Color PAD_ASPHALT = new Color(0.13f, 0.13f, 0.16f, 1f);
    public static final Color PAD_YELLOW = new Color(0.96f, 0.76f, 0.16f, 1f);
    public static final Color PAD_MARK = new Color(0.90f, 0.92f, 0.96f, 1f);

    // Earth
    public static final Color EARTH_OCEAN = new Color(0.16f, 0.34f, 0.62f, 1f);
    public static final Color EARTH_LAND = new Color(0.28f, 0.52f, 0.40f, 1f);
    public static final Color EARTH_CLOUD = new Color(0.82f, 0.86f, 0.92f, 0.7f);
}
