import Foundation

let years = 10, foodPerPerson = 20, acresPerPerson = 10

/// SplitMix64. The Python and web games use the same one, so a seed means the same reign everywhere.
struct SplitMix: Codable {
    var x: UInt64
    mutating func next() -> UInt64 {
        x &+= 0x9E3779B97F4A7C15
        var z = x
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    // Our own draws, not the standard library's, so one seed gives one reign on every platform and OS version.
    mutating func int(_ lo: Int, _ hi: Int) -> Int { lo + Int(next() % UInt64(hi - lo + 1)) }
    mutating func chance(_ p: Double) -> Bool { Double(next() >> 11) / 9007199254740992 < p }
}

/// How hard the dice lean. Classic and today's game always use `.normal`, the 1968 odds.
struct Rules: Equatable {
    var grain = 2800, acres = 1000, ratChance = 0.4, mercy = 0.45
    static let normal = Rules()
    // Plague is the same at every level: it thins the city, and a thin city scores better on land a head.
    static let easy = Rules(grain: 3600, acres: 1200, ratChance: 0.25, mercy: 0.6)
    static let hard = Rules(grain: 2400, acres: 900, ratChance: 0.5, mercy: 0.35)
}

struct City: Codable {
    var year = 1, people = 100, grain = 2800, acres = 1000, price = 19
    var starvedTotal = 0
    var starvedPct = 0.0  // sum of yearly starvation %, the classic P1 numerator
    var over = ""         // non-empty = reign ended, holds the reason
    var impeached = false
    var guarded = false   // story mode: cats keep the rats out for one year
    var yieldBonus = 0    // story mode: extra bushels an acre at the next harvest
}

struct Orders: Codable { var buy = 0, feed = 0, plant = 0 }

struct YearReport: Codable {
    var year = 0, peopleBefore = 0, yield = 0, harvest = 0, rats = 0, starved = 0, born = 0, plague = false
    var peopleAfter = 0, grainAfter = 0, acresAfter = 0
}

/// Refuses bad orders with the king's counsel. Empty string means legal.
func check(_ c: City, _ o: Orders) -> String {
    let cost = o.buy * c.price
    if o.buy < 0 && -o.buy > c.acres { return "You do not own that much land." }
    if cost > c.grain { return "Not enough grain to buy that land." }
    let left = c.grain - cost
    if o.feed < 0 || o.plant < 0 { return "That does not work. Try again." }
    if o.feed > left { return "Not enough grain to feed that many." }
    if o.plant > c.acres + o.buy { return "You do not own that much land." }
    if o.plant > left - o.feed { return "Not enough grain for seed." }
    if o.plant > c.people * acresPerPerson { return "Not enough people to farm that much." }
    return ""
}

/// Plays one year. Assumes `check` passed.
func step(_ c: inout City, _ o: Orders, _ rng: inout SplitMix, rules: Rules = .normal) -> YearReport {
    var r = YearReport(year: c.year, peopleBefore: c.people)
    c.acres += o.buy
    c.grain -= o.buy * c.price + o.feed + o.plant
    r.yield = rng.int(1, 5) + c.yieldBonus
    c.yieldBonus = 0
    r.harvest = o.plant * r.yield
    if rng.chance(rules.ratChance) {
        let eaten = c.grain / [2, 4][rng.int(0, 1)]
        if !c.guarded { r.rats = eaten }
    }
    c.guarded = false
    c.grain += r.harvest - r.rats
    let fed = o.feed / foodPerPerson
    r.starved = max(0, c.people - fed)
    if Double(r.starved) > rules.mercy * Double(c.people) {
        c.over = "You let \(r.starved) people starve in one year. The people threw you out!"
        c.impeached = true
    }
    c.starvedTotal += r.starved
    c.starvedPct += 100 * Double(r.starved) / Double(max(c.people, 1))
    c.people -= r.starved
    if r.starved == 0 {
        r.born = rng.int(1, 5) * (20 * c.acres + c.grain) / max(c.people, 1) / 100 + 1
    }
    c.people += r.born
    r.plague = rng.chance(0.15)
    if r.plague { c.people /= 2 }
    c.year += 1
    c.price = rng.int(17, 26)
    if c.over.isEmpty && c.year > years { c.over = "Your 10 years are over." }
    r.peopleAfter = c.people; r.grainAfter = c.grain; r.acresAfter = c.acres
    return r
}

enum Grade: String, Comparable {
    case f = "F", c = "C", b = "B", aPlus = "A+"
    private var rank: Int { [Grade.f: 0, .c: 1, .b: 2, .aPlus: 3][self]! }
    static func < (a: Grade, b: Grade) -> Bool { a.rank < b.rank }
}

func grade(_ c: City) -> Grade {
    let served = max(c.year - 1, 1)
    let p1 = c.starvedPct / Double(served)
    let land = Double(c.acres) / Double(max(c.people, 1))
    if c.impeached || p1 > 33 || land < 7 { return .f }
    if p1 > 10 || land < 9 { return .c }
    if p1 > 3 || land < 10 { return .b }
    return .aPlus
}

/// Bounds the UI sliders use. Each later bound depends on the earlier orders.
extension City {
    var maxBuy: Int { grain / price }
    var minBuy: Int { -acres }
    func maxFeed(_ o: Orders) -> Int { max(0, grain - o.buy * price) }
    func maxPlant(_ o: Orders) -> Int {
        max(0, min(acres + o.buy, people * acresPerPerson, grain - o.buy * price - o.feed))
    }
    /// Orders that keep everyone fed and sow what the grain allows.
    var sensibleOrders: Orders {
        let feed = min(grain, people * foodPerPerson)
        return Orders(buy: 0, feed: feed, plant: min(acres, people * acresPerPerson, grain - feed))
    }
}
