package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.achievements.Achievement;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/**
 * One entry in TROPHIES: what the row says and whether its seal is filled.
 *
 * <p>The seal's fill is the <em>only</em> difference between earned and locked
 * — there is no padlock glyph and no greyscale filter, so an empty well is the
 * locked state. A hidden trophy gives away neither its name nor its
 * rule until it is won, which is the whole point of hiding it.
 *
 * <p>The date a trophy was won is shown: it is real information the row has the
 * width for.
 *
 * @param title       the trophy's name, upper-cased, or {@code ???} while hidden
 * @param description what earns it, upper-cased, or a placeholder while hidden
 * @param status      {@code EARNED <date>} or {@code LOCKED}
 * @param earned      whether the seal is filled
 */
record TrophyEntry(String title, String description, String status, boolean earned) {

    private static final DateTimeFormatter DAY =
            DateTimeFormatter.ofPattern("MMM d", Locale.ENGLISH).withZone(ZoneId.systemDefault());

    /**
     * {@code earnedAt} is null for a trophy that has not been won.
     *
     * @param achievement the catalog entry
     * @param earnedAt    when it was first earned, or null
     * @return the row, concealed if the trophy is hidden and not yet earned
     */
    static TrophyEntry of(Achievement achievement, Instant earnedAt) {
        boolean earned = earnedAt != null;
        boolean concealed = achievement.hidden() && !earned;
        return new TrophyEntry(
                concealed ? "???" : achievement.title().toUpperCase(Locale.ROOT),
                concealed ? "A HIDDEN TROPHY — EARN IT TO REVEAL"
                        : achievement.description().toUpperCase(Locale.ROOT),
                earned ? "EARNED " + DAY.format(earnedAt).toUpperCase(Locale.ROOT) : "LOCKED",
                earned);
    }

    /**
     * The row's background.
     *
     * @return {@code 0xRRGGBB}, earned or locked
     */
    int rowColour() {
        return earned ? ScreenArt.ROW_EARNED : ScreenArt.ROW_LOCKED;
    }

    /**
     * The seal's fill: the one thing that says earned or locked.
     *
     * @return {@code 0xRRGGBB}, filled when earned, an empty well when locked
     */
    int sealColour() {
        return earned ? ScreenArt.SEAL_EARNED : ScreenArt.SEAL_LOCKED;
    }

    /**
     * Earned rows are cream; locked ones sit back without being unreadable.
     *
     * @return {@code 0xRRGGBB} for the row's text
     */
    int textColour() {
        return earned ? ScreenArt.BODY : ScreenArt.TROPHY_LOCKED_TEXT;
    }
}
