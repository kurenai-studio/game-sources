package com.tomer.scoundrel.audio;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.rules.GameEvent;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Which sound each move makes, and the pitch, volume and version it plays at. */
class SfxChoiceTest {

    private static final float EPSILON = 1e-6f;

    private static Card monster(int value) {
        return new Card("M" + value, CardType.MONSTER, value);
    }

    private static Card weapon(int value) {
        return new Card("W" + value, CardType.WEAPON, value);
    }

    private static Card potion(int value) {
        return new Card("P" + value, CardType.POTION, value);
    }

    private static List<Sfx> sounds(GameEvent... events) {
        return new SfxChoice(1).forEvents(List.of(events), 0);
    }

    /** The file without its version, which is the part the mapping decides. */
    private static List<String> stems(List<Sfx> sfx) {
        List<String> stems = new ArrayList<>();
        for (Sfx s : sfx) {
            stems.add(s.file().substring(0, s.file().lastIndexOf('_')));
        }
        return stems;
    }

    // --- the mapping, one event type at a time ------------------------------

    /** Avoiding a room sounds a sweep. */
    @Test
    void avoidingSweeps() {
        assertEquals(List.of("sweep"), stems(sounds(new GameEvent.RoomAvoided(List.of()))));
    }

    /** Equipping sounds light, medium or heavy by the weapon's value. */
    @Test
    void equippingIsWeightedByTheWeapon() {
        assertEquals(List.of("equip_light"), stems(sounds(new GameEvent.WeaponEquipped(weapon(2)))));
        assertEquals(List.of("equip_medium"), stems(sounds(new GameEvent.WeaponEquipped(weapon(6)))));
        assertEquals(List.of("equip_heavy"), stems(sounds(new GameEvent.WeaponEquipped(weapon(10)))));
    }

    /** A weapon kill that costs no health is the blade alone, weighted by the weapon. */
    @Test
    void aCleanWeaponKillIsTheBladeAlone() {
        SfxChoice choice = new SfxChoice(1);
        List<Sfx> sfx = choice.forEvents(
                List.of(new GameEvent.MonsterDefeated(monster(7), true, 0)), 9);
        assertEquals(List.of("blade_heavy"), stems(sfx));
    }

    /** A weapon kill that lets damage through adds a thud after the blade, weighted by the damage. */
    @Test
    void damageThroughAWeaponAddsAThudWeightedByTheDamage() {
        SfxChoice choice = new SfxChoice(1);
        assertEquals(List.of("blade_medium", "thud_light"), stems(choice.forEvents(
                List.of(new GameEvent.MonsterDefeated(monster(8), true, 3)), 5)));
        assertEquals(List.of("blade_light", "thud_heavy"), stems(choice.forEvents(
                List.of(new GameEvent.MonsterDefeated(monster(14), true, 12)), 2)));
    }

    /** The blade is weighted by the weapon, not by the monster. */
    @Test
    void theBladeIsWeightedByTheWeaponNotTheMonster() {
        SfxChoice choice = new SfxChoice(1);
        // The same Ace, killed by a light and by a heavy weapon.
        assertEquals("blade_light", stems(choice.forEvents(
                List.of(new GameEvent.MonsterDefeated(monster(14), true, 10)), 4)).get(0));
        assertEquals("blade_heavy", stems(choice.forEvents(
                List.of(new GameEvent.MonsterDefeated(monster(14), true, 4)), 10)).get(0));
    }

    /** A bare-handed kill sounds a fist, weighted by the monster. */
    @Test
    void aBareHandedFightIsWeightedByTheMonster() {
        assertEquals(List.of("fist_light"), stems(sounds(new GameEvent.MonsterDefeated(monster(3), false, 3))));
        assertEquals(List.of("fist_medium"), stems(sounds(new GameEvent.MonsterDefeated(monster(9), false, 9))));
        assertEquals(List.of("fist_heavy"), stems(sounds(new GameEvent.MonsterDefeated(monster(11), false, 11))));
    }

    /** A potion that heals nothing still sounds a drink, weighted by the potion. */
    @Test
    void aPotionThatHealsNothingIsStillADrink() {
        // Drunk at full health: it counts as the room's potion, it just heals 0.
        assertEquals(List.of("drink_heavy"), stems(sounds(new GameEvent.PotionUsed(potion(8), 0))));
        assertEquals(List.of("drink_light"), stems(sounds(new GameEvent.PotionUsed(potion(2), 2))));
    }

    /** A wasted potion sounds a spill. */
    @Test
    void aWastedPotionSpills() {
        assertEquals(List.of("spill"), stems(sounds(new GameEvent.PotionWasted(potion(5)))));
    }

    /** A dealt room, a degraded weapon, a win and a loss make no sound effect. */
    @Test
    void theEventsThatMakeNoSound() {
        // RoomDealt: the flips follow the cards landing, not the event.
        // WeaponDegraded: fires with every weapon kill, which already sounds.
        // GameWon / GameLost: the music's cues, not effects.
        assertEquals(List.of(), sounds(
                new GameEvent.RoomDealt(List.of(monster(2))),
                new GameEvent.WeaponDegraded(weapon(5), 7),
                new GameEvent.GameWon(20),
                new GameEvent.GameLost(-12)));
    }

    /** GameEvent is deliberately not sealed; new card effects may add types. */
    private record SomeFutureEvent() implements GameEvent {
    }

    /** An event type it does not know is silent rather than an error. */
    @Test
    void anEventTypeItDoesNotKnowIsSilentRatherThanAnError() {
        assertEquals(List.of(), sounds(new SomeFutureEvent()));
    }

    /** A whole costly weapon-kill move, refill included, sounds only the blade and the thud. */
    @Test
    void aWholeWeaponKillMoveSoundsOnlyTheKill() {
        // What the engine actually reports for a costly kill that refills the room.
        List<Sfx> sfx = new SfxChoice(1).forEvents(List.of(
                new GameEvent.MonsterDefeated(monster(9), true, 4),
                new GameEvent.WeaponDegraded(weapon(5), 9),
                new GameEvent.RoomDealt(List.of(monster(2), potion(3)))), 5);
        assertEquals(List.of("blade_medium", "thud_light"), stems(sfx));
    }

    // --- pitch, volume and versions -----------------------------------------

    /** A single-version, unweighted sound plays at exactly its own pitch and volume every time. */
    @Test
    void singleVersionSoundsAreExactlyTheSameEveryTime() {
        SfxChoice choice = new SfxChoice(3);
        for (int i = 0; i < 20; i++) {
            for (Sfx sfx : List.of(choice.click(), choice.chime(),
                    choice.forEvents(List.of(new GameEvent.PotionWasted(potion(4))), 0).get(0),
                    choice.forEvents(List.of(new GameEvent.RoomAvoided(List.of())), 0).get(0))) {
                assertEquals(1f, sfx.pitch(), EPSILON, sfx.file());
                assertEquals(1f, sfx.volume(), EPSILON, sfx.file());
                assertTrue(sfx.file().endsWith("_1"), sfx.file());
            }
        }
    }

    /** A weighted single-version sound carries its value's pitch nudge and nothing else. */
    @Test
    void aWeightedSingleVersionSoundCarriesOnlyItsValueNudge() {
        Sfx equip = sounds(new GameEvent.WeaponEquipped(weapon(2))).get(0);
        assertEquals(Scale.WEAPON.pitchOf(2), equip.pitch(), EPSILON);
        assertEquals(1f, equip.volume(), EPSILON);
        Sfx drink = sounds(new GameEvent.PotionUsed(potion(10), 3)).get(0);
        assertEquals(Scale.POTION.pitchOf(10), drink.pitch(), EPSILON);
    }

    /**
     * A frequent sound varies in pitch and volume within the jitter, is never
     * louder, and never repeats its version.
     */
    @Test
    void frequentSoundsVarySlightlyButNeverLouder() {
        SfxChoice choice = new SfxChoice(11);
        Set<Float> pitches = new HashSet<>();
        String previous = null;
        for (int i = 0; i < 200; i++) {
            Sfx flip = choice.flip(0);
            assertTrue(flip.pitch() >= 1f - SfxChoice.PITCH_JITTER - EPSILON
                    && flip.pitch() <= 1f + SfxChoice.PITCH_JITTER + EPSILON, "pitch " + flip.pitch());
            assertTrue(flip.volume() >= 1f - SfxChoice.VOLUME_JITTER - EPSILON
                    && flip.volume() <= 1f + EPSILON, "volume " + flip.volume());
            assertTrue(!flip.file().equals(previous), "flip " + i + " repeated " + previous);
            previous = flip.file();
            pitches.add(flip.pitch());
        }
        assertTrue(pitches.size() > 1, "the jitter should actually move the pitch");
    }

    /** The jitter is applied on top of the value's pitch nudge. */
    @Test
    void theJitterRidesOnTopOfTheValueNudge() {
        SfxChoice choice = new SfxChoice(5);
        float base = Scale.WEAPON.pitchOf(2);
        for (int i = 0; i < 50; i++) {
            Sfx blade = choice.forEvents(
                    List.of(new GameEvent.MonsterDefeated(monster(5), true, 0)), 2).get(0);
            assertTrue(blade.pitch() >= base * (1f - SfxChoice.PITCH_JITTER) - EPSILON
                    && blade.pitch() <= base * (1f + SfxChoice.PITCH_JITTER) + EPSILON,
                    "pitch " + blade.pitch());
        }
    }

    /** The same seed makes the same choices. */
    @Test
    void theSameSeedMakesTheSameChoices() {
        SfxChoice a = new SfxChoice(99);
        SfxChoice b = new SfxChoice(99);
        for (int i = 0; i < 30; i++) {
            assertEquals(a.flip(i % 4), b.flip(i % 4), "flip " + i);
        }
    }

    // --- the deal's riffle (four even flips a frame apart would read as a machine gun) ---

    /** Each later card of a deal plays quieter than the previous card at its quietest. */
    @Test
    void eachLaterCardOfADealIsQuieterThanTheOneBefore() {
        // With the variation on top, the fade must still order them: a card's loudest
        // play is quieter than the previous card's quietest.
        SfxChoice choice = new SfxChoice(21);
        for (int card = 1; card < 4; card++) {
            float louder = SfxChoice.RIFFLE_GAIN[card - 1] * (1f - SfxChoice.VOLUME_JITTER);
            for (int i = 0; i < 50; i++) {
                assertTrue(choice.flip(card).volume() < louder, "card " + card);
            }
        }
    }

    /** Each card of a deal plays within its own riffle step's level and pitch. */
    @Test
    void eachCardPlaysWithinItsStepOfTheRiffle() {
        SfxChoice choice = new SfxChoice(8);
        for (int card = 0; card < 4; card++) {
            float gain = SfxChoice.RIFFLE_GAIN[card];
            float pitch = SfxChoice.RIFFLE_PITCH[card];
            for (int i = 0; i < 50; i++) {
                Sfx flip = choice.flip(card);
                assertTrue(flip.volume() <= gain + EPSILON
                        && flip.volume() >= gain * (1f - SfxChoice.VOLUME_JITTER) - EPSILON,
                        "card " + card + " volume " + flip.volume());
                assertTrue(flip.pitch() <= pitch * (1f + SfxChoice.PITCH_JITTER) + EPSILON
                        && flip.pitch() >= pitch * (1f - SfxChoice.PITCH_JITTER) - EPSILON,
                        "card " + card + " pitch " + flip.pitch());
            }
        }
    }

    /** The riffle's first step is at full level and pitch, and each later step is lower in both. */
    @Test
    void theRiffleStartsFullAndFallsInLevelAndPitch() {
        assertEquals(1f, SfxChoice.RIFFLE_GAIN[0], 0f);
        assertEquals(1f, SfxChoice.RIFFLE_PITCH[0], 0f);
        for (int card = 1; card < SfxChoice.RIFFLE_GAIN.length; card++) {
            assertTrue(SfxChoice.RIFFLE_GAIN[card] < SfxChoice.RIFFLE_GAIN[card - 1], "gain " + card);
            assertTrue(SfxChoice.RIFFLE_PITCH[card] < SfxChoice.RIFFLE_PITCH[card - 1], "pitch " + card);
        }
    }

    /** Cards past the fourth keep the riffle's last step. */
    @Test
    void cardsPastTheFourthKeepTheLastStep() {
        // A ruleset with a bigger room deals more; the riffle holds its last step.
        SfxChoice choice = new SfxChoice(4);
        int last = SfxChoice.RIFFLE_GAIN.length - 1;
        for (int i = 0; i < 20; i++) {
            Sfx flip = choice.flip(6);
            assertTrue(flip.volume() <= SfxChoice.RIFFLE_GAIN[last] + EPSILON, "volume " + flip.volume());
            assertTrue(flip.pitch() <= SfxChoice.RIFFLE_PITCH[last] * (1f + SfxChoice.PITCH_JITTER) + EPSILON,
                    "pitch " + flip.pitch());
        }
    }

    /** A negative place in the deal is refused with IllegalArgumentException. */
    @Test
    void aCardHasAPlaceInTheDeal() {
        assertThrows(IllegalArgumentException.class, () -> new SfxChoice(1).flip(-1));
    }

    /** The menu click and the trophy chime are their own single files, at plain pitch and volume. */
    @Test
    void theMenuAndTrophySoundsAreTheirOwnFiles() {
        SfxChoice choice = new SfxChoice(1);
        assertEquals(new Sfx(Sound.CLICK, "click_1", 1f, 1f), choice.click());
        assertEquals(new Sfx(Sound.CHIME, "chime_1", 1f, 1f), choice.chime());
    }
}
