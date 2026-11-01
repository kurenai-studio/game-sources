import SwiftUI
import ImageIO

/// Pixel sprites drawn by art/make_sprites.py and bundled as PNGs.
enum Sprites {
    private static var cache: [String: CGImage] = [:]

    static func image(_ name: String) -> CGImage? {
        if let hit = cache[name] { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        cache[name] = img
        return img
    }

    /// The villager looks: tunic, skin and hair differ.
    static let looks = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]

    /// Every sprite the scene asks for by name. The tests check each one loads.
    static let names: [String] = {
        var n = ["ghost", "tombstone", "skull", "grain", "flag_0", "flag_1", "fish", "cat_0", "cat_1", "king_2", "sheep_0", "sheep_1", "scuffle_0", "scuffle_1", "house_a", "house_b", "house_c", "ziggurat",
                 "king_0", "king_1", "palm_0", "palm_1", "granary", "sack", "rat_0", "rat_1", "cloud_a", "cloud_b",
                 "sun_0", "sun_1", "bird_0", "bird_1", "camel_0", "camel_1", "plague", "spark",
                 "ox_0", "ox_1", "boat", "flame_0", "flame_1"]
        for v in looks + ["sick"] { n += (0..<4).map { "villager_\(v)_\($0)" } }
        for v in looks { n += ["cheer_\(v)_0", "cheer_\(v)_1"] }
        for st in 0..<3 { n += ["wheat_\(st)_0", "wheat_\(st)_1"] }
        n += ["wheat_dry_0", "wheat_dry_1"]
        return n
    }()
}
