package com.tomer.scoundrel.screens;

/**
 * When each board sound plays, read off the effect it belongs to — never typed
 * in. A move is settled the instant it is pressed, but the picture is not, and a
 * sound played on the press arrives before the thing it is the sound of. So each
 * sound waits for its effect's own clock to reach the moment the picture changes:
 * the slash crossing, the weapon reaching the rail, the bottle pouring, a card
 * landing. Retime an animation and its sound follows it.
 *
 * <p>Times are seconds on the effect's own clock, which the killing blow runs at
 * half speed — so its sound lands late with it, without anything here knowing.
 * The deal is on its own clock too, which only starts once the effect is over.
 *
 * <p>Pure and headless, so the timing table in {@code docs/audio.md} is tested
 * rather than trusted.
 */
final class Beats {

    private static final CardFlight.Flight DEAL = CardFlight.dealTo(0, 0);

    private Beats() {
    }

    /**
     * A bare-handed fight: on the first blow. Its file holds both, a frame apart.
     *
     * @return seconds on the fight's clock
     */
    static float strike() {
        return Barehanded.HIT_FRAMES[0] * Barehanded.FRAME;
    }

    /**
     * A weapon kill: as the slash bar starts across the card (167 ms). The card
     * jumps up whole a frame earlier ({@link WeaponKill#cardCut}); if the blade
     * reads late in play, that is the other candidate.
     *
     * @return seconds on the kill's clock
     */
    static float slice() {
        return WeaponKill.SLASH_START;
    }

    /**
     * An equip: as the weapon's card reaches the rail.
     *
     * @return seconds on the equip flight's clock: the flight's whole length
     */
    static float equip() {
        return CardFlight.EQUIP.total();
    }

    /**
     * An avoid: as the room sets off, all four cards together.
     *
     * @return 0, the sweep's first instant
     */
    static float sweep() {
        return 0f;
    }

    /**
     * A drink: as the bottle pours — the same moment the bar starts to fill.
     *
     * @return seconds on the drink's clock
     */
    static float drink() {
        return PotionDrink.POUR_START;
    }

    /**
     * A wasted potion: as it spills.
     *
     * @return seconds on the spill's clock
     */
    static float spill() {
        return PotionSpill.SPILL_START;
    }

    /**
     * A card of a deal: as the card in room slot {@code slot} lands. Cards set off
     * a frame apart in slot order, so a carried-over card's slot is skipped rather
     * than counted — it slides, and makes no sound.
     *
     * @param slot the room slot the card lands in, from 0
     * @return seconds on the deal's clock
     */
    static float dealLanding(int slot) {
        return slot * DEAL.staggerTime() + DEAL.total();
    }
}
