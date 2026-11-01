package com.tomer.scoundrel.audio;

import com.tomer.scoundrel.rules.GameEvent;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Decides which sound effects a moment makes — which file, pitch and volume —
 * from what the engine reported. It decides <em>what</em>, never <em>when</em>:
 * every sound of a move plays on its animation's beat, which the board knows
 * and this class does not.
 *
 * <p>It observes the engine from outside, as achievements and the run log do:
 * it reads {@link GameEvent}s and nothing in {@code model} or {@code rules}
 * knows it exists.
 *
 * <p>Weighted sounds take their file from the card's value band and a small
 * pitch nudge from where the value sits inside it ({@link Scale}). A sound
 * heard often also varies slightly on every play — a different version, a
 * little pitch either way, a little quieter — because the same waveform back to
 * back reads as mechanical. A rare sound never varies.
 */
public final class SfxChoice {

    /**
     * How far a frequent sound's pitch may wander either way: ±2%. A starting
     * value, tuned by ear in the listening rounds.
     */
    static final float PITCH_JITTER = 0.02f;
    /**
     * How much quieter a frequent sound may play: up to 10% (about 0.9 dB).
     * Only ever quieter, never above the level the file was mastered at.
     */
    static final float VOLUME_JITTER = 0.1f;

    private final Random random;
    private final VariantPicker picker;

    /**
     * A chooser whose versions and jitter all come from one seeded generator.
     *
     * @param seed any value; the same seed makes the same sequence of choices
     */
    public SfxChoice(long seed) {
        this.random = new Random(seed);
        this.picker = new VariantPicker(random);
    }

    /**
     * The sounds one resolved move makes, in the order its events arrived. They
     * all belong to the same moment — a weapon kill's blade and thud land
     * together — so the board plays them on one beat.
     *
     * @param events      one move's events, as {@link com.tomer.scoundrel.rules.MoveResult} lists them
     * @param weaponValue the value of the weapon equipped when the move was
     *                    made; only read for a monster killed with it
     * @return the sounds, in event order; empty for a move that makes none
     */
    public List<Sfx> forEvents(List<GameEvent> events, int weaponValue) {
        List<Sfx> sounds = new ArrayList<>();
        for (GameEvent event : events) {
            switch (event) {
                case GameEvent.RoomAvoided avoided -> sounds.add(plain(Sound.SWEEP));
                case GameEvent.WeaponEquipped equipped ->
                        sounds.add(weighted(Sound.EQUIP, equipped.weapon().value()));
                case GameEvent.MonsterDefeated kill when kill.withWeapon() -> {
                    sounds.add(weighted(Sound.BLADE, weaponValue));
                    if (kill.damageTaken() > 0) {
                        sounds.add(weighted(Sound.THUD, kill.damageTaken()));
                    }
                }
                case GameEvent.MonsterDefeated fight ->
                        sounds.add(weighted(Sound.FIST, fight.monster().value()));
                case GameEvent.PotionUsed drunk -> sounds.add(weighted(Sound.DRINK, drunk.potion().value()));
                case GameEvent.PotionWasted wasted -> sounds.add(plain(Sound.SPILL));
                // Silent by design. RoomDealt: the flips follow the cards as they
                // land, not the event. WeaponDegraded: fires with every weapon
                // kill, which already sounds. GameWon / GameLost: the music's cues.
                // Anything newer: a card effect nobody has voiced yet.
                default -> {
                }
            }
        }
        return sounds;
    }

    /**
     * The deal's riffle: each card of a deal a little quieter than the one before
     * (0, −2.2, −4.2, −6 dB)...
     *
     * <p>The cards land exactly a frame apart, and four even flips on that beat read as
     * a machine gun however soft each one is — round 1's verdict, twice. Shaped like
     * this, with each flip's tail overlapping the next, the four read as one hand
     * dealing. Chosen by ear over one sound per deal and over the first card alone.
     */
    static final float[] RIFFLE_GAIN = {1f, 0.78f, 0.62f, 0.5f};
    /** ...and a touch lower: 1.5% a card. */
    static final float[] RIFFLE_PITCH = {1f, 0.985f, 0.97f, 0.955f};

    /**
     * One card landing in the room: the {@code card}-th of its deal to land, counted
     * from 0. Later cards step down the riffle; past its end they keep its last step,
     * for a ruleset that deals a bigger room.
     *
     * @param card the card's place in its deal, from 0
     * @return the flip, pitched and quietened for that place
     * @throws IllegalArgumentException if {@code card} is negative
     */
    public Sfx flip(int card) {
        if (card < 0) {
            throw new IllegalArgumentException("a card's place in its deal starts at 0, got " + card);
        }
        int step = Math.min(card, RIFFLE_GAIN.length - 1);
        Sfx flip = plain(Sound.FLIP);
        return new Sfx(flip.sound(), flip.file(), flip.pitch() * RIFFLE_PITCH[step],
                flip.volume() * RIFFLE_GAIN[step]);
    }

    /**
     * A menu button going down.
     *
     * @return the click, identical every time
     */
    public Sfx click() {
        return plain(Sound.CLICK);
    }

    /**
     * Trophies unlocked.
     *
     * @return the chime, identical every time
     */
    public Sfx chime() {
        return plain(Sound.CHIME);
    }

    private Sfx plain(Sound sound) {
        return choose(sound, sound.stem(), 1f);
    }

    private Sfx weighted(Sound sound, int value) {
        Scale scale = sound.scale();
        return choose(sound, sound.stem(scale.weightOf(value)), scale.pitchOf(value));
    }

    private Sfx choose(Sound sound, String stem, float pitch) {
        int version = picker.pick(stem, sound.versions());
        float volume = 1f;
        if (sound.varies()) {
            pitch *= 1f + PITCH_JITTER * (2f * random.nextFloat() - 1f);
            volume = 1f - VOLUME_JITTER * random.nextFloat();
        }
        return new Sfx(sound, stem + "_" + version, pitch, volume);
    }
}
