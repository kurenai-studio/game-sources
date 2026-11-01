package com.tomer.scoundrel.screens;

import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Disposable;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;

/**
 * The four suit pips beside a card's rank, as 12×12 masks tinted at draw time.
 *
 * <p>The shapes themselves live in {@link PipMask}, which is pure and checked
 * row by row: at this size the geometry <em>is</em> the artwork, and it is much
 * easier to see that a pip is wrong in a list of row widths than in a texture.
 * All this class does is upload them.
 */
final class Pips implements Disposable {

    /** The size a pip is drawn at, in pixels. */
    static final int SIZE = PipMask.SIZE;

    private final Texture[] textures = new Texture[PipMask.Suit.values().length];
    private final TextureRegion[] regions = new TextureRegion[textures.length];

    /** Builds one white, {@code Nearest}-filtered texture per suit, to be tinted when drawn. */
    Pips() {
        for (PipMask.Suit suit : PipMask.Suit.values()) {
            build(suit);
        }
    }

    private void build(PipMask.Suit suit) {
        boolean[] mask = PipMask.generate(suit);
        Pixmap pixmap = new Pixmap(SIZE, SIZE, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.None);
        for (int y = 0; y < SIZE; y++) {
            for (int x = 0; x < SIZE; x++) {
                pixmap.drawPixel(x, y, mask[y * SIZE + x] ? 0xffffffff : 0x00000000);
            }
        }
        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        textures[suit.ordinal()] = texture;
        regions[suit.ordinal()] = new TextureRegion(texture);
    }

    /**
     * The pip for a card: monsters carry their real suit, read from the id the
     * same way the sprite is; weapons are diamonds and potions hearts, which is
     * what they are in the deck.
     *
     * @param card the card being printed
     * @return its suit's {@link #SIZE}-pixel pip, white, owned by this object
     */
    TextureRegion forCard(Card card) {
        if (card.type() == CardType.MONSTER) {
            return regions[(card.id().endsWith("C")
                    ? PipMask.Suit.CLUBS : PipMask.Suit.SPADES).ordinal()];
        }
        return regions[(card.type() == CardType.WEAPON
                ? PipMask.Suit.DIAMONDS : PipMask.Suit.HEARTS).ordinal()];
    }

    @Override
    public void dispose() {
        for (Texture texture : textures) {
            texture.dispose();
        }
    }
}
