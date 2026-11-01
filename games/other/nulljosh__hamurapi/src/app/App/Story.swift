import Foundation

/// The story script. The web game reads the same story.json, so the words live in one place.
struct Story: Decodable {
    struct Card: Decodable { let title: String, text: String }
    struct Needs: Decodable { var grain: Int?, acres: Int?, people: Int? }
    struct Gamble: Decodable { let chance: Double; var acres: Int?; let then: String }
    struct Choice: Decodable {
        let label: String, then: String
        var grain: Int?, acres: Int?, people: Int?, acresPct: Int?, yieldBonus: Int?
        var cats: Bool?, peek: Bool?, gamble: Gamble?
        enum CodingKeys: String, CodingKey { case label, then, grain, acres, people, acresPct, yieldBonus, cats = "guard", peek, gamble }
    }
    struct Omen: Decodable { let id: String, title: String, text: String; var needs: Needs?; let choices: [Choice] }

    let intro: Card
    let interludes: [String: Card]
    let omens: [Omen]
    let epilogues: [String: String]
    let hints: [String: String]

    static let shared: Story = {
        let url = Bundle.main.url(forResource: "story", withExtension: "json")!
        return try! JSONDecoder().decode(Story.self, from: Data(contentsOf: url))
    }()

    /// The omen for this year, if fortune sends one. Years 2 to 9, about two years in three, never the same one twice.
    func omen(for c: City, seen: Set<String>, rng: inout SplitMix) -> Omen? {
        guard c.year >= 2, c.year <= 9, rng.chance(0.7) else { return nil }
        let open = omens.filter { o in
            !seen.contains(o.id) && c.grain >= (o.needs?.grain ?? 0) && c.acres >= (o.needs?.acres ?? 0) && c.people >= (o.needs?.people ?? 0)
        }
        return open.isEmpty ? nil : open[rng.int(0, open.count - 1)]
    }

    /// Whether the city can pay for a choice. A choice that costs no land is never blocked by having none.
    static func canAfford(_ ch: Choice, _ c: City) -> Bool {
        c.grain + (ch.grain ?? 0) >= 0 && ((ch.acres ?? 0) >= 0 || c.acres + (ch.acres ?? 0) >= 1)
    }

    /// Applies a choice to the city and returns what came of it. `harvest` is a copy of the year's dice, for the astrologer.
    func apply(_ ch: Choice, to c: inout City, rng: inout SplitMix, harvest: SplitMix) -> String {
        c.grain = max(0, c.grain + (ch.grain ?? 0))
        c.acres = max(1, c.acres + (ch.acres ?? 0) + c.acres * (ch.acresPct ?? 0) / 100)
        c.people = max(1, c.people + (ch.people ?? 0))
        if ch.cats == true { c.guarded = true }
        c.yieldBonus += ch.yieldBonus ?? 0
        var said = ch.then
        if let g = ch.gamble, rng.chance(g.chance) { c.acres = max(1, c.acres + (g.acres ?? 0)); said = g.then }
        if ch.peek == true {
            var look = harvest  // looking does not change what comes
            let y = look.int(1, 5) + c.yieldBonus
            said += " A \(y >= 4 ? "big" : y <= 2 ? "small" : "fair") harvest is coming: \(y) bushels an acre."
        }
        return said
    }
}
