package com.tomer.scoundrel.screens;

/**
 * A card leaving the room: swept to the depth ticker when a room is avoided, or
 * carried down to the rail when a weapon is equipped.
 *
 * <p>Both are the same motion — a few whole-pixel hops with the card shrinking
 * as it goes — so they are one set of arithmetic differing only in where they
 * land, how many hops, and how fast they shrink. A hop holds for its whole
 * duration; there is no position between one and the next, which is what makes
 * it read as steps rather than a slide.
 */
final class CardFlight {

    /** Effects run at 12fps, and a hop is always a whole number of frames. */
    private static final float FRAME = 1f / Frames.EFFECT_FPS;

    /**
     * The depth ticker's centre: where a swept room lands, and where a dealt
     * card comes from.
     *
     * <p>Named {@code _CX}/{@code _CY} because {@link HudArt#TICKER_Y} is a
     * different number for a different thing — the strip's top edge, not a
     * flight target.
     *
     * <p>The rail's anchor is <b>not</b> declared here. It lives in
     * {@link BoardArt} with the rest of the furniture, and {@link #EQUIP} reads
     * it from there; a second copy can drift from the one the rail is drawn at.
     */
    static final int TICKER_CX = 640;
    /** The depth ticker's centre y, in design pixels measured downward. */
    static final int TICKER_CY = 60;

    /**
     * One kind of flight: where it lands, how its hops are timed, and how the card
     * shrinks or grows along the way.
     *
     * @param toX         where the card lands
     * @param toY         where the card lands
     * @param hopTime     how long each hop holds
     * @param staggerTime how long after the card to its left a card sets off
     * @param scales      the card's size at each hop, as a percentage
     */
    record Flight(int toX, int toY, float hopTime, float staggerTime, int[] scales) {

        /**
         * How many hops the flight takes.
         *
         * @return the length of {@code scales}
         */
        int hops() {
            return scales.length;
        }

        /**
         * How long one card's flight lasts.
         *
         * @return seconds, from setting off to landing
         */
        float total() {
            return hops() * hopTime;
        }

        /**
         * How long until the last of {@code cards} has landed.
         *
         * @param cards how many cards fly, in stagger order
         * @return seconds, from the first setting off to the last landing
         */
        float totalFor(int cards) {
            return total() + Math.max(0, cards - 1) * staggerTime;
        }

        /**
         * Whether one card's flight is over.
         *
         * @param elapsed seconds on that card's own clock
         * @return true from {@link #total()} on
         */
        boolean finished(float elapsed) {
            return elapsed >= total();
        }
    }

    /**
     * The whole room hops into the ticker together — one parallel action per
     * card with no delay between them. Avoiding is a single decision about four
     * cards, and emptying them left to right would make it read as four, at a
     * frame a card for the privilege.
     *
     * <p>Three hops of one frame: a room you have already decided to be rid of
     * is gone in 250ms.
     */
    static final Flight AVOID = new Flight(TICKER_CX, TICKER_CY, FRAME, 0f,
            new int[] {100, 58, 16});

    /**
     * Three hops to the rail, shrinking to the icon it becomes. One card, so
     * nothing to stagger against, and a hop a frame, so a weapon you have just
     * taken is on the rail in 250ms.
     */
    static final Flight EQUIP = new Flight(
            BoardArt.railIconX() + BoardArt.RAIL_ICON / 2,
            BoardArt.railIconY() + BoardArt.RAIL_ICON / 2,
            FRAME, 0f, new int[] {100, 55, 18});

    /**
     * A card arriving in the room, growing as it comes, three hops of one
     * frame. Dealt with no stagger at all the room lands as one event rather
     * than as four cards, so it is a whole frame between cards: the
     * smallest gap this grid can express, and enough to see each one land.
     *
     * @param toX the slot's x the card lands on, in design pixels
     * @param toY the slot's y the card lands on, in design pixels
     * @return a three-hop flight, staggered a frame a card, growing to full size
     */
    static Flight dealTo(int toX, int toY) {
        return new Flight(toX, toY, FRAME, FRAME, new int[] {28, 64, 100});
    }

    /**
     * A card that was already on the board moving to its new slot as the room
     * closes up around a resolved card. It never changes size — it is already
     * the right one — and, unlike a deal, it does not stagger.
     *
     * <p>That difference is deliberate. Cards coming up out of the dungeon are
     * four separate events and read better one after another. The survivors
     * shifting along are one row re-centring itself, and cascading them would make
     * a resolved card look as though it had set off a second deal.
     *
     * @param toX the new slot's x, in design pixels
     * @param toY the new slot's y, in design pixels
     * @return a three-hop, unstaggered flight at full size throughout
     */
    static Flight slideTo(int toX, int toY) {
        return new Flight(toX, toY, FRAME, 0f, new int[] {100, 100, 100});
    }

    private CardFlight() {
    }

    /**
     * A card's own clock. On a staggered flight each card sets off after the one
     * before it and sits where it was until then; on an unstaggered one every
     * card shares the same clock and they move together.
     *
     * @param flight  the flight
     * @param index   the card's place in the stagger, from 0
     * @param elapsed seconds on the flight's shared clock
     * @return seconds on this card's clock; negative until it sets off
     */
    static float localTime(Flight flight, int index, float elapsed) {
        return elapsed - index * flight.staggerTime();
    }

    /**
     * Whether this card has set off yet.
     *
     * @param flight  the flight
     * @param index   the card's place in the stagger, from 0
     * @param elapsed seconds on the flight's shared clock
     * @return true once its own clock has started
     */
    static boolean started(Flight flight, int index, float elapsed) {
        return localTime(flight, index, elapsed) >= 0f;
    }

    /**
     * Whether this card has arrived. The depth ticker asks it of every card
     * still on its way up out of the dungeon — the engine gave the card up when
     * the move was applied, but until it lands it is still between the ticks and
     * the table, and its tick has to stay lit.
     *
     * @param flight  the flight
     * @param index   the card's place in the stagger, from 0
     * @param elapsed seconds on the flight's shared clock
     * @return true once its own flight is over
     */
    static boolean landed(Flight flight, int index, float elapsed) {
        return localTime(flight, index, elapsed) >= flight.total();
    }

    /** Which hop is showing, clamped to the last one once the flight is over. */
    private static int hopOf(Flight flight, float elapsed) {
        int hop = Frames.atPeriod(elapsed, flight.hopTime());
        return Math.max(0, Math.min(flight.hops() - 1, hop));
    }

    /**
     * Where the card is across, held on its current hop.
     *
     * @param flight  the flight
     * @param fromX   where it set off from, in design pixels
     * @param elapsed seconds on the card's own clock
     * @return its x this frame, in whole design pixels
     */
    static int x(Flight flight, int fromX, float elapsed) {
        return lerp(fromX, flight.toX(), hopOf(flight, elapsed), flight.hops());
    }

    /**
     * Where the card is down, held on its current hop.
     *
     * @param flight  the flight
     * @param fromY   where it set off from, in design pixels
     * @param elapsed seconds on the card's own clock
     * @return its y this frame, in whole design pixels
     */
    static int y(Flight flight, int fromY, float elapsed) {
        return lerp(fromY, flight.toY(), hopOf(flight, elapsed), flight.hops());
    }

    /**
     * The card's size right now, as a percentage of its board size.
     *
     * @param flight  the flight
     * @param elapsed seconds on the card's own clock
     * @return the current hop's entry in {@code scales}
     */
    static int scale(Flight flight, float elapsed) {
        return flight.scales()[hopOf(flight, elapsed)];
    }

    /**
     * Hop 0 sits at the start and the last hop sits exactly on the anchor, so a
     * flight always begins where the card was and ends where it belongs.
     */
    private static int lerp(int from, int to, int hop, int hops) {
        if (hops <= 1) {
            return to;
        }
        return Math.round(from + (to - from) * (hop / (float) (hops - 1)));
    }
}
