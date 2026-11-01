package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.tomer.scoundrel.model.Card;

/**
 * What is printed on a card: the rank and suit pip in its header, the type
 * stamped opposite them, and the value numeral filling the footer under the
 * well.
 *
 * <p>Text is placed by measuring it rather than by a hand-tuned baseline, so a
 * one-glyph rank and a two-glyph one sit on the same line and the numeral is
 * centred whatever the font's own metrics are. All the positions come from
 * {@link BoardArt}; the arithmetic worth testing is there.
 */
final class CardFace {

    private final Theme theme;
    private final Pips pips;
    private final GlyphLayout layout = new GlyphLayout();
    private final Color tint = new Color();

    /**
     * A printer sharing the screen's fonts and pip regions.
     *
     * @param theme where the Silkscreen fonts come from
     * @param pips  the suit pips, one per suit
     */
    CardFace(Theme theme, Pips pips) {
        this.theme = theme;
        this.pips = pips;
    }

    /**
     * The card's printing, at a card whose top-left is the design-space slot.
     *
     * @param batch the board's batch, already begun; font and batch colours are left white
     * @param card  the card to print
     * @param slotX the card's left edge, in 1280×720 design pixels
     * @param slotY the card's top edge, in design pixels measured down from the top
     */
    void draw(Batch batch, Card card, int slotX, int slotY) {
        CardArt.Palette palette = CardArt.paletteFor(card.type());
        drawHeader(batch, card, slotX, slotY, palette);
        drawValue(batch, card, slotX, slotY);
    }

    private void drawHeader(Batch batch, Card card, int slotX, int slotY,
                            CardArt.Palette palette) {
        BitmapFont rankFont = theme.pixelLabel;
        String rank = Labels.rank(card.value());
        layout.setText(rankFont, rank);
        int rankW = Math.round(layout.width);
        int top = headerTop(slotY, layout.height);

        setColour(rankFont, BoardArt.VALUE_COLOUR);
        int rankX = BoardArt.rankX(slotX);
        rankFont.draw(batch, rank, rankX, CardArt.toWorldY(top, 0));

        // The pip sits a fixed gap after the rank, centred in the header band.
        int pipX = rankX + rankW + BoardArt.PIP_GAP;
        int pipY = slotY + (BoardArt.pipY() - CardArt.SLOT_Y);
        batch.setColor(colour(BoardArt.VALUE_COLOUR, 1f));
        batch.draw(pips.forCard(card), pipX, CardArt.toWorldY(pipY, Pips.SIZE),
                Pips.SIZE, Pips.SIZE);
        batch.setColor(Color.WHITE);

        // The type is right-aligned against the far padding, in the card's own
        // label colour — the only place each ramp names itself.
        BitmapFont typeFont = theme.pixelLabel;
        String type = Labels.cardType(card.type());
        layout.setText(typeFont, type);
        setColour(typeFont, palette.label());
        typeFont.draw(batch, type, BoardArt.typeRightX(slotX) - layout.width,
                CardArt.toWorldY(headerTop(slotY, layout.height), 0));
        typeFont.setColor(Color.WHITE);
        rankFont.setColor(Color.WHITE);
    }

    /** Vertically centred in the 26px header band, inside the frame. */
    private static int headerTop(int slotY, float textHeight) {
        return slotY + CardArt.FRAME + Math.round((CardArt.HEADER_H - textHeight) / 2f);
    }

    /**
     * The value, centred under the well with a hard four-pixel shadow. Not a
     * blur: the same glyphs drawn twice, four whole pixels apart.
     */
    private void drawValue(Batch batch, Card card, int slotX, int slotY) {
        BitmapFont font = theme.pixelDisplay;
        String value = String.valueOf(card.value());
        layout.setText(font, value);
        int x = BoardArt.valueCentreX(slotX) - Math.round(layout.width / 2f);
        int top = slotY + BoardArt.VALUE_BOTTOM - Math.round(layout.height);

        setColour(font, BoardArt.VALUE_SHADOW, BoardArt.VALUE_SHADOW_ALPHA);
        font.draw(batch, value, x, CardArt.toWorldY(top + BoardArt.VALUE_SHADOW_DY, 0));
        setColour(font, BoardArt.VALUE_COLOUR);
        font.draw(batch, value, x, CardArt.toWorldY(top, 0));
        font.setColor(Color.WHITE);
    }

    private void setColour(BitmapFont font, int rgb) {
        setColour(font, rgb, 1f);
    }

    private void setColour(BitmapFont font, int rgb, float alpha) {
        font.setColor(colour(rgb, alpha));
    }

    private Color colour(int rgb, float alpha) {
        tint.set((rgb >>> 16 & 0xff) / 255f, (rgb >>> 8 & 0xff) / 255f,
                (rgb & 0xff) / 255f, alpha);
        return tint;
    }
}
