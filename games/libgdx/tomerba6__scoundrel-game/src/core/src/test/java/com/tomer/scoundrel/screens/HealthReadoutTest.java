package com.tomer.scoundrel.screens;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * What the health bar says, which is not always what the state says. The bar
 * lags the engine on purpose: a drink is resolved the instant you press the
 * card, but nothing may appear at the bar until the bottle has flown there and
 * poured, or the fill has no visible cause.
 *
 * <p>Choosing between those readings is a decision, so it lives out here where
 * it can be pinned. The held case must not fall through to "at rest", or the
 * bar fills on the press and then again on the pour.
 */
class HealthReadoutTest {

    private static final int CAP = 20;
    /** 14 → 20, the widths those healths fill to. */
    private static final HealthReadout.Change DRINK = new HealthReadout.Change(
            HudArt.barFillWidth(14, CAP), HudArt.barFillWidth(20, CAP), 14, 20);
    /** 20 → 8, going the other way. */
    private static final HealthReadout.Change HIT = new HealthReadout.Change(
            HudArt.barFillWidth(20, CAP), HudArt.barFillWidth(8, CAP), 20, 8);

    /** At rest, the bar and number show the state's health, unmoved. */
    @Test
    void atRestTheBarSaysWhatTheStateSays() {
        HealthReadout readout = HealthReadout.of(
                HealthReadout.Phase.REST, 14, CAP, HealthReadout.Change.NONE, 0f);
        assertEquals(HudArt.barFillWidth(14, CAP), readout.fill());
        assertEquals(14, readout.number());
        assertEquals(0, readout.offsetX());
        assertFalse(readout.healing());
        assertFalse(readout.bleeding());
    }

    /**
     * The held case, in one assertion. Between the press and the pour the
     * engine has already healed you — {@code health} is 20 here — but the bar
     * must still read 14, or the heal is shown twice.
     */
    @Test
    void aDrinkShowsNothingUntilTheBottlePours() {
        HealthReadout held = HealthReadout.of(
                HealthReadout.Phase.HELD, 20, CAP, DRINK, 0f);
        assertEquals(DRINK.fromWidth(), held.fill(), "the bar filled before the bottle poured");
        assertEquals(14, held.number(), "the number ran ahead of the bottle");
        assertFalse(held.healing(), "nothing is happening at the bar yet");
    }

    /**
     * And it must not jump when the pour finally starts. The held fill and the
     * heal's first frame are the same width, so the bottle landing continues the
     * bar rather than rewinding it.
     */
    @Test
    void theBarDoesNotJumpWhenThePourBegins() {
        HealthReadout held = HealthReadout.of(
                HealthReadout.Phase.HELD, 20, CAP, DRINK, 0f);
        HealthReadout pouring = HealthReadout.of(
                HealthReadout.Phase.HEALING, 20, CAP, DRINK, 0f);
        assertEquals(held.fill(), pouring.fill(),
                "the bar rewound between the press and the pour");
    }

    /** A heal grows the bar to its new width and marks it as healing. */
    @Test
    void aHealGrowsToTheNewWidthAndPaintsItselfGreen() {
        HealthReadout start = HealthReadout.of(
                HealthReadout.Phase.HEALING, 20, CAP, DRINK, 0f);
        assertTrue(start.healing());
        assertFalse(start.bleeding());
        HealthReadout end = HealthReadout.of(
                HealthReadout.Phase.HEALING, 20, CAP, DRINK, 1f);
        assertEquals(DRINK.toWidth(), end.fill());
        assertTrue(end.fill() > start.fill(), "the fill should have grown");
    }

    /** A hit drains the bar, shakes it, and marks it as bleeding. */
    @Test
    void aHitDrainsTheBarAndJoltsIt() {
        HealthReadout readout = HealthReadout.of(
                HealthReadout.Phase.BLEEDING, 8, CAP, HIT, 0f);
        assertTrue(readout.bleeding());
        assertFalse(readout.healing());
        assertEquals(HpPulse.damageWidth(HIT.fromWidth(), HIT.toWidth(), 0f), readout.fill());
        assertEquals(HpPulse.barOffset(HIT.fromWidth(), HIT.toWidth(), 0f), readout.offsetX(),
                "a hit shakes the bar");
    }

    /** Only a hit moves the bar sideways; a drink arrives calmly. */
    @Test
    void nothingButAHitJoltsTheBar() {
        for (HealthReadout.Phase phase : new HealthReadout.Phase[] {
                HealthReadout.Phase.REST, HealthReadout.Phase.HELD, HealthReadout.Phase.HEALING}) {
            assertEquals(0, HealthReadout.of(phase, 20, CAP, DRINK, 0f).offsetX(),
                    phase + " should not jolt the bar");
        }
    }

    /** A killing blow empties the bar; it never draws backwards. */
    @Test
    void aKillingBlowEmptiesTheBarRatherThanInverting() {
        HealthReadout.Change fatal = new HealthReadout.Change(
                HudArt.barFillWidth(3, CAP), 0, 3, -6);
        HealthReadout readout = HealthReadout.of(
                HealthReadout.Phase.BLEEDING, -6, CAP, fatal, 1f);
        assertEquals(0, readout.fill());
    }

    /**
     * But the <em>number</em> goes past zero, and must. How far under you went
     * is the whole story of the last blow — and the death score charges you for
     * it — so a fatal hit that reads "0" hides what actually happened. The bar's
     * fill is what clamps.
     */
    @Test
    void theReadingGoesNegativeEvenThoughTheBarCannot() {
        HealthReadout.Change fatal = new HealthReadout.Change(
                HudArt.barFillWidth(3, CAP), 0, 3, -6);
        // While the blow is still landing, and again once it has settled — the
        // two are different branches and both have to report the overkill.
        assertEquals(-6, HealthReadout.of(
                HealthReadout.Phase.BLEEDING, -6, CAP, fatal, 0f).number());
        assertEquals(-6, HealthReadout.of(
                HealthReadout.Phase.REST, -6, CAP, HealthReadout.Change.NONE, 0f).number());
    }
}
