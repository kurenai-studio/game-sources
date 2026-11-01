package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.tomer.scoundrel.model.CardType;

/**
 * Draws the card frame — outer bezel, plate, the two 2px bevels and the
 * recessed well the sprite sits in.
 *
 * <p>Everything is a tinted rectangle on a single white pixel, so the whole card
 * is one texture and never breaks the batch. All measurements come from
 * {@link CardArt}; this class only converts them to draw calls, which is why it
 * has no arithmetic worth testing and {@code CardArt} has all of it.
 */
final class CardFrame {

    private final TextureRegion pixel;
    private final Color tint = new Color();

    /**
     * A frame drawer on the theme's single white pixel.
     *
     * @param theme where the white pixel comes from
     */
    CardFrame(Theme theme) {
        this.pixel = theme.whiteRegion();
    }

    /**
     * Draws one card with its top-left at the design-space point
     * {@code (slotX, slotY)} — y measured downward, as the art is specified.
     *
     * @param batch the board's batch, already begun; its colour is restored after each fill
     * @param type  the card's type, which picks the palette
     * @param slotX the card's left edge, in design pixels
     * @param slotY the card's top edge, in design pixels measured downward
     */
    void draw(Batch batch, CardType type, int slotX, int slotY) {
        draw(batch, type, slotX, slotY, CardArt.CARD_W, CardArt.CARD_H);
    }

    /**
     * The same card at a reduced size, for one in flight. Every measurement is
     * scaled by the same ratio and rounded, so a shrinking card keeps its
     * proportions and stays on whole pixels at each hop — it is only ever drawn
     * at a handful of discrete sizes, never tweened between them.
     *
     * @param batch  the board's batch, already begun
     * @param type   the card's type, which picks the palette
     * @param slotX  the card's left edge, in design pixels
     * @param slotY  the card's top edge, in design pixels measured downward
     * @param width  the card's width at this size, in design pixels
     * @param height the card's height at this size, in design pixels
     */
    void draw(Batch batch, CardType type, int slotX, int slotY, int width, int height) {
        CardArt.Palette palette = CardArt.paletteFor(type);
        float sx = width / (float) CardArt.CARD_W;
        float sy = height / (float) CardArt.CARD_H;
        int frame = Math.max(1, Math.round(CardArt.FRAME * sx));
        int bevel = Math.max(1, Math.round(CardArt.BEVEL * sx));

        // The bezel every card sits in, then the plate inset inside it.
        fill(batch, slotX, slotY, width, height, CardArt.OUTER);
        int plateX = slotX + frame;
        int plateY = slotY + frame;
        int plateW = width - 2 * frame;
        int plateH = height - 2 * frame;
        fill(batch, plateX, plateY, plateW, plateH, palette.plate());

        // Bevels: light along the top and left, dark along the bottom and right,
        // so the plate reads as raised. Each is CardArt.BEVEL, scaled with the
        // card, and they stop short of each other's corner.
        fill(batch, plateX, plateY, plateW - bevel, bevel, palette.light());
        fill(batch, plateX, plateY, bevel, plateH - bevel, palette.light());
        fill(batch, plateX + bevel, plateY + plateH - bevel, plateW - bevel, bevel, palette.dark());
        fill(batch, plateX + plateW - bevel, plateY + bevel, bevel, plateH - bevel, palette.dark());

        // The well, recessed by a hard shadow along its top edge and the faintest
        // cream lip along its bottom.
        int wellX = slotX + Math.round((CardArt.wellLeft(0)) * sx);
        int wellY = slotY + Math.round((CardArt.wellTop() - CardArt.SLOT_Y) * sy);
        int wellW = Math.round(CardArt.wellWidth() * sx);
        int wellH = Math.round(CardArt.WELL_H * sy);
        fill(batch, wellX, wellY, wellW, wellH, palette.well());
        fill(batch, wellX, wellY, wellW, 2, 0x000000, 0.6f);
        fill(batch, wellX, wellY + wellH - 2, wellW, 2, 0xe8ddc7, 0.05f);

        // The hairline above the value numeral in the footer.
        fill(batch, plateX + Math.round(6 * sx), wellY + wellH,
                plateW - Math.round(12 * sx), 2, 0x000000, 0.55f);
    }

    private void fill(Batch batch, int x, int y, int w, int h, int rgb) {
        fill(batch, x, y, w, h, rgb, 1f);
    }

    /** {@code y} arrives in design space and is flipped once, here. */
    private void fill(Batch batch, int x, int y, int w, int h, int rgb, float alpha) {
        tint.set((rgb >>> 16 & 0xff) / 255f, (rgb >>> 8 & 0xff) / 255f, (rgb & 0xff) / 255f, alpha);
        Color previous = batch.getColor().cpy();
        batch.setColor(tint);
        batch.draw(pixel, x, CardArt.toWorldY(y, h), w, h);
        batch.setColor(previous);
    }
}
