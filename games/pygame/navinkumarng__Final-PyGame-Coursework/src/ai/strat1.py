import random
from typing import TYPE_CHECKING, Optional

from ai.utils import find_first_group

if TYPE_CHECKING:
    from core.game import Game


def strat1(game: "Game", max_actions: int = 10) -> Optional[bool]:
    """"Hard" CPU strategy: greedily discard any valid group first, then draw
    while the hand is small, steal from whoever holds the most cards, or
    draw-and-discard a random card, in that priority order.
    """
    if game.winner is not None:
        return None

    actions_taken = 0

    while actions_taken < max_actions and game.winner is None:
        player = game.current_player()
        group_cards = find_first_group(player.hand)

        if group_cards is not None:
            game.discard_group(group_cards)
            actions_taken += 1
            if game.winner is not None:
                break
            continue

        can_draw_more = player.can_take_more_cards(1)
        hand_size = len(player.hand)

        if hand_size < 8 and not game.turn.used_draw_up_to_3 and can_draw_more and len(game.deck.cards) > 0:
            game.draw_up_to_3(2)
            actions_taken += 1
            if game.winner is not None:
                break
            continue

        if not game.turn.used_steal and can_draw_more:
            best_target_index = None
            best_size = -1
            for i, p in enumerate(game.players):
                if i == game.turn.player_index:
                    continue
                if len(p.hand) > best_size:
                    best_size = len(p.hand)
                    best_target_index = i
            if best_target_index is not None and best_size > 1:
                game.steal_card(best_target_index)
                actions_taken += 1
                if game.winner is not None:
                    break
                continue

        if not game.turn.used_draw_discard and len(game.deck.cards) > 0 and len(player.hand) > 0:
            discard_card = random.choice(player.hand)
            game.draw_and_discard(discard_card)
            actions_taken += 1
            if game.winner is not None:
                break
            continue

        break

    did_act = (actions_taken > 0)

    game.next_player()
    return did_act
