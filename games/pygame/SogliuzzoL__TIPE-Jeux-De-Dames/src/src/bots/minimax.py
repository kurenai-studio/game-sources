from plateau import coups_possibles, Plateau


def run_minimax(plateau: Plateau):
    return coups_possibles(plateau.positions(), plateau.round_side)[0]
