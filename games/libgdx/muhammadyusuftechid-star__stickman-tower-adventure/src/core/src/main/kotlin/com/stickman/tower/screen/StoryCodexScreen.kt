package com.stickman.tower.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input.Keys
import com.badlogic.gdx.Screen
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Vector2
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.Align
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.achievement.AchievementManager
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Screen Interaktif Pembaca Kisah & Worldbuilding (Story Codex / Tomes of Aethelgard - Edisi 50 Bab).
 * Memuat arsip 5 Saga Menara (50 Lantai) dengan sistem Tab Bar Navigasi 5 Saga:
 * - Saga I: The Lower Bastion & Sunken Garrison (Lantai 1 - 10)
 * - Saga II: The Sunken Archives & Clockwork Foundry (Lantai 11 - 20)
 * - Saga III: The Gilded Catacombs & Basalt Chasm (Lantai 21 - 30)
 * - Saga IV: The Astral Abyss & Crimson Eclipse (Lantai 31 - 40)
 * - Saga V: The Celestial Canvas & Primordial Zenith (Lantai 41 - 50)
 *
 * Masing-masing tab menampilkan 10 kapsul bab bertema bioma (anti-dempet spacing),
 * pembaca teks kisah 2 halaman per bab (Kisah Ekologi & Transkrip 50 Prasasti Batu Kuno),
 * partikel atmosferik, serta kontrol ganda (Sentuh/Mouse & Keyboard).
 */
class StoryCodexScreen(
    private val game: StickmanGame,
    private val returnScreen: Screen? = null
) : Screen {

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private var shapeRendererInstance: ShapeRenderer? = null
    private val shapeRenderer: ShapeRenderer get() = shapeRendererInstance ?: ShapeRenderer().also { shapeRendererInstance = it }

    private var batchInstance: SpriteBatch? = null
    private val batch: SpriteBatch get() = batchInstance ?: SpriteBatch().also { batchInstance = it }

    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private var animTime = 0f
    private var inputCooldown = 0.25f

    data class CodexPage(
        val subtitle: String,
        val paragraphs: List<String>
    )

    data class CodexChapter(
        val floorNumber: Int,
        val title: String,
        val tag: String,
        val pages: List<CodexPage>
    )

    data class CodexSaga(
        val sagaNumber: Int,
        val title: String,
        val tabLabel: String,
        val chapters: List<CodexChapter>
    )

    val sagas: List<CodexSaga> = listOf(
        // =====================================================================
        // SAGA I: THE LOWER BASTION & SUNKEN GARRISON (LANTAI 1 - 10)
        // =====================================================================
        CodexSaga(
            sagaNumber = 1,
            title = "Saga I: Benteng Bawah & Jurang Duri",
            tabLabel = "SAGA I",
            chapters = listOf(
                createChapter(1, "Lt 1: Panggilan Abu", "BASTION",
                    "Kaelen The Bladeweaver terbangun di Padang Abu tanpa ingatan masa lalu, hanya sebuah rune bara menyala di dadanya.",
                    "Tablet I: 'Hari ke-1. Seratus prajurit tiba di gerbang bawah. Garis tubuh kami terasa ringan, namun pedang tak lagi bergetar oleh detak jantung fana. Jangan pernah berhenti melangkah saat menara memanggil.'"),
                createChapter(2, "Lt 2: Pelarutan Kinetik", "BASTION",
                    "Di luar menara, fenomena The Dissolution mencairkan tubuh siapa pun yang diam menjadi genangan tinta mati.",
                    "Tablet II: 'Bumi luar menara telah menjadi kuburan lapar. Berhentilah bergerak selama satu helaan napas, dan kakimu akan meleleh menjadi tinta hitam. Menara ini satu-satunya tempat di mana gravitasi pembunuh itu bisa ditundukkan.'"),
                createChapter(3, "Lt 3: Misteri Tinta & Daging", "BASTION",
                    "Wujud siluet geometris adalah hasil pemadatan paksa dewa, mengkristalkan kehendak jiwa menjadi Anima Core.",
                    "Tablet III: 'Apakah wujud siluet ini sebuah kutukan, ataukah pemadatan eksistensial paksa? Selama bara Anima Core di dada menyala, bilah bajamu takkan pernah mengenal rasa lelah.'"),
                createChapter(4, "Lt 4: Sumpah Ksatria Oakhaven", "BASTION",
                    "Jenderal Oakhaven menolak melarikan diri saat peradaban runtuh, bersumpah menjaga gerbang uji bagi calon pembebas.",
                    "Tablet IV: 'Sang Jenderal berdiri di gerbang atas. Ia tahu dewa telah mengutuk peradaban ini, namun ia menolak melarikan diri. Jika tugasku menjaga gerbang ini, katanya, maka hanya ksatria yang lebih tajam dari pedangku yang boleh lewat.'"),
                createChapter(5, "Lt 5: Gugurnya Sang Penjaga", "BOS",
                    "Kaelen berduel kehormatan melawan Jenderal Oakhaven. Sebelum gugur, sang jenderal menitipkan pedang kepercayaannya.",
                    "Tablet V: 'Tebasan angin Kaelen membelah perisai sang jenderal. Oakhaven tersenyum di balik topeng kayunya seraya berbisik: Teruslah mendaki, Nak... dunia ini menunggumu membebaskan fajar.'"),
                createChapter(6, "Lt 6: Suaka Penempa Vulcanus", "SUAKA",
                    "Kawah penempaan tersembunyi milik Vulcanus. Besi meteorit adalah materi tunggal yang menolak kutukan Tinta Primordial.",
                    "Tablet VI: 'Api tempaan Vulcanus adalah satu-satunya pelindung dari dinginnya pembekuan tinta. Di sini, baja ditempa bukan untuk membunuh, melainkan untuk menjaga asa tetap menyala.'"),
                createChapter(7, "Lt 7: Anomali Tekanan Hampa", "BASTION",
                    "Dinding menara mulai memperlihatkan jurang antariksa kosmos hampa udara, di mana gravitasi mulai berfluktuasi.",
                    "Tablet VII: 'Tekanan udara lenyap di lantai ini. Satu lompatan membawamu mengambang bebas, namun jarum-jarum duri di bawah sana siap melarutkan tubuhmu jika kau kehilangan kendali momentum.'"),
                createChapter(8, "Lt 8: Miasma Lembah Sutra", "MIASMA",
                    "Kabut racun kristal ungu merayap di lorong laba-laba. Pemanah Amethyst membidik dari balik jaring beracun.",
                    "Tablet VIII: 'Kabut ungu ini membakar paru-paru biologis yang telah tiada, menggantikannya dengan rasa terbakar di dalam jiwa. Pemanah bayangan Vespera mengintai dari balik kepompong sutra.'"),
                createChapter(9, "Lt 9: Sarang Ratu Kristal", "MIASMA",
                    "Sarang Lady Vespera dipenuhi racun dan jerat sutra tajam pemenggal leher pendaki.",
                    "Tablet IX: 'Lady Vespera bukan monster sejak lahir; ia adalah putri bangsawan yang meminum racun kristal demi melindungi adik-adiknya dari murka dewa. Kini ia meratap dalam kegelapan sarang kristal.'"),
                createChapter(10, "Lt 10: Pembebasan Zephyr", "UNLOCK",
                    "Kaelen memotong kepompong racun menyelamatkan Zephyr The Shadowstalker. Keduanya bekerja sama menumbangkan Lady Vespera.",
                    "Tablet X: 'Belati kembar Zephyr menari memutus jaring Vespera. Keduanya berpadu bagai kilat dan badai. Sang Ratu tersenyum sebelum larut: Kalian berdua... saling melengkapi... bawalah fajar ke atas sana.'")
            )
        ),

        // =====================================================================
        // SAGA II: THE SUNKEN ARCHIVES & CLOCKWORK FOUNDRY (LANTAI 11 - 20)
        // =====================================================================
        CodexSaga(
            sagaNumber = 2,
            title = "Saga II: Pabrik Jam & Kawah Magma",
            tabLabel = "SAGA II",
            chapters = listOf(
                createChapter(11, "Lt 11: Pipa-Pipa Uap Kuno", "FOUNDRY",
                    "Saluran pipa uap bertekanan tinggi dan gerbang hidrolik sempit yang hanya dapat ditembus oleh kelincahan Zephyr.",
                    "Tablet XI: 'Uap panas ini bukan sekadar uap air, melainkan keringat peradaban mesin masa lalu yang menolak mati. Melangkahlah lincah, atau logam tubuhmu akan melengkung terpanggang.'"),
                createChapter(12, "Lt 12: Laboratorium Alkimia", "ARCHIVE",
                    "Tabung-tabung kaca raksasa berisi residu cairan pelarut ingatan dan gulungan naskah arsitek kuno.",
                    "Tablet XII: 'Di dalam tabung-tabung ini para alkemis mencoba merekonstruksi darah biologis. Namun setiap tetes yang mereka ciptakan hanya mengundang dahaga para monster tinta.'"),
                createChapter(13, "Lt 13: Suaka Penempaan Inti", "SUAKA",
                    "Titik henti aman di mana Vulcanus menempah ulang belati Zephyr dengan lapisan karbon meteorit anti-leleh.",
                    "Tablet XIII: 'Vulcanus menghantam paron meteoritnya sembilan kali. Setiap ketukan membangkitkan resonansi Anima pada belati Zephyr: Jangan biarkan bayangan mengaburkan ketajaman intuisimu.'"),
                createChapter(14, "Lt 14: Roda Gigi Jam Takdir", "FOUNDRY",
                    "Roda gigi raksasa setinggi puluhan meter yang berputar tanpa henti, mengatur tempo perputaran siklus kematian.",
                    "Tablet XIV: 'Detik jam ini berdentang lambat. Di sini waktu bukan mengalir ke depan, melainkan berputar dalam lingkaran siksaan tanpa ujung yang dirancang sang arsitek menara.'"),
                createChapter(15, "Lt 15: Amukan Master Ignis", "BOS",
                    "Pertarungan sengit melawan Forge-Master Ignis di atas platform terak mendidih.",
                    "Tablet XV: 'Palu Ignis membakar udara menara menjadi lautan bara. Namun di balik keganasannya tersimpan duka mendalam atas hilangnya murid-murid terbaiknya di kawah bawah.'"),
                createChapter(16, "Lt 16: Ventilasi Beracun", "FOUNDRY",
                    "Lorong pipa ventilasi sempit dengan semburan uap magma bertekanan 50 bar.",
                    "Tablet XVI: 'Hanya siluet seringan Zephyr yang mampu meluncur di antara kisi-kisi uap tanpa terbakar. Satu hembusan angin bayangan membuka jalan bagi seluruh rombongan pendaki.'"),
                createChapter(17, "Lt 17: Arsip Ordo Eclipse", "ARCHIVE",
                    "Ruang berkas rahasia tempat Zephyr menemukan gulungan naskah asli pengorbanan rakyat Aethelgard.",
                    "Tablet XVII: 'Tinta di gulungan ini telah memudar, namun kebenaran di baliknya berteriak lantang: Menara ini bukan sarana penyelamatan, melainkan altimeter pemadatan semesta!'"),
                createChapter(18, "Lt 18: Piston Tekanan Hidrolik", "FOUNDRY",
                    "Piston-piston titan seberat puluhan ton yang menghantam lantai secara ritmis bagai palu godam raksasa.",
                    "Tablet XVIII: 'Hantaman piston ini mengguncang fondasi menara. Berlarilah saat piston terangkat, dan bersiaplah menangkis serbuan serangga mekanik yang bersembunyi di celah roda gigi.'"),
                createChapter(19, "Lt 19: Lorong Baja Meleleh", "FOUNDRY",
                    "Kanal peleburan baja panas tempat terak magma mengalir bagai air terjun api membara.",
                    "Tablet XIX: 'Baja cair mendidih di bawah jembatan besi. Panasnya mampu melarutkan tameng tertebal, namun bara di dada Kaelen dan Zephyr menolak untuk padam.'"),
                createChapter(20, "Lt 20: Beban Abadi Gorgon", "UNLOCK",
                    "Gorgon The Ironbreaker menahan pilar titan seberat ratusan ton bertahun-tahun demi melindungi bunker pengungsi.",
                    "Tablet XX: 'Pilar titan berderit menimpa bahu Gorgon. Dengan satu tebasan gabungan Kaelen dan Zephyr, tuas penahan terkunci. Gorgon mengaum melepaskan beban bajanya seraya membelah Slag Colossus!'")
            )
        ),

        // =====================================================================
        // SAGA III: THE GILDED CATACOMBS & BASALT CHASM (LANTAI 21 - 30)
        // =====================================================================
        CodexSaga(
            sagaNumber = 3,
            title = "Saga III: Jurang Basalt & Cermin Jiwa",
            tabLabel = "SAGA III",
            chapters = listOf(
                createChapter(21, "Lt 21: Kawah Basalt Hitam", "BASALT",
                    "Dinding batu basalt hitam meteorit yang hanya mampu dihancurkan oleh tebasan Colossal Greatsword Gorgon.",
                    "Tablet XXI: 'Batu basalt hitam ini membeku dari air mata bumi purba. Pedang biasa hanya akan patah membenturnya; hanya palu dan godam berjiwa titan yang mampu membuka jalan.'"),
                createChapter(22, "Lt 22: Sungai Lahar Pijar", "BASALT",
                    "Aliran magma kental membelah arena, menuntut lompatan tepat waktu di atas batu apung obsidian.",
                    "Tablet XXII: 'Sungai api ini menuntut kepastian langkah. Mereka yang ragu akan terseret arus magma, sementara mereka yang berani melompat akan menemukan batu pijakan surga.'"),
                createChapter(23, "Lt 23: Benteng Pertahanan Titan", "BASALT",
                    "Reruntuhan benteng pertahanan kaum paladin Titan Bastion yang gugur menahan serbuan monster lava.",
                    "Tablet XXIII: 'Di benteng inilah barisan paladin terakhir berdiri hingga napas penghabisan. Nisan mereka berupa pedang raksasa yang tertancap kokoh menghadap kawah lava.'"),
                createChapter(24, "Lt 24: Sarkofagus Para Martir", "BASALT",
                    "Ruang peristirahatan terakhir saudara-saudara seperjuangan Gorgon.",
                    "Tablet XXIV: 'Gorgon menundukkan kepalanya di depan sarkofagus marmer hitam. Tidak ada air mata yang menetes, hanya tekad baja yang membara kian terang di matanya.'"),
                createChapter(25, "Lt 25: Raja Golem Magma", "BOS",
                    "Duel dahsyat menghancurkan kulit batu tebal Sang Raja Golem Magma dengan Guard Break Gorgon.",
                    "Tablet XXV: 'Tebasan pemecah perisai Gorgon meretakkan inti Raja Golem. Zephyr menusuk urat magmanya, sementara Kaelen menuntaskan tebasan terakhir pembebas kawah.'"),
                createChapter(26, "Lt 26: Ambang Retakan Angkasa", "KOSMOS",
                    "Dinding batu menara runtuh terbuka menghadap cakrawala antariksa nebula berbintang cyan.",
                    "Tablet XXVI: 'Dinding batu berakhir di sini. Di depan kita terbentang jurang kosmos tak berdasar di mana angin bintang melolong memanggil jiwa-jiwa pengelana.'"),
                createChapter(27, "Lt 27: Hembusan Angin Bintang", "KOSMOS",
                    "Gravitasi rendah memungkinkan lompatan 2x lebih tinggi melintasi pulau meteorit melayang.",
                    "Tablet XXVII: 'Angin kosmis mengangkat tubuh kita seringan kapas. Nikmati sensasi terbang ini, namun ingatlah bahwa jurang di bawah sana tidak memiliki dasar penolong.'"),
                createChapter(28, "Lt 28: Jembatan Meteorit", "KOSMOS",
                    "Rantai bongkahan batu meteorit melayang bebas yang berguncang oleh pusaran medan magnet semesta.",
                    "Tablet XXVIII: 'Platform meteorit ini bergerak selaras dengan denyut gravitasi menara. Sinergi tiga pahlawan adalah kunci menjaga keseimbangan di atas titian bintang.'"),
                createChapter(29, "Lt 29: Gravitasi Terbalik", "KOSMOS",
                    "Pusaran singularitas gravitasi memutarbalikkan persepsi atas dan bawah secara ekstrem.",
                    "Tablet XXIX: 'Langit menjadi lantai, jurang menjadi atap. Hukum alam ditundukkan oleh kehendak pencipta menara. Hanya keteguhan batin yang mampu menuntun arah langkahmu.'"),
                createChapter(30, "Lt 30: Nexus of Reflections", "BOS",
                    "Pertarungan cermin jiwa melawan The Shadow Doppelgänger menghadapi keraguan terdalam batin pahlawan.",
                    "Tablet XXX: 'Cermin hitam memantulkan bayangan keraguan kita: rasa bersalah Kaelen, trauma Zephyr, dan duka Gorgon. Menaklukkan bayangan diri sendiri adalah kemenangan sejati.'")
            )
        ),

        // =====================================================================
        // SAGA IV: THE ASTRAL ABYSS & CRIMSON ECLIPSE (LANTAI 31 - 40)
        // =====================================================================
        CodexSaga(
            sagaNumber = 4,
            title = "Saga IV: Retakan Astral & Gerhana Darah",
            tabLabel = "SAGA IV",
            chapters = listOf(
                createChapter(31, "Lt 31: Dimensi di Balik Kanvas", "ASTRAL",
                    "Dinding menara lenyap total; jembatan cahaya melayang di ruang hampa antar-galaksi dengan Altar Prisma.",
                    "Tablet XXXI: 'Di balik dinding kanvas ini realitas fana terurai menjadi serpihan cahaya. Altar Prisma Triad berdiri sebagai simbol persatuan tiga pahlawan terpilih.'"),
                createChapter(32, "Lt 32: Kepulauan Melayang", "ASTRAL",
                    "Kepulauan batu obsidian melayang bebas di tengah pusaran badai debu kosmis.",
                    "Tablet XXXII: 'Pulau-pulau batu melayang anggun di angkasa. Zephyr melompat lincah membuka celah angin sementara Gorgon dan Kaelen menyambut serbuan monster terbang.'"),
                createChapter(33, "Lt 33: Labirin Singularitas", "ASTRAL",
                    "Ruang berputar pada sudut 90 derajat; waktu melambat saat proyektil musuh mendekat.",
                    "Tablet XXXIII: 'Waktu melambat di pusaran singularitas ini. Lakukan Perfect Parry pada serpihan bintang musuh untuk memantulkan hukum waktu dewa kembali ke asalnya.'"),
                createChapter(34, "Lt 34: Gema Jiwa Terlarut", "ASTRAL",
                    "Angin kosmis membisikkan jutaan ratapan jiwa penduduk Aethelgard yang telah larut di bumi bawah.",
                    "Tablet XXXIV: 'Bisikan orang-orang mati memanggil dari kegelapan jurang: Teruslah mendaki... jangan biarkan darah dan air mata kami menjadi noda sia-sia di kanvas dewa.'"),
                createChapter(35, "Lt 35: The Void Chimera", "BOS",
                    "Monster kosmis bertentakel bintang penjaga gerbang katedral gerhana darah.",
                    "Tablet XXXV: 'Ketiga kepala Chimera Kehampaan memuntahkan laser kehampaan. Dengan memadukan kekuatan Triad di Altar Prisma, monster kosmis ini berhasil diruntuhkan.'"),
                createChapter(36, "Lt 36: Katedral Gerhana Darah", "CATHEDRAL",
                    "Cahaya cyan kosmis perlahan memerah di bawah gerhana bulan merah darah (*Blood Moon*).",
                    "Tablet XXXVI: 'Kubah katedral gotik hitam menjulang di bawah gerhana bulan merah darah. Di sini para bangsawan durhaka menyembah keabadian palsu yang ditawarkan pangeran vampir.'"),
                createChapter(37, "Lt 37: Koridor Beludru Merah", "CATHEDRAL",
                    "Tirai beludru katedral basah oleh tetesan darah; musuh meregenerasi luka di bawah sinar bulan merah.",
                    "Tablet XXXVII: 'Musuh-musuh bertaring meregenerasi luka mereka di bawah sinar bulan merah. Pancing mereka ke bayangan pilar katedral di mana pedang kita dapat menembus jantungnya.'"),
                createChapter(38, "Lt 38: Altar Pengorbanan Anima", "ALTAR",
                    "Altar darah tempat para bangsawan mengorbankan rakyat jelata demi keabadian rupa.",
                    "Tablet XXXVIII: 'Di atas altar darah ini harga sebuah nyawa fana ditukar dengan setetes pigmen merah abadi. Darah para martir kini menuntut pembalasan setimpal.'"),
                createChapter(39, "Lt 39: Katakomba Darah Abadi", "CATHEDRAL",
                    "Peti-peti marmer berlumur darah terbuka, membangkitkan pasukan algojo bertaring bersenjatakan kapak eksekusi.",
                    "Tablet XXXIX: 'Gorgon menahan ayunan kapak algojo dengan Super Armor-nya, memberi ruang bagi Zephyr untuk menusuk titik lemah di balik jubah besi mereka.'"),
                createChapter(40, "Lt 40: Runtuhnya Pangeran Darah", "BOS",
                    "Duel klimaks menembus balairung takhta megah melawan Malakor The Crimson Sovereign.",
                    "Tablet XL: 'Malakor tersungkur di depan takhtanya seraya memuntahkan tinta merah: Di atas lantai 40... para dewa tidak lagi bermain dengan darah... mereka bermain dengan hukum penciptaan!'")
            )
        ),

        // =====================================================================
        // SAGA V: THE CELESTIAL CANVAS & PRIMORDIAL ZENITH (LANTAI 41 - 50)
        // =====================================================================
        CodexSaga(
            sagaNumber = 5,
            title = "Saga V: Puncak Kanvas Kosmis Dewa",
            tabLabel = "SAGA V",
            chapters = listOf(
                createChapter(41, "Lt 41: Tangga Marmer Suci", "ZENITH",
                    "Cahaya merah darah memudar digantikan marmer putih suci dan aurora keemasan spektakuler.",
                    "Tablet XLI: 'Cahaya merah darah memudar, digantikan oleh kilau marmer putih bersih dan aurora keemasan. Warna-warna spektrum kuno mulai berbisik di udara menara.'"),
                createChapter(42, "Lt 42: Pilar Spektrum Purba", "ZENITH",
                    "Di dalam pilar marmer terperangkap warna biru samudra dan hijau hutan purba.",
                    "Tablet XLII: 'Di dalam pilar marmer ini terperangkap warna biru samudra dan hijau hutan. Anima Core ketiga pahlawan beresonansi menciptakan perisai fajar pelindung.'"),
                createChapter(43, "Lt 43: Geometri Non-Euclidean", "ZENITH",
                    "Platform melayang dalam koordinat matematika empat dimensi yang menantang akal budi.",
                    "Tablet XLIII: 'Platform melayang dalam koordinat matematika empat dimensi. Pemain harus memecahkan puzzle rotasi warna primer untuk membuka gerbang surga.'"),
                createChapter(44, "Lt 44: Lautan Tinta Penciptaan", "ZENITH",
                    "Jembatan marmer melayang di atas samudra tinta hitam murni tempat seluruh galaksi digambar.",
                    "Tablet XLIV: 'Di bawah jembatan marmer terhampar samudra tinta hitam murni tempat seluruh galaksi digambar. Ombak pasang tinta menyapu berkala; berpeganglah pada pilar iman!'"),
                createChapter(45, "Lt 45: Malaikat Geometri Suci", "BOS",
                    "Pertarungan melawan Archon of Pure Geometry berlaser pembelah realitas platform.",
                    "Tablet XLV: 'Archon tanpa wajah menghadang. Serangannya berupa garis laser putih pemotong realitas. Zephyr melesat menembus celah laser sementara Kaelen dan Gorgon meruntuhkan intinya.'"),
                createChapter(46, "Lt 46: Tangga Fajar Kosmis", "ZENITH",
                    "Setiap anak tangga marmer memancarkan nada musik sakral saat diinjak menuju singgasana.",
                    "Tablet XLVI: 'Setiap anak tangga yang diinjak memancarkan nada musik sakral. Menara berguncang menyambut kedatangan tiga ksatria fana di depan singgasana dewa.'"),
                createChapter(47, "Lt 47: Ruang Tunggu Arsitek", "ZENITH",
                    "Pilar setinggi seratus meter memuat lukisan mural sejarah seluruh peradaban yang pernah dihapus.",
                    "Tablet XLVII: 'Lukisan-lukisan sejarah seluruh peradaban yang pernah diciptakan dan dihapus terpampang di dinding pilar setinggi seratus meter. Kita bukan peradaban pertama yang dihancurkan.'"),
                createChapter(48, "Lt 48: Ambang Kanvas Primordial", "ALTAR",
                    "Lentera Aria memancarkan pendar terangnya; altar pengorbanan terakhir sebelum pintu dewa.",
                    "Tablet XLVIII: 'Aria memancarkan cahaya pendar terangnya: Kaelen, Zephyr, Gorgon... saat kalian melangkah menembus pintu ini, tidak ada lagi jalan kembali. Takdir seluruh Aethelgard ada di tangan kalian.'"),
                createChapter(49, "Lt 49: Sumpah Triad of Dawn", "ZENITH",
                    "Ketiga pahlawan menyatukan bilah senjata di ambang gerbang emas keadilan fajar.",
                    "Tablet XLIX: 'Ketiga pahlawan menyatukan bilah senjata mereka di ambang gerbang emas: Demi warna yang dirampas, demi jiwa yang larut, demi fajar yang merdeka: hari ini, dewa takdir akan jatuh!'"),
                createChapter(50, "Lt 50: Patahnya Pena Takdir", "FINAL",
                    "Pertarungan klimaks pamungkas mematahkan The Primordial Stylus memicu Fajar Kosmis (The Chromatic Dawn).",
                    "Tablet L: 'Bilah pedang Kaelen, belati Zephyr, dan godam Gorgon menghantam tepat di tengah batang The Primordial Stylus. KRAAAAKKK! Pena terbelah dua. Cawan tinta meledak. Fajar kosmis merekah. Kita bukan lagi coretan dewa; kita adalah pelukis dari hidup kita sendiri!'")
            )
        )
    )

    private var selectedSagaIndex = 0
    private var selectedChapterIndex = 0
    private var currentPageIndex = 0

    // Partikel Latar Belakang (Golden / Cyan Ink Embers)
    private class StoryParticle(
        val pos: Vector2 = Vector2(),
        val vel: Vector2 = Vector2(),
        var size: Float = 0f,
        var color: Color = Color.WHITE,
        var maxLife: Float = 1f
    ) {
        var life: Float = 0f
        val isExpired: Boolean get() = life >= maxLife

        fun reset(initial: Boolean = false) {
            val x = MathUtils.random(0f, 1280f)
            val y = if (initial) MathUtils.random(0f, 720f) else -10f
            pos.set(x, y)
            vel.set(MathUtils.random(-12f, 12f), MathUtils.random(20f, 50f))
            size = MathUtils.random(2f, 4.5f)
            val isGold = MathUtils.randomBoolean(0.7f)
            color = if (isGold) Color(1f, 0.82f, 0.28f, MathUtils.random(0.3f, 0.65f))
                    else Color(0.25f, 0.85f, 1f, MathUtils.random(0.3f, 0.65f))
            maxLife = MathUtils.random(8f, 15f)
            life = 0f
        }
    }
    private val particles = mutableListOf<StoryParticle>()

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        FontManager.init()
        inputCooldown = 0.25f
        selectedSagaIndex = 0
        selectedChapterIndex = 0
        currentPageIndex = 0

        // Berikan trofi pencapaian membuka Story Codex
        val save = com.stickman.tower.rpg.SaveManager.load()
        AchievementManager.loadFromSave(save)
        if (AchievementManager.onStoryCodexOpened(save)) {
            com.stickman.tower.rpg.SaveManager.save(save)
        }

        particles.clear()
        for (i in 0 until 40) {
            val p = StoryParticle()
            p.reset(initial = true)
            particles.add(p)
        }
    }

    override fun render(delta: Float) {
        animTime += delta
        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }
        if (game.screen !== this) return

        updateParticles(delta)

        ScreenUtils.clear(0.035f, 0.045f, 0.075f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // =========================================================================
        // 1. RENDER LATAR BELAKANG GEOMETRIS & KOTAK CODEX (SHAPE RENDERER)
        // =========================================================================
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Partikel Cahaya Jiwa Menara
        for (p in particles) {
            val alpha = (1f - (p.life / p.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(p.color.r, p.color.g, p.color.b, p.color.a * alpha * 0.45f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 1.6f)
            shapeRenderer.setColor(1f, 1f, 1f, alpha * 0.8f)
            shapeRenderer.circle(p.pos.x, p.pos.y, p.size * 0.5f)
        }

        // Panel Judul Atas
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(40f, 640f, 1200f, 60f)
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.85f)
        shapeRenderer.rectLine(40f, 640f, 1240f, 640f, 2.5f)

        // Kolom Kiri: Navigasi Sidebar (40f..400f, 100f..620f)
        shapeRenderer.setColor(0.05f, 0.07f, 0.12f, 0.92f)
        shapeRenderer.rect(40f, 100f, 360f, 520f)
        shapeRenderer.setColor(0.18f, 0.24f, 0.35f, 0.75f)
        shapeRenderer.rectLine(400f, 100f, 400f, 620f, 2f)

        // ---------------------------------------------------------------------
        // TAB BAR 5 SAGA DI BAGIAN ATAS SIDEBAR (575f..615f)
        // ---------------------------------------------------------------------
        val tabW = 68f
        val tabH = 36f
        val tabSpacing = 3.5f
        val tabStartX = 45f
        val tabY = 574f

        for (s in sagas.indices) {
            val tx = tabStartX + s * (tabW + tabSpacing)
            val isSagaActive = (s == selectedSagaIndex)

            if (isSagaActive) {
                val pulse = sin(animTime * 5f) * 0.08f
                shapeRenderer.setColor(0.14f, 0.22f, 0.34f, 0.95f)
                shapeRenderer.rect(tx, tabY, tabW, tabH)
                // Aksen Emas Bawah Tab Aktif
                shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.90f + pulse)
                shapeRenderer.rectLine(tx, tabY, tx + tabW, tabY, 3.5f)
                shapeRenderer.rectLine(tx, tabY + tabH, tx + tabW, tabY + tabH, 1.2f)
            } else {
                shapeRenderer.setColor(0.07f, 0.09f, 0.15f, 0.75f)
                shapeRenderer.rect(tx, tabY, tabW, tabH)
                shapeRenderer.setColor(0.20f, 0.25f, 0.35f, 0.45f)
                shapeRenderer.rectLine(tx, tabY, tx + tabW, tabY, 1f)
            }
        }

        // Garis Pemisah antara Tab Bar dan Daftar Bab
        shapeRenderer.setColor(0.22f, 0.28f, 0.40f, 0.75f)
        shapeRenderer.rectLine(42f, 568f, 398f, 568f, 1.5f)

        // ---------------------------------------------------------------------
        // DAFTAR 10 BAB DALAM SAGA AKTIF (108f..562f - Anti-Dempet Spacing)
        // ---------------------------------------------------------------------
        val activeChapters = sagas[selectedSagaIndex].chapters
        val chapterItemH = 41.5f
        val chapterSpacing = 3.8f
        val chapterStartY = 565f - chapterItemH

        for (i in activeChapters.indices) {
            val ch = activeChapters[i]
            val itemY = chapterStartY - (i * (chapterItemH + chapterSpacing))
            val isChapSelected = (i == selectedChapterIndex)

            if (isChapSelected) {
                val pulse = sin(animTime * 5f) * 0.08f
                shapeRenderer.setColor(0.12f, 0.18f, 0.28f, 0.95f)
                shapeRenderer.rect(45f, itemY, 350f, chapterItemH)
                // Ornamen Bingkai Emas Kaligrafi di Tepi Kiri Bab Aktif
                shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.90f + pulse)
                shapeRenderer.rectLine(45f, itemY, 45f, itemY + chapterItemH, 4f)
                shapeRenderer.rectLine(45f, itemY, 395f, itemY, 1.2f)
                shapeRenderer.rectLine(45f, itemY + chapterItemH, 395f, itemY + chapterItemH, 1.2f)
            } else {
                shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.65f)
                shapeRenderer.rect(45f, itemY, 350f, chapterItemH)
            }

            // Kapsul Tinta Tematik Bioma (Thematic Ink Capsule Pill)
            val pillColors = when (ch.tag) {
                "BASTION" -> floatArrayOf(0.15f, 0.20f, 0.28f, 0.45f, 0.70f, 0.95f)
                "SUAKA" -> floatArrayOf(0.24f, 0.16f, 0.06f, 0.95f, 0.70f, 0.25f)
                "FOUNDRY" -> floatArrayOf(0.26f, 0.12f, 0.06f, 0.95f, 0.45f, 0.20f)
                "BASALT" -> floatArrayOf(0.20f, 0.10f, 0.05f, 0.85f, 0.50f, 0.15f)
                "KOSMOS" -> floatArrayOf(0.08f, 0.18f, 0.28f, 0.35f, 0.85f, 1.0f)
                "ASTRAL" -> floatArrayOf(0.18f, 0.08f, 0.26f, 0.75f, 0.45f, 0.95f)
                "CATHEDRAL" -> floatArrayOf(0.25f, 0.05f, 0.08f, 0.90f, 0.20f, 0.25f)
                "ZENITH" -> floatArrayOf(0.22f, 0.22f, 0.30f, 0.95f, 0.90f, 0.75f)
                "BOS", "FINAL", "UNLOCK" -> floatArrayOf(0.28f, 0.18f, 0.05f, 1.0f, 0.85f, 0.30f)
                else -> floatArrayOf(0.12f, 0.16f, 0.22f, 0.50f, 0.65f, 0.80f)
            }
            val pillW = 64f
            val pillH = 15f
            val pillX = 322f
            val pillY = itemY + 13f

            shapeRenderer.setColor(pillColors[0], pillColors[1], pillColors[2], 0.90f)
            shapeRenderer.rect(pillX, pillY, pillW, pillH)
            shapeRenderer.setColor(pillColors[3], pillColors[4], pillColors[5], 0.85f)
            shapeRenderer.rectLine(pillX, pillY, pillX + pillW, pillY, 1f)
            shapeRenderer.rectLine(pillX, pillY + pillH, pillX + pillW, pillY + pillH, 1f)
            shapeRenderer.rectLine(pillX, pillY, pillX, pillY + pillH, 1f)
            shapeRenderer.rectLine(pillX + pillW, pillY, pillX + pillW, pillY + pillH, 1f)
        }

        // ---------------------------------------------------------------------
        // PANEL KANAN: WADAH BACA TEKS KISAH (CODEX READER PARCHMENT)
        // ---------------------------------------------------------------------
        shapeRenderer.setColor(0.06f, 0.08f, 0.13f, 0.94f)
        shapeRenderer.rect(420f, 100f, 820f, 520f)
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.70f)
        shapeRenderer.rectLine(420f, 620f, 1240f, 620f, 2f)
        shapeRenderer.rectLine(420f, 100f, 1240f, 100f, 2f)
        shapeRenderer.rectLine(420f, 100f, 420f, 620f, 2f)
        shapeRenderer.rectLine(1240f, 100f, 1240f, 620f, 2f)

        // Ornamen Sudut Kotak Baca (Calligraphic Corner Notches)
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.9f)
        shapeRenderer.rectLine(420f, 620f, 445f, 620f, 4f)
        shapeRenderer.rectLine(420f, 620f, 420f, 595f, 4f)
        shapeRenderer.rectLine(1240f, 620f, 1215f, 620f, 4f)
        shapeRenderer.rectLine(1240f, 620f, 1240f, 595f, 4f)
        shapeRenderer.rectLine(420f, 100f, 445f, 100f, 4f)
        shapeRenderer.rectLine(420f, 100f, 420f, 125f, 4f)
        shapeRenderer.rectLine(1240f, 100f, 1215f, 100f, 4f)
        shapeRenderer.rectLine(1240f, 100f, 1240f, 125f, 4f)

        // Bookmark Pill Nomor Halaman (Pojok Kanan Atas Kontainer)
        shapeRenderer.setColor(0.09f, 0.14f, 0.22f, 0.95f)
        shapeRenderer.rect(1090f, 580f, 130f, 26f)
        shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.85f)
        shapeRenderer.rectLine(1090f, 580f, 1220f, 580f, 1.2f)
        shapeRenderer.rectLine(1090f, 606f, 1220f, 606f, 1.2f)
        shapeRenderer.rectLine(1090f, 580f, 1090f, 606f, 1.2f)
        shapeRenderer.rectLine(1220f, 580f, 1220f, 606f, 1.2f)

        // Garis Pemisah Subtitle di Halaman Baca
        shapeRenderer.setColor(0.20f, 0.28f, 0.40f, 0.65f)
        shapeRenderer.rectLine(445f, 545f, 1215f, 545f, 1.5f)

        // Tombol Navigasi Bawah: [❮ SEBELUMNYA] [SELANJUTNYA ❯] dan [KEMBALI KE MENU]
        val curChapterP = activeChapters[selectedChapterIndex]
        val totalPagesP = curChapterP.pages.size

        // Tombol Page Prev (445f - 605f)
        if (currentPageIndex > 0) {
            shapeRenderer.setColor(0.10f, 0.16f, 0.26f, 0.95f)
            shapeRenderer.rect(445f, 40f, 160f, 44f)
            shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.85f)
            shapeRenderer.rectLine(445f, 40f, 605f, 40f, 1.5f)
            shapeRenderer.rectLine(445f, 84f, 605f, 84f, 1.5f)
            shapeRenderer.rectLine(445f, 40f, 445f, 84f, 1.5f)
            shapeRenderer.rectLine(605f, 40f, 605f, 84f, 1.5f)
        } else {
            shapeRenderer.setColor(0.06f, 0.08f, 0.13f, 0.60f)
            shapeRenderer.rect(445f, 40f, 160f, 44f)
            shapeRenderer.setColor(0.20f, 0.25f, 0.35f, 0.40f)
            shapeRenderer.rectLine(445f, 40f, 605f, 40f, 1f)
            shapeRenderer.rectLine(445f, 84f, 605f, 84f, 1f)
        }

        // Tombol Page Next (635f - 795f)
        if (currentPageIndex < totalPagesP - 1) {
            shapeRenderer.setColor(0.10f, 0.16f, 0.26f, 0.95f)
            shapeRenderer.rect(635f, 40f, 160f, 44f)
            shapeRenderer.setColor(0.95f, 0.78f, 0.25f, 0.85f)
            shapeRenderer.rectLine(635f, 40f, 795f, 40f, 1.5f)
            shapeRenderer.rectLine(635f, 84f, 795f, 84f, 1.5f)
            shapeRenderer.rectLine(635f, 40f, 635f, 84f, 1.5f)
            shapeRenderer.rectLine(795f, 40f, 795f, 84f, 1.5f)
        } else {
            shapeRenderer.setColor(0.06f, 0.08f, 0.13f, 0.60f)
            shapeRenderer.rect(635f, 40f, 160f, 44f)
            shapeRenderer.setColor(0.20f, 0.25f, 0.35f, 0.40f)
            shapeRenderer.rectLine(635f, 40f, 795f, 40f, 1f)
            shapeRenderer.rectLine(635f, 84f, 795f, 84f, 1f)
        }

        // Tombol Kembali Ke Menu (980f - 1240f)
        shapeRenderer.setColor(0.20f, 0.08f, 0.10f, 0.95f)
        shapeRenderer.rect(980f, 38f, 260f, 46f)
        shapeRenderer.setColor(0.95f, 0.35f, 0.35f, 0.90f)
        shapeRenderer.rectLine(980f, 38f, 1240f, 38f, 2f)
        shapeRenderer.rectLine(980f, 84f, 1240f, 84f, 2f)
        shapeRenderer.rectLine(980f, 38f, 980f, 84f, 2f)
        shapeRenderer.rectLine(1240f, 38f, 1240f, 84f, 2f)

        shapeRenderer.end()

        // =========================================================================
        // 2. RENDER TEKS & TIPOGRAFI LORE (SPRITE BATCH)
        // =========================================================================
        batch.begin()

        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Judul Layar (H1 Display Token)
        titleF.color = Color.WHITE
        titleF.draw(batch, "KRONIK MENARA AETHELGARD", 50f, 685f)
        smallF.setColor(1f, 0.85f, 0.35f, 0.9f)
        smallF.draw(batch, "Arsip 50 Bab & Transkrip 50 Prasasti Kuno Kanonikal", 710f, 678f)

        // ---------------------------------------------------------------------
        // TEKS TAB BAR 5 SAGA
        // ---------------------------------------------------------------------
        for (s in sagas.indices) {
            val tx = tabStartX + s * (tabW + tabSpacing)
            val isSagaActive = (s == selectedSagaIndex)
            if (isSagaActive) {
                smallF.setColor(1.0f, 0.90f, 0.40f, 1f)
            } else {
                smallF.setColor(0.65f, 0.72f, 0.85f, 0.8f)
            }
            smallF.draw(batch, sagas[s].tabLabel, tx, tabY + 24f, tabW, Align.center, false)
        }

        // ---------------------------------------------------------------------
        // DAFTAR BAB DI SIDEBAR
        // ---------------------------------------------------------------------
        val maxSidebarTextW = 260f
        for (i in activeChapters.indices) {
            val ch = activeChapters[i]
            val itemY = chapterStartY - (i * (chapterItemH + chapterSpacing))

            if (i == selectedChapterIndex) {
                regF.setColor(1f, 0.88f, 0.35f, 1f)
                val activeTitle = "◆ ${ch.title}"
                regF.draw(batch, activeTitle, 54f, itemY + 28f, maxSidebarTextW, Align.left, false)
            } else {
                regF.setColor(0.80f, 0.85f, 0.95f, 0.90f)
                regF.draw(batch, ch.title, 54f, itemY + 28f, maxSidebarTextW, Align.left, false)
            }

            // Teks Kapsul Tag
            smallF.setColor(1f, 1f, 1f, 0.95f)
            smallF.draw(batch, ch.tag, 322f, itemY + 25f, 64f, Align.center, false)
        }

        // ---------------------------------------------------------------------
        // KONTEN BACAAN (PANEL KANAN)
        // ---------------------------------------------------------------------
        val curChapter = activeChapters[selectedChapterIndex]
        val totalPages = curChapter.pages.size
        val curPage = curChapter.pages[currentPageIndex]

        // Judul Bab Aktif (H2 Header)
        headF.setColor(1f, 0.88f, 0.35f, 1f)
        headF.draw(batch, "${sagas[selectedSagaIndex].title}  •  ${curChapter.title}", 445f, 595f, 620f, Align.left, false)

        // Nomor Halaman (Bookmark Pill)
        smallF.setColor(1f, 0.90f, 0.40f, 1f)
        smallF.draw(batch, "Halaman ${currentPageIndex + 1} / $totalPages", 1090f, 598f, 130f, Align.center, false)

        // Subtitle Halaman
        regF.setColor(0.35f, 0.85f, 1.0f, 0.95f)
        regF.draw(batch, curPage.subtitle, 445f, 532f, 770f, Align.left, false)

        // Paragraf Kisah (Anti-Aliased Body Typography, lineHeight ~26px)
        var textY = 485f
        for (p in curPage.paragraphs) {
            val isTabletQuote = p.startsWith("📜") || p.startsWith("Tablet")
            if (isTabletQuote) {
                regF.setColor(1.0f, 0.92f, 0.65f, 1f)
            } else {
                regF.setColor(0.92f, 0.94f, 0.98f, 0.95f)
            }
            glyphLayout.setText(regF, p, regF.color, 770f, Align.left, true)
            regF.draw(batch, p, 445f, textY, 770f, Align.left, true)
            textY -= (glyphLayout.height + 20f)
        }

        // Teks Tombol Navigasi Bawah
        if (currentPageIndex > 0) {
            regF.setColor(1f, 0.85f, 0.3f, 1f)
        } else {
            regF.setColor(0.4f, 0.45f, 0.55f, 0.5f)
        }
        regF.draw(batch, "❮ SEBELUMNYA", 445f, 68f, 160f, Align.center, false)

        if (currentPageIndex < totalPages - 1) {
            regF.setColor(1f, 0.85f, 0.3f, 1f)
        } else {
            regF.setColor(0.4f, 0.45f, 0.55f, 0.5f)
        }
        regF.draw(batch, "SELANJUTNYA ❯", 635f, 68f, 160f, Align.center, false)

        headF.setColor(1f, 0.50f, 0.50f, 1f)
        headF.draw(batch, "KEMBALI KE MENU", 980f, 68f, 260f, Align.center, false)

        // Petunjuk Tombol Keyboard
        smallF.setColor(0.55f, 0.62f, 0.72f, 0.85f)
        smallF.draw(batch, "[Q/E] Saga  •  [W/S] Bab  •  [A/D] Hal  •  [ESC] Menu", 48f, 64f)

        batch.end()
    }

    private fun handleInput() {
        // Navigasi Tab Saga ([Q] / [E] atau [1]..[5])
        if (Gdx.input.isKeyJustPressed(Keys.Q)) {
            if (selectedSagaIndex > 0) {
                selectedSagaIndex--
                selectedChapterIndex = 0
                currentPageIndex = 0
                AudioManager.playSlashLight()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.E)) {
            if (selectedSagaIndex < sagas.size - 1) {
                selectedSagaIndex++
                selectedChapterIndex = 0
                currentPageIndex = 0
                AudioManager.playSlashLight()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.NUM_1)) switchSaga(0)
        if (Gdx.input.isKeyJustPressed(Keys.NUM_2)) switchSaga(1)
        if (Gdx.input.isKeyJustPressed(Keys.NUM_3)) switchSaga(2)
        if (Gdx.input.isKeyJustPressed(Keys.NUM_4)) switchSaga(3)
        if (Gdx.input.isKeyJustPressed(Keys.NUM_5)) switchSaga(4)

        // Navigasi Bab dalam Saga aktif (Atas/Bawah)
        val activeChapters = sagas[selectedSagaIndex].chapters
        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            if (selectedChapterIndex > 0) {
                selectedChapterIndex--
                currentPageIndex = 0
                AudioManager.playSlashLight()
            }
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            if (selectedChapterIndex < activeChapters.size - 1) {
                selectedChapterIndex++
                currentPageIndex = 0
                AudioManager.playSlashLight()
            }
        }

        // Navigasi Paginasi Halaman (Kiri/Kanan)
        if (Gdx.input.isKeyJustPressed(Keys.LEFT) || Gdx.input.isKeyJustPressed(Keys.A)) {
            previousPage()
        }
        if (Gdx.input.isKeyJustPressed(Keys.RIGHT) || Gdx.input.isKeyJustPressed(Keys.D)) {
            nextPage()
        }

        // Deteksi Interaksi Sentuh Layar / Mouse
        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            // Klik Tab Bar 5 Saga (574f..614f)
            val tabW = 68f
            val tabSpacing = 3.5f
            val tabStartX = 45f
            val tabY = 574f
            for (s in sagas.indices) {
                val tx = tabStartX + s * (tabW + tabSpacing)
                if (touchVec.x in tx..(tx + tabW) && touchVec.y in tabY..(tabY + 36f)) {
                    switchSaga(s)
                    break
                }
            }

            // Klik Daftar Bab (108f..565f)
            val chapterItemH = 41.5f
            val chapterSpacing = 3.8f
            val chapterStartY = 565f - chapterItemH
            for (i in activeChapters.indices) {
                val itemY = chapterStartY - (i * (chapterItemH + chapterSpacing))
                if (touchVec.x in 45f..395f && touchVec.y in itemY..(itemY + chapterItemH)) {
                    if (selectedChapterIndex != i) {
                        selectedChapterIndex = i
                        currentPageIndex = 0
                        AudioManager.playSlashLight()
                        HapticManager.vibrateLight()
                    }
                    break
                }
            }

            // Klik Tombol Prev Page (445f..605f, 40f..84f)
            if (touchVec.x in 445f..605f && touchVec.y in 40f..84f) {
                previousPage()
            }

            // Klik Tombol Next Page (635f..795f, 40f..84f)
            if (touchVec.x in 635f..795f && touchVec.y in 40f..84f) {
                nextPage()
            }

            // Klik Tombol Kembali (980f..1240f, 38f..84f)
            if (touchVec.x in 980f..1240f && touchVec.y in 38f..84f) {
                returnToPreviousScreen()
            }
        }

        // Tombol Kembali Keyboard / Android Back
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK)) {
            returnToPreviousScreen()
        }
    }

    private fun switchSaga(index: Int) {
        if (index in sagas.indices && selectedSagaIndex != index) {
            selectedSagaIndex = index
            selectedChapterIndex = 0
            currentPageIndex = 0
            AudioManager.playSlashLight()
            HapticManager.vibrateLight()
        }
    }

    private fun previousPage() {
        if (currentPageIndex > 0) {
            currentPageIndex--
            AudioManager.playJump()
            HapticManager.vibrateLight()
        }
    }

    private fun nextPage() {
        val totalPages = sagas[selectedSagaIndex].chapters[selectedChapterIndex].pages.size
        if (currentPageIndex < totalPages - 1) {
            currentPageIndex++
            AudioManager.playJump()
            HapticManager.vibrateLight()
        }
    }

    private fun returnToPreviousScreen() {
        AudioManager.playSlashLight()
        (game as? StickmanGame)?.releasePreservedScreen(returnScreen ?: this)
        game.setScreen(returnScreen ?: MainMenuScreen(game))
    }

    private fun updateParticles(delta: Float) {
        for (p in particles) {
            p.life += delta
            p.pos.x += p.vel.x * delta
            p.pos.y += p.vel.y * delta
            if (p.isExpired || p.pos.y > 730f) {
                p.reset(initial = false)
            }
        }
    }

    override fun resize(width: Int, height: Int) {
        viewport.update(width, height, true)
    }

    override fun pause() {}
    override fun resume() {}
    override fun hide() {}

    override fun dispose() {
        shapeRendererInstance?.dispose()
        batchInstance?.dispose()
    }

    companion object {
        fun createChapter(
            floor: Int,
            title: String,
            tag: String,
            overview: String,
            tabletQuote: String
        ): CodexChapter {
            return CodexChapter(
                floorNumber = floor,
                title = title,
                tag = tag,
                pages = listOf(
                    CodexPage(
                        subtitle = "Kisah Perjalanan & Ekologi Lantai $floor",
                        paragraphs = listOf(
                            overview,
                            "Di lantai ini, gema masa lalu peradaban Aethelgard terasa semakin pekat. Udara menara beresonansi dengan detak Anima Core, menguji ketajaman insting dan kelincahan gerakan pahlawan pendaki."
                        )
                    ),
                    CodexPage(
                        subtitle = "Prasasti Kuno: Transkrip Resmi Tablet $floor",
                        paragraphs = listOf(
                            "📜 $tabletQuote",
                            "Ukiran prasasti obsidian ini tidak luntur oleh terpaan waktu maupun genangan tinta purba, menjadi saksi bisu bagi siapa pun yang berani menantang takdir para arsitek menara."
                        )
                    )
                )
            )
        }
    }
}
