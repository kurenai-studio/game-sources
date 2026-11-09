# Ball Sort Warna

Game puzzle Ball Sort 2D — tuang bola sampai tiap tabung berisi satu warna.
Godot 4.4, portrait HP (720x1280), renderer GL Compatibility.

## Cara main

1. Tap satu tabung untuk memilihnya (tabung terangkat + panah kuning).
2. Tap tabung lain untuk menuang bola warna atas ke sana.
3. Aturan tuang:
   - Tabung tujuan tidak boleh penuh.
   - Kalau tabung tujuan tidak kosong, warna atasnya harus sama.
   - Yang dituang adalah seluruh rangkaian bola warna sama di atas
     (sebatas ruang kosong di tabung tujuan).
4. Menang kalau semua tabung yang terisi penuh dengan satu warna.

Tombol **↩ Urung** membatalkan satu langkah (angka di tombol = sisa langkah
yang bisa diurungkan), **＋ Tabung** menambah satu tabung kosong (maks 2 per
level), **Petunjuk** menampilkan langkah optimal berikutnya (dihitung solver
BFS di runtime), **⟳ Ulang** mengulang level. Tombol **Level** di kiri atas
membuka layar pilih level.

## Fase 1 — 30 level, hint, save progres

- **30 level** (L1–3 buatan tangan; L4–30 digenerate acak dengan seed tetap
  dan diverifikasi solvable oleh solver BFS dengan aturan tuang yang sama).
  Tingkat kesulitan naik: L4–10 = 3 warna, L11–20 = 4 warna, L21–30 =
  5 warna. Langkah minimal tiap level tercatat untuk penilaian bintang.
- **Layar pilih level** (grid 5×6): nomor level + bintang yang diraih,
  level terkunci sampai level sebelumnya selesai.
- **Save progres** (`user://ball_sort_save.cfg`): level yang terbuka,
  bintang per level, dan langkah terbaik per level tersimpan otomatis.
- **Hint**: solver BFS di runtime mencari solusi optimal dari posisi
  sekarang dan menyorot tabung sumber + menyebut tabung tujuan. Kalau
  pencarian melewati batas state, hint memakai langkah valid apa pun.
- **Deteksi deadlock**: kalau tidak ada langkah valid tersisa (dan belum
  menang), game menampilkan pesan buntu sampai pemain mengurungkan atau
  mengulang level.

## Fase 2 — Animasi tuang, suara, getar

- **Animasi tuang beneran**: bola tidak lagi teleport — bola-bola yang
  dituang terbang dari mulut tabung sumber ke mulut tabung tujuan mengikuti
  busur parabola, satu per satu dengan jeda kecil (`scripts/pour_fx.gd`).
  Selama animasi berjalan, input diblokir; state baru di-commit setelah
  animasi selesai, jadi undo tetap mengembalikan keadaan sebelum tuang.
- **Suara sintesis prosedural** (`scripts/sound.gd`): semua suara dibuat
  di kode ke AudioStreamWAV 16-bit (tanpa file audio sama sekali) — pilih
  tabung, klik tombol, tuang (sapuan nada turun), tabung selesai (dua nada),
  langkah gagal (bunyi kotak rendah), menang (arpeggio 4 nada).
- **Tombol mute** di layar pilih level ("Suara: Nyala/Mati"), tersimpan di
  file save yang sama.
- **Getar** (`Input.vibrate_handheld`): 60 ms saat tuang berhasil, 40 ms
  saat langkah gagal, 120 ms saat menang.

## Tampilan (UI/UX)

Riset dari screenshot game Ball Sort / Water Sort yang ramai dimainkan +
praktik HUD game puzzle mobile:

- **Background gradient indigo gelap** (atas terang, bawah gelap) + **rak putih**
  di bawah tabung — tabung terlihat berdiri di atas rak, seperti game aslinya.
- **HUD minimal, papan adalah UI-nya:** atas cuma ada pill **LEVEL** (kiri),
  pill **Langkah** (kanan), dan **3 titik progres level** di tengah
  (emas = level berjalan, hijau = selesai, redup = belum). Tengah layar suci:
  tidak ada yang menutupi tabung.
- **Tabung kaca bersudut membulat**, bola glossy dengan highlight; tabung yang
  dipilih **naik + border emas + panah kuning**; tabung yang selesai
  **berkilau emas + bintang**.
- **Feedback tiap aksi:** tuang berhasil = tabung tujuan "pop" membesar sebentar;
  tuang gagal = tabung digoyang + pesan kenapa ("Tabung tujuan sudah penuh!" /
  "Warna atas tidak cocok!").
- **Panel menang:** bingkai emas, **bintang 1–3** dibanding langkah minimal
  (3 bintang kalau ≤ minimal, 2 kalau ≤ minimal+5), info langkah, tombol emas
  "Level Berikutnya".

## Level

| Level | Warna | Tabung | Langkah minimal |
| --- | --- | --- | --- |
| 1 | 3 (merah, hijau, biru) | 5 (2 kosong) | 10 |
| 2 | 4 (+ kuning) | 6 (2 kosong) | 13 |
| 3 | 5 (+ ungu) | 7 (2 kosong) | 16 |

Semua level sudah dibuktikan bisa diselesaikan dengan solver BFS
(menggunakan aturan tuang yang sama dengan game ini).

## Cara buka

1. Clone repo ini, atau download ZIP-nya.
2. Buka Godot — Import — pilih `project.godot` di folder ini.
3. Tekan Run (F5). Di HP: tap tabung langsung di layar sentuh.

## Struktur

| File | Isi |
| --- | --- |
| `project.godot` | Konfigurasi: main scene, viewport portrait 720x1280, GL Compatibility |
| `scenes/main.tscn` | Scene utama: judul, HUD, wadah tabung, tombol, panel menang |
| `scripts/main.gd` | Logika game: level, pilih/tuang, undo, menang/kalah, UI |
| `scripts/tube.gd` | Satu tabung: gambar tabung + bola, tap, status penuh/seragam |
| `icon.svg` | Ikon project |

## Lisensi

MIT — lihat `LICENSE`.
