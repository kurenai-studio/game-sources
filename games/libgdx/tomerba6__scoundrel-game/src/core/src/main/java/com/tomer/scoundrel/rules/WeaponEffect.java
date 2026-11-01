package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;

import java.util.List;

/** Weapons are binding: equipping is the only way to resolve one. */
public final class WeaponEffect implements CardEffect {

    /** Creates the effect. It holds no state, so one instance serves every weapon. */
    public WeaponEffect() {
    }

    @Override
    public List<Move> legalMoves(Card card, GameState state) {
        return List.of(new Move.TakeWeapon(card));
    }

    @Override
    public void resolve(Move.CardMove move, ResolutionContext ctx) {
        ctx.equip(move.targetCard());
        ctx.emit(new GameEvent.WeaponEquipped(move.targetCard()));
    }
}
