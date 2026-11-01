import Foundation

/// The robot ruler from ruler.py. Plays for the top grade; the demo and the benchmarks both use it.
enum Ruler {
    static let gate = 16, cap = 19, share = 6  // tuned by ruler.py --sweep

    static func orders(_ c: City) -> Orders {
        let tend = c.people * acresPerPerson
        let seed = min(c.acres, tend)
        // One hungry mouth shuts the gates: newcomers only arrive when nobody starves.
        let hungry = c.acres < gate * c.people ? 1 : 0
        let feed = (c.people - hungry) * foodPerPerson
        if c.year == years {  // last year: the harvest can't help the grade, spare grain becomes land
            return Orders(buy: max(0, (c.grain - feed) / c.price), feed: min(feed, c.grain), plant: 0)
        }
        var buy = 0
        let short = feed + seed - c.grain
        if short > 0 {
            buy = -min(c.acres - 1, (short + c.price - 1) / c.price)
        } else if c.price <= cap {
            buy = (-short) / c.price / share
        }
        let left = c.grain - buy * c.price - feed
        return Orders(buy: buy, feed: feed, plant: max(0, min(c.acres + buy, tend, left)))
    }

    /// Orders that are always legal, whatever the rule of thumb says.
    static func legal(_ c: City) -> Orders {
        let o = orders(c)
        return check(c, o).isEmpty ? o : Orders(buy: 0, feed: min(c.grain, c.people * foodPerPerson), plant: 0)
    }

    static func reign(seed: UInt64) -> City {
        var rng = SplitMix(x: seed), c = City()
        while c.over.isEmpty { _ = step(&c, legal(c), &rng) }
        return c
    }
}
