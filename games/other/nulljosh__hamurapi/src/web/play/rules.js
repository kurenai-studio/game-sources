// The rules of Hamurapi for the web game. Mirrors app/App/Game.swift, Ruler.swift, Story.swift and hamurapi.py.
// `node web/play/rules.js` plays 200 reigns and checks the total against the Swift and Python ports.
const YEARS = 10, FOOD = 20, TEND = 10;
const M = (1n << 64n) - 1n;
const div = (a, b) => Math.trunc(a / b);

// SplitMix64 with our own draws, so one seed gives one reign on every platform.
class SplitMix {
  constructor(seed) { this.x = BigInt.asUintN(64, BigInt(seed)); }
  next() {
    this.x = (this.x + 0x9E3779B97F4A7C15n) & M;
    let z = this.x;
    z = ((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n) & M;
    z = ((z ^ (z >> 27n)) * 0x94D049BB133111EBn) & M;
    return z ^ (z >> 31n);
  }
  int(lo, hi) { return lo + Number(this.next() % BigInt(hi - lo + 1)); }
  chance(p) { return Number(this.next() >> 11n) / 9007199254740992 < p; }
  copy() { const c = new SplitMix(0); c.x = this.x; return c; }
}

// How hard the dice lean. Classic and today's game always use normal, the 1968 odds.
const RULES = {
  // Plague is the same at every level: it thins the city, and a thin city scores better on land a head.
  easy: { grain: 3600, acres: 1200, rat: 0.25, mercy: 0.6 },
  normal: { grain: 2800, acres: 1000, rat: 0.4, mercy: 0.45 },
  hard: { grain: 2400, acres: 900, rat: 0.5, mercy: 0.35 },
};

function newCity(rules = RULES.normal) {
  return { year: 1, people: 100, grain: rules.grain, acres: rules.acres, price: 19, starvedTotal: 0, starvedPct: 0,
           over: "", impeached: false, guarded: false, yieldBonus: 0 };
}

// Refuses bad orders. Empty string means legal.
function check(c, o) {
  const cost = o.buy * c.price;
  if (o.buy < 0 && -o.buy > c.acres) return "You do not own that much land.";
  if (cost > c.grain) return "Not enough grain to buy that land.";
  const left = c.grain - cost;
  if (o.feed < 0 || o.plant < 0) return "That does not work. Try again.";
  if (o.feed > left) return "Not enough grain to feed that many.";
  if (o.plant > c.acres + o.buy) return "You do not own that much land.";
  if (o.plant > left - o.feed) return "Not enough grain for seed.";
  if (o.plant > c.people * TEND) return "Not enough people to farm that much.";
  return "";
}

// Plays one year. Assumes check passed. The order of the dice must never change.
function step(c, o, rng, rules = RULES.normal) {
  const r = { year: c.year, peopleBefore: c.people, yield: 0, harvest: 0, rats: 0, starved: 0, born: 0, plague: false };
  c.acres += o.buy;
  c.grain -= o.buy * c.price + o.feed + o.plant;
  r.yield = rng.int(1, 5) + c.yieldBonus;
  c.yieldBonus = 0;
  r.harvest = o.plant * r.yield;
  if (rng.chance(rules.rat)) {
    const eaten = div(c.grain, [2, 4][rng.int(0, 1)]);
    if (!c.guarded) r.rats = eaten;
  }
  c.guarded = false;
  c.grain += r.harvest - r.rats;
  r.starved = Math.max(0, c.people - div(o.feed, FOOD));
  if (r.starved > rules.mercy * c.people) {
    c.over = `You let ${r.starved} people starve in one year. The people threw you out!`;
    c.impeached = true;
  }
  c.starvedTotal += r.starved;
  c.starvedPct += 100 * r.starved / Math.max(c.people, 1);
  c.people -= r.starved;
  if (r.starved === 0) r.born = div(div(rng.int(1, 5) * (20 * c.acres + c.grain), Math.max(c.people, 1)), 100) + 1;
  c.people += r.born;
  r.plague = rng.chance(0.15);
  if (r.plague) c.people = div(c.people, 2);
  c.year += 1;
  c.price = rng.int(17, 26);
  if (!c.over && c.year > YEARS) c.over = "Your 10 years are over.";
  r.peopleAfter = c.people; r.grainAfter = c.grain; r.acresAfter = c.acres;
  return r;
}

function grade(c) {
  const p1 = c.starvedPct / Math.max(c.year - 1, 1), land = c.acres / Math.max(c.people, 1);
  if (c.impeached || p1 > 33 || land < 7) return "F";
  if (p1 > 10 || land < 9) return "C";
  if (p1 > 3 || land < 10) return "B";
  return "A+";
}

// Bounds the sliders use. Each later bound depends on the earlier orders.
const maxBuy = c => div(c.grain, c.price);
const maxFeed = (c, o) => Math.max(0, c.grain - o.buy * c.price);
const maxPlant = (c, o) => Math.max(0, Math.min(c.acres + o.buy, c.people * TEND, c.grain - o.buy * c.price - o.feed));
function sensible(c) {
  const feed = Math.min(c.grain, c.people * FOOD);
  return { buy: 0, feed, plant: Math.min(c.acres, c.people * TEND, c.grain - feed) };
}

// The robot ruler. Plays for the top grade; the demo and the benchmarks both use it.
const Ruler = {
  gate: 16, cap: 19, share: 6,
  orders(c) {
    const tend = c.people * TEND, seed = Math.min(c.acres, tend);
    const hungry = c.acres < this.gate * c.people ? 1 : 0;  // one hungry mouth shuts the gates
    const feed = (c.people - hungry) * FOOD;
    if (c.year === YEARS) return { buy: Math.max(0, div(c.grain - feed, c.price)), feed: Math.min(feed, c.grain), plant: 0 };
    let buy = 0;
    const short = feed + seed - c.grain;
    if (short > 0) buy = -Math.min(c.acres - 1, div(short + c.price - 1, c.price));
    else if (c.price <= this.cap) buy = div(div(-short, c.price), this.share);
    return { buy, feed, plant: Math.max(0, Math.min(c.acres + buy, tend, c.grain - buy * c.price - feed)) };
  },
  legal(c) { const o = this.orders(c); return check(c, o) ? { buy: 0, feed: Math.min(c.grain, c.people * FOOD), plant: 0 } : o; },
  reign(seed) { const rng = new SplitMix(seed), c = newCity(); while (!c.over) step(c, this.legal(c), rng); return c; },
};

// The omen for this year, if fortune sends one. Years 2 to 9, about two years in three, never the same one twice.
function omenFor(story, c, seen, rng) {
  if (c.year < 2 || c.year > 9 || !rng.chance(0.7)) return null;
  const open = story.omens.filter(o => !seen.includes(o.id) && c.grain >= (o.needs?.grain ?? 0)
    && c.acres >= (o.needs?.acres ?? 0) && c.people >= (o.needs?.people ?? 0));
  return open.length ? open[rng.int(0, open.length - 1)] : null;
}

// Whether the city can pay for a choice. A choice that costs no land is never blocked by having none.
const canAfford = (ch, c) => c.grain + (ch.grain ?? 0) >= 0 && ((ch.acres ?? 0) >= 0 || c.acres + (ch.acres ?? 0) >= 1);

// Applies a choice to the city and returns what came of it. `harvest` is a copy of the year's dice, for the star reader.
function applyChoice(ch, c, rng, harvest) {
  c.grain = Math.max(0, c.grain + (ch.grain ?? 0));
  c.acres = Math.max(1, c.acres + (ch.acres ?? 0) + div(c.acres * (ch.acresPct ?? 0), 100));
  c.people = Math.max(1, c.people + (ch.people ?? 0));
  if (ch.guard) c.guarded = true;
  c.yieldBonus += ch.yieldBonus ?? 0;
  let said = ch.then;
  if (ch.gamble && rng.chance(ch.gamble.chance)) { c.acres = Math.max(1, c.acres + (ch.gamble.acres ?? 0)); said = ch.gamble.then; }
  if (ch.peek) {
    const y = harvest.copy().int(1, 5) + c.yieldBonus;
    said += ` A ${y >= 4 ? "big" : y <= 2 ? "small" : "fair"} harvest is coming: ${y} bushels an acre.`;
  }
  return said;
}

// One number for n reigns. `python3 ruler.py --golden` and the Swift tests must give the same one.
function golden(n = 200) {
  let total = 0;
  for (let i = 0; i < n; i++) { const c = Ruler.reign(i); total += c.people + 3 * c.acres + 7 * c.grain + 11 * c.starvedTotal; }
  return total;
}

// The same idea for the story: 120 scripted reigns across all three levels, taking the cards as they come.
// The Swift tests play the same script and must land on the same number.
function storyGolden(story, n = 120) {
  let total = 0;
  for (let seed = 0; seed < n; seed++) {
    const rules = [RULES.normal, RULES.easy, RULES.hard][seed % 3];
    const rng = new SplitMix(seed), srng = new SplitMix(BigInt(seed) ^ 0x5707n), c = newCity(rules), seen = [];
    while (!c.over) {
      if (c.year !== 1 && !story.interludes[c.year]) {
        const o = omenFor(story, c, seen, srng);
        if (o) {
          seen.push(o.id);
          const pick = [seed % 2, 1 - seed % 2].find(i => canAfford(o.choices[i], c));
          if (pick !== undefined) applyChoice(o.choices[pick], c, srng, rng);
        }
      }
      step(c, Ruler.legal(c), rng, rules);
    }
    total += c.people + 3 * c.acres + 7 * c.grain + 11 * c.starvedTotal + 13 * ["F", "C", "B", "A+"].indexOf(grade(c)) + 17 * seen.length;
  }
  return total;
}

const GOLDEN = 639940, STORY_GOLDEN = 390695;
if (typeof module !== "undefined") {
  module.exports = { SplitMix, RULES, newCity, check, step, grade, sensible, Ruler, omenFor, canAfford, applyChoice, golden, storyGolden };
  if (require.main === module) {
    const t0 = Date.now(), wins = Array.from({ length: 1000 }, (_, i) => grade(Ruler.reign(i))).filter(g => g === "A+").length;
    const story = storyGolden(require("./story.json"));
    console.log(`golden ${golden()} (want ${GOLDEN}), story ${story} (want ${STORY_GOLDEN}), A+ in ${wins} of 1000, ${Date.now() - t0} ms`);
    process.exit(golden() === GOLDEN && story === STORY_GOLDEN ? 0 : 1);
  }
}
