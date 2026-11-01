import XCTest
@testable import Hamurapi

final class HamurapiTests: XCTestCase {
    private func scratch() -> UserDefaults {
        let d = UserDefaults(suiteName: "hamurapi.test")!; d.removePersistentDomain(forName: "hamurapi.test"); return d
    }

    // MARK: the rules

    func testInvariantsAcross200Reigns() {
        for seed in 0..<200 {
            var rng = SplitMix(x: UInt64(seed)), c = City()
            while c.over.isEmpty {
                let o = c.sensibleOrders
                XCTAssertEqual(check(c, o), "", "seed \(seed)")
                _ = step(&c, o, &rng)
                XCTAssertTrue(c.grain >= 0 && c.people >= 0 && c.acres >= 0, "seed \(seed)")
            }
            XCTAssertLessThanOrEqual(c.year, years + 1)
        }
    }

    func testIllegalOrdersRefused() {
        let c = City()
        XCTAssertNotEqual(check(c, Orders(buy: 1_000_000)), "")
        XCTAssertNotEqual(check(c, Orders(plant: 5000)), "")
        XCTAssertNotEqual(check(c, Orders(buy: -2000)), "")
        XCTAssertNotEqual(check(c, Orders(feed: -1)), "")
    }

    func testGrades() {
        XCTAssertEqual(grade(City(over: "x", impeached: true)), .f)
        XCTAssertEqual(grade(City(year: 11, people: 90)), .aPlus)
        XCTAssertEqual(grade(City(year: 11, people: 120)), .c)
        XCTAssertTrue(Grade.f < .c && Grade.c < .b && Grade.b < .aPlus)
    }

    /// The same number `python3 ruler.py --golden` prints and the web game checks. If it moves, a port has drifted.
    func testGoldenMatchesPythonAndWeb() {
        var total = 0
        for seed in 0..<200 {
            let c = Ruler.reign(seed: UInt64(seed))
            total += c.people + 3 * c.acres + 7 * c.grain + 11 * c.starvedTotal
        }
        XCTAssertEqual(total, 639940)
    }

    /// The same script as storyGolden() in web/play/rules.js. If the numbers part, the story has drifted between app and web.
    func testStoryGoldenMatchesWeb() {
        let story = Story.shared
        var total = 0
        for seed in 0..<120 {
            let rules = [Rules.normal, .easy, .hard][seed % 3]
            var rng = SplitMix(x: UInt64(seed)), srng = SplitMix(x: UInt64(seed) ^ 0x5707)
            var c = City(grain: rules.grain, acres: rules.acres), seen: Set<String> = []
            while c.over.isEmpty {
                if c.year != 1 && story.interludes["\(c.year)"] == nil, let o = story.omen(for: c, seen: seen, rng: &srng) {
                    seen.insert(o.id)
                    if let pick = [seed % 2, 1 - seed % 2].first(where: { Story.canAfford(o.choices[$0], c) }) {
                        _ = story.apply(o.choices[pick], to: &c, rng: &srng, harvest: rng)
                    }
                }
                _ = step(&c, Ruler.legal(c), &rng, rules: rules)
            }
            total += c.people + 3 * c.acres + 7 * c.grain + 11 * c.starvedTotal
            total += 13 * [Grade.f, .c, .b, .aPlus].firstIndex(of: grade(c))! + 17 * seen.count
        }
        XCTAssertEqual(total, 390695)
    }

    // MARK: benchmarks

    func testRulerEarnsAPlusMostOfTheTime() {
        let wins = (0..<1000).filter { grade(Ruler.reign(seed: UInt64($0))) == .aPlus }.count
        XCTAssertGreaterThanOrEqual(wins, 850, "the robot ruler got worse: \(wins) of 1000")
    }

    func testThousandReignsBenchmark() {
        measure { for seed in 0..<1000 { _ = Ruler.reign(seed: UInt64(seed)) } }
    }

    // MARK: the game around the rules

    func testClampKeepsOrdersLegal() {
        let g = GameModel(seed: 1, defaults: scratch()); g.begin(.classic)
        for b in [-5000, 0, 5000] { g.orders = Orders(buy: b, feed: 99999, plant: 99999); g.clamp(); XCTAssertEqual(g.error, "") }
    }

    func testClassicReignThroughModel() {
        let d = scratch(), g = GameModel(seed: 3, defaults: d); g.begin(.classic)
        while g.phase != .over { XCTAssertNotEqual(g.phase, .card); if g.phase == .orders { g.submit() } else { g.next() } }
        XCTAssertFalse(g.log.isEmpty)
        XCTAssertEqual(g.reigns, 1)
        XCTAssertEqual(d.string(forKey: "best"), grade(g.city).rawValue)
    }

    func testStoryReignsStayLegalWhateverYouChoose() {
        for seed in 0..<60 {
            let g = GameModel(seed: UInt64(seed), defaults: scratch()); g.begin(.story)
            XCTAssertEqual(g.phase, .card, "a story opens on the crown card")
            var cards = 0
            while g.phase != .over {
                switch g.phase {
                case .card:
                    cards += 1
                    let choices = g.card?.omen?.choices ?? []
                    g.choose(choices.indices.first { seed % 2 == $0 % 2 && g.canAfford(choices[$0]) } ?? max(0, choices.count - 1))
                case .orders:
                    XCTAssertEqual(g.error, "", "seed \(seed) year \(g.city.year)")
                    g.submit()
                default: g.next()
                }
                XCTAssertTrue(g.city.grain >= 0 && g.city.people >= 0 && g.city.acres >= 0)
            }
            XCTAssertGreaterThanOrEqual(cards, 1)
        }
    }

    func testEveryOmenChoiceAppliesCleanly() {
        let story = Story.shared
        XCTAssertEqual(story.omens.count, 10)
        for omen in story.omens {
            XCTAssertEqual(omen.choices.count, 2, omen.id)
            for ch in omen.choices {
                var c = City(), rng = SplitMix(x: 1)
                let said = story.apply(ch, to: &c, rng: &rng, harvest: SplitMix(x: 2))
                XCTAssertFalse(said.isEmpty)
                XCTAssertTrue(c.grain >= 0 && c.people >= 1 && c.acres >= 1, omen.id)
            }
        }
        for g in ["A+", "B", "C", "F"] { XCTAssertNotNil(story.epilogues[g]) }
    }

    func testCatsStopRatsOnceAndBarleyAddsOne() {
        var plain = City(), helped = City()
        helped.guarded = true; helped.yieldBonus = 1
        let o = Orders(buy: 0, feed: 2000, plant: 300)  // leaves grain in store for the rats to find
        let seed = (UInt64(0)..<200).first { s in var r = SplitMix(x: s), c = City(); return step(&c, o, &r).rats > 0 }!
        var a = SplitMix(x: seed), b = SplitMix(x: seed)
        let r1 = step(&plain, o, &a), r2 = step(&helped, o, &b)
        XCTAssertGreaterThan(r1.rats, 0)
        XCTAssertEqual(r2.rats, 0)
        XCTAssertEqual(r2.yield, r1.yield + 1)
        XCTAssertFalse(helped.guarded)
        XCTAssertEqual(helped.yieldBonus, 0)
        XCTAssertEqual(plain.price, helped.price, "helping must not change the dice")
    }

    func testDemoDoesNotCountAsYourReign() {
        let d = scratch(), g = GameModel(seed: 5, defaults: d)
        g.startDemo(); g.stopDemo(); g.demo = true
        while g.phase != .over { if g.phase == .orders { g.orders = Ruler.legal(g.city); g.submit() } else { g.next() } }
        XCTAssertEqual(g.reigns, 0)
        XCTAssertEqual(g.best, "")
    }

    func testEverySpriteAndSoundIsInTheBundle() {
        for name in Sprites.names { XCTAssertNotNil(Sprites.image(name), name) }
        for name in ["music", "tap", "harvest", "poor", "rats", "starve", "arrive", "plague", "omen", "win", "lose"] {
            XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "mp3"), name)
        }
    }

    func testDifficultyChangesTheOddsNotTheDice() {
        XCTAssertGreaterThan(Rules.easy.grain, Rules.normal.grain)
        XCTAssertLessThan(Rules.hard.grain, Rules.normal.grain)
        let hardWins = (0..<300).filter { s in
            var r = SplitMix(x: UInt64(s)), c = City(grain: Rules.hard.grain, acres: Rules.hard.acres)
            while c.over.isEmpty { _ = step(&c, Ruler.legal(c), &r, rules: .hard) }
            return grade(c) == .aPlus
        }.count
        let easyWins = (0..<300).filter { s in
            var r = SplitMix(x: UInt64(s)), c = City(grain: Rules.easy.grain, acres: Rules.easy.acres)
            while c.over.isEmpty { _ = step(&c, Ruler.legal(c), &r, rules: .easy) }
            return grade(c) == .aPlus
        }.count
        XCTAssertGreaterThan(easyWins, hardWins)
    }

    func testAReignSurvivesQuitting() {
        let d = scratch(), g = GameModel(seed: 9, defaults: d); g.begin(.classic)
        g.submit(); g.next(); g.submit(); g.next()
        let city = g.city
        let back = GameModel(defaults: d)
        XCTAssertTrue(back.canResume)
        back.resume()
        XCTAssertEqual(back.phase, .orders)
        XCTAssertEqual(back.city.year, city.year)
        XCTAssertEqual(back.city.grain, city.grain)
        XCTAssertEqual(back.log.count, 2)
        g.submit(); back.submit()
        XCTAssertEqual(g.city.grain, back.city.grain, "the dice carry on where they stopped")
        while back.phase != .over { if back.phase == .orders { back.submit() } else { back.next() } }
        XCTAssertFalse(GameModel(defaults: d).canResume, "a finished reign leaves nothing to resume")
    }

    /// Selling every acre used to disable both buttons on the next card, with no way out.
    func testNoCardCanTrapYou() {
        var c = City(); c.acres = 0
        for omen in Story.shared.omens { XCTAssertTrue(omen.choices.contains { Story.canAfford($0, c) }, omen.id) }
        c.grain = 0
        for omen in Story.shared.omens { XCTAssertTrue(omen.choices.contains { Story.canAfford($0, c) }, omen.id) }
    }

    func testQuittingOnTheReportCannotRedoTheYear() {
        let d = scratch(), g = GameModel(seed: 4, defaults: d); g.begin(.classic)
        g.submit()  // the dice are thrown; the player is looking at the report
        let back = GameModel(seed: 4, defaults: d); back.resume()
        XCTAssertEqual(back.city.year, g.city.year)
        XCTAssertEqual(back.city.grain, g.city.grain)
        XCTAssertEqual(back.log.count, 1)
    }

    func testAnEndedReignCountsEvenIfYouNeverLookAtTheGrade() {
        let d = scratch(), g = GameModel(seed: 4, defaults: d); g.begin(.classic)
        g.orders = Orders(); g.submit()  // feed nobody: thrown out on the spot
        XCTAssertTrue(g.city.impeached)
        let back = GameModel(defaults: d)
        XCTAssertEqual(back.reigns, 1)
        XCTAssertFalse(back.canResume)
        g.next(); g.next(); g.submit()  // extra taps do nothing
        XCTAssertEqual(g.reigns, 1)
        XCTAssertEqual(g.phase, .over)
    }

    func testAUnreadableSaveIsDropped() {
        let d = scratch(); d.set(Data("not a save".utf8), forKey: "saved")
        let g = GameModel(defaults: d)
        XCTAssertTrue(g.canResume)
        g.resume()
        XCTAssertFalse(g.canResume)
        XCTAssertEqual(g.phase, .title)
        XCTAssertNil(d.data(forKey: "saved"))
    }

    func testStagedScreenshotsLand() {
        for (shot, phase) in [("title", GameModel.Phase.title), ("card", .card), ("orders", .orders), ("report", .report), ("plague", .report), ("over", .over)] {
            let g = GameModel(defaults: scratch()); g.stage(shot)
            XCTAssertEqual(g.phase, phase, shot)
        }
    }
}
