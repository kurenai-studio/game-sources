package com.stickman.tower.bestiary

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.rpg.SaveData

/**
 * Entri Bestiarium Lapangan Kanonikal (Field Bestiary Entry).
 * Mengintegrasikan catatan lapangan Cendekiawan Aurelius dan taktik tempur Kapten Valerius.
 */
data class BestiaryEntry(
    val id: String,
    val name: String,
    val subtitle: String,
    val classification: String,
    val habitat: String,
    val physicalDescription: String,
    val loreNotesAurelius: String,
    val tacticNotesValerius: String,
    val weaknesses: List<String>,
    val silhouetteColor: Color = Color(0.15f, 0.18f, 0.24f, 1f),
    val accentColor: Color = Color.GOLD,
    val unlockFloor: Int = 1
) {
    val title: String get() = subtitle
    val threatZone: String get() = habitat
    val lore: String get() = loreNotesAurelius
    val tactics: String get() = tacticNotesValerius
    val weakness: String get() = weaknesses.joinToString(", ")
    val colorHex: String get() = "#%02x%02x%02x".format(
        (accentColor.r * 255).toInt().coerceIn(0, 255),
        (accentColor.g * 255).toInt().coerceIn(0, 255),
        (accentColor.b * 255).toInt().coerceIn(0, 255)
    )
}

/**
 * Pengelola Ensiklopedia Bestiarium Lapangan Menara (Bestiary Manager).
 * Memantau jumlah eliminasi monster (Kill Count) dan status penyingkapan catatan lapangan.
 */
object BestiaryManager {

    val CRIMSON_GRUNT = BestiaryEntry(
        id = "CRIMSON_GRUNT",
        name = "Crimson Grunt",
        subtitle = "Prajurit Tinta Buas",
        classification = "Inked Abomination / Terdistorsi Akut",
        habitat = "Lantai 1 s/d 3 (Benteng Bawah & Jurang Duri)",
        physicalDescription = "Siluet tubuh berombak tak beraturan dengan mata merah membara. Tangan kanan termutasi menjadi cakar tinta bergerigi setajam obsidian.",
        loreNotesAurelius = "Mereka adalah prajurit Aethelgard yang kehilangan akal sehat saat The Great Inking melanda. Ketika kesadaran mereka tertekan menjadi garis hitam, ingatan akan martabat terhapus, menyisakan naluri binatang murni yang lapar akan kinetika.",
        tacticNotesValerius = "Jangan menangkis terlalu awal. Tunggu hingga siluet mereka condong ke depan dalam ayunan cakar. Satu Dentang Penolakan Takdir (Perfect Parry) akan membanting mereka ke lantai selama 1.5 detik.",
        weaknesses = listOf("Perfect Parry", "Stagger", "Heavy Finisher"),
        silhouetteColor = Color(0.25f, 0.10f, 0.12f, 1f),
        accentColor = Color(0.95f, 0.25f, 0.25f, 1f),
        unlockFloor = 1
    )

    val OBSIDIAN_KNIGHT = BestiaryEntry(
        id = "OBSIDIAN_KNIGHT",
        name = "Obsidian Shield Knight",
        subtitle = "Ksatria Perisai Batu Hitam",
        classification = "Garrison Automaton / Sisa Tentara Penjaga",
        habitat = "Lantai 4, 7, dan Koridor Pertahanan Elit",
        physicalDescription = "Siluet jangkung berpostur tegap dengan perisai batu obsidian setinggi dua meter di tangan kiri dan gada berduri pendek di tangan kanan.",
        loreNotesAurelius = "Ksatria-ksatria ini tidak kehilangan akal karena panik, melainkan karena sumpah militer abadi. Saat para dewa menumpahkan tinta, Legiun Obsidian memilih mengunci perisai mereka dan bersumpah menjaga lorong menara selamanya.",
        tacticNotesValerius = "Menyerang perisai mereka dari depan adalah bunuh diri. Melompatlah melompati kepala mereka (cross-up), atau gunakan tebasan ketiga kombo untuk memicu Guard Break, lalu serang punggungnya!",
        weaknesses = listOf("Guard Break", "Cross-up Jump", "Backstab"),
        silhouetteColor = Color(0.12f, 0.15f, 0.22f, 1f),
        accentColor = Color(0.35f, 0.75f, 1.0f, 1f),
        unlockFloor = 4
    )

    val AMETHYST_SNIPER = BestiaryEntry(
        id = "AMETHYST_SNIPER",
        name = "Amethyst Sniper",
        subtitle = "Pemanah Kaca Ungu",
        classification = "Alchemical Wraith / Penenun Kristal Racun",
        habitat = "Lantai 2, 4, 5, dan 7 (Platform Tinggi & Langit-langit)",
        physicalDescription = "Siluet ramping lincah berselubungkan kabut keunguan. Membawa busur panjang yang dirangkai dari pecahan kaca kristal Amethyst kuno.",
        loreNotesAurelius = "Sebelum kataklisme, para sarjana di The Sunken Archives mencoba membuat penawar dari ekstrak kristal ungu. Eksperimen gagal; kristal justru mengkristalkan paru-paru mereka. Kini mereka tak bisa bernafas tanpa kabut racun Miasma.",
        tacticNotesValerius = "Mereka sangat pengecut. Begitu kau mendekat dalam dua langkah, mereka akan melompat mundur (kiting). Tutup jarak menggunakan Dash I-Frames lalu habisi sebelum mereka sempat menarik busur.",
        weaknesses = listOf("Dash I-Frames", "Close-quarters Rush", "Projectile Shuriken"),
        silhouetteColor = Color(0.22f, 0.10f, 0.28f, 1f),
        accentColor = Color(0.85f, 0.45f, 0.95f, 1f),
        unlockFloor = 2
    )

    val SHADOW_PHANTOM = BestiaryEntry(
        id = "SHADOW_PHANTOM",
        name = "Shadow Phantom",
        subtitle = "Hantu Cakar Astral",
        classification = "Astral Anomaly / Jiwa Mengambang",
        habitat = "Lantai 7 s/d 9 (Tebing Angkasa & Cermin Jiwa)",
        physicalDescription = "Siluet melayang tanpa kaki dengan sepasang sayap tinta compang-camping dan cakar panjang melengkung tajam.",
        loreNotesAurelius = "Saat menara retak menembus ruang hampa astral, gravitasi melemah. Jiwa pendaki yang jatuh di jurang kosmis tidak pernah menyentuh tanah sehingga tidak terlarut seutuhnya. Mereka melayang membenci siapapun yang memiliki kaki untuk berpijak.",
        tacticNotesValerius = "Gunakan loncatan tinggi di zona gravitasi rendah Lantai 7. Serang mereka dengan kombo aerial juggle di udara sebelum mereka menukik ke bawah.",
        weaknesses = listOf("Aerial Juggle", "Low-Gravity Air Combos", "Rising Dragon"),
        silhouetteColor = Color(0.15f, 0.16f, 0.30f, 1f),
        accentColor = Color(0.45f, 0.85f, 1.0f, 1f),
        unlockFloor = 7
    )

    val BOSS_OAKHAVEN = BestiaryEntry(
        id = "BOSS_OAKHAVEN",
        name = "Jenderal Oakhaven",
        subtitle = "Panglima Benteng Kayu Bawah",
        classification = "Tower Guardian / Ksatria Pelindung Ordo",
        habitat = "Lantai 5 (Benteng Bawah / The Lower Bastion)",
        physicalDescription = "Ksatria raksasa bersenjatakan Greatsword emas yang mampu membelah platform batu dengan sekali tebasan.",
        loreNotesAurelius = "Oakhaven bersumpah pada ordo monokrom bukan karena kebencian, melainkan menjaga agar ksatria yang lemah tidak melangkah ke jurang kematian di lantai atas.",
        tacticNotesValerius = "Ketika pedangnya berkilat emas, jangan berguling menjauh; lakukan Dentang Penolakan Takdir (Parry) tepat waktu untuk melipatgandakan peluang stagger!",
        weaknesses = listOf("Perfect Parry Bilah Emas", "Dodge Roll Cross-up"),
        silhouetteColor = Color(0.25f, 0.20f, 0.10f, 1f),
        accentColor = Color(0.95f, 0.82f, 0.30f, 1f),
        unlockFloor = 5
    )

    val BOSS_MATRON = BestiaryEntry(
        id = "BOSS_MATRON",
        name = "The Amethyst Matron",
        subtitle = "Lady Vespera • Sang Ratu Busur Bayang",
        classification = "Alchemical Sovereign / Ratu Sarang Miasma",
        habitat = "Lantai 10 (Sarang Amethyst / The Violet Sanctum)",
        physicalDescription = "Ratu bayangan berkepompong kristal ungu yang menembakkan salvo panah beracun ke segala penjuru kawah.",
        loreNotesAurelius = "Korupsi Miasma melarutkan tekad para pejuang masa lalu, mengubah sarang alkimia menjadi makam para pendaki yang kehilangan arah.",
        tacticNotesValerius = "Panah ungu menyebar secara diagonal. Manfaatkan platform vertikal untuk menghindar dan serang saat ia memulihkan busurnya.",
        weaknesses = listOf("Vertical Platform Flanking", "Punish Recovery Window"),
        silhouetteColor = Color(0.28f, 0.12f, 0.32f, 1f),
        accentColor = Color(0.90f, 0.40f, 1.0f, 1f),
        unlockFloor = 10
    )

    val BOSS_CALLIGRAPHER = BestiaryEntry(
        id = "BOSS_CALLIGRAPHER",
        name = "The Grand Calligrapher",
        subtitle = "Arsitek Tinta Primordial",
        classification = "Primordial Sovereign / Penulis Takdir",
        habitat = "Lantai 50 (Puncak Kanvas Kosmis / Primordial Zenith)",
        physicalDescription = "Entitas kosmis agung dengan pena emas primordial yang sanggup menggambar pilar tinta pemusnah kenyataan.",
        loreNotesAurelius = "Baginya, warna adalah kekacauan dan keserakahan manusia. Hanya monokrom hitam-putih yang mutlak abadi.",
        tacticNotesValerius = "Patahkan pilar tinta hitam yang ia panggil. Saat penanya terangkat untuk memanggil hujan meteorit tinta, serang tanpa henti!",
        weaknesses = listOf("Ink Pillar Destruction", "All-Out Attack on Channeling"),
        silhouetteColor = Color(0.32f, 0.28f, 0.14f, 1f),
        accentColor = Color(1.0f, 0.90f, 0.45f, 1f),
        unlockFloor = 50
    )

    val ENTRIES: List<BestiaryEntry> = listOf(
        CRIMSON_GRUNT,
        OBSIDIAN_KNIGHT,
        AMETHYST_SNIPER,
        SHADOW_PHANTOM,
        BOSS_OAKHAVEN,
        BOSS_MATRON,
        BOSS_CALLIGRAPHER
    )

    fun getEntry(id: String): BestiaryEntry? {
        return ENTRIES.find { it.id.equals(id, ignoreCase = true) }
    }

    fun getById(id: String): BestiaryEntry? = getEntry(id)

    fun recordKill(id: String, saveData: SaveData) {
        val current = saveData.bestiaryKills[id] ?: 0
        saveData.bestiaryKills[id] = current + 1
    }

    fun getKillCount(id: String, saveData: SaveData): Int {
        return saveData.bestiaryKills[id] ?: 0
    }

    fun getKills(saveData: SaveData, id: String): Int = getKillCount(id, saveData)

    fun isDiscovered(entry: BestiaryEntry, saveData: SaveData): Boolean {
        // Terbuka jika sudah pernah membunuh atau sudah pernah mencapai lantai habitatnya
        return getKillCount(entry.id, saveData) > 0 || saveData.highestTowerFloor >= entry.unlockFloor
    }
}
