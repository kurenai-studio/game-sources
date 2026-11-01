import SwiftUI

struct RootView: View {
    @State private var game = GameModel()
    @State private var showRules = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 700
            let reserve = (compact ? 340 : 200) + geo.safeAreaInsets.bottom
            ZStack(alignment: .bottom) {
                GameScene(snap: game.snapshot, reserve: reserve).ignoresSafeArea()
                VStack(spacing: 0) {
                    HUD(game: game, compact: compact, showRules: $showRules)
                    if game.phase == .title && !compact { TitleHeading(compact: compact).transition(.opacity) }
                    Spacer(minLength: 0)
                    // On a phone the city fills the top, so the name sits low, just above the buttons.
                    if game.phase == .title && compact { TitleHeading(compact: compact).padding(.bottom, 10).transition(.opacity) }
                    Group {
                        switch game.phase {
                        case .title: TitlePanel(game: game, compact: compact)
                        case .card: CardPanel(game: game, compact: compact)
                        case .orders: OrdersPanel(game: game, compact: compact)
                        case .report: ReportPanel(game: game, compact: compact)
                        case .over: OverPanel(game: game, compact: compact)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(maxWidth: 1040)
                    .padding(.horizontal, compact ? 10 : 18)
                    .padding(.bottom, compact ? 8 : 16)
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.15), value: game.phase)
        }
        .background(Theme.sky)
        .foregroundStyle(Theme.ink)
        .tint(Theme.accent)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showRules) { SettingsSheet(game: game) }
        .onAppear {
            if let shot = ProcessInfo.processInfo.environment["HAMURABI_SHOT"] { game.stage(shot) }
        }
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 580)
        #endif
    }
}

// MARK: top bar

struct HUD: View {
    @Bindable var game: GameModel
    let compact: Bool
    @Binding var showRules: Bool

    var body: some View {
        let c = game.city
        HStack(spacing: 8) {
            if game.phase != .title && game.phase != .over {
                VStack(spacing: 6) {
                    HStack(spacing: compact ? 12 : 26) {
                        stat("Year", "\(game.phase == .report ? game.report?.year ?? c.year : min(c.year, years)) of \(years)")
                        stat("People", fmt(c.people))
                        stat("Acres", fmt(c.acres))
                        stat("Grain", fmt(c.grain))
                    }
                    HStack(spacing: 5) {  // the reign so far: one pip a year, red for a year with deaths
                        ForEach(1...years, id: \.self) { y in
                            let past = y - 1 < game.log.count ? game.log[y - 1] : nil
                            Capsule().fill(past == nil ? Theme.line : (past!.starved > 0 || past!.plague) ? Theme.accent : Theme.ink)
                                .frame(width: y == c.year && past == nil ? 16 : 8, height: 4)
                        }
                    }
                }
                .padding(.horizontal, compact ? 14 : 18).padding(.vertical, 8)
                .glass(24)
                .accessibilityElement(children: .combine)
            }
            Spacer(minLength: 0)
            if game.demo {
                Button("Play it yourself") { game.begin() }.buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 10).glass(20)
            } else if game.phase != .title && game.mode != .story && !compact {
                Text(game.mode == .daily ? "Today's game" : "Classic 1968").font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
                    .padding(.horizontal, 12).padding(.vertical, 10).glass(20)
            }
            round(game.muted ? "speaker.slash.fill" : "speaker.wave.2.fill", game.muted ? "Turn sound on" : "Turn sound off") { game.muted.toggle() }
            round("gearshape.fill", "Settings and how to play") { showRules = true }
        }
        .padding(.horizontal, compact ? 10 : 18).padding(.top, topInset)
    }

    /// On the Mac the bar sits under the window buttons.
    private var topInset: CGFloat {
        #if os(macOS)
        34
        #else
        10
        #endif
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.headline).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                .contentTransition(.numericText()).animation(.snappy, value: value)
            Text(label).font(.caption2).foregroundStyle(Theme.muted)
        }
    }

    private func round(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.subheadline.weight(.semibold)).frame(width: 40, height: 40).contentShape(Rectangle()) }
            .buttonStyle(.plain).glass(20).accessibilityLabel(label)
    }
}

// MARK: title

struct TitleHeading: View {
    let compact: Bool
    var body: some View {
        VStack(spacing: 6) {
            Text("Hamurapi").font(.system(size: compact ? 54 : 78, weight: .heavy)).tracking(-1)
            Text("Be king for 10 years. Feed your people. Keep your crown.")
                .font(compact ? .subheadline : .title3).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 26).padding(.vertical, 14).glass(30)
        .padding(.top, compact ? 10 : 6).padding(.horizontal, 16)
    }
}

struct TitlePanel: View {
    let game: GameModel
    let compact: Bool

    var body: some View {
        VStack(spacing: 10) {
            if game.canResume {
                Button("Keep playing") { game.resume() }.buttonStyle(PrimaryButton()).keyboardShortcut(.defaultAction)
                Button("Start a new game") { game.begin(.story) }.buttonStyle(QuietButton())
            } else {
                Button("Start a new game") { game.begin(.story) }.buttonStyle(PrimaryButton()).keyboardShortcut(.defaultAction)
            }
            HStack(spacing: 8) {
                Button(game.playedToday ? "Today: \(game.dailyGrade)" : "Today's game") { game.begin(.daily) }.buttonStyle(QuietButton())
                    .accessibilityHint("Everyone playing today gets the same luck")
                Button("Classic 1968") { game.begin(.classic) }.buttonStyle(QuietButton())
                Button("Watch a demo") { game.startDemo() }.buttonStyle(QuietButton())
            }
            if !game.best.isEmpty {
                Text("Best grade \(game.best) in \(game.reigns) \(game.reigns == 1 ? "game" : "games")")
                    .font(.footnote.weight(.medium)).foregroundStyle(Theme.muted)
            }
            Text(Credits.line).font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
        .padding(compact ? 14 : 18).glass(28)
        .frame(maxWidth: 620)
    }
}

enum Credits {
    static let line = "Based on Hamurabi by Doug Dyment, 1968. Copyright 2026 Joshua Trommel. MIT License."
}

// MARK: story card

struct CardPanel: View {
    let game: GameModel
    let compact: Bool

    var body: some View {
        if let card = game.card {
            VStack(alignment: .leading, spacing: 12) {
                Text(card.title).font(.title2.weight(.bold))
                Text(card.text).font(.body).fixedSize(horizontal: false, vertical: true)
                if let omen = card.omen {
                    ForEach(Array(omen.choices.enumerated()), id: \.offset) { i, ch in
                        if i == 0 { Button(ch.label) { game.choose(i) }.buttonStyle(PrimaryButton()).disabled(!game.canAfford(ch)) }
                        else { Button(ch.label) { game.choose(i) }.buttonStyle(QuietButton()).disabled(!game.canAfford(ch)) }
                    }
                } else {
                    Button("Continue") { game.choose(0) }.buttonStyle(PrimaryButton()).keyboardShortcut(.defaultAction)
                }
            }
            .padding(compact ? 16 : 22).glass(28)
            .frame(maxWidth: 560)
        }
    }
}

// MARK: orders

struct OrdersPanel: View {
    @Bindable var game: GameModel
    let compact: Bool

    var body: some View {
        let c = game.city, o = game.orders
        let left = c.grain - o.buy * c.price - o.feed - o.plant
        let starving = c.people - min(o.feed / foodPerPerson, c.people)
        let word = !game.note.isEmpty ? game.note : game.hint

        let land = OrderControl(title: "Land", big: o.buy >= 0 ? "Buy \(fmt(o.buy))" : "Sell \(fmt(-o.buy))",
                                detail: "\(o.buy >= 0 ? "costs" : "pays") \(fmt(abs(o.buy) * c.price)) bushels, \(c.price) an acre",
                                value: $game.orders.buy, range: c.minBuy...max(c.maxBuy, c.minBuy), game: game, compact: compact)
        let feed = OrderControl(title: "Feed", big: fmt(o.feed),
                                detail: "feeds \(fmt(min(o.feed / foodPerPerson, c.people))) of \(fmt(c.people)) people",
                                value: $game.orders.feed, range: 0...c.maxFeed(o), game: game, compact: compact,
                                quick: ("Everyone", min(c.maxFeed(o), c.people * foodPerPerson)))
        let plant = OrderControl(title: "Plant", big: fmt(o.plant),
                                 detail: "acres, uses \(fmt(o.plant)) bushels of seed",
                                 value: $game.orders.plant, range: 0...c.maxPlant(o), game: game, compact: compact,
                                 quick: ("All I can", c.maxPlant(o)))
        let summary = VStack(alignment: .leading, spacing: 6) {
            HStack { Text("Grain left").font(.caption).foregroundStyle(Theme.muted); Spacer()
                Text(fmt(left)).font(.headline).monospacedDigit().foregroundStyle(left < 0 ? Theme.accent : Theme.ink) }
            if !game.error.isEmpty { Text(game.error).font(.caption).foregroundStyle(Theme.accent).lineLimit(2) }
            else if starving > 0 { Text("\(fmt(starving)) will go hungry.\(game.shortOfGrain && o.buy >= 0 ? " Sell land to buy food." : "")").font(.caption.weight(.semibold)).foregroundStyle(Theme.accent) }
            else { Text("Everyone eats").font(.caption).foregroundStyle(Theme.muted) }
            Button("End the year") { game.submit() }.buttonStyle(PrimaryButton())
                .disabled(!game.error.isEmpty || game.demo).keyboardShortcut(.defaultAction)
        }

        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            if !word.isEmpty {
                Text(word).font(.footnote).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12).padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }
            if compact {
                VStack(spacing: 8) { land; feed; plant; summary }
            } else {
                HStack(alignment: .top, spacing: 16) { land; feed; plant; summary.frame(width: 190) }
            }
        }
        .padding(compact ? 14 : 18).glass(28)
        .disabled(game.demo)
    }
}

struct OrderControl: View {
    let title: String, big: String, detail: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let game: GameModel
    let compact: Bool
    var quick: (String, Int)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(compact ? .subheadline.weight(.semibold) : .headline)
                if compact { Text(big).font(.subheadline.weight(.bold)).monospacedDigit() }
                Spacer()
                if compact { Text(detail).font(.caption).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.8) }
                if let q = quick {
                    Button(q.0) { withAnimation(.easeOut(duration: 0.2)) { value = q.1; game.clamp() }; Feel.tap() }
                        .buttonStyle(.plain).font(.caption.weight(.semibold)).foregroundStyle(Theme.accent)
                        .accessibilityLabel("\(title): \(q.0)")
                }
            }
            if !compact {
                Text(big).font(.title2.weight(.bold)).monospacedDigit().contentTransition(.numericText())
                Text(detail).font(.caption).foregroundStyle(Theme.muted)
            }
            HStack(spacing: 8) {
                step(-1, "minus.circle", "Less \(title)")
                if range.lowerBound < range.upperBound {
                    Slider(value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()); game.clamp() }),
                           in: Double(range.lowerBound)...Double(range.upperBound))
                        .accessibilityLabel(title).accessibilityValue(big)
                } else {
                    Capsule().fill(Theme.line).frame(height: 4)
                }
                step(1, "plus.circle", "More \(title)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func step(_ d: Int, _ symbol: String, _ label: String) -> some View {
        Button { value += d; game.clamp() } label: { Image(systemName: symbol).font(.title3).frame(width: 30, height: 30).contentShape(Rectangle()) }
            .buttonStyle(.plain).foregroundStyle(Theme.accent).accessibilityLabel(label)
    }
}

// MARK: report

struct ReportPanel: View {
    let game: GameModel
    let compact: Bool

    var body: some View {
        if let r = game.report {
            let c = game.city
            VStack(alignment: .leading, spacing: 10) {
                Text("Year \(r.year)").font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    line("\(r.yield <= 2 ? "Bad" : r.yield >= 4 ? "Great" : "Good") harvest: \(r.yield) bushels an acre, \(fmt(r.harvest)) in all.", bad: r.yield <= 2)
                    line(r.rats > 0 ? "Rats ate \(fmt(r.rats)) bushels." : "No rats this year.", bad: r.rats > 0)
                    line(r.starved > 0 ? "\(fmt(r.starved)) \(r.starved == 1 ? "person" : "people") starved." : "Nobody starved.", bad: r.starved > 0)
                    if r.born > 0 { line("\(fmt(r.born)) new \(r.born == 1 ? "person" : "people") moved in.") }
                    if r.plague { line("A sickness killed half your people.", bad: true) }
                    if !c.over.isEmpty { line(c.over, bad: c.impeached) }
                }
                Button(c.over.isEmpty ? "Next year" : "See your grade") { game.next() }
                    .buttonStyle(PrimaryButton()).keyboardShortcut(.defaultAction).disabled(game.demo)
            }
            .padding(compact ? 14 : 18).glass(28)
            .frame(maxWidth: 520)
        }
    }

    private func line(_ t: String, bad: Bool = false) -> some View {
        Text(t).font(.subheadline).foregroundStyle(bad ? Theme.accent : Theme.ink).fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: verdict

struct OverPanel: View {
    let game: GameModel
    let compact: Bool

    var body: some View {
        let c = game.city, g = grade(c)
        let each = c.people == 0 ? "none" : String(format: "%.1f", Double(c.acres) / Double(c.people))
        let stats = HStack(alignment: .top, spacing: compact ? 12 : 18) {
            stat("People", fmt(c.people)); stat("Acres each", each); stat("Starved", fmt(c.starvedTotal))
            stat("Harvested", fmt(game.harvested)); stat("Plagues", "\(game.plagues)")
        }
        let actions = VStack(spacing: 8) {
            Button("Play again") { game.begin(game.mode == .daily ? .story : game.mode) }.buttonStyle(PrimaryButton()).keyboardShortcut(.defaultAction)
            HStack(spacing: 8) {
                if !game.demo { ShareLink(item: game.shareText) { Text("Share") }.buttonStyle(QuietButton()) }
                Button("Menu") { game.quitToMenu() }.buttonStyle(QuietButton())
            }
        }
        let letter = Text(g.rawValue).font(.system(size: compact ? 64 : 88, weight: .heavy)).foregroundStyle(g == .f ? Theme.accent : Theme.ink)
            .accessibilityLabel("Grade \(g.rawValue)")
        let words = VStack(alignment: .leading, spacing: 6) {
            Text(game.demo ? "The robot played this one. " + c.over : c.over).font(.caption).foregroundStyle(Theme.muted)
            Text(Story.shared.epilogues[g.rawValue] ?? "").font(.subheadline).fixedSize(horizontal: false, vertical: true)
            if g != .aPlus && !c.impeached {
                Text("For an A+, let almost nobody starve and keep 10 acres for each person.").font(.caption).foregroundStyle(Theme.muted)
            }
        }
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 10) { HStack(spacing: 14) { letter; words }; stats; actions }
            } else {
                HStack(spacing: 22) { letter; VStack(alignment: .leading, spacing: 10) { words; stats }; actions.frame(width: 210) }
            }
        }
        .padding(compact ? 14 : 18).glass(28)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.headline).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption2).foregroundStyle(Theme.muted).lineLimit(1)
        }
    }
}

// MARK: settings, rules and credits

struct SettingsSheet: View {
    @Bindable var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Settings").font(.title2.weight(.bold)); Spacer()
                    Button("Done") { dismiss() }.buttonStyle(.plain).foregroundStyle(Theme.accent).font(.headline) }
                VStack(alignment: .leading, spacing: 6) {
                    Text("How hard").font(.subheadline.weight(.bold))
                    Picker("How hard", selection: $game.difficulty) {
                        Text("Easy").tag(GameModel.Difficulty.easy)
                        Text("Normal").tag(GameModel.Difficulty.normal)
                        Text("Hard").tag(GameModel.Difficulty.hard)
                    }.pickerStyle(.segmented).labelsHidden()
                    Text(game.difficulty == .easy ? "More grain and land to start. Fewer rats."
                         : game.difficulty == .hard ? "Less grain and land to start. More rats."
                         : "The same odds as the 1968 game.").foregroundStyle(Theme.muted)
                    Text("This changes new story games. Classic and today's game always use Normal.").font(.caption).foregroundStyle(Theme.muted)
                }
                Toggle("Music", isOn: $game.music)
                Toggle("Sound", isOn: Binding(get: { !game.muted }, set: { game.muted = !$0 }))
                if game.phase != .title {
                    Button("Back to the menu") { game.quitToMenu(); dismiss() }.buttonStyle(.plain).foregroundStyle(Theme.accent)
                    Text("Your game is saved at the start of each year.").font(.caption).foregroundStyle(Theme.muted)
                }
                Button("Clear my best grade") { confirmReset = true }.buttonStyle(.plain).foregroundStyle(Theme.accent)
                    .confirmationDialog("Clear your best grade and game count?", isPresented: $confirmReset) {
                        Button("Clear", role: .destructive) { game.resetRecords() }
                    }
                Divider()
                Text("How to play").font(.headline)
                Text("You are king for 10 years. Each year you make 3 choices.")
                para("Land", "Buy or sell land. The price changes every year, from 17 to 26 bushels an acre.")
                para("Feed", "Each person eats \(foodPerPerson) bushels a year. If too many people starve in one year, you are thrown out.")
                para("Plant", "Each acre needs 1 bushel of seed. One person can farm \(acresPerPerson) acres. You get back 1 to 5 bushels an acre. It is luck.")
                Text("Then rats, sickness and the harvest decide how the year went. After 10 years you get a grade. For an A+, let almost nobody starve and keep 10 acres for each person.")
                para("3 ways to play", "A new game has a story with choices. Classic is the 1968 game with nothing added. Today's game gives everyone the same luck for one day.")
                Divider()
                Text("Credits").font(.headline)
                Text("This game began as The Sumer Game by Mabel Addis and William McKay in 1964. Doug Dyment wrote Hamurabi in 1968. David Ahl put it in his book 101 BASIC Computer Games in 1973, and it spread everywhere. This version is new: new code, new art, new music and a new story. Nothing is copied from the old ones.")
                Text("Copyright 2026 Joshua Trommel. MIT License.").foregroundStyle(Theme.muted)
            }
            .font(.subheadline)
            .padding(24)
        }
        .foregroundStyle(Theme.ink)
        .tint(Theme.accent)
        .background(Theme.sky)
        .preferredColorScheme(.light)
        #if os(macOS)
        .frame(width: 480, height: 640)
        #endif
    }
    private func para(_ h: String, _ t: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(h).font(.subheadline.weight(.bold)); Text(t).foregroundStyle(Theme.muted) }
    }
}
