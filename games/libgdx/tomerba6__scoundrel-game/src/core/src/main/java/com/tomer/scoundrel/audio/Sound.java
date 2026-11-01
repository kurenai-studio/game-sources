package com.tomer.scoundrel.audio;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Every sound effect in the game, and the files each one is rendered to.
 *
 * <p>The file names are the contract — like the sprite region names — between
 * the Python that renders {@code assets/audio/sfx/} and the code that plays it:
 * {@code <sound>_<version>}, or {@code <sound>_<weight>_<version>} for a
 * weighted one. {@link #allFiles()} is the one list both sides are checked
 * against.
 *
 * <p>The list is closed on purpose. The game is fast — cards act on press, and
 * a click during an animation skips it — so every moment gets exactly one
 * sound, and a sound that would always land on top of another was cut: the
 * weapon wearing down (it fires with every weapon kill), the old weapon being
 * discarded (it happens inside the equip), a heal (it would sit on the drink),
 * and taking damage, which is folded into the hit as the {@link #THUD}.
 *
 * <p>Only a sound heard often has more than one version, and only those vary
 * in pitch and volume. The rare moments sound identical every time, which is
 * what makes them recognisable.
 */
public enum Sound {
    /** A menu button going down: title, mode select, ledger, trophies, the end panel. */
    CLICK(1),
    /** A card from the dungeon landing in the room. Four land a frame apart. */
    FLIP(3),
    /** A whole room swept back into the dungeon. */
    SWEEP(1),
    /** A weapon landing on the rail. */
    EQUIP(1, Scale.WEAPON),
    /** A weapon kill's blade, weighted by the weapon. */
    BLADE(2, Scale.WEAPON),
    /** Damage a weapon let through, under the blade. A clean kill has none. */
    THUD(2, Scale.DAMAGE),
    /** A bare-handed fight — both blows in one sound — weighted by the monster. */
    FIST(2, Scale.MONSTER),
    /** A potion pouring, even at full health. */
    DRINK(1, Scale.POTION),
    /** A wasted potion tipping over where it stood. */
    SPILL(1),
    /** Trophies unlocked, on the end panel. */
    CHIME(1);

    private final int versions;
    /** The scale a weighted sound is split along; null for an unweighted one. */
    private final Scale scale;

    Sound(int versions) {
        this(versions, null);
    }

    Sound(int versions, Scale scale) {
        this.versions = versions;
        this.scale = scale;
    }

    /**
     * How many versions of each weight were rendered.
     *
     * @return 1 or more; the file names count from 1
     */
    public int versions() {
        return versions;
    }

    /**
     * The weights rendered for this sound; empty when it is not weighted.
     *
     * @return the weights, lightest first
     */
    public List<Weight> weights() {
        return scale == null ? List.of() : scale.weights();
    }

    /**
     * The scale a weighted sound is split along.
     *
     * @return the scale, or null for an unweighted sound
     */
    Scale scale() {
        return scale;
    }

    /**
     * Whether each play is nudged in pitch and volume: only sounds heard often.
     *
     * @return true exactly when the sound has more than one version
     */
    public boolean varies() {
        return versions > 1;
    }

    /**
     * Whether pending copies of this sound become one when an animation is
     * skipped. Only the flip: a skipped deal lands four cards at once, and four
     * flips on the same instant are one louder noise, not four cards.
     *
     * @return true for {@link #FLIP} only
     */
    public boolean collapsesOnSkip() {
        return this == FLIP;
    }

    /**
     * How many copies of this sound may play at once; a new one past that stops
     * the oldest. Four flips, because a deal's four overlap by design — the
     * riffle. One chime, because a second on top of the first is only louder.
     * Two of everything else: fast play lands a second kill while the first
     * still rings, and cutting it off mid-ring would click.
     *
     * @return the polyphony limit: 4, 1 or 2
     */
    public int voices() {
        return switch (this) {
            case FLIP -> 4;
            case CHIME -> 1;
            default -> 2;
        };
    }

    /**
     * The file stem of an unweighted sound: {@code click}.
     *
     * @return the sound's name in lower case; the version number is appended to it
     * @throws IllegalArgumentException if this sound is weighted
     */
    public String stem() {
        if (scale != null) {
            throw new IllegalArgumentException(this + " is weighted; name a weight");
        }
        return fileName();
    }

    /**
     * The file stem of a weighted sound: {@code blade_light}.
     *
     * @param weight one of {@link #weights()}
     * @return the sound's name and the weight's, in lower case, joined by an underscore
     * @throws IllegalArgumentException if this sound has no files at that weight, or none
     *                                  at all because it is unweighted
     */
    public String stem(Weight weight) {
        if (!weights().contains(weight)) {
            throw new IllegalArgumentException(this + " has no " + weight + " files");
        }
        return fileName() + "_" + weight.fileName();
    }

    /**
     * Every file this sound was rendered to, without the extension.
     *
     * @return one name per weight and version, e.g. {@code thud_light_1}
     */
    List<String> files() {
        List<String> stems = new ArrayList<>();
        if (scale == null) {
            stems.add(stem());
        } else {
            for (Weight weight : weights()) {
                stems.add(stem(weight));
            }
        }
        List<String> files = new ArrayList<>();
        for (String stem : stems) {
            for (int version = 1; version <= versions; version++) {
                files.add(stem + "_" + version);
            }
        }
        return files;
    }

    /**
     * Every sound-effect file the game expects to find, without the extension.
     *
     * @return an unmodifiable list, grouped by sound in declaration order
     */
    public static List<String> allFiles() {
        List<String> files = new ArrayList<>();
        for (Sound sound : values()) {
            files.addAll(sound.files());
        }
        return List.copyOf(files);
    }

    private String fileName() {
        return name().toLowerCase(Locale.ROOT);
    }
}
