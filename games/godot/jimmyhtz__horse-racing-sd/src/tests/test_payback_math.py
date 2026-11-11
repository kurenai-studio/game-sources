"""Independent small-state checks, not assertions copied from the formula."""
import itertools
import sys
import unittest
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools' / 'payback_v2'))
try:
    import math_model as model
except ImportError:
    model = None


class PaybackMathTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(model, 'Movement-derived probability model has not been implemented')

    @staticmethod
    def enumerate_finish(distance, p):
        mass = {0: Fraction(1)}
        finish = defaultdict(Fraction)
        for turn in range(1, distance + 1):
            next_mass = defaultdict(Fraction)
            for position, chance in mass.items():
                for step, weight in [(1, 1-p), (2, p)]:
                    if position+step >= distance:
                        finish[turn] += chance*weight
                    else:
                        next_mass[position+step] += chance*weight
            mass = next_mass
        return finish

    def test_finish_distribution_matches_all_small_movement_paths(self):
        for distance in [2, 3, 4, 7, 12]:
            for p in [Fraction(1, 5), Fraction(1, 2), Fraction(4, 5)]:
                actual = model.finish_pmf(distance, float(p))
                expected = self.enumerate_finish(distance, p)
                self.assertAlmostEqual(sum(actual), 1, places=12)
                for turn, value in enumerate(actual):
                    self.assertAlmostEqual(value, float(expected[turn]), places=12)

    def test_ordered_probabilities_match_exhaustive_shuffled_crossings(self):
        probabilities = [Fraction(1, 4), Fraction(1, 3), Fraction(1, 2), Fraction(2, 3), Fraction(3, 4)]
        distributions = [self.enumerate_finish(3, p) for p in probabilities]
        expected = defaultdict(Fraction)
        for rounds in itertools.product(*[list(d) for d in distributions]):
            mass = Fraction(1)
            for horse, turn in enumerate(rounds):
                mass *= distributions[horse][turn]
            for order in itertools.permutations(range(5)):
                ordered = sorted(range(5), key=lambda h: (rounds[h], order.index(h)))
                expected[tuple(ordered[:2])] += mass / 120
        actual = model.finish_probabilities([model.finish_pmf(3, float(p)) for p in probabilities])
        for i in range(5):
            self.assertAlmostEqual(actual['wins'][i], float(sum(v for (a,b),v in expected.items() if a == i)), places=12)
            for j in range(5):
                self.assertAlmostEqual(actual['ordered'][i][j], float(expected[i,j]), places=12)
        self.assertAlmostEqual(sum(actual['pairs']), 1, places=12)

    def test_integer_card_has_exact_equal_return_for_every_bet(self):
        card = model.card_contract(90, [3,5,9,30,6,10,45,15,45,18])
        self.assertEqual(card['exact_return'], Fraction(9,10))
        for p,m in zip(card['pair_probabilities'],card['payoffs']):
            self.assertEqual(p*m, Fraction(9,10))

    def test_incoherent_or_invalid_card_rejected(self):
        for payoffs in [[3,5,7,20,6,10,28,14,39,63], [9]*9, [9]*9+[0], [9]*9+[3.5], [9]*9+[True]]:
            with self.assertRaises(ValueError):
                model.card_contract(90,payoffs)
        for distance,p in [(0,.5),(2,0),(2,1),(2,float('nan'))]:
            with self.assertRaises(ValueError):
                model.finish_pmf(distance,p)

    def test_public_card_contains_payoffs_only(self):
        contract = model.card_contract(90,[9]*10)
        self.assertEqual(set(model.public_card(contract)), {'payoffs','payout_semantics'})

    def test_mixture_reconstructs_every_pair_not_just_the_average(self):
        self.assertTrue(hasattr(model,'fit_profiles'), 'Movement profile fitter missing')
        distributions = [model.finish_pmf(400,p) for p in [.6,.4]]
        component = model.finish_probabilities([distributions[0]]*2+[distributions[1]]*3)
        contract = model.card_contract(90,[3,5,9,30,6,10,45,15,45,18])
        fit = model.fit_profiles(component, contract)
        self.assertEqual(sum(fit['profile_units']), 2**48)
        self.assertGreaterEqual(min(fit['profile_units']),0)
        self.assertLess(fit['max_return_error'],1e-6)
        self.assertAlmostEqual(sum(fit['wins']),1,places=11)
        for p,target in zip(fit['pairs'], contract['pair_probabilities']):
            self.assertAlmostEqual(p,float(target),places=11)

    def test_impossible_mixture_fails_closed(self):
        self.assertTrue(hasattr(model,'fit_profiles'), 'Movement profile fitter missing')
        d = model.finish_pmf(50,.5)
        component = model.finish_probabilities([d]*5)
        with self.assertRaises(ValueError):
            model.fit_profiles(component,model.card_contract(90,[3,5,9,30,6,10,45,15,45,18]))


if __name__ == '__main__':
    unittest.main()
