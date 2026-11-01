package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.CardType;
import com.tomer.scoundrel.model.GameState;
import com.tomer.scoundrel.rules.Move.TakePotion;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static com.tomer.scoundrel.rules.Cards.potion;
import static com.tomer.scoundrel.rules.Cards.weapon;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Determinism plus the extension seams: constants come from the Ruleset, and a
 * new card definition + effect or a harder ruleset plug in through the
 * unmodified engine.
 */
class ConfigurationTest {

    /** The same seed deals the same game. */
    @Test
    void sameSeedProducesIdenticalGames() {
        ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());
        assertEquals(engine.newGame(42L), engine.newGame(42L));
    }

    /** A seeded deal holds exactly the standard deck's 44 cards, each once. */
    @Test
    void seededShuffleIsAPermutationOfTheStandard44() {
        ScoundrelEngine engine = new ScoundrelEngine(Rulesets.standard());
        GameState g = engine.newGame(7L);
        List<String> inPlay = new ArrayList<>();
        g.room().forEach(c -> inPlay.add(c.id()));
        g.dungeon().forEach(c -> inPlay.add(c.id()));
        List<String> expected = new ArrayList<>(
                new StandardDeck().cards().stream().map(CardDefinition::id).toList());
        assertEquals(expected.stream().sorted().toList(), inPlay.stream().sorted().toList());
    }

    /** Starting health comes from the ruleset the engine is given. */
    @Test
    void constantsComeFromTheRulesetNotTheEngine() {
        Ruleset standard = Rulesets.standard();
        Ruleset harder = new Ruleset(15, standard.healthCap(), standard.roomSize(),
                standard.cardsResolvedPerTurn(), standard.potionsPerTurn(),
                standard.avoidRule(), standard.scoring(), standard.deck());
        GameState g = new ScoundrelEngine(harder).newGame(1L);
        assertEquals(15, g.health());
    }

    /**
     * A ruleset with a lower start and a lower cap plays through the same engine,
     * healing clipped to its cap.
     */
    @Test
    void aHarderRulesetPlaysThroughTheUnmodifiedEngine() {
        // Lower start AND a lower cap: healing must clip to the ruleset's cap.
        Ruleset standard = Rulesets.standard();
        Ruleset hard = new Ruleset(12, 15, 4, 3, 1,
                standard.avoidRule(), standard.scoring(), standard.deck());
        ScoundrelEngine engine = new ScoundrelEngine(hard);
        GameState g = engine.newGame(List.of(
                potion(9), weapon(2), weapon(3), weapon(4), weapon(5)));
        assertEquals(12, g.health());
        GameState next = engine.apply(g, new TakePotion(potion(9))).state();
        assertEquals(15, next.health()); // 12 + 9 clipped to cap 15
    }

    /** A ruleset allowing two potions a turn heals with both, and wastes the third. */
    @Test
    void potionsPerTurnAboveOneIsHonored() {
        Ruleset standard = Rulesets.standard();
        Ruleset generous = new Ruleset(5, 20, 4, 3, 2,
                standard.avoidRule(), standard.scoring(), standard.deck());
        ScoundrelEngine engine = new ScoundrelEngine(generous);
        GameState g = engine.newGame(List.of(
                potion(3), potion(4), potion(5), weapon(2), weapon(3)));
        g = engine.apply(g, new TakePotion(potion(3))).state();
        assertEquals(8, g.health());
        g = engine.apply(g, new TakePotion(potion(4))).state();
        assertEquals(12, g.health()); // second potion of the turn heals too
        MoveResult third = engine.apply(g, new TakePotion(potion(5)));
        assertEquals(12, third.state().health()); // third exceeds the allowance
        assertTrue(third.events().contains(new GameEvent.PotionWasted(potion(5))));
    }

    /**
     * A new card with its own effect, an elixir that ignores the potion
     * allowance, plays through the unchanged engine.
     */
    @Test
    void aNewCardDefinitionAndEffectPlugInWithoutEngineChanges() {
        // An "elixir": heals ignoring the per-turn potion allowance.
        CardEffect elixirEffect = new CardEffect() {
            @Override
            public List<Move> legalMoves(Card card, GameState state) {
                return List.of(new TakePotion(card));
            }

            @Override
            public void resolve(Move.CardMove move, ResolutionContext ctx) {
                int healed = ctx.heal(move.targetCard().value());
                ctx.emit(new GameEvent.PotionUsed(move.targetCard(), healed));
            }
        };
        CardDefinition elixirDef = new CardDefinition("ELIXIR", CardType.POTION, 9, elixirEffect);
        List<CardDefinition> defs = new ArrayList<>(new StandardDeck().cards());
        defs.add(elixirDef);
        DeckDefinition deckWithElixir = () -> defs;

        Ruleset standard = Rulesets.standard();
        Ruleset withElixir = new Ruleset(10, 20, 4, 3, 1,
                standard.avoidRule(), standard.scoring(), deckWithElixir);
        ScoundrelEngine engine = new ScoundrelEngine(withElixir);

        GameState g = engine.newGame(List.of(
                potion(3), elixirDef.card(), weapon(2), weapon(3), weapon(4)));
        g = engine.apply(g, new TakePotion(potion(3))).state();   // 13, allowance used
        g = engine.apply(g, new TakePotion(elixirDef.card())).state();
        assertEquals(20, g.health()); // elixir healed 7 despite the used allowance
    }
}
