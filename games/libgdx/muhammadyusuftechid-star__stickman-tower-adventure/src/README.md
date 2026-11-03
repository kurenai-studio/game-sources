# ⚔️ Stickman Tower Adventure

<p align="center">
  <img src="assets/banner.png" alt="Stickman Tower Adventure Banner" width="100%" style="border-radius: 14px; max-width: 880px; box-shadow: 0 10px 30px rgba(0,0,0,0.6);" />
</p>

<p align="center">
  <a href="https://kotlinlang.org/"><img src="https://img.shields.io/badge/Kotlin-2.4.20-7F52FF.svg?logo=kotlin&logoColor=white" alt="Kotlin" /></a>
  <a href="https://libgdx.com/"><img src="https://img.shields.io/badge/libGDX-1.14.2-EA2027.svg?logo=libgdx&logoColor=white" alt="libGDX" /></a>
  <a href="#-arsitektur--prinsip-rekayasa-perangkat-lunak"><img src="https://img.shields.io/badge/Architecture-Clean%20%7C%20Zero--Allocation%20GC-brightgreen.svg" alt="Architecture" /></a>
  <a href="#-skema-kontrol-cross-platform"><img src="https://img.shields.io/badge/Platform-Android%20(API%2021--36)%20%7C%20Desktop%20(LWJGL3)-48bb78.svg" alt="Platform" /></a>
  <a href="#-automated-testing--qa-pipeline"><img src="https://img.shields.io/badge/Tests-211%20Passed%20(Headless)-success.svg?logo=checkmarx&logoColor=white" alt="Tests" /></a>
  <a href="StickmanTowerAdventure_50Floors_Master.apk"><img src="https://img.shields.io/badge/APK%20Release-4.7%20MB%20(R8%20Optimized)-blue.svg?logo=android&logoColor=white" alt="APK Size" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License" /></a>
</p>

> **Stickman Tower Adventure** adalah game **2D Action Roguelite RPG** performa tinggi yang dibangun dari nol menggunakan bahasa pemrograman **Kotlin 2.4** dan framework **libGDX 1.14** untuk platform **Android** dan **Desktop (PC)**.  
> Dirancang dengan standar rekayasa perangkat lunak kelas industri: modularitas tinggi, **zero-allocation procedural vector rendering** untuk garansi 60–120 FPS mulus di segala perangkat mobile, sistem fisika kinematika deterministik, eksplorasi **50 Lantai Tower (5 Mega Saga Mitologi Tinta)**, 5 pahlawan legenda, sistem Rune Alchemy & Blood Altar, Spirit Companion, serta **211 automated unit tests** yang terintegrasi pada pipeline QA.

---

## 📑 Daftar Isi
1. [Fitur Utama & Gameplay Matrix](#-fitur-utama--gameplay-matrix)
2. [Eksplorasi 50 Lantai & 5 Mega Saga Mitologis](#-eksplorasi-50-lantai--5-mega-saga-mitologis)
3. [Roster Karakter & Sistem Pertarungan](#-roster-karakter--sistem-pertarungan)
4. [Arsitektur & Prinsip Rekayasa Perangkat Lunak](#-arsitektur--prinsip-rekayasa-perangkat-lunak)
5. [Model Kinematika & Kalibrasi Fisika Platforming](#-model-kinematika--kalibrasi-fisika-platforming)
6. [Sistem RPG, Meta Progression & Rune Alchemy](#-sistem-rpg-meta-progression--rune-alchemy)
7. [Struktur Repositori & Domain Boundaries](#-struktur-repositori--domain-boundaries)
8. [Skema Kontrol & Navigasi Mobile](#-skema-kontrol--navigasi-mobile)
9. [Automated Testing & QA Pipeline](#-automated-testing--qa-pipeline)
10. [Panduan Menjalankan & Membangun APK Release](#-panduan-menjalankan--membangun-apk-release)
11. [Keputusan Desain Rekayasa (Architectural Trade-offs)](#-keputusan-desain-rekayasa-architectural-trade-offs)
12. [Lisensi & Kontributor](#-lisensi--kontributor)

---

## 🎮 Fitur Utama & Gameplay Matrix

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              STICKMAN TOWER ADVENTURE                                  │
├─────────────────────┬──────────────────────────┬───────────────────────────────────────┤
│    Action Combat    │    50-Floor Saga Ascend  │           Meta Progression            │
├─────────────────────┼──────────────────────────┼───────────────────────────────────────┤
│ • 3-Hit Combo FSM   │ • 50 Unique Handcrafted  │ • 15-Node Branching Talent Tree       │
│ • Perfect Parry     │   Floors & Lore Tablets  │ • Rune Alchemy & Blood Altar Synthesis│
│ • Dash Invulnerable │ • 5 Mega Sagas & Biomes  │ • Blacksmith Weapon & Armor Tempering │
│ • Ultimate Skills   │ • Co-op Ally Battles     │ • 12 Stackable Relics System          │
│ • Spirit Companion  │ • 6 Apex Bosses + Rush   │ • 50-Chapter Story Codex & Bestiary   │
│ • Zero Pop-In Cull  │ • Infinite Endless Spire │ • Daily Bounties & Achievements       │
└─────────────────────┴──────────────────────────┴───────────────────────────────────────┘
```

| Modul | Implementasi Teknis | Dampak Gameplay |
| :--- | :--- | :--- |
| **Dynamic Combat FSM** | Transisi state serangan 3 tahap (`COMBO_1`, `COMBO_2`, `FINISHER`) dengan *input buffering* dan *attack phase timer*. | Aksi pertarungan terasa responsif, fleksibel, dan memiliki ritme kombo yang terarah. |
| **Perfect Parry & Hitstop** | Deteksi *timing window* presisi (150 ms) dengan penghentian waktu sesaat (*hitstop*), getaran haptic, dan serangan balasan critical +25%. | Memberikan *reward* bagi pemain berkemampuan tinggi (*high skill ceiling*). |
| **Spirit Companion (Ink Familiar)** | Entitas pendamping cerdas yang melayang dan otomatis menembakkan proyektil magis saat pemain mengeksekusi kombo atau parry. | Menambah kedalaman strategi tempur dan burst damage melawan musuh bergelombang. |
| **Co-op Ally AI (Fase 25 & 26)** | Sekutu AI berkemampuan tinggi (Zephyr sang Pemanah Badai & Gorgon sang Titan Pilar) yang bertarung berdampingan di lantai klimaks. | Sensasi pertarungan kooperatif epik melawan bos multi-fase. |
| **Adaptive Zero Pop-In Culling** | Buffer horizontal kamera adaptif 72 meter (`[camX - 32m, camX + 40m]`) dengan perlindungan proyektil musuh aktif. | Eliminasi total objek/musuh yang berkedip atau telat muncul saat bergerak cepat. |
| **Hardware Back Navigation** | Integrasi interupsi tombol Back bawaan Android (`Input.Keys.BACK`) untuk pause menu dan konfirmasi keluar game aman. | Mencegah game force-close mendadak saat tombol fisik/navigasi HP tertekan. |

---

## 🏛️ Eksplorasi 50 Lantai & 5 Mega Saga Mitologis

Game terbagi ke dalam **5 Babak Saga Besar** dengan identitas visual, mekanik rintangan, dan narasi cerita yang khas:

```
[ Lantai 1 - 10 ]  SAGA I: PONDASI KELAM & KEBANGKITAN ZEPHYR
                   • Bioma: Obsidian Underforge & Runic Bastion
                   • Bos: Floor 5 Miniboss & Floor 10 Apex Boss "Obsidian Goliath"
                   • Fitur: Penyelamatan Zephyr sang Pemanah Badai

[ Lantai 11 - 20 ] SAGA II: LAUTAN LAHAR TITAN & BEBAN GORGON
                   • Bioma: Basalt Molten Core & Titan Foundry
                   • Bos: Floor 15 Miniboss & Floor 20 Apex Boss "Ignis the Scorched"
                   • Fitur: Penghancuran Rantai Lahar & Sekutu Co-op Gorgon

[ Lantai 21 - 30 ] SAGA III: LABIRIN KRISTAL PRISMATIK & NEXUS REFLEKSI
                   • Bioma: Prismatic Ice Caverns & Mirror Rift
                   • Bos: Floor 25 Miniboss & Floor 30 Apex Boss "Caelum the Void Warden"
                   • Fitur: Teka-teki Refleksi Cermin & Altar Kristal Astral

[ Lantai 31 - 40 ] SAGA IV: RETAKAN ASTRAL & KUIL KELAM MALAKOR
                   • Bioma: Void Nebulae & Cosmic Shrines
                   • Bos: Floor 35 Miniboss & Floor 40 Apex Boss "Umbra the Eclipse"
                   • Fitur: Platform Gravitasi Membalik & Zona Hampa Udara

[ Lantai 41 - 50 ] SAGA V: PUNCAK KANVAS KOSMIS & SANG KALIGRAFER AGUNG
                   • Bioma: Celestial Zenith & The Infinite Ink Canvas
                   • Bos: Floor 45 Miniboss & Floor 50 Apex Final Boss "Grand Calligrapher"
                   • Fitur: 50 Prasasti Lore Kuno & Epilog Pencerahan Dunia Tinta
```

---

## 🥋 Roster Karakter & Sistem Pertarungan

Pemain dapat memilih dan membuka pahlawan legenda dengan gaya bermain yang unik:

| Karakter | Gelar / Senjata | Gaya Bertarung | Kecepatan | HP / DEF | Skill Khusus |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Kaelen** | *Wandering Swordsman* (Pedang Baja) | Balanced Platformer | $7.5\text{ m/s}$ | Normal / Normal | **Slash Arc Burst**: Kombo 3-hit beruntun & tebasan membelah angin. |
| **Zephyr** | *The Windrunner* (Busur Astral) | Agile Sniper | $9.5\text{ m/s}$ | Sedang / Ringan | **Astral Arrow**: Tembakan panah penembus rintangan & dash melayang. |
| **Gorgon** | *The Titan Defender* (Pilar Basalt) | Heavy Juggernaut | $5.8\text{ m/s}$ | Sangat Tinggi / Tebal | **Titan Slam**: Hempasan tanah bergetar & perisai kebal interupsi. |
| **Aria** | *Celestial Maiden* (Resonansi Cahaya) | Spellblade Mystic | $8.2\text{ m/s}$ | Tinggi / Sedang | **Prismatic Pulse**: Gelombang cahaya penyembuh & ledakan area. |
| **Malakor** | *Grand Calligrapher* (Kuas Kosmis) | Master of Ink | $8.8\text{ m/s}$ | Tinggi / Tinggi | **Genesis Script**: Memanggil tinta hidup pemusnah massal. |

---

## 🏗️ Arsitektur & Prinsip Rekayasa Perangkat Lunak

Aplikasi dibangun dengan memisahkan logika simulasi game dari detail visual platform (*Clean Multiplatform Architecture*):

```
                          ┌─────────────────────────────┐
                          │         Input Layer         │
                          │   (Keyboard/Gamepad/Touch)  │
                          └──────────────┬──────────────┘
                                         ▼
                          ┌─────────────────────────────┐
                          │       CompositeInput        │
                          │   (Unified Control Contract)│
                          └──────────────┬──────────────┘
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Core Game Loop                                 │
│                                                                             │
│   ┌────────────────────┐    ┌────────────────────┐    ┌─────────────────┐   │
│   │   Physics & World  │    │  Combat & Entities │    │   RPG & Meta    │   │
│   │   (Box2D 16:9 Mtr) │◄──►│  (FSM, Stats, Hit) │◄──►│  (Talent, Relic)│   │
│   └────────────────────┘    └────────────────────┘    └─────────────────┘   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Rendering Layer                                │
│                                                                             │
│   ┌──────────────────────────────────┐  ┌───────────────────────────────┐   │
│   │ World Camera (Box2D Simulation)  │  │ UI Canvas (FitViewport 1280x720)│ │
│   │ Procedural Stickman & Particles  │  │ HUD, Overlays, Floating Text  │   │
│   └──────────────────────────────────┘  └───────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1. Zero-Allocation GC Hygiene (Garansi 60–120 FPS Mobile)
- **In-Place Vector Mutation:** Tidak ada alokasi `Vector2()` atau `Vector3()` baru di dalam method `update()` atau `render()`. Semua kalkulasi menggunakan cache objek statis/member dengan mutasi in-place (`tmpVec.set(...)`).
- **Object Recycling & Pooling:** Partikel percikan ([ParticleManager](file:///home/yusuf/projekan/game/game1/core/src/main/kotlin/com/stickman/tower/vfx/)), damage number melayang ([FloatingTextManager](file:///home/yusuf/projekan/game/game1/core/src/main/kotlin/com/stickman/tower/combat/FloatingText.kt)), dan proyektil panah dikelola dengan struktur array pooling yang digunakan kembali (*recycled*).
- **Procedural Vector Engine:** Visual digambar menggunakan primitif geometris OpenGL tanpa aset bitmap berat, memangkas konsumsi VRAM GPU hingga 90%.

### 2. Strict Viewport & Coordinate Decoupling
- **World Space (Simulasi Fisika):** Satuan meter logis dengan kamera aspek rasio 16:9 (`16.0f x 9.0f`). Menjamin akselerasi, massa, gravitasi, dan deteksi benturan bersifat deterministik di semua resolusi perangkat.
- **UI HUD Space (Presentasi Layar):** Menggunakan pixel-based `FitViewport(1280f, 720f)`. Menjaga rasio grafis tetap proporsional tanpa distorsi pada berbagai layar HP modern (rasio 19.5:9, 20:9, maupun tablet 4:3).

---

## 📐 Model Kinematika & Kalibrasi Fisika Platforming

Platforming yang presisi menuntut keseimbangan matematis yang ketat antara kecepatan impuls vertikal, koefisien gravitasi, dan penempatan rintangan:

### Persamaan Kinematika Puncak Lompatan
$$\Delta y_{max} = \frac{v_{0y}^2}{2 \cdot |g|}$$

Dengan gravitasi terkalibrasi $g = -25.0\text{ m/s}^2$:
- **Heavy (Gorgon Titan):** $v_{0y} = 10.8\text{ m/s} \implies \Delta y_{max} = \frac{116.64}{50} = \mathbf{2.33\text{ meter}}$
- **Balanced (Kaelen Swordsman):** $v_{0y} = 11.5\text{ m/s} \implies \Delta y_{max} = \frac{132.25}{50} = \mathbf{2.64\text{ meter}}$
- **Agile (Zephyr Windrunner):** $v_{0y} = 12.2\text{ m/s} \implies \Delta y_{max} = \frac{148.84}{50} = \mathbf{2.98\text{ meter}}$

### Aturan Emas Tata Letak Balok & Rintangan (Level Design Constraints)
1. **Maksimum Elevasi Balok Bertingkat ($\Delta y$):** Dibatasi antara **$1.4\text{ m} - 1.75\text{ m}$**, berada jauh di bawah ambang batas minimal lompatan karakter paling berat ($2.33\text{ m}$).
2. **Celah Horizontal Lompatan ($\Delta x$):** Dibatasi maksimum **$1.0\text{ m} - 1.5\text{ m}$**, memastikan karakter berkecepatan lambat ($5.8\text{ m/s}$) dapat mendarat dengan aman.
3. **Mekanisme Anti-Frustrasi (Coyote Time & Input Buffer):**
   - `COYOTE_TIME = 0.15s`: Karakter tetap dapat melompat hingga 150 ms setelah kakinya melewati tepi platform.
   - `JUMP_BUFFER_TIME = 0.15s`: Input lompatan yang ditekan sesaat sebelum menyentuh lantai akan otomatis dieksekusi begitu karakter mendarat.
   - `EARLY_RELEASE_GRAVITY = 1.35x`: Pelepasan tombol lompat menghasilkan busur melengkung yang luwes, menghindari efek "jatuh seperti batu".

---

## 🔮 Sistem RPG, Meta Progression & Rune Alchemy

1. **Rune Alchemy System (Fase 22):**
   - Mengumpulkan *Rune of Might, Swiftness, Iron, Vitality, dan Leech*.
   - Melakukan sintesis dan penempaan rune untuk menghasilkan bonus pasif permanen.
2. **Blood Altar (Pengorbanan Darah):**
   - Mengorbankan persentase HP maksimum di altar kuno untuk memperoleh buff serangan dahsyat berisiko tinggi (*High Risk, High Reward*).
3. **Blacksmith Weapon & Armor Tempering:**
   - Meningkatkan level senjata dan zirah menggunakan Gold dan Void Shards hasil jarahan peti harta.
4. **15-Node Talent Tree:**
   - Pohon bakat dengan 3 cabang utama: *Warrior (Kekuatan Fisik)*, *Rogue (Kecepatan & Crit)*, dan *Sorcerer (Kekuatan Tinta & Cooldown)*.

---

## 📁 Struktur Repositori & Domain Boundaries

```bash
stickman-tower-adventure/
├── android/                 # Android Native Module (Activity, JNI, Manifest, ProGuard)
│   └── src/main/kotlin/com/stickman/tower/android/
│       └── AndroidLauncher.kt
├── core/                    # Pure Multiplatform Kotlin Engine Logic
│   ├── src/main/kotlin/com/stickman/tower/
│   │   ├── achievement/     # Achievement tracker & unlock notifications
│   │   ├── audio/           # Procedural sound synthesis & Haptic Feedback bridge
│   │   ├── bestiary/        # Monster catalog & combat statistics
│   │   ├── bounty/          # Daily contracts & bounty rewards
│   │   ├── character/       # Player entities, 5 Hero classes, FSM
│   │   ├── combat/          # Combo FSM, Hitbox/Hurtbox, Parry, Projectiles
│   │   ├── dialog/          # NPC Dialogue & procedural voice chirps
│   │   ├── endless/         # Endless Spire procedural mutator system
│   │   ├── enemy/           # Enemy AI behaviors & 6 Apex Bosses
│   │   ├── input/           # Unified CompositeInput, Gamepad & VirtualController
│   │   ├── lore/            # 50 Lore Tablets & 50-Chapter Story Codex
│   │   ├── physics/         # Box2D platforms, sensors, collision raycasts
│   │   ├── quest/           # Story quests & progression tracking
│   │   ├── relic/           # 12 Stackable Relics System
│   │   ├── rpg/             # Stats progression, formulas, JSON persistence
│   │   ├── rune/            # Rune Alchemy & Blood Altar systems
│   │   ├── screen/          # Game screens (Play, Menu, Blacksmith, Talent, Codex)
│   │   ├── talent/          # 15-Node Talent tree & Sub-Class managers
│   │   ├── ui/              # FontManager & resolution-independent HUD
│   │   ├── vfx/             # Particle pooling systems & procedural screen shakes
│   │   ├── tools/           # LevelSanityValidator, DevToolsOverlay & Profiler
│   │   └── world/           # 50-Floor Tower builder, hazards & checkpoints
│   └── src/test/kotlin/     # 211 Automated Unit Tests (Headless QA Architecture)
├── lwjgl3/                  # Desktop PC Launcher Module (LWJGL3 / OpenGL backend)
│   └── src/main/kotlin/com/stickman/tower/lwjgl3/
│       └── Lwjgl3Launcher.kt
├── assets/                  # Typography (NotoSans TTF), Icons, and Manifests
├── StickmanTowerAdventure_50Floors_Master.apk # Master Release APK (4.7 MB)
├── Alur_Pembuatan_Aplikasi.md  # Detailed Macro-to-Micro Engineering Roadmap
├── Alur_Pengembangan_Ekspansi_30_Lantai.md # 50 Floors Full Expansion Roadmap
└── LORE_AND_WORLDBUILDING.md    # Canonical Lore, Mythology & Worldbuilding
```

---

## 🕹️ Skema Kontrol & Navigasi Mobile

| Aksi Permainan | Keyboard (Desktop PC) | Gamepad (Xbox / Generic) | Layar Sentuh (Android) |
| :--- | :---: | :---: | :---: |
| **Navigasi / Lari** | `A` / `D` atau `Panah` | Left Analog Stick / D-Pad | Virtual Joystick (Kiri) |
| **Lompat / Air Jump** | `W` / `Space` | Tombol `A` (Cross) | Tombol `JUMP` |
| **Serangan Melee / Kombo** | `J` / `Z` | Tombol `X` (Square) | Tombol `ATK` |
| **Serangan Ranged / Panah** | `K` / `C` | Tombol `Y` (Triangle) | Tombol `RNG` |
| **Dodge Roll (Invulnerable)**| `L` / `Shift` | Right Trigger (`RT`) / `B` | Tombol `DASH` |
| **Perfect Parry / Deflect** | `F` | Left Bumper (`LB`) | Tombol `PARRY` |
| **Ultimate Skill Nuke** | `U` / `V` | Left Trigger (`LT`) | Tombol `ULT` |
| **Menu Jeda / Pause** | `Escape` / `P` | Tombol `Start` / `Menu` | Tombol `PAUSE` / **Tombol Back HP** |

---

## 🧪 Automated Testing & QA Pipeline

Logika inti game dilindungi oleh **211 automated unit tests** yang dapat dieksekusi secara **headless** tanpa memerlukan display server atau OpenGL context:

```bash
# Eksekusi seluruh unit test suite:
./gradlew test --console=plain
```

```
> Task :core:test
com.stickman.tower.audio.HapticManagerTest           > testHapticPatternTrigger() PASSED
com.stickman.tower.character.CharacterArchetypeTest  > testArchetypeAttributes() PASSED
com.stickman.tower.combat.ParryTest                  > testPerfectParryWindow() PASSED
com.stickman.tower.endless.EndlessAndTalentTest      > testSpireFloorMutators() PASSED
com.stickman.tower.enemy.EnemyTest                   > testEnemyFSMTransitions() PASSED
com.stickman.tower.expansion.ExpansionFloorsSanityTest> testAll50FloorsReachability() PASSED
com.stickman.tower.lore.LoreAndTabletsTest           > test50LoreTabletsIntegrity() PASSED
com.stickman.tower.rune.RuneAlchemyTest              > testRuneSynthesisAndBloodAltar() PASSED
com.stickman.tower.companion.CompanionTest           > testInkFamiliarBurstProc() PASSED
com.stickman.tower.tools.ToolsProgrammerTestSuite    > testLevelSanityAndPerformance() PASSED

BUILD SUCCESSFUL in 14s
211 actionable tests: 211 executed (100% Success Rate)
```

---

## 🚀 Panduan Menjalankan & Membangun APK Release

### Prasyarat Lingkungan
- **JDK:** Java Development Kit versi 17 atau lebih baru
- **Android SDK:** Platform API 36 (Android 15/16) dan Build Tools

### 1. Menjalankan di Desktop (Linux / macOS / Windows)
```bash
# Clone repositori
git clone https://github.com/muhammadyusuftechid-star/stickman-tower-adventure.git
cd stickman-tower-adventure

# Jalankan game di desktop via LWJGL3
./gradlew lwjgl3:run
```

### 2. Membangun APK Release Produksi (~4.7 MB)
```bash
# Build APK Master Release dengan R8 Tree-Shaking & ProGuard
./gradlew android:assembleRelease

# File output otomatis dibuat di:
# android/build/outputs/apk/release/android-release.apk
```

### 📦 Unduh File APK Siap Pasang
File APK produksi hasil build terbaru telah tersedia di root direktori proyek:  
👉 **[StickmanTowerAdventure_50Floors_Master.apk](StickmanTowerAdventure_50Floors_Master.apk)** *(Ukuran: 4.96 MB / ~4.7 MiB)*

---

## ⚖️ Keputusan Desain Rekayasa (Architectural Trade-offs)

1. **Rendering Prosedural Geometric vs Sprite Sheet Bitmap:**
   - *Keputusan:* Menggunakan rendering primitif dinamis via `ShapeRenderer` untuk stickman, bilah pedang, busur tebasan, dan partikel debu.
   - *Alasan:* Mengurangi jejak memori GPU secara drastis, memungkinkan visualisasi trail animasi yang luwes pada refresh rate 120 Hz, dan menjaga ukuran final APK tetap sangat kecil (< 5 MB).
2. **Adaptive Zero Pop-In Frustum Culling:**
   - *Keputusan:* Menetapkan batas culling horizontal selebar 72 meter (`[camX - 32m, camX + 40m]`).
   - *Alasan:* Mengeliminasi bug visual pop-in pada platform saat mundur/lompat dan memastikan musuh serta proyektil aktif ter-render mulus sebelum masuk layar kamera.
3. **Deterministic Kinematic Collision vs Rigidbody Dynamic Physics:**
   - *Keputusan:* Karakter utama menggunakan kalkulasi kinematika AABB berbasis Box2D sensor, bukan full dynamic rigid body.
   - *Alasan:* Menghindari perilaku fisika yang tidak diinginkan dalam game platformer aksi (seperti karakter tergelincir di dinding miring, ketidakstabilan pendaratan tepi balok, atau fenomena *physics tunneling* pada frame rate tinggi).
4. **Save Game Crash Safety:**
   - *Keputusan:* Data disimpan dalam format JSON terstruktur dengan validasi fallback otomatis jika file korup (`stickman_save.json.bak`).

---

## 📄 Lisensi & Kontributor

- **Lead Engineer / Author:** Muhammad Yusuf ([@muhammadyusuftechid-star](https://github.com/muhammadyusuftechid-star))
- **Lisensi:** Proyek ini didistribusikan di bawah lisensi resmi [MIT License](LICENSE). Bebas digunakan untuk bahan studi, referensi arsitektur game Kotlin, dan portofolio teknis.
