package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.CardType;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The card frame's measurements and palette, in the 1280×720 design space the
 * art is specified in. Pinned here because every one of these numbers is a
 * hand-set constant that a screenshot would only catch if someone happened to
 * look at the right two pixels.
 */
class CardArtTest {

    /** The four slots' left edges are at 252, 452, 652 and 852. */
    @Test
    void theFourSlotsSitOnTheSpecifiedPitch() {
        assertEquals(252, CardArt.slotX(0));
        assertEquals(452, CardArt.slotX(1));
        assertEquals(652, CardArt.slotX(2));
        assertEquals(852, CardArt.slotX(3));
    }

    /** The row's top edge is at y=214. */
    @Test
    void theRowSitsWhereTheReferenceRenderPutsIt() {
        assertEquals(214, CardArt.SLOT_Y);
    }

    /** A row of four is centred on the stage. */
    @Test
    void theRowOfFourIsCentredInTheWorld() {
        int left = CardArt.slotX(0);
        int right = (int) Theme.WORLD_WIDTH - (CardArt.slotX(3) + CardArt.CARD_W);
        assertEquals(left, right, "row should be symmetric, was " + left + " vs " + right);
    }

    /** Neighbouring cards are 24px apart. */
    @Test
    void theGapBetweenCardsIsTwentyFour() {
        assertEquals(24, CardArt.slotX(1) - (CardArt.slotX(0) + CardArt.CARD_W));
    }

    /** Each card type has its own plate, well and label colours. */
    @Test
    void eachCardTypeCarriesItsOwnRamp() {
        CardArt.Palette monster = CardArt.paletteFor(CardType.MONSTER);
        assertEquals(0x230d16, monster.plate());
        assertEquals(0x4f1d1e, monster.light());
        assertEquals(0x12060f, monster.dark());
        assertEquals(0x0e050c, monster.well());
        assertEquals(0xa85338, monster.label());

        assertEquals(0x141a24, CardArt.paletteFor(CardType.WEAPON).plate());
        assertEquals(0x070a10, CardArt.paletteFor(CardType.WEAPON).well());
        assertEquals(0x17281a, CardArt.paletteFor(CardType.POTION).plate());
        assertEquals(0x71b45c, CardArt.paletteFor(CardType.POTION).label());
    }

    /** Every card type has a palette. */
    @Test
    void everyTypeHasAPalette() {
        for (CardType type : CardType.values()) {
            assertTrue(CardArt.paletteFor(type) != null, "no palette for " + type);
        }
    }

    /**
     * The plate is inset 2px inside the outer frame, so the 26px header runs
     * from y=2 to y=28 and the well starts at SLOT_Y+28 — not SLOT_Y+26, which
     * would leave the frame out.
     */
    @Test
    void theWellSitsBelowTheHeaderInsideTheFrame() {
        assertEquals(CardArt.SLOT_Y + 28, CardArt.wellTop());
        assertEquals(140, CardArt.WELL_H);
        assertEquals(CardArt.slotX(0) + 8, CardArt.wellLeft(CardArt.slotX(0)));
        assertEquals(160, CardArt.wellWidth());
    }

    /** The sprite is centred in its well, both ways. */
    @Test
    void theSpriteIsCentredInTheWell() {
        int slot = CardArt.slotX(2);
        int left = CardArt.spriteLeft(slot);
        int right = CardArt.wellLeft(slot) + CardArt.wellWidth() - (left + CardArt.SPRITE);
        assertEquals(left - CardArt.wellLeft(slot), right, "sprite not horizontally centred");

        int top = CardArt.spriteTop() - CardArt.wellTop();
        int bottom = CardArt.WELL_H - CardArt.SPRITE - top;
        assertEquals(top, bottom, "sprite not vertically centred");
    }

    /** The sprite is 128px wide at even offsets, so each source pixel lands whole at ×2. */
    @Test
    void theSpriteLandsOnWholePixelsAtTimesTwo() {
        // 64x64 drawn at x2. If any of these offsets were odd the art would sit
        // half a source pixel off the grid.
        assertEquals(128, CardArt.SPRITE);
        for (int i = 0; i < 4; i++) {
            assertEquals(0, CardArt.spriteLeft(CardArt.slotX(i)) % 2,
                    "odd sprite x in slot " + i);
        }
        assertEquals(0, CardArt.spriteTop() % 2, "odd sprite y");
    }

    /**
     * The art is specified with y downward from the top of the screen; the
     * viewport measures upward from the bottom. Getting this backwards silently
     * flips the whole board, so it is converted in exactly one place.
     */
    @Test
    void designSpaceConvertsToWorldCoordinates() {
        assertEquals(720 - 0 - 256, CardArt.toWorldY(0, 256));
        assertEquals(720 - CardArt.SLOT_Y - CardArt.CARD_H,
                CardArt.toWorldY(CardArt.SLOT_Y, CardArt.CARD_H));
        // A full-height element starts at the world origin.
        assertEquals(0, CardArt.toWorldY(0, 720));
    }
}
