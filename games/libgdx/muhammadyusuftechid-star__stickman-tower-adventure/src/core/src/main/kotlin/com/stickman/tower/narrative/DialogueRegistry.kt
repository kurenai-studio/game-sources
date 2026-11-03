package com.stickman.tower.narrative

import com.badlogic.gdx.graphics.Color
import com.stickman.tower.world.DialogueBranchOption
import com.stickman.tower.world.DialogueLine
import com.stickman.tower.world.MoraleBuffType
import com.stickman.tower.world.StoryDialogue

/**
 * Registri resmi naskah lakon sinematik standar industri (Cinematic Screenplay Scenes 01 - 05).
 * Memuat dialog karakter dengan palet warna diegetik, arahan vokal prosedural, dan percabangan moril.
 */
object DialogueRegistry {

    // Palet Warna Suara Diegetik Karakter
    val COLOR_KAELEN = Color(0.95f, 0.95f, 1.0f, 1f)         // Putih Berkilau (Hero Pendaki)
    val COLOR_ARIA = Color(0.35f, 0.85f, 1.0f, 1f)           // Biru Cyan Murni (Radiant Sprite)
    val COLOR_OAKHAVEN = Color(0.55f, 0.85f, 0.45f, 1f)       // Hijau Hutan Lumut (Jenderal Kehormatan)
    val COLOR_MATRON = Color(0.85f, 0.45f, 0.95f, 1f)         // Ungu Kristal Miasma (The Amethyst Matron)
    val COLOR_VULCANUS = Color(1.0f, 0.65f, 0.25f, 1f)        // Oranye Bara Meteorit (Sang Penempa Jiwa)
    val COLOR_ZEPHYR = Color(0.2f, 0.95f, 0.85f, 1f)          // Cyan Bayangan (Zephyr The Phantom Strider)
    val COLOR_IGNIS = Color(0.95f, 0.35f, 0.15f, 1f)           // Merah Lahar Pijar (Forge-Master Ignis)
    val COLOR_GORGON = Color(0.85f, 0.70f, 0.25f, 1f)          // Emas Titan Kuno (Gorgon The Ironbreaker)
    val COLOR_CALLIGRAPHER = Color(0.95f, 0.82f, 0.35f, 1f)   // Emas Primordial Gelap (Grand Calligrapher)
    val COLOR_CHIMERA = Color(0.70f, 0.40f, 0.90f, 1f)        // Ungu Nebula Kosmis (The Void Chimera)
    val COLOR_MALAKOR = Color(0.90f, 0.15f, 0.20f, 1f)        // Merah Darah Gelap (Malakor The Crimson Sovereign)
    val COLOR_ARCHON = Color(0.85f, 0.95f, 1.0f, 1f)          // Putih Cyan Geometri (Archon of Pure Geometry)

    /**
     * SCENE 01: Prolog Gerbang Bawah (Floor 1)
     */
    val SCENE_01_PROLOGUE = StoryDialogue(
        triggerX = 2.0f,
        triggerY = 1.0f,
        triggerRadius = 3.0f,
        lines = listOf(
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Bangunlah, Pendaki Garis! Tubuhmu... seluruh warnamu telah dihisap oleh kutukan Tinta Primordial!",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pendaki Jiwa Kosong",
                text = "Tanganku... hanya goresan tinta hitam di atas kanvas mati ini. Di mana warna dunia dan ingatan kita?",
                speakerColor = COLOR_KAELEN
            ),
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Sang Kaligrafer Agung telah menyegelnya di puncak menara. Cabut bilah pedangmu, Kaelen! Tiada jalan pulang selain menembus lantai demi lantai!",
                speakerColor = COLOR_ARIA
            )
        )
    )

    /**
     * SCENE 02: Duel Kehormatan Jenderal Oakhaven (Floor 3)
     */
    val SCENE_02_OAKHAVEN = StoryDialogue(
        triggerX = 4.0f,
        triggerY = 1.2f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Jenderal Oakhaven",
                title = "Panglima Benteng Kayu",
                text = "Berhenti, jiwa yang tak berkilau. Aku Jenderal Oakhaven, pengawal Benteng Bawah. Pedangku bersumpah pada keabadian ordo hitam-putih.",
                speakerColor = COLOR_OAKHAVEN
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pendaki Jiwa",
                text = "Bebaskan jalan, Jenderal! Kami mendaki bukan untuk menodai kehormatanmu, melainkan memulihkan warna semesta yang dirampas!",
                speakerColor = COLOR_KAELEN
            ),
            DialogueLine(
                speaker = "Jenderal Oakhaven",
                title = "Panglima Benteng Kayu",
                text = "Kata-kata indah tak bernilai di hadapan tebasan baja. Tunjukkan bahwa kehendakmu lebih keras daripada hukum Menara!",
                speakerColor = COLOR_OAKHAVEN
            )
        )
    )

    /**
     * SCENE 03: Kawah Alkimia The Amethyst Matron (Floor 5)
     */
    val SCENE_03_MATRON = StoryDialogue(
        triggerX = 4.0f,
        triggerY = 1.2f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "The Amethyst Matron",
                title = "Ratu Sarang Miasma",
                text = "Ssshh... mangsa baru merayap ke sarang ungu kami. Apakah kau mencium getah manis yang kan melarutkan garis ragamu?",
                speakerColor = COLOR_MATRON
            ),
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya",
                text = "Tutup telingamu dari desisnya, Kaelen! Panah kristal ungunya membius dan meracuni memori para pejuang masa lalu!",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "The Amethyst Matron",
                title = "Ratu Sarang Miasma",
                text = "Bahkan busur kristalku yang retak ini masih sanggup menenun keputusasaanmu menjadi kepompong tinta abadi!",
                speakerColor = COLOR_MATRON
            )
        )
    )

    /**
     * SCENE 04: Suaka Paron Vulcanus (Floor 6 - Interactive Branching)
     */
    val SCENE_04_VULCANUS = StoryDialogue(
        triggerX = 10.5f,
        triggerY = 1.5f,
        triggerRadius = 2.8f,
        lines = listOf(
            DialogueLine(
                speaker = "Vulcanus",
                title = "Sang Penempa Jiwa",
                text = "Denting paluku adalah satu-satunya irama di menara ini yang menolak tunduk pada keheningan Tinta Primordial.",
                speakerColor = COLOR_VULCANUS
            ),
            DialogueLine(
                speaker = "Vulcanus",
                title = "Sang Penempa Jiwa",
                text = "Koin emasmu adalah tetesan matahari purba. Namun sebelum kau melangkah ke tebing kosmis di atas, katakan padaku: Apa yang menggerakkan bilah pedangmu?",
                speakerColor = COLOR_VULCANUS,
                branchOptions = listOf(
                    DialogueBranchOption(
                        choiceId = "CHOICE_VENGEANCE",
                        promptText = "[1] Pembalasan Dendam (Hancurkan Tirani Kaligrafer)",
                        reactionSpeaker = "Vulcanus",
                        reactionTitle = "Sang Penempa Jiwa",
                        reactionText = "Bagus! Kemurkaan adalah bahan bakar terbaik untuk meleburkan baja terkeras. Terimalah Kinetic Surge: tebasanmu kan bergetar melipatgandakan daya hancur (+8% ATK)!",
                        moraleBuff = MoraleBuffType.KINETIC_SURGE
                    ),
                    DialogueBranchOption(
                        choiceId = "CHOICE_RESTORATION",
                        promptText = "[2] Restorasi Warna (Pulihkan Kedamaian Aethelgard)",
                        reactionSpeaker = "Vulcanus",
                        reactionTitle = "Sang Penempa Jiwa",
                        reactionText = "Hati yang luhur adalah perisai paling kokoh. Terimalah Spiritual Ward: hangatnya bara api kan memulihkan darahmu dari racun jurang (+15% HP & Regen)!",
                        moraleBuff = MoraleBuffType.SPIRITUAL_WARD
                    )
                )
            ),
            DialogueLine(
                speaker = "Vulcanus",
                title = "Sang Penempa Jiwa",
                text = "Bawalah berkat penempaanku ke jurang kosmis di Lantai 7. Jangan biarkan bara api ini padam sebelum menara runtuh!",
                speakerColor = COLOR_VULCANUS
            )
        )
    )

    /**
     * SCENE 05: Sarang Lady Vespera & Penyelamatan Zephyr (Floor 10)
     */
    val SCENE_05_VESPERA_AND_ZEPHYR = StoryDialogue(
        triggerX = 12.0f,
        triggerY = 1.3f,
        triggerRadius = 4.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Lady Vespera",
                title = "Sang Ratu Busur Bayang",
                text = "Hahaha... mangsa baru merayap ke Sarang Ungu. Lihatlah teman pencurimu ini, Kaelen! Ia terbungkus rapi dalam sutra kristalku!",
                speakerColor = COLOR_MATRON
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Lepaskan dia, Vespera! Menara ini bukan makam untuk prajurit yang setia pada tanah airnya!",
                speakerColor = COLOR_KAELEN
            ),
            DialogueLine(
                speaker = "Lady Vespera",
                title = "Sang Ratu Busur Bayang",
                text = "Jika kau ingin membebaskannya, tebas kepompong itu di hadapanku! Tapi sebelum pedangmu mencapainya, panah racunku kan menembus jantungmu!",
                speakerColor = COLOR_MATRON
            )
        )
    )

    /**
     * SCENE 06: Suaka Tempa Vulcanus - The Second Forge Refuge (Floor 13)
     */
     val SCENE_06_VULCANUS_SANCTUARY = StoryDialogue(
         triggerX = 18.0f,
         triggerY = 1.3f,
         triggerRadius = 3.2f,
         lines = listOf(
             DialogueLine(
                 speaker = "Vulcanus",
                 title = "Sang Penempa Jiwa",
                 text = "Selamat datang di perapian keduaku, Kaelen, Zephyr! Aku melihat belati kembar Zephyr kembali menari di sisimu.",
                 speakerColor = COLOR_VULCANUS
             ),
             DialogueLine(
                 speaker = "Zephyr",
                 title = "Sang Pengintai Bayangan",
                 text = "Ventilasi mesin di bawah sini hampir membakar paru-paruku, kakek tua. Tapi kami berhasil lewat.",
                 speakerColor = COLOR_ZEPHYR
             ),
             DialogueLine(
                 speaker = "Vulcanus",
                 title = "Sang Penempa Jiwa",
                 text = "Istirahatlah di suaka ini. Namun berhati-hatilah... di Lantai 15 murid terbaikku, Ignis, telah meminum terak baja cair dan kehilangan akalnya. Dan di Lantai 20, Gorgon sedang meregang nyawa menahan pilar kawah!",
                 speakerColor = COLOR_VULCANUS
             )
         )
     )

    /**
     * SCENE 07: Singgasana Ignis (Floor 15)
     */
    val SCENE_07_IGNIS = StoryDialogue(
        triggerX = 4.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Forge-Master Ignis",
                title = "Murid Terpilih Vulcanus",
                text = "Baja ini... menolak dingin! Tubuh lelehanku adalah wadah keabadian menara! Kalian takkan pernah melewati kawah tempa ini!",
                speakerColor = COLOR_IGNIS
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Kau bukan dewa, Ignis! Keabadianmu hanyalah penjara terak yang membakar jiwamu sendiri! Biarkan pedang ini membebaskanmu!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 08: Ambang Tungku Titan & Penyelamatan Gorgon (Floor 20)
     */
    val SCENE_08_GORGON_RESCUE = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "GRRRHHH...! Pundakku... takkan mundur satu jengkal pun! Di bawah sini... ribuan pengungsi tak berdosa berlindung!",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Kaelen, alihkan monster raksasa Slag Colossus itu! Tuas katup lahar di samping pilar harus kita tebas sebelum pilar ini patah!",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Bertahanlah, Gorgon! Kami datang untuk memotong rantai bebanmu!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 09: Kawah Basalt & Langkah Gorgon (Floor 21)
     */
    val SCENE_09_BASALT_CRATER = StoryDialogue(
        triggerX = 6.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Dinding basalt di depan kita membeku dari lahar purba. Pedang biasa hanya akan memantul. Biarkan Greatsword-ku yang meremukkannya!",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Hantam tepat di retakan urat magma itu, kawan besar. Aku akan menusuk monster yang mencoba menyergapmu dari belakang.",
                speakerColor = COLOR_ZEPHYR
            )
        )
    )

    /**
     * SCENE 10: Singgasana Raja Golem Magma (Floor 25)
     */
    val SCENE_10_MAGMA_GOLEM = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Magma Golem King",
                title = "Penjaga Kawah Purba",
                text = "GRRRROOOAAAR...! KAWIS BASALT INI TIDAK MENERIMA PENYUSUP BERDARAH DAGING!",
                speakerColor = COLOR_IGNIS
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Kulit batunya tebal! Kaelen, Zephyr, pancing dia mengangkat tinjunya! Aku akan melancarkan Guard Break untuk menghancurkan intinya!",
                speakerColor = COLOR_GORGON
            )
        )
    )

    /**
     * SCENE 11: Ambang Retakan Kosmis (Floor 26)
     */
    val SCENE_11_ASTRAL_RIFT = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Lihat dinding menara di atas sana... retak dan memperlihatkan jurang antariksa kosmos! Gravitasi di sini mulai berfluktuasi liar!",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Udara menipis, tapi api bara di pedang kita masih menyala. Lompatlah bersama hembusan angin bintang!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 12: The Nexus of Reflections (Floor 30)
     */
    val SCENE_12_NEXUS_OF_REFLECTIONS = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "The Shadow Doppelganger",
                title = "Cermin Jiwa Gelap",
                text = "Selamat datang di cermin keputusasaan kalian. Rasa bersalah Kaelen, ketakutan Zephyr, dan beban pundak Gorgon... semuanya bersatu menjadi algojo kalian!",
                speakerColor = COLOR_CALLIGRAPHER
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Bayangan hanyalah ketiadaan cahaya. Bersama bara api dan tekad kami, kami akan menghancurkan cermin ilusi ini!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 13: Jembatan Cahaya Antarbintang (Floor 31)
     */
    val SCENE_13_ASTRAL_ISLES = StoryDialogue(
        triggerX = 6.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Zephyr",
                title = "Penjelajah Bayangan",
                text = "Dinding menara lenyap... kita melangkah di atas jembatan cahaya bintang! Altar Prisma di depan kita... energinya memanggil resonansi jiwa kita!",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Kalian berdua siap? Sentuh Altar Prisma kapan pun kita membutuhkan kecepatan belati Zephyr atau ketangguhan perisai Gorgon!",
                speakerColor = COLOR_KAELEN
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Palu Bastion",
                text = "Otot bajaku selalu siap di garis depan jika ada monster angkasa yang perlu diremukkan!",
                speakerColor = COLOR_GORGON
            )
        )
    )

    /**
     * SCENE 14: Sarang Chimera Kehampaan (Floor 35)
     */
    val SCENE_14_VOID_CHIMERA = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "The Void Chimera",
                title = "Penjaga Gerbang Nebula",
                text = "*Desisan tentakel kosmis menggelegar*... Tiga jiwa fana berani menyeberangi kehampaan bintang... kalian akan larut dalam kegelapan abadi!",
                speakerColor = COLOR_CHIMERA
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Penjelajah Bayangan",
                text = "Tiga kepala, tiga titik lemah! Kaelen, alihkan serangannya, Gorgon hancurkan pelindungnya, aku akan menusuk intinya dari bayangan!",
                speakerColor = COLOR_ZEPHYR
            )
        )
    )

    /**
     * SCENE 15: Katedral Gerhana Darah (Floor 36)
     */
    val SCENE_15_BLOOD_CATHEDRAL = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Cahaya cyan kosmis telah berganti merah pekat... gerhana bulan darah telah tiba! Di depan sana berdiri Katedral Malakor!",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Palu Bastion",
                text = "Bau darah dan kemunafikan bangsawan menguar dari pilar gotik ini. Berhati-hatilah, mereka meregenerasi luka di bawah sinar bulan merah!",
                speakerColor = COLOR_GORGON
            )
        )
    )

    /**
     * SCENE 16: Singgasana Pangeran Darah (Floor 40)
     */
    val SCENE_16_MALAKOR_SHOWDOWN = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Malakor The Crimson Sovereign",
                title = "Pangeran Darah Abadi",
                text = "Selamat datang di Katedral Keabadian, serangga-serangga menara. Darah kalian adalah persembahan sempurna bagi fajar malam abadi!",
                speakerColor = COLOR_MALAKOR
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Keabadianmu dibangun di atas tumbal rakyat tak berdosa, Malakor! Bilah pedang kami akan mengakhiri pesta darahmu sekarang juga!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 17: Tangga Marmer Putih Suci (Floor 41)
     */
    val SCENE_17_CELESTIAL_CANVAS = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Lantai 41... marmer putih suci bermandikan aurora fajar keemasan. Kita telah menembus kegelapan menuju Kanvas Semesta!",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Lantai marmer ini begitu bersih hingga memantulkan angkasa. Tapi awas... lautan tinta hitam purba di bawah jurang bergolak ganas.",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Pilar-pilar ini menopang kubah surga. Anima Core kita beresonansi... fajar warna yang dirampas semakin dekat!",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Tetap waspada, kawan-kawan. Ini adalah babak terakhir sebelum singgasana pencipta. Terus melangkah!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 18: Balairung Malaikat Geometri (Floor 45)
     */
    val SCENE_18_ARCHON_GEOMETRY = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Archon of Pure Geometry",
                title = "Malaikat Penjaga Sumbu Nol",
                text = "BENTUK FANA KALIAN ADALAH KECACATAN SIMETRI. KANVAS INI HANYA MENERIMA PERSAMAAN KOSMIS YANG MURNI!",
                speakerColor = COLOR_ARCHON
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Laser putihnya membelah platform realitas! Aku akan melesat menembus bayang-bayang geometrinya!",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Biarkan tameng bajaku menahan sinar pembelahnya! Kaelen, tebas intinya saat ia mengisi daya!",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Jiwa yang bernyawa bukan sekadar rumus matematika, Archon! Hancurkan batas geometrimu!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 19: Koridor Emas & Sumpah Triad of Dawn (Floor 49)
     */
    val SCENE_19_DAWN_STAIRCASE = StoryDialogue(
        triggerX = 5.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "Aria",
                title = "Peri Cahaya Menara",
                text = "Di balik pintu gerbang emas ini... singgasana Sang Kaligrafer Agung berdiri. Tak ada lagi jalan kembali.",
                speakerColor = COLOR_ARIA
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Zephyr The Shadowstalker, belati bayangan untuk membongkar dusta para dewa.",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Gorgon The Ironbreaker, tameng baja untuk melindungi mereka yang menatap fajar.",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pewaris Bara Emas",
                text = "Demi warna yang dirampas, demi jiwa yang larut, demi fajar yang merdeka: hari ini, dewa takdir akan jatuh!",
                speakerColor = COLOR_KAELEN
            )
        )
    )

    /**
     * SCENE 50: Singgasana Kanvas Primordial (Floor 50 - Puncak Menara)
     */
    val SCENE_50_CALLIGRAPHER = StoryDialogue(
        triggerX = 4.0f,
        triggerY = 1.3f,
        triggerRadius = 3.5f,
        lines = listOf(
            DialogueLine(
                speaker = "The Grand Calligrapher",
                title = "Arsitek Tinta Primordial",
                text = "Kalian akhirnya tiba di tepi kenyataan. Menatap kanvas kosong tempat seluruh hukum dan takdir semesta digoreskan.",
                speakerColor = COLOR_CALLIGRAPHER
            ),
            DialogueLine(
                speaker = "Kaelen",
                title = "Pembebas Warna",
                text = "Kau memenjarakan semesta dalam monokrom kaku! Hidup bukanlah naskah mati yang boleh kau hapus sesukamu!",
                speakerColor = COLOR_KAELEN
            ),
            DialogueLine(
                speaker = "Zephyr",
                title = "Sang Pengintai Bayangan",
                text = "Tinta hitammu takkan pernah mampu lagi menggelapkan tekad kami!",
                speakerColor = COLOR_ZEPHYR
            ),
            DialogueLine(
                speaker = "Gorgon",
                title = "Paladin Benteng Besi",
                text = "Greatsword-ku akan meremukkan penamu menjadi serpihan debu!",
                speakerColor = COLOR_GORGON
            ),
            DialogueLine(
                speaker = "The Grand Calligrapher",
                title = "Arsitek Tinta Primordial",
                text = "Warna adalah kekacauan. Hitam dan putih adalah kesempurnaan abadi. Jika kalian ingin menggambar ulang takdir... patahkan penaku dengan darah kalian!",
                speakerColor = COLOR_CALLIGRAPHER
            )
        )
    )

    fun getSceneForFloor(floor: Int): StoryDialogue? {
        val scene = when (floor) {
            1 -> SCENE_01_PROLOGUE
            5 -> SCENE_02_OAKHAVEN
            6 -> SCENE_04_VULCANUS
            10 -> SCENE_05_VESPERA_AND_ZEPHYR
            13 -> SCENE_06_VULCANUS_SANCTUARY
            15 -> SCENE_07_IGNIS
            20 -> SCENE_08_GORGON_RESCUE
            21 -> SCENE_09_BASALT_CRATER
            25 -> SCENE_10_MAGMA_GOLEM
            26 -> SCENE_11_ASTRAL_RIFT
            30 -> SCENE_12_NEXUS_OF_REFLECTIONS
            31 -> SCENE_13_ASTRAL_ISLES
            35 -> SCENE_14_VOID_CHIMERA
            36 -> SCENE_15_BLOOD_CATHEDRAL
            40 -> SCENE_16_MALAKOR_SHOWDOWN
            41 -> SCENE_17_CELESTIAL_CANVAS
            45 -> SCENE_18_ARCHON_GEOMETRY
            49 -> SCENE_19_DAWN_STAIRCASE
            50 -> SCENE_50_CALLIGRAPHER
            else -> null
        }
        scene?.reset()
        return scene
    }
}
