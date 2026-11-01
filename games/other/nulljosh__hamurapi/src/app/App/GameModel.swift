import SwiftUI

@Observable final class GameModel {
    enum Phase { case title, card, orders, report, over }
    enum Mode: String, Codable { case story, classic, daily }
    enum Difficulty: String, Codable, CaseIterable {
        case easy, normal, hard
        var rules: Rules { self == .easy ? .easy : self == .hard ? .hard : .normal }
    }
    struct StoryCard { let title: String, text: String; var omen: Story.Omen? }
    private struct Saved: Codable {
        var city: City, log: [YearReport], mode: Mode, difficulty: Difficulty, rng: SplitMix, storyRng: SplitMix, seen: [String]
        var day: Int      // the day a daily game's dice belong to
        var atGate: Bool  // saved before this year's card was drawn
    }

    var city = City()
    var orders = Orders()
    var phase = Phase.title
    var mode = Mode.story
    var report: YearReport?
    var reportStart: TimeInterval = 0
    var yearStart: TimeInterval = 0
    var frozenAge: Double?
    var log: [YearReport] = []
    var card: StoryCard?
    var note = ""          // what the last choice led to, shown above the orders
    var demo = false
    var canResume = false
    var muted = Sound.shared.muted { didSet { Sound.shared.muted = muted } }
    var music = !Sound.shared.musicOff { didSet { Sound.shared.musicOff = !music } }
    /// Picked in settings. Only the story uses it; classic and today's game keep the 1968 odds.
    var difficulty: Difficulty { didSet { defaults.set(difficulty.rawValue, forKey: "difficulty") } }

    private var playing = Difficulty.normal  // the level this reign started on
    private var day = 0                      // the day this reign's dice belong to
    private var lastPlanted = 0
    private var lastGuarded = false
    private var rng: SplitMix
    private var storyRng = SplitMix(x: 0)
    private var seen: Set<String> = []
    private var demoTask: Task<Void, Never>?
    private let fixedSeed: UInt64?
    private let defaults: UserDefaults

    var best: String { didSet { defaults.set(best, forKey: "best") } }
    var reigns: Int { didSet { defaults.set(reigns, forKey: "reigns") } }
    var dailyDay: Int { didSet { defaults.set(dailyDay, forKey: "dailyDay") } }
    var dailyGrade: String { didSet { defaults.set(dailyGrade, forKey: "dailyGrade") } }

    init(seed: UInt64? = nil, defaults: UserDefaults = .standard) {
        fixedSeed = seed
        rng = SplitMix(x: seed ?? 0)
        self.defaults = defaults
        best = defaults.string(forKey: "best") ?? ""
        reigns = defaults.integer(forKey: "reigns")
        dailyDay = defaults.integer(forKey: "dailyDay")
        dailyGrade = defaults.string(forKey: "dailyGrade") ?? ""
        difficulty = Difficulty(rawValue: defaults.string(forKey: "difficulty") ?? "") ?? .normal
        canResume = defaults.data(forKey: "saved") != nil
    }

    /// Days since 1970 in UTC. Everyone who plays today's game gets the same dice.
    static var today: Int { Int(Date().timeIntervalSince1970 / 86400) }
    private static var now: TimeInterval { Date().timeIntervalSinceReferenceDate }
    var playedToday: Bool { dailyDay == Self.today && !dailyGrade.isEmpty }

    var error: String { check(city, orders) }
    var hint: String { reigns == 0 && !demo ? Story.shared.hints["\(city.year)"] ?? "" : "" }
    var harvested: Int { log.reduce(0) { $0 + $1.harvest } }
    var plagues: Int { log.filter(\.plague).count }
    /// True when even every bushel in the barn cannot feed everyone: time to sell land.
    var shortOfGrain: Bool { city.grain - orders.buy * city.price < city.people * foodPerPerson }

    var shareText: String {
        let link = "hamurapi.jaybulb.com"
        if city.impeached { return "I got thrown out as king in year \(log.count) of Hamurapi. Can you do better? \(link)" }
        let each = city.people == 0 ? "nobody left" : String(format: "%.1f acres each", Double(city.acres) / Double(city.people))
        let what = mode == .daily ? "played today's game" : "was king for 10 years"
        return "I \(what) in Hamurapi and got \(grade(city).rawValue). \(fmt(city.starvedTotal)) starved, \(each). \(link)"
    }

    /// What the scene draws for the current phase.
    var snapshot: SceneSnapshot {
        var s = SceneSnapshot(year: min(city.year, years), people: city.people, acres: city.acres, grain: city.grain, starved: city.starvedTotal)
        switch phase {
        case .title: s = SceneSnapshot()
        case .card: s.planted = 0; s.omen = card?.omen?.id; s.cats = city.guarded; s.yearStart = yearStart
        case .orders: s.acres = city.acres + orders.buy; s.planted = orders.plant; s.cats = city.guarded; s.yearStart = yearStart
        case .report:
            s.year = city.year  // already the next year, so the sun glides forward and never back
            s.planted = lastPlanted; s.cats = lastGuarded; s.report = report; s.reportStart = reportStart; s.frozenAge = frozenAge
        case .over: s.planted = min(city.acres, city.people * acresPerPerson); s.grade = grade(city)
        }
        return s
    }

    // MARK: a reign

    /// Wipes the last reign and seats a new one. Everything a reign owns is reset here and nowhere else.
    private func fresh(_ mode: Mode, level: Difficulty) {
        self.mode = mode
        day = Self.today
        let seed = fixedSeed ?? (mode == .daily ? UInt64(day) : UInt64.random(in: .min ... .max))
        rng = SplitMix(x: seed)
        storyRng = SplitMix(x: seed ^ 0x5707)
        playing = level
        city = City(grain: level.rules.grain, acres: level.rules.acres)
        log = []; report = nil; seen = []; frozenAge = nil; note = ""; card = nil
        lastPlanted = 0; lastGuarded = false
        Sound.shared.cancelQueued()
        Sound.shared.startMusic()
    }

    func begin(_ mode: Mode = .story) {
        stopDemo()
        fresh(mode, level: mode == .story ? difficulty : .normal)
        enterYear()
    }

    /// Story mode stops at the gate of each year for a card: the opening, a turning point, or an omen.
    private func enterYear() {
        note = ""; card = nil
        yearStart = Self.now
        if mode == .story && !demo {
            let story = Story.shared
            if city.year == 1 { card = StoryCard(title: story.intro.title, text: story.intro.text) }
            else if let c = story.interludes["\(city.year)"] { card = StoryCard(title: c.title, text: c.text) }
            else if let o = story.omen(for: city, seen: seen, rng: &storyRng) {
                seen.insert(o.id)
                card = StoryCard(title: o.title, text: o.text, omen: o)
                Feel.omen()
            }
        }
        if card == nil { toOrders() } else { phase = .card }
    }

    func canAfford(_ ch: Story.Choice) -> Bool { Story.canAfford(ch, city) }

    func choose(_ index: Int) {
        guard phase == .card else { return }
        if let o = card?.omen, o.choices.indices.contains(index) {
            note = Story.shared.apply(o.choices[index], to: &city, rng: &storyRng, harvest: rng)
        }
        Feel.tap()
        toOrders()
    }

    private func toOrders() {
        card = nil
        save(atGate: false)
        orders = city.sensibleOrders
        phase = .orders
    }

    /// Keeps each order inside what the earlier ones leave possible.
    func clamp() {
        orders.buy = min(max(orders.buy, city.minBuy), city.maxBuy)
        orders.feed = min(max(orders.feed, 0), city.maxFeed(orders))
        orders.plant = min(max(orders.plant, 0), city.maxPlant(orders))
    }

    func submit() {
        guard phase == .orders, error.isEmpty else { return }
        lastPlanted = orders.plant
        lastGuarded = city.guarded
        let r = step(&city, orders, &rng, rules: playing.rules)
        report = r; log.append(r)
        reportStart = Self.now
        phase = .report
        // The dice are thrown: save now, so quitting on this screen cannot buy a second try at the year.
        if city.over.isEmpty { save(atGate: true) } else { finish() }
        Feel.year(r)
    }

    /// Counts the reign the moment it ends.
    private func finish() {
        guard !demo else { return }
        let g = grade(city)
        reigns += 1
        if best.isEmpty || g > (Grade(rawValue: best) ?? .f) { best = g.rawValue }
        if mode == .daily && dailyDay != day { dailyDay = day; dailyGrade = g.rawValue }
        clearSave()
    }

    func next() {
        guard phase == .report else { return }
        Sound.shared.cancelQueued()
        guard !city.over.isEmpty else { return enterYear() }
        phase = .over
        Feel.verdict(grade(city))
    }

    /// Back to the title. A reign in progress stays saved.
    func quitToMenu() {
        stopDemo()
        Sound.shared.cancelQueued()
        phase = .title
    }

    // MARK: keep playing later

    private func save(atGate: Bool) {
        guard !demo, frozenAge == nil,
              let data = try? JSONEncoder().encode(Saved(city: city, log: log, mode: mode, difficulty: playing, rng: rng, storyRng: storyRng,
                                                         seen: Array(seen), day: day, atGate: atGate)) else { return }
        defaults.set(data, forKey: "saved"); canResume = true
    }

    private func clearSave() {
        defaults.removeObject(forKey: "saved"); canResume = false
    }

    func resume() {
        guard let data = defaults.data(forKey: "saved"), let s = try? JSONDecoder().decode(Saved.self, from: data) else {
            return clearSave()  // a save this build cannot read is no save
        }
        stopDemo()
        city = s.city; log = s.log; mode = s.mode; playing = s.difficulty; rng = s.rng; storyRng = s.storyRng; seen = Set(s.seen); day = s.day
        report = nil; frozenAge = nil; note = ""; card = nil
        Sound.shared.startMusic()
        if s.atGate { enterYear() } else { yearStart = Self.now; toOrders() }
    }

    func resetRecords() {
        best = ""; reigns = 0; dailyDay = 0; dailyGrade = ""
    }

    // MARK: demo, the robot ruler plays a whole reign while you watch

    func startDemo() {
        stopDemo()
        demo = true
        fresh(.classic, level: .normal)
        yearStart = Self.now
        toOrders()
        demoTask = Task { @MainActor [weak self] in
            while let self, self.demo, !Task.isCancelled {
                switch self.phase {
                case .orders:
                    try? await Task.sleep(for: .seconds(1.2))
                    guard self.demo, !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.8)) { self.orders = Ruler.legal(self.city) }
                    try? await Task.sleep(for: .seconds(1.5))
                    guard self.demo, !Task.isCancelled else { return }
                    self.submit()
                case .report:
                    try? await Task.sleep(for: .seconds(self.report?.plague == true ? 7.5 : 5))
                    guard self.demo, !Task.isCancelled else { return }
                    self.next()
                default:
                    return
                }
            }
        }
    }

    func stopDemo() {
        demo = false
        demoTask?.cancel()
        demoTask = nil
    }

    // MARK: staged moments for screenshots: HAMURABI_SHOT=title|card|orders|report|plague|over

    func stage(_ shot: String) {
        stopDemo()
        mode = shot == "card" ? .story : .classic
        frozenAge = 0  // staged games are never saved; the real value is set below
        /// Plays seeds in turn and stops on the first year that matches.
        func play(_ robot: Bool, until match: (YearReport) -> Bool) -> Bool {
            for seed in UInt64(0)..<500 {
                var dice = SplitMix(x: seed), c = City(), years: [YearReport] = []
                while c.over.isEmpty {
                    let o = robot ? Ruler.legal(c) : c.sensibleOrders
                    let r = step(&c, o, &dice)
                    years.append(r)
                    if c.over.isEmpty && r.year >= 3 && match(r) {
                        city = c; report = r; log = years; lastPlanted = o.plant; rng = dice
                        return true
                    }
                }
            }
            return false
        }
        switch shot {
        case "orders" where play(true, until: { $0.year == 4 && !$0.plague }):
            orders = city.sensibleOrders; phase = .orders
        case "report" where play(false, until: { $0.yield >= 4 && $0.rats > 0 && $0.born > 0 && !$0.plague }):
            frozenAge = 2.3; phase = .report
        case "plague" where play(false, until: { $0.plague && $0.yield >= 3 && $0.starved == 0 }):
            frozenAge = 5.0; phase = .report
        case "card":
            city = City(); city.year = 3
            if let o = Story.shared.omens.first(where: { $0.id == "refugees" }) { card = StoryCard(title: o.title, text: o.text, omen: o); phase = .card }
        case "over":
            if let seed = (UInt64(0)..<500).first(where: { grade(Ruler.reign(seed: $0)) == .aPlus }) {
                var dice = SplitMix(x: seed); city = City(); log = []
                while city.over.isEmpty { log.append(step(&city, Ruler.legal(city), &dice)) }
                phase = .over
            }
        default: phase = .title
        }
        if phase != .report { frozenAge = nil }
        if ProcessInfo.processInfo.environment["HAMURABI_LIVE"] != nil, frozenAge != nil {  // for the trailer: let the year play out
            frozenAge = nil
            reportStart = Self.now + 2.5
        }
    }
}
