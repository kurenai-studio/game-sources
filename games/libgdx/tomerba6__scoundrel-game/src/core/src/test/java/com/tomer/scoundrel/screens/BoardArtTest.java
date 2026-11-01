package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The furniture around the cards — the card's own header and value, the trophy
 * rail, the potion marker and the feed. Pinning every number here is the only
 * way a wrong one gets caught: on screen a six-pixel error looks like a design
 * choice.
 */
class BoardArtTest {

    /** The rail well is an 80px box at (24, 610). */
    @Test
    void theRailWellMatchesTheReference() {
        assertEquals(24, BoardArt.RAIL_X);
        assertEquals(610, BoardArt.RAIL_Y);
        assertEquals(80, BoardArt.RAIL_BOX);
    }

    /**
     * The rail weapon is drawn at ×1 and centred in its well: 72px would be
     * ×1.125 of a 64px sprite, giving some source pixels one screen pixel and
     * their neighbours two.
     */
    @Test
    void theRailIconIsDrawnAtTimesOneAndCentredInItsWell() {
        assertEquals(Sprites.SIZE, BoardArt.RAIL_ICON);
        int left = BoardArt.railIconX() - (BoardArt.RAIL_X + BoardArt.FRAME);
        int right = BoardArt.RAIL_BOX - 2 * BoardArt.FRAME - BoardArt.RAIL_ICON - left;
        assertEquals(left, right, "rail icon not horizontally centred");
        int top = BoardArt.railIconY() - (BoardArt.RAIL_Y + BoardArt.FRAME);
        int bottom = BoardArt.RAIL_BOX - 2 * BoardArt.FRAME - BoardArt.RAIL_ICON - top;
        assertEquals(top, bottom, "rail icon not vertically centred");
    }

    /** Slain chips run right from x=116 on a 26px pitch, 4px apart. */
    @Test
    void slainChipsMarchRightOnTheirOwnPitch() {
        assertEquals(116, BoardArt.chipX(0));
        assertEquals(142, BoardArt.chipX(1));
        assertEquals(168, BoardArt.chipX(2));
        // 22 wide on a 26 pitch leaves a 4px gap.
        assertEquals(4, BoardArt.chipX(1) - (BoardArt.chipX(0) + BoardArt.CHIP_W));
    }

    /**
     * The degradation plate follows the chips, so it moves right as the weapon
     * takes kills. Two chips put it at 176.
     */
    @Test
    void theSlaysPlateFollowsTheChips() {
        assertEquals(176, BoardArt.slaysPlateX(2));
        assertTrue(BoardArt.slaysPlateX(0) < BoardArt.slaysPlateX(1),
                "the plate should move right as chips are added");
        assertEquals(BoardArt.CHIP_PITCH,
                BoardArt.slaysPlateX(3) - BoardArt.slaysPlateX(2));
    }

    /** A fresh weapon has no chips, and the plate must not overlap the column. */
    @Test
    void theSlaysPlateClearsTheColumnWithNoChips() {
        assertTrue(BoardArt.slaysPlateX(0) >= BoardArt.COLUMN_X,
                "plate should not sit left of the rail column");
    }

    /** Feed lines stack downward from below the Avoid button, a pitch apart. */
    @Test
    void theFeedStacksDownwardFromUnderTheAvoidButton() {
        assertTrue(BoardArt.feedLineY(0) > HudArt.AVOID_Y + HudArt.AVOID_H,
                "the feed must clear the Avoid button");
        assertEquals(BoardArt.FEED_PITCH, BoardArt.feedLineY(1) - BoardArt.feedLineY(0));
        assertEquals(BoardArt.FEED_PITCH * 3, BoardArt.feedLineY(3) - BoardArt.feedLineY(0));
    }

    /** The feed is right-aligned, so it never runs under the room. */
    @Test
    void theFeedHangsOffTheRightMargin() {
        assertEquals(1256, BoardArt.FEED_RIGHT);
        assertTrue(BoardArt.FEED_RIGHT < Theme.WORLD_WIDTH, "feed must stay on screen");
    }

    /**
     * The header's rank and type sit 8px in from the card's edges, and the pip
     * is centred in the header.
     */
    @Test
    void theCardHeaderSitsInsideThePlatePadding() {
        int slot = CardArt.slotX(1);
        // 2px frame then the header's 6px padding.
        assertEquals(slot + 8, BoardArt.rankX(slot));
        assertEquals(slot + CardArt.CARD_W - 8, BoardArt.typeRightX(slot));
        // The pip is centred in the 26px header.
        int inset = BoardArt.pipY() - (CardArt.SLOT_Y + CardArt.FRAME);
        assertEquals(CardArt.HEADER_H - BoardArt.PIP - inset, inset,
                "pip not vertically centred in the header");
    }

    /** The value numeral is centred on its card. */
    @Test
    void theValueNumeralIsCentredOnTheCard() {
        for (int i = 0; i < 4; i++) {
            int slot = CardArt.slotX(i);
            assertEquals(slot + CardArt.CARD_W / 2, BoardArt.valueCentreX(slot));
        }
    }

    /**
     * The numeral's drop shadow is a 4px hard offset, not a blur — it sits
     * below the glyph and nowhere else.
     */
    @Test
    void theValueShadowIsAWholeFourPixelsBelow() {
        assertEquals(4, BoardArt.VALUE_SHADOW_DY);
    }

    /** The marker's icon is a clean halving of the 64px sprite. */
    @Test
    void thePotionMarkerHalvesTheSprite() {
        assertEquals(Sprites.SIZE / 2, BoardArt.MARKER_ICON);
        assertEquals(0, Sprites.SIZE % BoardArt.MARKER_ICON);
        int inset = BoardArt.markerIconX() - BoardArt.MARKER_X;
        assertEquals(BoardArt.MARKER_BOX - BoardArt.MARKER_ICON - inset, inset,
                "marker icon not centred in its box");
    }

    /**
     * The two icons on the bottom strip share a centre line. The chips do not:
     * they are the lower half of a two-row column beside the rail, so their row
     * sits below it — the plate is what lines up with them.
     */
    @Test
    void theBottomStripIsOnOneCentreLine() {
        int rail = BoardArt.RAIL_Y + BoardArt.RAIL_BOX / 2;
        assertEquals(rail, BoardArt.MARKER_Y + BoardArt.MARKER_BOX / 2);
        assertEquals(BoardArt.CHIP_Y + BoardArt.CHIP_H / 2,
                BoardArt.PLATE_Y + BoardArt.PLATE_H / 2);
    }
}
