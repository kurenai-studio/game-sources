package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The board HUD's measurements. Pinned here because they are hand-set constants
 * that a screenshot would only catch if someone looked at exactly the right
 * pixel.
 */
class HudArtTest {

    /** The health bar is 216×24 at (24, 34), with a 212×20 interior inside its 2px frame. */
    @Test
    void theHealthBarMatchesTheReference() {
        assertEquals(24, HudArt.BAR_X);
        assertEquals(34, HudArt.BAR_Y);
        assertEquals(216, HudArt.BAR_W);
        assertEquals(24, HudArt.BAR_H);
        // 2px frame all round leaves the interior the fill runs in.
        assertEquals(212, HudArt.barInteriorWidth());
        assertEquals(20, HudArt.barInteriorHeight());
    }

    /**
     * The fill is proportional, not one segment per point of health — the
     * separators are an overlay on top of a continuous bar. At 14 of 20 it fills
     * to x=174, which is 148px of the 212 available.
     */
    @Test
    void theFillIsProportionalAndMatchesTheReferenceAtFourteenOfTwenty() {
        assertEquals(148, HudArt.barFillWidth(14, 20));
        assertEquals(0, HudArt.barFillWidth(0, 20));
        assertEquals(212, HudArt.barFillWidth(20, 20));
    }

    /** The fill clamps to the bar for health above the cap or below zero. */
    @Test
    void theFillNeverOverrunsOrGoesNegative() {
        assertEquals(212, HudArt.barFillWidth(25, 20), "over-full health should clamp");
        assertEquals(0, HudArt.barFillWidth(-7, 20), "a negative score should not draw backwards");
    }

    /** The interior is banded 6, 8 and 6px, filling its 20px. */
    @Test
    void theBarIsBandedInThreeStripes() {
        // 6 / 8 / 6 of the 20px interior, lightest at the top.
        assertEquals(6, HudArt.BAND_TOP);
        assertEquals(8, HudArt.BAND_MID);
        assertEquals(6, HudArt.BAND_LOW);
        assertEquals(HudArt.barInteriorHeight(), HudArt.BAND_TOP + HudArt.BAND_MID + HudArt.BAND_LOW);
    }

    /** The spent track is a lipped recess, not an unlit copy of the fill. */
    @Test
    void theEmptyTrackIsFlatUnderALip() {
        assertEquals(2, HudArt.BAR_LIP_H);
        assertEquals(0x3b4334, HudArt.BAR_EMPTY_LIP);
        assertEquals(0x1e2a1c, HudArt.BAR_EMPTY);
    }

    /** Separators are translucent 2px lines on a 10px pitch. */
    @Test
    void separatorsSitOnATenPixelPitch() {
        assertEquals(10, HudArt.SEGMENT_PITCH);
        assertEquals(2, HudArt.SEGMENT_GAP);
        // Translucent, so one line reads correctly over both the lit fill
        // and the spent track rather than needing a colour for each.
        assertEquals(0x2d3029, HudArt.SEGMENT_LINE);
        assertTrue(HudArt.SEGMENT_ALPHA > 0.79f && HudArt.SEGMENT_ALPHA < 0.81f);
    }

    /** One tick per card left in the dungeon, so the ticker is a real gauge. */
    @Test
    void theDepthTickerIsOneTickPerCard() {
        assertEquals(4, HudArt.TICK_PITCH);
        assertEquals(2, HudArt.TICK_W);
        assertEquals(27, HudArt.ticksLit(27));
        assertEquals(0, HudArt.ticksLit(0));
    }

    /**
     * The lit block is the thing you read, so it is what stays centred — not the
     * whole strip. The dim tail runs off to the right and the strip's left edge
     * walks right as the dungeon drains.
     */
    @Test
    void theLitTicksStayCentredAsTheDungeonDrains() {
        for (int depth : new int[] {44, 27, 12, 1}) {
            int left = HudArt.tickerX(depth);
            int right = left + HudArt.tickerWidth(depth);
            assertEquals(Theme.WORLD_WIDTH / 2f, (left + right) / 2f, 0.5f,
                    "the lit block should be centred at depth " + depth);
        }
    }

    /** A shallower dungeon puts the ticker strip further right. */
    @Test
    void theStripWalksRightAsItDrains() {
        assertTrue(HudArt.tickerX(20) > HudArt.tickerX(44),
                "a shallower dungeon puts the strip further right");
    }

    /** The ticker strip, full or empty, stays on the stage and clear of the Avoid plate. */
    @Test
    void theTickerFitsTheWholeDungeonInsideTheStage() {
        int width = HudArt.tickerWidth(44);
        assertEquals(44 * 4 - 2, width);
        // Deepest is furthest left, shallowest furthest right; the whole strip
        // is always drawn, so both ends have to clear the stage and the Avoid
        // plate beyond it.
        assertTrue(HudArt.tickerX(44) >= 0, "a full dungeon should not run off the left");
        assertTrue(HudArt.tickerX(0) + width < HudArt.AVOID_X,
                "an empty dungeon should not reach the Avoid plate");
    }

    /**
     * The whole button, frame included — the 2px frame around the plate and its
     * bevel, as every widget in the menu kit has.
     */
    @Test
    void theAvoidButtonMatchesTheReferenceIncludingItsFrame() {
        assertEquals(1141, HudArt.AVOID_X);
        assertEquals(24, HudArt.AVOID_Y);
        assertEquals(115, HudArt.AVOID_W);
        assertEquals(45, HudArt.AVOID_H);
        // 111 is the plate, bevel included: the button less its 2px frame on each side.
        assertEquals(111, HudArt.AVOID_W - 2 * 2 * ScreenArt.THICK + 4);
    }

    /**
     * The accents are shared with the sprites and must stay on the ramps, or a
     * gold button would not match the gold on a card.
     */
    @Test
    void theAccentsAreSharedWithTheSprites() {
        int[] accents = {HudArt.GOLD, HudArt.GOLD_LIGHT, HudArt.GOLD_DARK,
                         HudArt.FILL_TOP, HudArt.LABEL_DARK, HudArt.FILL_HEAL};
        for (int rgb : accents) {
            assertTrue(Ramps.contains(rgb),
                    "accent #" + Integer.toHexString(rgb) + " is off the palette");
        }
    }

    /**
     * The furniture is not. The frame and the bar's mid and low bands sit
     * between ramp steps in the reference, and are matched exactly rather than
     * snapped to the nearest step -- that is what keeps a render diffable
     * against the reference. Pinned so the choice is deliberate, not drift.
     */
    @Test
    void theChromeIsMatchedToTheReferenceEvenWhereItIsOffTheRamps() {
        assertEquals(0x0f1410, HudArt.FRAME);
        assertEquals(0x9a8b70, HudArt.FILL_MID);
        assertEquals(0x6b5f4c, HudArt.FILL_LOW);
        assertFalse(Ramps.contains(HudArt.FRAME), "if this ever lands on a ramp, revisit");
    }

    /**
     * Avoid is the only button on the board, and it is hit-tested against the
     * same numbers it is drawn from — but the pointer arrives with y upward and
     * the plate is specified with y downward. That flip is the whole test: get
     * it wrong and the button works 660 pixels above where it appears.
     */
    @Test
    void theAvoidPlateIsHitWhereItIsDrawn() {
        float bottom = CardArt.toWorldY(HudArt.AVOID_Y, HudArt.AVOID_H);
        assertTrue(HudArt.avoidContains(HudArt.AVOID_X + HudArt.AVOID_W / 2f,
                bottom + HudArt.AVOID_H / 2f), "the middle of the plate should hit");
        // Its own corners, and a pixel outside each of them.
        assertTrue(HudArt.avoidContains(HudArt.AVOID_X, bottom));
        assertFalse(HudArt.avoidContains(HudArt.AVOID_X - 1, bottom));
        assertFalse(HudArt.avoidContains(HudArt.AVOID_X, bottom - 1));
        assertFalse(HudArt.avoidContains(HudArt.AVOID_X + HudArt.AVOID_W, bottom));
        assertFalse(HudArt.avoidContains(HudArt.AVOID_X, bottom + HudArt.AVOID_H));
    }

    /** Mirroring the y is not the same as not mirroring it — pin that it is not. */
    @Test
    void theAvoidPlateIsNotHitAtItsDesignSpaceY() {
        assertFalse(HudArt.avoidContains(HudArt.AVOID_X + 4, HudArt.AVOID_Y + 4),
                "design-space y should not hit; the button is at the top of the screen");
    }
}
