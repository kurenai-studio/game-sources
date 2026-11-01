import SwiftUI

/// What the scene needs to draw the city and its year.
struct SceneSnapshot {
    var year = 1, people = 100, acres = 1000, grain = 2800, planted = 800
    var starved = 0            // deaths so far this reign; they stay on the hill as graves
    var report: YearReport?
    var reportStart: TimeInterval = 0
    var frozenAge: Double?     // screenshots pin the year's animation at one moment
    var grade: Grade?
    var omen: String?          // the story card on screen; some of them change the view
    var cats = false           // bought from the trader: they guard the barn this year
    var yearStart: TimeInterval = 0
}

/// Deterministic pseudo-random in [0, 1) so every sprite keeps its own habits from frame to frame.
private func rnd(_ i: Int, _ salt: Int) -> Double {
    var x = UInt64(truncatingIfNeeded: i &* 7919 &+ salt &* 104729 &+ 12345)
    x = (x ^ (x >> 15)) &* 0x2C1B3C6D; x = (x ^ (x >> 12)) &* 0x297A2D39; x ^= x >> 15
    return Double(x % 100_000) / 100_000
}
private func smooth(_ v: Double) -> Double { let c = min(max(v, 0), 1); return c * c * (3 - 2 * c) }
private func villagers(_ people: Int) -> Int { people <= 0 ? 0 : min(max(people / 4, 1), 40) }
private func graves(_ starved: Int) -> Int { min((starved + 3) / 4, 12) }

struct GameScene: View {
    let snap: SceneSnapshot
    /// Points at the bottom of the window the controls cover.
    let reserve: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || snap.frozenAge != nil)) { tl in
            Canvas(rendersAsynchronously: false) { ctx, size in
                let still = reduceMotion || snap.frozenAge != nil
                var p = Painter(ctx: ctx, size: size, reserve: reserve, snap: snap,
                                t: still ? 1.0 : tl.date.timeIntervalSinceReferenceDate, still: reduceMotion)
                p.drawAll()
            }
        }
        .background(Theme.sky)
        .accessibilityHidden(true)
    }
}

private struct Painter {
    var ctx: GraphicsContext
    let size: CGSize, snap: SceneSnapshot, t: Double
    let s: CGFloat                 // screen points per art pixel
    let W: Double, UH: Double, hz: Double
    let rt: Double                 // seconds into the year's report; huge when there is none
    var images: [String: GraphicsContext.ResolvedImage] = [:]

    init(ctx: GraphicsContext, size: CGSize, reserve: CGFloat, snap: SceneSnapshot, t: Double, still: Bool) {
        self.ctx = ctx; self.size = size; self.snap = snap; self.t = t
        s = max(2, min(size.width / 300, size.height / 190).rounded())
        W = Double(size.width / s)
        UH = max(80, Double((size.height - reserve) / s))
        hz = UH * 0.40
        if snap.report == nil { rt = 999 }
        else if let f = snap.frozenAge { rt = f }
        else { rt = still ? 999 : max(0, t - snap.reportStart) }
    }

    // MARK: primitives

    mutating func sprite(_ name: String) -> GraphicsContext.ResolvedImage? {
        if let hit = images[name] { return hit }
        guard let cg = Sprites.image(name) else { return nil }
        let r = ctx.resolve(Image(decorative: cg, scale: 1).interpolation(.none))
        images[name] = r
        return r
    }
    func w(_ name: String) -> Double { Double(Sprites.image(name)?.width ?? 0) }
    func h(_ name: String) -> Double { Double(Sprites.image(name)?.height ?? 0) }

    /// Draws a sprite with its top-left at art pixel (x, y).
    mutating func put(_ name: String, _ x: Double, _ y: Double, flip: Bool = false, alpha: Double = 1) {
        guard let img = sprite(name), alpha > 0 else { return }
        var c = ctx
        c.opacity = alpha
        let px = (CGFloat(x) * s).rounded(), py = (CGFloat(y) * s).rounded()
        let sw = img.size.width * s, sh = img.size.height * s
        if flip { c.translateBy(x: px + sw, y: py); c.scaleBy(x: -1, y: 1) } else { c.translateBy(x: px, y: py) }
        c.draw(img, in: CGRect(x: 0, y: 0, width: sw, height: sh))
    }

    /// Stands a sprite on the ground at (cx, footY) with a soft shadow under it.
    mutating func stand(_ name: String, _ cx: Double, _ footY: Double, flip: Bool = false, alpha: Double = 1, shadow: Bool = true, lift: Double = 0) {
        let sw = w(name), sh = h(name)
        if shadow && alpha > 0 {
            let r = CGRect(x: CGFloat(cx - sw * 0.42 + 1) * s, y: CGFloat(footY - 1.6) * s, width: CGFloat(sw * 0.84) * s, height: 3.2 * s)
            ctx.fill(Path(ellipseIn: r), with: .color(.black.opacity(0.13 * alpha)))
        }
        put(name, cx - sw / 2, footY - sh + 1 - lift, flip: flip, alpha: alpha)  // lift: the body bobs, the shadow stays down
    }

    mutating func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
        ctx.fill(Path(CGRect(x: CGFloat(x) * s, y: CGFloat(y) * s, width: CGFloat(w) * s, height: CGFloat(h) * s)), with: .color(color))
    }

    /// A number that floats up and fades, like "+4,000".
    mutating func label(_ text: String, _ x: Double, _ y: Double, from start: Double, color: Color) {
        let age = rt - start
        guard age > 0, age < 1.8 else { return }
        let at = CGPoint(x: CGFloat(x) * s, y: CGFloat(y - age * 9) * s)
        let size = max(13, 5.5 * s)
        var c = ctx
        c.opacity = age < 1.3 ? 1 : max(0, 1 - (age - 1.3) / 0.5)
        let back = c.resolve(Text(text).font(.system(size: size, weight: .heavy)).foregroundColor(.white))
        for (dx, dy) in [(-1.5, 0.0), (1.5, 0.0), (0.0, -1.5), (0.0, 1.5)] { c.draw(back, at: CGPoint(x: at.x + dx, y: at.y + dy)) }
        c.draw(c.resolve(Text(text).font(.system(size: size, weight: .heavy)).foregroundColor(color)), at: at)
    }

    // MARK: layout

    var granaryX: Double { W - 20 }
    var laneMin: Double { max(hz + 24, UH * 0.52) }
    var laneMax: Double { max(laneMin + 8, UH * 0.64) }
    var riverTop: Double { UH * 0.68 }
    var fieldTop: Double { UH * 0.78 }
    var fieldRows: Int { max(1, Int((UH - 4 - fieldTop) / 13)) }
    var fieldCols: Int { max(4, Int((W - 12) / 11)) }
    var plotSpread: Double { (W - 12) / Double(fieldCols) }

    // MARK: scene

    mutating func drawAll() {
        // A jolt when something bad lands.
        if let r = snap.report {
            let hit = (r.rats > 0 && rt > 1.4 && rt < 1.7) || (r.starved > 0 && rt > 1.8 && rt < 2.1) || (r.plague && rt > 3.4 && rt < 3.9)
            if hit { ctx.translateBy(x: CGFloat(Int(rt * 40) % 2 == 0 ? 1 : -1) * s, y: CGFloat(Int(rt * 31) % 2 == 0 ? 1 : -1) * s * 0.5) }
        }
        drawSky()
        drawGround()
        drawTown()
        drawFar()
        drawRiver()
        drawFields()
        drawGraves()
        drawFolk()
        drawEvents()
        drawWeather()
        let since = t - snap.yearStart
        if snap.yearStart > 0, snap.report == nil, snap.grade == nil, since >= 0, since < 2.2 {  // each year opens with its number
            var c = ctx
            c.opacity = min(1, since / 0.3) * min(1, (2.2 - since) / 0.6)
            let text = Text("Year \(snap.year)").font(.system(size: max(26, 11 * s), weight: .heavy)).foregroundColor(Theme.ink)
            c.draw(c.resolve(text), at: CGPoint(x: size.width / 2, y: CGFloat(hz * 0.45) * s))
        }
        let full = CGRect(origin: .zero, size: size).insetBy(dx: -4 * s, dy: -4 * s)
        ctx.fill(Path(full), with: .radialGradient(Gradient(colors: [.clear, .black.opacity(0.07)]),
                                                   center: CGPoint(x: size.width / 2, y: size.height * 0.4),
                                                   startRadius: min(size.width, size.height) * 0.45, endRadius: max(size.width, size.height) * 0.8))
    }

    mutating func drawSky() {
        // The reign is one long day: dawn in year one, a starry evening by year ten.
        let glide = snap.report == nil ? 1 : smooth(rt / 3)
        let p = min(max(Double(snap.year) - 2 + glide, 0), 9) / 9
        let dawn = smooth((0.25 - p) / 0.25), dusk = smooth((p - 0.55) / 0.45)
        func mix(_ a: [Double], _ b: [Double], _ k: Double) -> [Double] { zip(a, b).map { $0 + ($1 - $0) * k } }
        let top = mix(mix([0.985, 0.985, 0.98], [0.99, 0.955, 0.95], dawn), [0.56, 0.65, 0.82], dusk)
        let low = mix([0.925, 0.94, 0.955], [0.84, 0.88, 0.94], dusk)
        let sky = CGRect(x: -4 * s, y: -4 * s, width: size.width + 8 * s, height: CGFloat(hz) * s + 4 * s)
        ctx.fill(Path(sky), with: .linearGradient(Gradient(colors: [Color(red: top[0], green: top[1], blue: top[2]), Color(red: low[0], green: low[1], blue: low[2])]),
                                                  startPoint: .zero, endPoint: CGPoint(x: 0, y: CGFloat(hz) * s)))
        if dusk > 0.3 {
            for i in 0..<40 { rect((rnd(i, 50) * W).rounded(), (rnd(i, 51) * hz * 0.7).rounded(), 1, 1, .white.opacity((dusk - 0.3) / 0.7 * (0.6 + 0.4 * sin(t * 2 + Double(i))))) }
        }
        let sx = W * (0.30 + 0.45 * p), sy = hz * (0.80 - 0.26 * sin(p * .pi))
        let glow = CGRect(x: CGFloat(sx - 34) * s, y: CGFloat(sy - 34) * s, width: 68 * s, height: 68 * s)
        ctx.fill(Path(ellipseIn: glow), with: .radialGradient(Gradient(colors: [Theme.accent.opacity(0.22), Theme.accent.opacity(0)]),
                                                              center: CGPoint(x: CGFloat(sx) * s, y: CGFloat(sy) * s), startRadius: 0, endRadius: 34 * s))
        for k in 0..<5 {  // slow shafts of light
            let a = -0.9 + Double(k) * 0.45 + sin(t * 0.2 + Double(k)) * 0.05
            var ray = Path()
            ray.move(to: CGPoint(x: CGFloat(sx) * s, y: CGFloat(sy) * s))
            ray.addLine(to: CGPoint(x: CGFloat(sx + sin(a) * 260 - 9) * s, y: CGFloat(sy + cos(a) * 260) * s))
            ray.addLine(to: CGPoint(x: CGFloat(sx + sin(a) * 260 + 9) * s, y: CGFloat(sy + cos(a) * 260) * s))
            ctx.fill(ray, with: .color(.white.opacity(0.16)))
        }
        put("sun_\(Int(t / 0.7) % 2)", sx - w("sun_0") / 2, sy - h("sun_0") / 2)

        // Two ridges of far hills.
        for (layer, color) in [(0, Color(red: 0.90, green: 0.915, blue: 0.93)), (1, Color(red: 0.855, green: 0.87, blue: 0.89))] {
            var path = Path()
            path.move(to: CGPoint(x: -4 * s, y: CGFloat(hz) * s))
            var x = -4.0
            while x <= W + 4 {
                let k = Double(layer)
                let y = hz - (9 - k * 4) - (7 - k * 2) * sin(x * (0.021 + k * 0.013) + 1.3 + k * 2.1) - 3 * sin(x * 0.057 + k)
                path.addLine(to: CGPoint(x: CGFloat(x) * s, y: CGFloat(y) * s))
                x += 3
            }
            path.addLine(to: CGPoint(x: CGFloat(W + 4) * s, y: CGFloat(hz) * s))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
        }

        for (i, c) in [("cloud_a", 0.18, 7.0, 0.18), ("cloud_b", 0.55, 4.0, 0.34), ("cloud_a", 0.82, 5.5, 0.10), ("cloud_b", 0.33, 3.0, 0.06)].enumerated() {
            let span = W + 70
            put(c.0, (c.1 * span + t * c.2).truncatingRemainder(dividingBy: span) - 40, hz * c.3 + 3 + Double(i % 2) * 3)
        }
        for b in 0..<3 {
            let span = W + 40
            let x = (W * rnd(b, 1) + t * (14 + Double(b) * 5)).truncatingRemainder(dividingBy: span) - 20
            put("bird_\(Int(t * 3 + Double(b)) % 2)", x, hz * (0.25 + 0.2 * rnd(b, 2)) + sin(t + Double(b) * 2) * 3)
        }
    }

    mutating func drawGround() {
        let ground = CGRect(x: -4 * s, y: CGFloat(hz) * s, width: size.width + 8 * s, height: size.height - CGFloat(hz) * s + 4 * s)
        ctx.fill(Path(ground), with: .linearGradient(Gradient(colors: [Color(red: 0.955, green: 0.955, blue: 0.945), Color(red: 0.90, green: 0.90, blue: 0.885)]),
                                                     startPoint: CGPoint(x: 0, y: CGFloat(hz) * s), endPoint: CGPoint(x: 0, y: size.height)))
        let total = Double(size.height / s)
        for i in 0..<Int(W * (total - hz) / 70) {
            let x = rnd(i, 20) * W, y = hz + 2 + rnd(i, 21) * (total - hz - 2)
            rect(x.rounded(), y.rounded(), rnd(i, 22) < 0.3 ? 2 : 1, 1, .black.opacity(0.055))
        }
    }

    mutating func drawFar() {
        let span = W * 2.2 + 90  // long gaps between caravans
        let cx = (t * 7 + 40).truncatingRemainder(dividingBy: span) - 30
        let bob = Int(t * 2) % 2
        stand("camel_\(bob)", cx, riverTop - 1)
        stand("camel_\(1 - bob)", cx - 30, riverTop - 1)
    }

    mutating func drawTown() {
        let zw = w("ziggurat"), zh = h("ziggurat")
        let zcx = 5 + zw / 2, zfoot = hz + 10, ztop = zfoot - zh + 1
        stand("ziggurat", zcx, zfoot)
        let fl = Int(t * 8) % 2
        for fx in [zcx - zw / 2 + 10.5, zcx + zw / 2 - 10.5] {
            let c = CGPoint(x: CGFloat(fx) * s, y: CGFloat(ztop + 13) * s), rad = (9 + CGFloat(fl)) * s
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.72, blue: 0.3).opacity(0.35), .clear]), center: c, startRadius: 0, endRadius: rad))
        }
        put("flame_\(fl)", zcx - zw / 2 + 8, ztop + 17 - h("flame_0") + 1)
        put("flame_\(1 - fl)", zcx + zw / 2 - 8 - w("flame_0"), ztop + 17 - h("flame_0") + 1)
        if snap.grade != .f {  // a deposed king leaves the roof empty
            let r = snap.report
            let grieving = ((r?.starved ?? 0) > 0 && rt > 1.8 && rt < 5) || ((r?.plague ?? false) && rt > 4.4 && rt < 7)
            let waving = snap.grade == .aPlus || ((r?.yield ?? 0) >= 4 && rt > 0.8 && rt < 2.6) || Int(t / 2.2) % 3 == 0
            stand(grieving ? "king_2" : "king_\(waving ? Int(t * 2.5) % 2 : 0)", zcx - 9, ztop + 9, shadow: false)
        }

        // Houses: back row then front row, as many as the people need and the width allows.
        let x0 = zcx + zw / 2 + 14, x1 = granaryX - 34
        let cols = max(1, Int((x1 - x0) / 20) + 1)
        let n = min(max(snap.people / 6, 1), cols * 2)
        for row in 0..<2 {
            for i in stride(from: row, to: n, by: 2) {
                let col = i / 2
                let name = ["house_a", "house_b", "house_c"][(i * 7 + 1) % 3]
                let cx = x0 + Double(col) * 20 + Double(row) * 9, foot = hz + 9 + Double(row) * 12
                stand(name, cx, foot)
                if row == 0 && col % 2 == 0 {  // cooking smoke
                    for k in 0..<3 {
                        let age = (t * 0.35 + Double(k) / 3 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
                        rect(cx + 3 + sin(age * 6 + Double(i)) * 1.5, foot - h(name) - age * 13, 1.5 + age * 2, 1.5 + age * 2, .black.opacity(0.16 * (1 - age)))
                    }
                }
            }
        }
        for (i, f) in [0.40, 0.66, 0.90].enumerated() where W * f < granaryX - 26 {
            stand("palm_\(Int(t * 1.2 + Double(i)) % 2)", W * f, hz + 11 + Double(i % 2) * 2)
        }

        // Granary, shaking when rats are in it, with sacks beside it for the grain in store.
        let rats = (snap.report?.rats ?? 0) > 0 && rt > 1.4 && rt < 3.2
        stand("granary", granaryX + (rats ? Double(Int(t * 20) % 2) : 0), hz + 11)
        let sacks = min(max(snap.grain / 700, 0), 10)
        for i in 0..<sacks {
            let tier = i < 6 ? 0 : 1, k = tier == 0 ? i : i - 6
            stand("sack", granaryX - 19 - Double(k) * 7 - Double(tier) * 3.5, hz + 12 - Double(tier) * 5, shadow: tier == 0)
        }
        if snap.cats {  // they pace in front of the barn all year
            for k in 0..<2 {
                let u = (t * 9 + Double(k) * 17).truncatingRemainder(dividingBy: 44), right = u < 22
                stand("cat_\(Int(t * 5 + Double(k)) % 2)", granaryX - 36 + (right ? u : 44 - u) + Double(k) * 6, hz + 16 + Double(k) * 4, flip: !right)
            }
        }
    }

    mutating func drawRiver() {
        let flood = snap.omen == "flood"
        let top = riverTop - (flood ? 5 : 0), hgt = flood ? 13.0 : 7.0
        let r = CGRect(x: -4 * s, y: CGFloat(top) * s, width: size.width + 8 * s, height: CGFloat(hgt) * s)
        ctx.fill(Path(r), with: .linearGradient(Gradient(colors: [Color(red: 0.71, green: 0.84, blue: 0.95), Color(red: 0.56, green: 0.73, blue: 0.90)]),
                                                startPoint: r.origin, endPoint: CGPoint(x: r.minX, y: r.maxY)))
        rect(-4, top, W + 8, 1, .white.opacity(0.7))
        rect(-4, top + hgt, W + 8, 1, .black.opacity(0.10))
        var x = -(t * (flood ? 22 : 6)).truncatingRemainder(dividingBy: 12)
        var i = 0
        while x < W { rect(x, top + 2 + Double(i % 3) * 1.5, 5, 1, .white.opacity(0.75)); x += 12; i += 1 }
        let boatX = (t * 9).truncatingRemainder(dividingBy: W + 60) - 30
        for k in 1...3 { rect(boatX - 9 - Double(k) * 5, top + 5 + Double(k % 2), 3, 1, .white.opacity(0.8 - Double(k) * 0.2)) }  // wake
        stand("boat", boatX, top + 5 + sin(t * 2) * 0.6, shadow: false)
        let clock = t / 3.7, jump = Int(clock), age = (clock - Double(jump)) * 3.7  // a fish jumps every few seconds
        if age < 0.9 {
            let fx = 20 + rnd(jump, 60) * (W - 40), k = age / 0.9
            put("fish", fx + k * 10, top + 1 - sin(k * .pi) * 9)
            if k < 0.15 || k > 0.85 { rect(fx + (k < 0.5 ? 0 : 10) - 1, top + 1, 8, 1, .white.opacity(0.9)) }
        }
    }

    mutating func drawFields() {
        let total = min(max(snap.acres / 25, 0), fieldRows * fieldCols), planted = min(total, (snap.planted + 24) / 25)
        let r = snap.report
        for i in 0..<total {
            let x = 6 + Double(i % fieldCols) * plotSpread + (plotSpread - 9) / 2, y = fieldTop + Double(i / fieldCols) * 13
            let sown = i < planted
            rect(x, y + 2, 9, 11, .black.opacity(sown ? 0.06 : 0.028))
            rect(x, y + 12, 9, 1, .black.opacity(sown ? 0.05 : 0.02))
            guard sown else { continue }
            for f in 0..<3 { rect(x + 1 + Double(f) * 3, y + 3, 1, 9, .black.opacity(0.035)) }
            let sway = Int(t * 2 + Double(i) * 0.37) % 2
            var name = "wheat_0_\(sway)"
            if let r { name = rt < 0.5 ? "wheat_1_\(sway)" : r.yield >= 3 ? "wheat_2_\(sway)" : "wheat_dry_\(sway)" }
            else if snap.grade != nil { name = "wheat_2_\(sway)" }
            put(name, x, y)
        }
        // Sheep graze whatever open ground is left below the fields.
        let pasture = fieldTop + Double((total + fieldCols - 1) / fieldCols) * 13 + 10, floor = Double(size.height / s) - 6
        if floor - pasture > 12 {
            for k in 0..<min(6, Int((floor - pasture) / 10) + 2) {
                let span = W - 30, u = (rnd(k, 80) * 2 * span + t * (1.5 + rnd(k, 81) * 2)).truncatingRemainder(dividingBy: 2 * span)
                let grazing = Int(t * 0.4 + rnd(k, 82) * 5) % 3 == 0
                stand("sheep_\(grazing ? 1 : Int(t * 2 + Double(k)) % 2)", 15 + (u < span ? u : 2 * span - u), pasture + rnd(k, 83) * (floor - pasture), flip: u >= span)
            }
        }
        if total > 0 { stand("flag_\(Int(t * 3) % 2)", 4, fieldTop + 1, shadow: false) }
        if r == nil {
            for b in 0..<4 {
                let x = W * (0.2 + 0.2 * Double(b)) + sin(t * 0.7 + Double(b) * 2) * 14, y = fieldTop - 4 + sin(t * 1.3 + Double(b)) * 5 + Double(b % 2) * 8
                let open = Int(t * 9 + Double(b)) % 2 == 0
                rect(x, y, open ? 3 : 1, open ? 1 : 2, b % 2 == 0 ? Theme.accent : Color(red: 0.23, green: 0.48, blue: 0.78))
            }
        }
        if r == nil && snap.grade == nil && planted > 0 {  // an ox works the top row while you decide
            let span = W + 40, u = (t * 8).truncatingRemainder(dividingBy: span * 2)
            let right = u < span
            stand("ox_\(Int(t * 3) % 2)", (right ? u : span * 2 - u) - 20, fieldTop + 1, flip: !right)
        }
    }

    mutating func drawGraves() {
        let before = graves(snap.starved - (snap.report?.starved ?? 0))
        let shown = snap.report != nil && rt < 2.4 ? before : graves(snap.starved)
        for k in 0..<shown { stand("tombstone", W - 8 - Double(k) * 9, laneMax + 6 - Double(k % 2) * 3) }
    }

    // MARK: people

    /// Where villager `id` has wandered to at time `at`. They pace their own lane.
    func wander(_ id: Int, at: Double) -> (x: Double, y: Double, right: Bool) {
        let margin = 8.0, span = W - 2 * margin
        let u = (rnd(id, 4) * 2 * span + (5 + rnd(id, 3) * 7) * at).truncatingRemainder(dividingBy: 2 * span)
        return (margin + (u < span ? u : 2 * span - u), laneMin + rnd(id, 5) * (laneMax - laneMin), u < span)
    }

    mutating func drawFolk() {
        var folk: [(x: Double, y: Double, right: Bool, id: Int, alpha: Double)] = []
        let r = snap.report
        let after = villagers(snap.people)
        if let r {
            let before = villagers(r.peopleBefore), alive = villagers(r.peopleBefore - r.starved)
            let grown = max(alive, villagers(r.peopleBefore - r.starved + r.born))
            // The plague takes the ones past `after`; they fade as the cloud passes.
            func fade(_ id: Int) -> Double { r.plague && id >= after && rt > 4.4 ? max(0, 1 - (rt - 4.4) / 0.8) : 1 }
            for id in 0..<before where id < alive || rt <= 1.8 {
                let p = wander(id, at: t)
                folk.append((p.x, p.y, p.right, id, id < alive ? fade(id) : 1))
            }
            for id in alive..<grown {  // newcomers walk in from the left
                let start = 2.4 + Double(id - alive) * 0.12
                guard rt > start else { continue }
                let p = wander(id, at: t), k = smooth((rt - start) / 2.4)
                folk.append((-10 * (1 - k) + p.x * k, p.y, k < 1 ? true : p.right, id, fade(id)))
            }
        } else {
            for id in 0..<after { let p = wander(id, at: t); folk.append((p.x, p.y, p.right, id, 1)) }
        }
        if snap.omen == "refugees" {  // a huddle waiting at the left gate
            for k in 0..<7 { folk.append((6 + Double(k % 4) * 7 + Double(k / 4) * 3, laneMin + 2 + Double(k / 4) * 7, true, 100 + k, -1)) }
        }
        let sick = (r?.plague ?? false) && rt > 3.4 && rt < 6.6
        let party = snap.grade == .aPlus || snap.omen == "festival" || ((r?.yield ?? 0) >= 4 && rt > 0.8 && rt < 2.6)
        // Now and then two of them settle it the old way: one vanishes into a cloud of dust and fists.
        let bout = t / 9, round = Int(bout), boutAge = (bout - Double(round)) * 9
        let brawler = r == nil && snap.grade == nil && snap.omen == nil && after >= 6 && boutAge < 2.6 ? Int(rnd(round, 70) * Double(after)) : -1
        for f in folk.sorted(by: { $0.y < $1.y }) where f.alpha != 0 {
            let look = Sprites.looks[f.id % Sprites.looks.count]
            if f.id == brawler {
                stand("scuffle_\(Int(t * 9) % 2)", f.x, f.y + 1)
                for k in 0..<3 { rect(f.x - 9 + rnd(Int(t * 6) + k, 71) * 18, f.y - 14 + rnd(Int(t * 6) + k, 72) * 8, 1, 1, Color(red: 0.91, green: 0.69, blue: 0.18)) }
            } else if f.alpha < 0 { stand("villager_\(look)_1", f.x, f.y) }  // standing still
            else if sick { stand("villager_sick_\(Int(t * 6 + Double(f.id)) % 4)", f.x, f.y, flip: !f.right, alpha: f.alpha) }
            else if party && f.id % 2 == 0 { stand("cheer_\(look)_\(Int(t * 5 + Double(f.id)) % 2)", f.x, f.y, alpha: f.alpha) }
            else {
                let step = Int(t * 6 + Double(f.id)) % 4
                stand("villager_\(look)_\(step)", f.x, f.y, flip: !f.right, alpha: f.alpha, lift: step % 2 == 1 ? 1 : 0)
            }
        }
        if snap.omen == "caravan" {
            for k in 0..<3 { stand("camel_\(k % 2)", 26 + Double(k) * 30, laneMax + 3) }
        }
    }

    // MARK: the year plays out

    mutating func drawEvents() {
        guard let r = snap.report else { return }
        let gx = granaryX, gy = hz - 8
        let ink = Theme.ink, bad = Theme.accent, good = Color(red: 0.20, green: 0.41, blue: 0.16)

        // Harvest grain flies to the granary.
        for i in 0..<min(r.harvest / 150, 40) {
            let p = (rt - 0.2 - Double(i) * 0.045) / 1.2
            guard p > 0, p < 1 else { continue }
            let sx = 10 + plotSpread * Double(Int(rnd(i, 6) * Double(fieldCols))), sy = fieldTop + Double(Int(rnd(i, 7) * Double(fieldRows))) * 13
            put("grain", sx + (gx - sx) * p, sy + (gy - sy) * p - sin(p * .pi) * 18)
        }
        label("+\(fmt(r.harvest))", gx - 44, hz + 2, from: 0.9, color: r.yield >= 3 ? good : ink)

        // Rats run at the granary, loiter, and scatter.
        if r.rats > 0 {
            for i in 0..<min(r.rats / 60 + 3, 14) {
                let start = 0.3 + Double(i) * 0.12
                let inP = smooth((rt - start) / 1.3), outP = smooth((rt - 3.0 - Double(i) * 0.05) / 1.2)
                guard rt > start, outP < 1 else { continue }
                let x = (W + 8) + (gx - 10 - (W + 8)) * inP + (W + 8 - gx + 10) * outP + rnd(i, 12) * 8
                put("rat_\(Int(t * 8 + Double(i)) % 2)", x, hz + 9 + rnd(i, 8) * 9, flip: outP > 0)
            }
            label("-\(fmt(r.rats))", gx - 44, hz + 12, from: 1.6, color: bad)
        }

        // The dead leave as ghosts.
        let alive = villagers(r.peopleBefore - r.starved), before = villagers(r.peopleBefore)
        if r.starved > 0 {
            for id in alive..<before {
                let age = rt - 1.8
                guard age > 0, age < 3 else { continue }
                let p = wander(id, at: snap.frozenAge == nil ? snap.reportStart + 1.8 : 1.0)
                put("ghost", p.x - 5 + sin(age * 3 + Double(id)) * 1.5, p.y - 13 - age * 12, alpha: max(0, 1 - age / 3))
            }
            label("-\(fmt(r.starved))", W / 2, laneMin - 16, from: 1.9, color: bad)
        }
        if r.born > 0 { label("+\(fmt(r.born))", 22, laneMin - 16, from: 2.6, color: ink) }

        // Plague rolls through.
        if r.plague {
            if rt > 3.2 && rt < 7.2 { put("plague", -36 + (W + 72) * (rt - 3.2) / 4.0, laneMin - 30, alpha: 0.9) }
            for i in 0..<6 {
                let age = rt - 4.4 - Double(i) * 0.15
                guard age > 0, age < 1.8 else { continue }
                put("skull", W * (0.15 + 0.14 * Double(i)), laneMin - 6 - age * 12, alpha: max(0, 1 - age / 1.8))
            }
            label("-\(fmt(r.peopleBefore - r.starved + r.born - r.peopleAfter))", W / 2, laneMin - 26, from: 4.5, color: bad)
        }
    }

    /// Dust on a failed harvest, fog with the plague, rain on a ruined reign, fireworks on a great one.
    mutating func drawWeather() {
        let whole = CGRect(origin: .zero, size: size).insetBy(dx: -4 * s, dy: -4 * s)
        if let r = snap.report {
            if r.yield <= 2 && rt > 0.4 && rt < 7 {
                let a = min(1, (rt - 0.4) / 0.8) * min(1, (7 - rt) / 1.5)
                for i in 0..<46 {
                    let x = (rnd(i, 30) * (W + 30) + t * (50 + rnd(i, 31) * 60)).truncatingRemainder(dividingBy: W + 30) - 15
                    rect(x, hz + rnd(i, 32) * (UH - hz), 3 + rnd(i, 33) * 5, 1, .black.opacity(0.10 * a))
                }
            }
            if r.plague && rt > 3.2 && rt < 7.4 {
                let a = min(1, (rt - 3.2) / 1.0) * min(1, (7.4 - rt) / 1.2)
                ctx.fill(Path(whole), with: .color(Color(red: 0.45, green: 0.62, blue: 0.2).opacity(0.13 * a)))
                for i in 0..<30 {
                    let y = (rnd(i, 34) * UH + t * (6 + rnd(i, 35) * 8)).truncatingRemainder(dividingBy: UH)
                    rect(rnd(i, 36) * W + sin(t + Double(i)) * 4, UH - y, 1, 1, Color(red: 0.37, green: 0.5, blue: 0.17).opacity(0.5 * a))
                }
            }
        }
        if snap.grade == .f {
            ctx.fill(Path(whole), with: .color(Color(red: 0.2, green: 0.24, blue: 0.3).opacity(0.14)))
            let total = Double(size.height / s)
            for i in 0..<90 {
                let fall = (rnd(i, 37) * total + t * (150 + rnd(i, 38) * 60)).truncatingRemainder(dividingBy: total)
                rect((rnd(i, 39) * (W + 40) - fall * 0.25).truncatingRemainder(dividingBy: W + 40), fall, 1, 4, Color(red: 0.36, green: 0.45, blue: 0.58).opacity(0.45))
            }
        }
        if snap.grade == .aPlus {
            let colors: [Color] = [Theme.accent, Color(red: 0.23, green: 0.48, blue: 0.78), Color(red: 0.91, green: 0.69, blue: 0.18), Color(red: 0.35, green: 0.60, blue: 0.23)]
            for b in 0..<3 {  // a firework every 1.7 seconds from each of three mortars
                let clock = t / 1.7 + Double(b) * 0.37, n = Int(clock), age = (clock - Double(n)) * 1.7
                let cx = W * (0.2 + 0.6 * rnd(n * 3 + b, 40)), cy = hz * (0.25 + 0.5 * rnd(n * 3 + b, 41))
                for k in 0..<18 where age < 1.3 {
                    let a = Double(k) / 18 * 2 * .pi, d = 26 * (1 - exp(-age * 3))
                    rect(cx + cos(a) * d, cy + sin(a) * d + age * age * 6, 2, 2, colors[(n + b) % 4].opacity(max(0, 1 - age / 1.3)))
                }
            }
            drawConfetti()
        }
    }

    mutating func drawConfetti() {
        let colors: [Color] = [Theme.accent, Color(red: 0.23, green: 0.48, blue: 0.78), Color(red: 0.91, green: 0.69, blue: 0.18), Color(red: 0.35, green: 0.60, blue: 0.23)]
        for i in 0..<70 {
            let y = (t * (12 + rnd(i, 9) * 18) + rnd(i, 10) * UH).truncatingRemainder(dividingBy: UH + 10) - 5
            rect(rnd(i, 11) * W + sin(t * 2 + Double(i)) * 3, y, 2, 2, colors[i % 4])
        }
    }
}
