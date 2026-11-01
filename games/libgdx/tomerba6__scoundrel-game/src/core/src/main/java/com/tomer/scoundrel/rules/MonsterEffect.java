package com.tomer.scoundrel.rules;

import com.tomer.scoundrel.model.Card;
import com.tomer.scoundrel.model.GameState;

import java.util.ArrayList;
import java.util.List;

/**
 * Monsters are fought barehanded (full value as damage) or with the equipped
 * weapon (damage = max(0, monster − weapon), monster stacked on the weapon).
 * The weapon option is offered only while degradation allows it.
 */
public final class MonsterEffect implements CardEffect {

    /** Creates the effect. It holds no state, so one instance serves every monster. */
    public MonsterEffect() {
    }

    @Override
    public List<Move> legalMoves(Card card, GameState state) {
        List<Move> moves = new ArrayList<>();
        moves.add(new Move.FightBarehanded(card));
        if (state.weapon() != null && state.weapon().canUseAgainst(card)) {
            moves.add(new Move.FightWithWeapon(card));
        }
        return List.copyOf(moves);
    }

    @Override
    public void resolve(Move.CardMove move, ResolutionContext ctx) {
        Card monster = move.targetCard();
        switch (move) {
            case Move.FightBarehanded ignored -> {
                ctx.damage(monster.value());
                ctx.emit(new GameEvent.MonsterDefeated(monster, false, monster.value()));
            }
            case Move.FightWithWeapon ignored -> {
                int damage = Math.max(0, monster.value() - ctx.weapon().weapon().value());
                ctx.damage(damage);
                ctx.slayWithWeapon(monster);
                ctx.emit(new GameEvent.MonsterDefeated(monster, true, damage));
                ctx.emit(new GameEvent.WeaponDegraded(ctx.weapon().weapon(), monster.value()));
            }
            default -> throw new IllegalMoveException("A monster can only be fought, got: " + move);
        }
    }
}
