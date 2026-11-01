package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;

import java.util.List;

/**
 * Heals up to the health cap while the room's potion allowance lasts; any
 * further potion that turn is discarded with no effect. A potion that heals 0
 * because health is already at the cap still counts as taken.
 */
public final class PotionEffect implements CardEffect {

    /** Creates the effect. It holds no state, so one instance serves every potion. */
    public PotionEffect() {
    }

    @Override
    public List<Move> legalMoves(Card card, GameState state) {
        return List.of(new Move.TakePotion(card));
    }

    @Override
    public void resolve(Move.CardMove move, ResolutionContext ctx) {
        Card potion = move.targetCard();
        if (ctx.potionsUsedThisRoom() < ctx.rules().potionsPerTurn()) {
            int healed = ctx.heal(potion.value());
            ctx.notePotionTaken();
            ctx.emit(new GameEvent.PotionUsed(potion, healed));
        } else {
            ctx.emit(new GameEvent.PotionWasted(potion));
        }
    }
}
