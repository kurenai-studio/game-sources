package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

/**
 * The five parts every screen outside the board is assembled from: a frame, a
 * face, a bevel, a label and a rule.
 *
 * <p>The six menu screens are these and nothing else, so this is the whole
 * vocabulary — a screen that needs a sixth part is either wrong or showing that
 * the vocabulary is. Everything is a tinted rectangle on a
 * single white pixel, so a whole screen is one texture and never breaks the
 * batch, exactly as {@link CardFrame} and {@link BoardHud} already work.
 *
 * <p>No arithmetic lives here; it is all in {@link ScreenArt} where it can be
 * tested. This class only turns measurements into draw calls.
 */
final class Chrome {

    /** The two menu button faces, plus the board's disabled one. */
    enum Plate {
        /** The prominent choice: gold, with a dark label. */
        GOLD,
        /** The quiet choice: a dark face, with a dim cream label. */
        DARK,
        /** The board's disabled plate: flat and dead, no bevel to speak of. */
        SPENT
    }

    private final TextureRegion pixel;
    private final Theme theme;
    private final GlyphLayout layout = new GlyphLayout();
    private final Color tint = new Color();

    /**
     * A menu kit drawing on the theme's white pixel and fonts.
     *
     * @param theme the shared fonts and textures
     */
    Chrome(Theme theme) {
        this.theme = theme;
        this.pixel = theme.whiteRegion();
    }

    // --- the parts ---------------------------------------------------------

    /**
     * Flat fill. {@code y} arrives in design space and is flipped once, here.
     *
     * @param batch the screen's batch, already begun; its colour is restored after
     * @param x     the left edge, in design pixels
     * @param y     the top edge, in design pixels measured downward
     * @param w     the width, in design pixels
     * @param h     the height, in design pixels
     * @param rgb   the colour, {@code 0xRRGGBB}, drawn opaque
     */
    void face(Batch batch, int x, int y, int w, int h, int rgb) {
        face(batch, x, y, w, h, rgb, 1f);
    }

    /**
     * Flat fill at an alpha.
     *
     * @param batch the screen's batch, already begun; its colour is restored after
     * @param x     the left edge, in design pixels
     * @param y     the top edge, in design pixels measured downward
     * @param w     the width, in design pixels
     * @param h     the height, in design pixels
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void face(Batch batch, int x, int y, int w, int h, int rgb, float alpha) {
        Color previous = batch.getColor().cpy();
        batch.setColor(rgb(rgb, alpha));
        batch.draw(pixel, x, CardArt.toWorldY(y, h), w, h);
        batch.setColor(previous);
    }

    /**
     * The 2px recess around a widget, drawn as four bars rather than a filled
     * rect behind it — a widget's face may be translucent, and a fill behind it
     * would show through and darken it.
     *
     * @param batch the screen's batch, already begun
     * @param x     the widget's left edge, frame included, in design pixels
     * @param y     the widget's top edge, frame included, in design pixels measured downward
     * @param w     the widget's width, frame included
     * @param h     the widget's height, frame included
     */
    void frame(Batch batch, int x, int y, int w, int h) {
        int t = ScreenArt.THICK;
        face(batch, x, y, w, t, ScreenArt.FRAME);
        face(batch, x, y + h - t, w, t, ScreenArt.FRAME);
        face(batch, x, y + t, t, h - 2 * t, ScreenArt.FRAME);
        face(batch, x + w - t, y + t, t, h - 2 * t, ScreenArt.FRAME);
    }

    /**
     * Light along the top and left, dark along the bottom and right, so the
     * face reads as raised. Each pair stops short of the other's corner, which
     * is the same mitre the card bevels use.
     *
     * @param batch the screen's batch, already begun
     * @param x     the face's left edge, inside the frame, in design pixels
     * @param y     the face's top edge, inside the frame, in design pixels measured downward
     * @param w     the face's width
     * @param h     the face's height
     * @param light {@code 0xRRGGBB} for the top and left
     * @param dark  {@code 0xRRGGBB} for the bottom and right
     */
    void bevel(Batch batch, int x, int y, int w, int h, int light, int dark) {
        int t = ScreenArt.THICK;
        face(batch, x, y, w - t, t, light);
        face(batch, x, y, t, h - t, light);
        face(batch, x + t, y + h - t, w - t, t, dark);
        face(batch, x + w - t, y, t, h, dark);
    }

    /**
     * Puts the whole screen under the modal dim, for an overlay that must be
     * answered before anything behind it. See {@link Theme#ditherRegion} for why
     * it is a dither and not a scrim.
     *
     * @param batch the screen's batch, already begun
     */
    void dim(Batch batch) {
        dither(batch, true);
    }

    /**
     * The lighter half of the same pattern, for the tutorial: the board under it
     * is the thing you are about to click, so it has to stay readable. A modal
     * dialog wants {@link #dim} instead — nothing behind that needs reading.
     *
     * @param batch the screen's batch, already begun
     */
    void veil(Batch batch) {
        dither(batch, false);
    }

    private void dither(Batch batch, boolean heavy) {
        Color previous = batch.getColor().cpy();
        batch.setColor(Color.WHITE);
        batch.draw(theme.ditherRegion(heavy, (int) Theme.WORLD_WIDTH, (int) Theme.WORLD_HEIGHT),
                0, 0, Theme.WORLD_WIDTH, Theme.WORLD_HEIGHT);
        batch.setColor(previous);
    }

    /**
     * A horizontal rule, {@link ScreenArt#THICK} deep, in the translucent rule colour.
     *
     * @param batch the screen's batch, already begun
     * @param x     the rule's left end, in design pixels
     * @param y     the rule's top edge, in design pixels measured downward
     * @param w     the rule's length
     */
    void rule(Batch batch, int x, int y, int w) {
        face(batch, x, y, w, ScreenArt.THICK, ScreenArt.RULE, ScreenArt.RULE_ALPHA);
    }

    /**
     * A horizontal rule in a colour of the caller's, opaque.
     *
     * @param batch the screen's batch, already begun
     * @param x     the rule's left end, in design pixels
     * @param y     the rule's top edge, in design pixels measured downward
     * @param w     the rule's length
     * @param rgb   the colour, {@code 0xRRGGBB}
     */
    void rule(Batch batch, int x, int y, int w, int rgb) {
        face(batch, x, y, w, ScreenArt.THICK, rgb);
    }

    // --- the one button shape ----------------------------------------------

    /**
     * A button: frame, bevel, face and a centred Silkscreen label. The board's
     * Avoid button, every choice in the move chooser and every menu button are
     * this method at different sizes — there is one button shape in the game and
     * one place that draws it, so they cannot drift apart.
     *
     * @param batch the screen's batch, already begun
     * @param x     the plate's left edge, frame included, in design pixels
     * @param y     the plate's top edge, frame included, in design pixels measured downward
     * @param w     the plate's width, frame included
     * @param h     the plate's height, frame included
     * @param text  the label, centred; empty for none
     * @param style which face to draw
     */
    void plate(Batch batch, int x, int y, int w, int h, String text, Plate style) {
        plate(batch, x, y, w, h, text, style, false);
    }

    /**
     * The same plate, held down. A menu that acts on release has to show what
     * it is about to act on, or a press that gets taken back by sliding off
     * looks like a button that did not work.
     *
     * <p>It is not a hover glow: nothing lights up, nothing scales, and every
     * colour is on the eighty. The bevel inverts — the dark
     * tone along the top and left, the light along the bottom and right — so the
     * same four colours read as a recess instead of a raise; the face drops to
     * its shadowed step; and the label travels {@link ScreenArt#SINK} down and
     * right into the well. Whole pixels, one frame, no tween.
     *
     * @param batch   the screen's batch, already begun
     * @param x       the plate's left edge, frame included, in design pixels
     * @param y       the plate's top edge, frame included, in design pixels measured downward
     * @param w       the plate's width, frame included
     * @param h       the plate's height, frame included
     * @param text    the label, centred; empty for none
     * @param style   which face to draw
     * @param pressed whether the plate is held down
     */
    void plate(Batch batch, int x, int y, int w, int h, String text, Plate style,
               boolean pressed) {
        int face;
        int light;
        int dark;
        int label;
        float labelAlpha = 1f;
        switch (style) {
            case GOLD -> {
                face = pressed ? ScreenArt.GOLD_PRESSED : ScreenArt.GOLD;
                light = ScreenArt.GOLD_LIGHT;
                dark = ScreenArt.GOLD_DARK;
                label = ScreenArt.GOLD_LABEL;
            }
            case DARK -> {
                face = pressed ? ScreenArt.DARK_PRESSED : ScreenArt.DARK;
                light = ScreenArt.DARK_LIGHT;
                dark = ScreenArt.DARK_DARK;
                label = ScreenArt.DARK_LABEL;
                labelAlpha = ScreenArt.DARK_LABEL_ALPHA;
            }
            default -> {
                // Spent: the plate is there but dead, so the bevel goes flat.
                face = HudArt.TICK_DIM;
                light = ScreenArt.FRAME;
                dark = ScreenArt.FRAME;
                label = BoardArt.NAME_COLOUR;
            }
        }
        int t = ScreenArt.THICK;
        int travel = pressed ? ScreenArt.SINK : 0;
        frame(batch, x, y, w, h);
        face(batch, x + t, y + t, w - 2 * t, h - 2 * t, face);
        bevel(batch, x + t, y + t, w - 2 * t, h - 2 * t,
                pressed ? dark : light, pressed ? light : dark);
        centred(batch, theme.pixelLabel, text, x + travel, y + travel, w, h, label, labelAlpha);
    }

    /**
     * A MUSIC or SOUND plate on the title: the dark plate with its label on the
     * left rather than centred, and its level as three pips on the right. Still
     * the one button shape — {@link #plate} draws it, with no label of its own —
     * and it sinks like any other, the label and the pips going down together.
     *
     * @param batch   the screen's batch, already begun
     * @param x       the plate's left edge, in design pixels; the row's y is fixed
     * @param text    {@code MUSIC} or {@code SOUND}
     * @param level   the level the pips show, 0 to 3
     * @param muted   whether M has silenced everything, which dims the lit pips
     * @param pressed whether the plate is held down
     */
    void levelPlate(Batch batch, int x, String text, int level, boolean muted, boolean pressed) {
        int y = ScreenArt.AUDIO_Y;
        plate(batch, x, y, ScreenArt.AUDIO_W, ScreenArt.AUDIO_H, "", Plate.DARK, pressed);
        int travel = pressed ? ScreenArt.SINK : 0;
        layout.setText(theme.pixelLabel, text);
        int top = y + Math.round((ScreenArt.AUDIO_H - layout.height) / 2f);
        text(batch, theme.pixelLabel, text, x + 2 * ScreenArt.THICK + ScreenArt.AUDIO_PAD + travel,
                top + travel, ScreenArt.DARK_LABEL, ScreenArt.DARK_LABEL_ALPHA);
        for (int pip = 0; pip < ScreenArt.PIPS; pip++) {
            face(batch, ScreenArt.pipX(x, pip) + travel, ScreenArt.pipY() + travel,
                    ScreenArt.PIP_W, ScreenArt.PIP_H, ScreenArt.pipColour(pip, level, muted));
        }
    }

    /**
     * The band every screen but the title carries: the screen's name, a caption
     * beside it on the same baseline, {@code ESC · BACK} on the right, and a
     * rule along the foot. Four screens share it, so it is drawn once here.
     *
     * @param batch   the screen's batch, already begun
     * @param name    the screen's name, upper-cased
     * @param caption the line beside it, e.g. how many runs the ledger holds
     */
    void header(Batch batch, String name, String caption) {
        header(batch, name, caption, false);
    }

    /**
     * As above, with the back plate held down.
     *
     * @param batch       the screen's batch, already begun
     * @param name        the screen's name, upper-cased
     * @param caption     the line beside it
     * @param backPressed whether the back plate is held down
     */
    void header(Batch batch, String name, String caption, boolean backPressed) {
        text(batch, theme.pixelTitle, name, ScreenArt.HEADER_X,
                ScreenArt.HEADER_TITLE_TOP, ScreenArt.BODY);
        int after = ScreenArt.HEADER_X + width(theme.pixelTitle, name)
                + ScreenArt.HEADER_CAPTION_GAP;
        text(batch, theme.pixelLabel, caption, after, ScreenArt.HEADER_CAPTION_TOP,
                ScreenArt.HEADER_CAPTION);
        plate(batch, ScreenArt.BACK_X, ScreenArt.BACK_Y, ScreenArt.BACK_W,
                ScreenArt.BACK_H, "ESC · BACK", Plate.DARK, backPressed);
        rule(batch, 0, ScreenArt.HEADER_H, (int) Theme.WORLD_WIDTH);
    }

    /**
     * A question over the modal dim: a heading in dried blood, two lines saying
     * exactly what is lost, and two plates. The safe choice is the gold one —
     * the opposite of how the rest of the game uses gold, and deliberate: the
     * prominent choice is the one that loses nothing. {@code sunk} is the index
     * of the plate held down, as {@link ScreenArt#dialogButtonAt} numbers them.
     *
     * <p>Whatever is behind goes under the dim first — the dialog asks about the
     * very thing behind it, so that has to stop competing with it.
     *
     * @param batch   the screen's batch, already begun
     * @param heading the question, upper-cased
     * @param first   the first line: what will be lost
     * @param second  the second line
     * @param keep    the safe plate's label, on gold, index 0
     * @param proceed the destructive plate's label, on dark, index 1
     * @param sunk    the index of the plate held down, or {@link PressGesture#NONE}
     */
    void confirmation(Batch batch, String heading, String first, String second,
                      String keep, String proceed, int sunk) {
        dim(batch);
        int x = ScreenArt.dialogX();
        int y = ScreenArt.DIALOG_Y;
        frame(batch, x, y, ScreenArt.DIALOG_W, ScreenArt.DIALOG_H);
        face(batch, x + ScreenArt.THICK, y + ScreenArt.THICK,
                ScreenArt.DIALOG_W - 2 * ScreenArt.THICK, ScreenArt.DIALOG_H - 2 * ScreenArt.THICK,
                ScreenArt.FACE_PANEL);

        int centre = (int) (Theme.WORLD_WIDTH / 2);
        centredOn(batch, theme.pixelBody, heading, centre, y + ScreenArt.DIALOG_HEADING_DY,
                ScreenArt.OUTCOME_LOST, 1f);
        centredOn(batch, theme.pixelLabel, first, centre, y + ScreenArt.DIALOG_LINE_DY,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);
        centredOn(batch, theme.pixelLabel, second, centre,
                y + ScreenArt.DIALOG_LINE_DY + ScreenArt.DIALOG_LINE_GAP,
                ScreenArt.BODY, ScreenArt.BODY_ALPHA);

        plate(batch, ScreenArt.dialogButtonX(0), ScreenArt.DIALOG_BUTTON_Y,
                ScreenArt.DIALOG_BUTTON_W, ScreenArt.BUTTON_H, keep, Plate.GOLD, sunk == 0);
        plate(batch, ScreenArt.dialogButtonX(1), ScreenArt.DIALOG_BUTTON_Y,
                ScreenArt.DIALOG_BUTTON_W, ScreenArt.BUTTON_H, proceed, Plate.DARK, sunk == 1);
    }

    // --- text --------------------------------------------------------------

    /**
     * Text placed by its top, which is what a Batch draw takes.
     *
     * @param batch the screen's batch, already begun; the font's colour is left white
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param x     its left edge, in design pixels
     * @param top   its top, in design pixels measured downward
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void text(Batch batch, BitmapFont font, String s, int x, int top, int rgb, float alpha) {
        font.setColor(rgb(rgb, alpha));
        font.draw(batch, s, x, CardArt.toWorldY(top, 0));
        font.setColor(Color.WHITE);
    }

    /**
     * Text placed by its top, opaque.
     *
     * @param batch the screen's batch, already begun
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param x     its left edge, in design pixels
     * @param top   its top, in design pixels measured downward
     * @param rgb   the colour, {@code 0xRRGGBB}
     */
    void text(Batch batch, BitmapFont font, String s, int x, int top, int rgb) {
        text(batch, font, s, x, top, rgb, 1f);
    }

    /**
     * Right-aligned against an edge — the column a table's numbers end on.
     *
     * @param batch the screen's batch, already begun
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param right the edge it ends on, in design pixels
     * @param top   its top, in design pixels measured downward
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void textRight(Batch batch, BitmapFont font, String s, int right, int top,
                   int rgb, float alpha) {
        layout.setText(font, s);
        text(batch, font, s, right - Math.round(layout.width), top, rgb, alpha);
    }

    /**
     * Left-aligned at {@code x} and centred down a row — how a table cell sits.
     * The row's height is what centres it, not the font's, so cells set in
     * different sizes still share one optical line.
     *
     * @param batch the screen's batch, already begun
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param x     its left edge, in design pixels
     * @param y     the row's top edge, in design pixels measured downward
     * @param h     the row's height
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void textInRow(Batch batch, BitmapFont font, String s, int x, int y, int h,
                   int rgb, float alpha) {
        layout.setText(font, s);
        text(batch, font, s, x, y + Math.round((h - layout.height) / 2f), rgb, alpha);
    }

    /**
     * The same, ending on an edge — the column a table's numbers line up against.
     *
     * @param batch the screen's batch, already begun
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param right the edge it ends on, in design pixels
     * @param y     the row's top edge, in design pixels measured downward
     * @param h     the row's height
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void textRightInRow(Batch batch, BitmapFont font, String s, int right, int y, int h,
                        int rgb, float alpha) {
        layout.setText(font, s);
        text(batch, font, s, right - Math.round(layout.width),
                y + Math.round((h - layout.height) / 2f), rgb, alpha);
    }

    /**
     * Centred in a box, horizontally and vertically — how a label sits on a plate.
     *
     * @param batch the screen's batch, already begun
     * @param font  one of the theme's Silkscreen faces
     * @param s     the text
     * @param x     the box's left edge, in design pixels
     * @param y     the box's top edge, in design pixels measured downward
     * @param w     the box's width
     * @param h     the box's height
     * @param rgb   the colour, {@code 0xRRGGBB}
     * @param alpha how opaque, 0 to 1
     */
    void centred(Batch batch, BitmapFont font, String s, int x, int y, int w, int h,
                 int rgb, float alpha) {
        layout.setText(font, s);
        int left = x + Math.round((w - layout.width) / 2f);
        int top = y + Math.round((h - layout.height) / 2f);
        text(batch, font, s, left, top, rgb, alpha);
    }

    /**
     * Centred on a vertical line, for a caption under a well.
     *
     * @param batch   the screen's batch, already begun
     * @param font    one of the theme's Silkscreen faces
     * @param s       the text
     * @param centreX the line it centres on, in design pixels
     * @param top     its top, in design pixels measured downward
     * @param rgb     the colour, {@code 0xRRGGBB}
     * @param alpha   how opaque, 0 to 1
     */
    void centredOn(Batch batch, BitmapFont font, String s, int centreX, int top,
                   int rgb, float alpha) {
        layout.setText(font, s);
        text(batch, font, s, centreX - Math.round(layout.width / 2f), top, rgb, alpha);
    }

    /**
     * How wide a string sets in a font.
     *
     * @param font one of the theme's Silkscreen faces
     * @param s    the text
     * @return its width, in whole pixels
     */
    int width(BitmapFont font, String s) {
        layout.setText(font, s);
        return Math.round(layout.width);
    }

    private Color rgb(int rgb, float alpha) {
        tint.set((rgb >>> 16 & 0xff) / 255f, (rgb >>> 8 & 0xff) / 255f,
                (rgb & 0xff) / 255f, alpha);
        return tint;
    }
}
