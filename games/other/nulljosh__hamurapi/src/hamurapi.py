"""Hamurapi, the 1968 game Hamurabi: rule Sumeria for 10 years. Run: python3 hamurapi.py [--demo]"""
import random, sys
from dataclasses import dataclass

YEARS, FOOD_PER_PERSON, ACRES_PER_PERSON = 10, 20, 10

class SplitMix:
    """SplitMix64. The app and the web game use the same one, so a seed means the same reign everywhere."""
    M = (1 << 64) - 1
    def __init__(self, seed): self.x = seed & self.M
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & self.M
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & self.M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & self.M
        return z ^ (z >> 31)
    def randint(self, a, b): return a + self.next() % (b - a + 1)
    def choice(self, xs): return xs[self.next() % len(xs)]
    def random(self): return (self.next() >> 11) / (1 << 53)

@dataclass
class State:
    year: int = 1
    people: int = 100
    grain: int = 2800
    acres: int = 1000
    price: int = 19
    starved_total: int = 0
    starved_pct: float = 0  # sum of yearly starvation %, classic P1 numerator
    over: str = ""  # non-empty = game ended, holds the reason

def check(s, buy, feed, plant):
    """Return an error string for an illegal order, else ''."""
    cost = buy * s.price
    if buy < 0 and -buy > s.acres: return "You don't own that much land."
    if cost > s.grain: return "Not enough grain to buy that land."
    left = s.grain - cost
    if feed < 0 or plant < 0: return "Hamurapi, think again."
    if feed > left: return "Not enough grain to feed that much."
    if plant > s.acres + buy: return "You don't own that much land."
    if plant > left - feed: return "Not enough grain for seed."
    if plant > s.people * ACRES_PER_PERSON: return "Not enough people to tend the fields."
    return ""

def step(s, buy, feed, plant, rng):
    """Advance one year. Assumes check() passed. Returns report lines."""
    s.acres += buy
    s.grain -= buy * s.price + feed + plant
    yield_ = rng.randint(1, 5)
    harvest = plant * yield_
    rats = s.grain // rng.choice([2, 4]) if rng.random() < 0.4 else 0
    s.grain += harvest - rats
    fed = feed // FOOD_PER_PERSON
    starved = max(0, s.people - fed)
    if starved > 0.45 * s.people:
        s.over = f"You starved {starved} people in one year. You are impeached!"
    s.starved_total += starved
    s.starved_pct += 100 * starved / max(s.people, 1)
    s.people -= starved
    born = rng.randint(1, 5) * (20 * s.acres + s.grain) // max(s.people, 1) // 100 + 1 if starved == 0 else 0
    s.people += born
    plague = rng.random() < 0.15
    if plague: s.people //= 2
    s.year += 1
    s.price = rng.randint(17, 26)
    if not s.over and s.year > YEARS: s.over = "Your 10-year term is over."
    return [f"Harvest {yield_} bu/acre ({harvest} bu). Rats ate {rats}.",
            f"{starved} starved, {born} arrived." + (" PLAGUE halved the city!" if plague else "")]

def grade(s):
    """Classic 1968 end-of-reign verdict, lettered."""
    years = max(s.year - 1, 1)
    p1, l = s.starved_pct / years, s.acres / max(s.people, 1)
    if s.over.endswith("impeached!") or p1 > 33 or l < 7: return "F"
    if p1 > 10 or l < 9: return "C"
    if p1 > 3 or l < 10: return "B"
    return "A+"

def report(s):
    return (f"\n--- Year {s.year} ---\nPopulation {s.people}, {s.acres} acres, "
            f"{s.grain} bushels in store. Land is {s.price} bu/acre.")

def ask(prompt):
    while True:
        try: return int(input(prompt))
        except ValueError: print("Enter a whole number.")
        except EOFError: sys.exit()

def play(rng=None):
    rng = rng or SplitMix(random.getrandbits(64))
    s = State()
    print("HAMURABI: rule wisely for 10 years.")
    while not s.over:
        print(report(s))
        while True:
            buy = ask("Acres to buy (negative to sell)? ")
            feed = ask("Bushels to feed the people? ")
            plant = ask("Acres to plant? ")
            err = check(s, buy, feed, plant)
            if not err: break
            print(err)
        print("\n".join(step(s, buy, feed, plant, rng)))
    print(f"\n{s.over}\n{s.people} people, {s.acres} acres ({s.acres // max(s.people,1)} per person), "
          f"{s.starved_total} starved over your reign. Grade: {grade(s)}")

def demo():
    # ponytail: seeded auto-player asserting invariants; replace with pytest if it grows
    for seed in range(200):
        rng, s = SplitMix(seed), State()
        while not s.over:
            feed = min(s.grain, s.people * FOOD_PER_PERSON)
            plant = min(s.acres, s.people * ACRES_PER_PERSON, s.grain - feed)
            assert check(s, 0, feed, plant) == "", (seed, s)
            step(s, 0, feed, plant, rng)
            assert s.grain >= 0 and s.people >= 0 and s.acres >= 0, (seed, s)
        assert s.year <= YEARS + 1
    s = State()
    assert check(s, 10**6, 0, 0) and check(s, 0, 0, 5000) and check(s, -2000, 0, 0)
    assert grade(State(over="You are impeached!")) == "F" and grade(State(year=11, people=90)) == "A+"
    print("demo ok: 200 seeded reigns, invariants hold")

if __name__ == "__main__":
    demo() if "--demo" in sys.argv else play()
