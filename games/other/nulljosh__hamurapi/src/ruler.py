"""A ruler that plays Hamurapi for an A+. Run: python3 ruler.py [seed] | --sweep | --bench | --golden"""
import sys, time
from hamurapi import State, SplitMix, step, check, grade, report, FOOD_PER_PERSON, ACRES_PER_PERSON

KNOBS = dict(gate=16, cap=19, share=6)  # tuned by sweep() over 1000 seeds

def orders(s, gate, cap, share):
    tend = s.people * ACRES_PER_PERSON
    seed = min(s.acres, tend)
    # One hungry mouth shuts the gates: immigration only comes when nobody starves.
    # Costs ~1% starvation (A+ allows 3%) and keeps acres per person up.
    hungry = 1 if s.acres < gate * s.people else 0
    feed = (s.people - hungry) * FOOD_PER_PERSON
    if s.year == 10:  # last year: the harvest can't help the grade, spare grain becomes land
        return max(0, (s.grain - feed) // s.price), min(feed, s.grain), 0
    buy = 0
    short = feed + seed - s.grain
    if short > 0:  # sell only what feeding and a full sowing need
        buy = -min(s.acres - 1, -(-short // s.price))
    elif s.price <= cap:
        buy = -short // s.price // share
    left = s.grain - buy * s.price - feed
    return buy, feed, max(0, min(s.acres + buy, tend, left))

def play(seed, quiet=False, **knobs):
    s, rng = State(), SplitMix(seed)
    while not s.over:
        o = orders(s, **(knobs or KNOBS))
        if check(s, *o): o = (0, min(s.grain, s.people * FOOD_PER_PERSON), 0)  # broke: feed what we can
        lines = step(s, *o, rng)
        if not quiet: print(report(s).strip().splitlines()[-1], "|", *lines)
    return s

def sweep(n=1000):
    best = max(((sum(grade(play(i, True, gate=g, cap=c, share=sh)) == "A+" for i in range(n)), g, c, sh)
                for g in (12, 14, 16, 18) for c in (17, 19, 21, 23) for sh in (2, 3, 6)))
    print(f"best: {best[0]}/{n} A+ with gate={best[1]} cap={best[2]} share={best[3]}")

def golden(n=200):
    """One number for n reigns. The Swift and web ports must print the same one, or the rules have drifted."""
    total = 0
    for i in range(n):
        s = play(i, True)
        total += s.people + 3 * s.acres + 7 * s.grain + 11 * s.starved_total
    return total

def bench(n=1000):
    """How good the ruler is and how fast the rules run."""
    t0 = time.perf_counter()
    grades = [grade(play(i, True)) for i in range(n)]
    secs = time.perf_counter() - t0
    print(f"{n} reigns in {secs:.2f}s ({n / secs:,.0f} a second)")
    for g in ("A+", "B", "C", "F"): print(f"  {g:2} {grades.count(g) / n:6.1%}")

if __name__ == "__main__":
    if "--sweep" in sys.argv: sweep(); sys.exit()
    if "--bench" in sys.argv: bench(); sys.exit()
    if "--golden" in sys.argv: print(golden()); sys.exit()
    s = play(int(sys.argv[1]) if len(sys.argv) > 1 else 7)
    print(s.over, f"{s.people} people, {s.acres} acres, {s.starved_total} starved. Grade: {grade(s)}")
