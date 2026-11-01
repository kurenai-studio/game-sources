package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.tomer.scoundrel.model.Card;

import java.util.List;

/**
 * Draws the board's chrome — the health bar, the depth ticker and the Avoid
 * button — from the measurements in {@link HudArt}.
 *
 * <p>Like the card frame, everything is a tinted rectangle on a single white
 * pixel, so the whole HUD is one texture and never breaks the batch. No
 * arithmetic lives here; it is all in {@code HudArt} where it can be tested.
 */
final class BoardHud {

    private final TextureRegion pixel;
    private final BitmapFont font;
    private final Theme theme;
    private final Chrome chrome;
    private final GlyphLayout layout = new GlyphLayout();
    private final Color tint = new Color();

    /**
     * A HUD drawing on the theme's white pixel and fonts.
     *
     * @param theme the shared fonts and textures
     */
    BoardHud(Theme theme) {
        this.theme = theme;
        this.pixel = theme.whiteRegion();
        this.font = theme.pixelBody;
        this.chrome = new Chrome(theme);
    }

    /**
     * The health bar at rest, filled to match {@code health}.
     *
     * @param batch     the board's batch, already begun
     * @param health    current health, which may be zero or negative
     * @param maxHealth the ruleset's cap, which the bar is scaled against
     * @param healing   paints the fill in the heal colour for the pulse
     */
    void drawHealth(Batch batch, int health, int maxHealth, boolean healing) {
        drawHealth(batch, health, maxHealth, healing, false, 0,
                HudArt.barFillWidth(health, maxHealth));
    }

    /**
     * The health bar mid-change: the fill, the jolt and the number's colour are
     * the caller's, from {@link HealthReadout}.
     *
     * @param batch     the board's batch, already begun
     * @param health    the number to print, unclamped
     * @param maxHealth the ruleset's cap, printed after the number
     * @param healing   paints the fill in the heal colour for the pulse
     * @param bleeding  paints the fill in dried blood while it drains
     * @param offsetX   the jolt a hit gives the whole bar
     * @param fillWidth how much is filled, so a change can step a segment at a time
     */
    void drawHealth(Batch batch, int health, int maxHealth, boolean healing,
                    boolean bleeding, int offsetX, int fillWidth) {
        int x = HudArt.BAR_X + offsetX;
        int y = HudArt.BAR_Y;
        fill(batch, x, y, HudArt.BAR_W, HudArt.BAR_H, HudArt.FRAME);

        int inX = x + 2;
        int inY = y + 2;
        int inW = HudArt.barInteriorWidth();
        fill(batch, inX, inY, inW, HudArt.barInteriorHeight(), HudArt.BAR_EMPTY);
        fill(batch, inX, inY, inW, HudArt.BAR_LIP_H, HudArt.BAR_EMPTY_LIP);

        // Three bands rather than one flat colour, so the bar reads as lit.
        int filled = Math.min(fillWidth, inW);
        if (filled > 0) {
            // A change repaints the whole fill so the bar reads as one event:
            // green while it grows, dried blood while it drains.
            int wash = healing ? HudArt.FILL_HEAL : HudArt.FILL_BLOOD;
            boolean changing = healing || bleeding;
            int top = changing ? wash : HudArt.FILL_TOP;
            int mid = changing ? wash : HudArt.FILL_MID;
            int low = changing ? wash : HudArt.FILL_LOW;
            fill(batch, inX, inY, filled, HudArt.BAND_TOP, top);
            fill(batch, inX, inY + HudArt.BAND_TOP, filled, HudArt.BAND_MID, mid);
            fill(batch, inX, inY + HudArt.BAND_TOP + HudArt.BAND_MID, filled, HudArt.BAND_LOW, low);
        }

        // Separators go on top of the fill, not between cells of it — the bar
        // underneath is continuous, which is why partial health lands mid-cell.
        for (int sx = inX + HudArt.SEGMENT_PITCH - HudArt.SEGMENT_GAP;
                sx < inX + inW; sx += HudArt.SEGMENT_PITCH) {
            fill(batch, sx, inY, HudArt.SEGMENT_GAP, HudArt.barInteriorHeight(),
                    HudArt.SEGMENT_LINE, HudArt.SEGMENT_ALPHA);
        }

        // The readout takes the colour of whatever is happening to the bar, and
        // holds it for as long as the bar is still changing.
        int colour = healing ? HudArt.FILL_HEAL
                : bleeding ? HudArt.FILL_BLOOD : HudArt.NUMBER_REST;
        // Unclamped: how far past zero a killing blow took you is the whole
        // story of that blow, and the death score charges you for it. Only the
        // bar's fill clamps, because a bar cannot draw backwards.
        String reading = String.valueOf(health);
        font.setColor(rgb(colour, 1f));
        font.draw(batch, reading, HudArt.NUMBER_X + offsetX,
                CardArt.toWorldY(HudArt.NUMBER_BASELINE, 0));
        font.setColor(Color.WHITE);

        // What the number is out of, dim and small behind it, so the reading
        // says "14 of 20" without a second widget.
        layout.setText(font, reading);
        BitmapFont small = theme.pixelLabel;
        small.setColor(rgb(BoardArt.HP_SUFFIX_COLOUR, 1f));
        small.draw(batch, "/" + maxHealth + " HP",
                HudArt.NUMBER_X + offsetX + layout.width + BoardArt.HP_SUFFIX_GAP,
                CardArt.toWorldY(HudArt.NUMBER_BASELINE + 4, 0));
        small.setColor(Color.WHITE);
    }

    /**
     * One tick per card still face-down; the rest of the dungeon sits dim. The
     * strip is placed so the lit block stays centred, so it walks right as the
     * dungeon drains rather than the gold shrinking away from the middle.
     *
     * @param batch    the board's batch, already begun
     * @param depth    cards still face-down, which are the lit ticks
     * @param deckSize every card the dungeon started with, one tick each
     */
    void drawTicker(Batch batch, int depth, int deckSize) {
        int left = HudArt.tickerX(depth);
        for (int i = 0; i < deckSize; i++) {
            int x = left + i * HudArt.TICK_PITCH;
            fill(batch, x, HudArt.TICKER_Y, HudArt.TICK_W, HudArt.TICKER_H,
                    i < HudArt.ticksLit(depth) ? HudArt.GOLD : HudArt.TICK_DIM);
        }
    }

    /**
     * The gold plate, bevelled light on top and dark below like every button.
     *
     * @param batch   the board's batch, already begun
     * @param enabled whether avoiding is legal now; a spent plate when not
     */
    void drawAvoid(Batch batch, boolean enabled) {
        drawPlate(batch, HudArt.AVOID_X, HudArt.AVOID_Y,
                HudArt.AVOID_W, HudArt.AVOID_H, "AVOID", enabled);
    }

    /**
     * How wide a label sets, so a plate can be sized around one.
     *
     * @param text the label
     * @return its width in the label face, in whole pixels
     */
    int labelWidth(String text) {
        layout.setText(theme.pixelLabel, text);
        return Math.round(layout.width);
    }

    /**
     * The board's one button — and the game's. Avoid is one of these, so is
     * every choice in the move chooser, and so is every button on every menu:
     * {@link Chrome#plate} draws all of them, so they cannot drift apart.
     *
     * @param batch   the board's batch, already begun
     * @param x       the plate's left edge, in design pixels
     * @param y       the plate's top edge, in design pixels measured downward
     * @param w       the plate's width
     * @param h       the plate's height
     * @param text    the label, centred on the plate
     * @param enabled gold when true, spent when false
     */
    void drawPlate(Batch batch, int x, int y, int w, int h, String text, boolean enabled) {
        chrome.plate(batch, x, y, w, h, text,
                enabled ? Chrome.Plate.GOLD : Chrome.Plate.SPENT);
    }

    /**
     * How deep the dungeon still is and how long the run has taken, on the same
     * centre line the lit ticks keep. Anchored to the board rather than to the
     * strip, which moves — a caption that slid about under a gauge would read as
     * the caption being loose.
     *
     * @param batch the board's batch, already begun
     * @param depth cards still face-down
     * @param time  the run's clock as {@link ClockText} prints it, or null to leave it off
     */
    void drawDepthLine(Batch batch, int depth, String time) {
        BitmapFont small = theme.pixelLabel;
        String text = time == null ? "DEPTH " + depth : "DEPTH " + depth + "  ·  " + time;
        layout.setText(small, text);
        int centre = Math.round(Theme.WORLD_WIDTH / 2f);
        small.setColor(rgb(BoardArt.DEPTH_COLOUR, 1f));
        small.draw(batch, text, Math.round(centre - layout.width / 2f),
                CardArt.toWorldY(BoardArt.DEPTH_TOP, 0));
        small.setColor(Color.WHITE);
    }

    /**
     * The trophy rail: the equipped weapon in its well, what it is, the
     * monsters stacked on it, and how much bite it has left. Barehanded is the
     * same well standing empty — the slot is always there, so equipping does
     * not shift the whole strip sideways.
     *
     * @param batch     the board's batch, already begun
     * @param icon      the weapon's sprite, drawn at ×1, or null when barehanded
     * @param name      the weapon's name and value, or {@code BAREHANDED}
     * @param slain     the monsters on the weapon, oldest first, or null when barehanded
     * @param threshold the bite plate's text, from {@link Labels#weaponThreshold}; null when
     *                  barehanded
     */
    void drawRail(Batch batch, TextureRegion icon, String name,
                  List<Card> slain, String threshold) {
        int x = BoardArt.RAIL_X;
        int y = BoardArt.RAIL_Y;
        int box = BoardArt.RAIL_BOX;
        int frame = BoardArt.FRAME;
        fill(batch, x, y, box, box, HudArt.FRAME);
        fill(batch, x + frame, y + frame, box - 2 * frame, box - 2 * frame, BoardArt.RAIL_WELL);
        // The same two inset shadows the card wells carry, so it reads recessed.
        fill(batch, x + frame, y + frame, box - 2 * frame, 2, 0x000000, 0.5f);
        fill(batch, x + frame, y + box - frame - 2, box - 2 * frame, 2, 0xe8ddc7, 0.05f);
        if (icon != null) {
            batch.draw(icon, BoardArt.railIconX(),
                    CardArt.toWorldY(BoardArt.railIconY(), BoardArt.RAIL_ICON),
                    BoardArt.RAIL_ICON, BoardArt.RAIL_ICON);
        }

        BitmapFont small = theme.pixelLabel;
        small.setColor(rgb(BoardArt.NAME_COLOUR, 1f));
        small.draw(batch, name, BoardArt.COLUMN_X, CardArt.toWorldY(BoardArt.NAME_TOP, 0));
        small.setColor(Color.WHITE);
        if (slain == null) {
            return; // barehanded: no chips, no plate
        }

        for (int i = 0; i < slain.size(); i++) {
            int cx = BoardArt.chipX(i);
            fill(batch, cx, BoardArt.CHIP_Y, BoardArt.CHIP_W, BoardArt.CHIP_H, HudArt.FRAME);
            fill(batch, cx + frame, BoardArt.CHIP_Y + frame,
                    BoardArt.CHIP_W - 2 * frame, BoardArt.CHIP_H - 2 * frame,
                    BoardArt.CHIP_FACE);
            String value = String.valueOf(slain.get(i).value());
            layout.setText(small, value);
            small.setColor(rgb(BoardArt.CHIP_LABEL, 1f));
            small.draw(batch, value,
                    Math.round(cx + (BoardArt.CHIP_W - layout.width) / 2f),
                    CardArt.toWorldY(BoardArt.CHIP_Y
                            + Math.round((BoardArt.CHIP_H - layout.height) / 2f), 0));
            small.setColor(Color.WHITE);
        }

        BitmapFont plateFont = theme.pixelLabel;
        layout.setText(plateFont, threshold);
        int plateX = BoardArt.slaysPlateX(slain.size());
        int plateW = Math.round(layout.width) + 2 * BoardArt.PLATE_PAD_X;
        fill(batch, plateX, BoardArt.PLATE_Y, plateW, BoardArt.PLATE_H, HudArt.GOLD);
        plateFont.setColor(rgb(HudArt.LABEL_DARK, 1f));
        plateFont.draw(batch, threshold, plateX + BoardArt.PLATE_PAD_X,
                CardArt.toWorldY(BoardArt.PLATE_Y
                        + Math.round((BoardArt.PLATE_H - layout.height) / 2f), 0));
        plateFont.setColor(Color.WHITE);
    }

    /**
     * The potion marker opposite the rail: one draught a room, and whether it
     * has been drunk. The icon is never dimmed — an alpha over a dark board
     * makes colours that are on no ramp — so the label carries the state.
     *
     * @param batch the board's batch, already begun
     * @param icon  a potion sprite, or null to leave the box empty
     * @param used  whether this turn's potion has already healed
     */
    void drawPotionMarker(Batch batch, TextureRegion icon, boolean used) {
        int x = BoardArt.MARKER_X;
        int y = BoardArt.MARKER_Y;
        int box = BoardArt.MARKER_BOX;
        fill(batch, x, y, box, box, HudArt.FRAME);
        if (icon != null) {
            batch.draw(icon, BoardArt.markerIconX(),
                    CardArt.toWorldY(BoardArt.markerIconY(), BoardArt.MARKER_ICON),
                    BoardArt.MARKER_ICON, BoardArt.MARKER_ICON);
        }
        BitmapFont small = theme.pixelLabel;
        small.setColor(rgb(used ? BoardArt.MARKER_USED : BoardArt.MARKER_READY, 1f));
        small.draw(batch, used ? "POTION USED" : "POTION READY", BoardArt.MARKER_LABEL_X,
                CardArt.toWorldY(BoardArt.MARKER_LABEL_TOP, 0));
        small.setColor(Color.WHITE);
    }

    /**
     * One line of the event feed, right-aligned down the margin. The alpha is
     * the caller's — it comes off a stepped fade, not a smooth one.
     *
     * @param batch the board's batch, already begun
     * @param text  the line
     * @param index its place in the feed, from 0 (the oldest)
     * @param alpha how strongly to draw it, from {@link Feed#alphaAt}
     */
    void drawFeedLine(Batch batch, String text, int index, float alpha) {
        BitmapFont line = theme.pixelLabel;
        layout.setText(line, text);
        line.setColor(rgb(BoardArt.FEED_COLOUR, alpha));
        line.draw(batch, text, BoardArt.FEED_RIGHT - layout.width,
                CardArt.toWorldY(BoardArt.feedLineY(index), 0));
        line.setColor(Color.WHITE);
    }

    private Color rgb(int rgb, float alpha) {
        tint.set((rgb >>> 16 & 0xff) / 255f, (rgb >>> 8 & 0xff) / 255f,
                (rgb & 0xff) / 255f, alpha);
        return tint;
    }

    private void fill(Batch batch, int x, int y, int w, int h, int rgb) {
        fill(batch, x, y, w, h, rgb, 1f);
    }

    /** {@code y} arrives in design space and is flipped once, here. */
    private void fill(Batch batch, int x, int y, int w, int h, int rgb, float alpha) {
        Color previous = batch.getColor().cpy();
        batch.setColor(rgb(rgb, alpha));
        batch.draw(pixel, x, CardArt.toWorldY(y, h), w, h);
        batch.setColor(previous);
    }
}
