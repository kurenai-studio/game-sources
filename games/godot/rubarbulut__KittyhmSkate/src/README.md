# Kittyhm Skate

Godot 4 ile hazırlanmış, tek ritim tuşlu kaykay / ritim oyunu.
**Space parkur için. Shift şarkı için.** Turkuaz sokak kedisiyle üç parçalık gece turu.
Karakter ve çevre grafikleri şimdilik kodla çizilen yer tutuculardır; geliştirme
önceliği oynanış, zamanlama, ses ve FX'tir.

## Aç ve oyna

Godot Project Manager → **Import** → bu klasördeki `project.godot` → **Edit**.
Editörde **F6** yerine **F5** ile ana oyunu çalıştır.

İlk açılışta 30 saniyelik **Learn to Ride** alıştırması karşılar. Shift vuruşları,
Space zıplaması ve uzun notalar sırayla öğretilir. Alıştırma, en az 6 nota,
1 engel ve 1 uzun nota tamamlandığında öğrenilmiş sayılır; gerekirse tekrar edilir.
Tur ekranına duraklatıp Q ile geçilebilir, alıştırmaya T ile her zaman dönülebilir.

| Parça | Tempo | Süre | Notalar | Bariyerler | Rail'ler |
|---|---:|---:|---:|---:|---:|
| Learn to Ride | 96 BPM | 30 sn | 12 | 3 | 0 |
| Alley Shift | 128 BPM | 45 sn | 78 | 11 | 0 |
| Rooftop Radio | 136 BPM | 56,47 sn | 95 | 8 | 5 |
| Midnight Overdrive | 148 BPM | 64,86 sn | 141 | 13 | 4 |

Bir parçayı bitirmek sonrakini açar. Şarkının ortasında game over yoktur; amaç
combo'yu, doğruluğu ve skoru geliştirmektir. Son parça gece turunu tamamlar.

İlk sekiz vuruş hazırlanma süresidir. Pembe bariyerleri Space ile aş;
kedinin çevresindeki sabit hedefe elmas ulaştığında Shift'e bas.
Ritim işaretleri ve bariyerler aynı yönden, aynı hızla gelir. Hedefin daralan
halkası yaklaşan notayı, kaykay altındaki hafif nabız ise müziğin vuruşunu gösterir.
Kedi zıplasa da ritim hedefi sabit kalır. **Tab** ile eski alt şerit görünümüne
anında geçip iki yerleşimi aynı koşuda karşılaştırabilirsin.

**Uzun notalar:** cyan elmasın başında Shift'e bas ve kuyruğu hedefe varana kadar
basılı tut. Erken bırakmak o notayı kaçırır. **Rail'ler:** Space ile zıplayıp üstüne
in; kedi otomatik grind yapar. Rail üzerinde de Shift ile ritim devam eder.
Space'e kısa dokunmak güvenli bir küçük ollie, basılı tutmak daha yüksek bir yay verir.

| Tuş | İşlev |
|---|---|
| Enter | Başlat / sonraki parçaya geç / devam et |
| Sol / sağ ok, 1 / 2 / 3 | Tur ekranında parça seç |
| Space | Zıpla (ollie) |
| Sol veya sağ Shift | Notaları vur / uzun notaları basılı tut |
| Esc veya P | Duraklat / devam et |
| R | Bölümü yeniden başlat |
| S | Menüde veya duraklatma ekranında ayarlar |
| V | Efekt yoğunluğu: tam / azaltılmış |
| Tab | Ritim görünümü: parkur üzerinde / klasik alt şerit |
| M | Sesi aç / kapat |
| T | Ana menüde veya tur ekranında alıştırma |
| F1 | Ana menüde veya tur ekranında kaynaklar / credits |
| C | Ana menü ayarlarından ses zamanlama ölçümü |
| H | Ayarlarda vuruş seslerini aç / kapat |
| Yukarı / aşağı ok | Ayarlarda müzik sesini değiştir |
| Sol / sağ ok | Ayarlarda ritim giriş ofseti, 5 ms adımlar |
| Backspace | Ayarlarda ofseti sıfırla |
| Q | Duraklatma ekranından menüye dön |

Pencere odağı kaybolunca oyun ve müzik birlikte duraklar. Hata yapınca oyun bitmez;
combo sıfırlanır ve şarkı devam eder. Tam isabet penceresi ±65 ms, iyi isabet ±145 ms.
Skor, en iyi combo, ağırlıklı doğruluk ve engel sayısı sonuç ekranında görünür.
En iyi skor ve ayarlar Godot'un `user://settings.cfg` dosyasına kaydedilir.
Kayıtlar parça bazındadır. Bozuk / eksik ayarlar güvenli varsayılanlara döner.
İlk prototipten gelen skorlar korunur; o sürüm doğruluk / combo saklamadığı için
eski skora sahte bir yüzde eklemek yerine "earlier prototype score" etiketi gösterilir.

## Ses zamanlaması

Ana menü → S → C. Önce dört vuruş dinle, sonra klik sesiyle birlikte Shift'e bas.
Ölçüm en az 8 tutarlı vuruş ister. Önerilen ofset yalnızca Enter ile uygulanır;
Esc değişiklik yapmadan çıkar. Fazla dağınık vuruşlar tekrar ölçüm ister.
Manuel ofset -200 ile +200 ms arasındadır. Pozitif değer basışı şarkıda daha geç,
negatif değer daha erken değerlendirir. Kulaklık / hoparlör değişiminde yeniden ölç.

## Prototipin kapsamı

- Ses başlangıç gecikmesini hesaba katan ortak müzik saati; fizikte 120 Hz alt adımlar.
  Kare atlaması veya arka planda yavaşlayan tarayıcı engelleri atlayıp bedava puan vermez.
- Aynı beat çizelgesine bağlı engeller ve ritim notaları.
- Space basışını iniş öncesinde 110 ms tamponlama.
- Combo çarpanı, parçacıklar ve ritimle tetiklenen kaykay animasyonu.
- Ridiculous Coding hissinden esinlenen vuruş patlamaları: piksel kıymıkları,
  sıçrayan semboller, şok halkaları ve combo arttıkça yoğunlaşan kutlamalar.
- Her 10 combo'da üst bölgede havai fişek / slogan; sarsıntı yalnızca arka planda.
  Notanın hedefi, kedi ve engeller yerinden oynamaz. V ile ek efektler azaltılır.
- Şarkının drop kısmında mor / neon şehir dönüşümü.
- Öğrenme bölümü, üç parçalık tur, açılan parçalar, tekrar oynama ve tur bitişi.
- Uzun notalar, erken bırakma değerlendirmesi, otomatik rail grind'ı.
- Ses zamanlaması ölçümü, ayrı müzik seviyesi ve kısa vuruş / iniş / bitiş sesleri.
- Kodla çizilmiş özgün geçici kedi ve şehir grafikleri.
- Samplesız, prosedürel üretilmiş dört özgün müzik parçası ve yedi geri bildirim sesi.

Final karakter / çevre sprite'ları bu oynanış çalışmasının kapsamı dışındadır.

## Kaynaklar

- `scripts/game.gd`: oyun döngüsü, giriş, puanlama ve arayüz / şehir çizimi.
- `scripts/beat_clock.gd`: ses gecikmesi düzeltilmiş saat ve duraklatma.
- `scripts/level.gd`: tempo, nota çizelgesi, engeller ve bölüm geçişleri.
- `scripts/cat_art.gd`: kodla çizilmiş kedi ve kaykay.
- `scripts/juice.gd`: vuruş patlamaları, combo kutlamaları ve arka plan sarsıntısı.
- `scripts/calibration.gd`: tutarlı vuruşlardan medyan ofset ölçümü.
- `tools/build_music.py`: WAV'ı yeniden oluşturma; Python + numpy gerektirir.
- `tools/export_charts.gd`, `tools/build_tour_music.py`: diğer parçaları tek yetkili
  Godot nota çizelgesinden üretme. `tools/build_feedback.py`: kısa sesler / metronom.
- `tests/smoke.gd`: puanlama, zamanlama, tam bölüm ve tekrar başlatma kontrolleri.
- `tests/tour.gd`: tüm parçalar; 30 / 60 / 120 FPS, kısa Space dokunuşları, rail,
  uzun nota, iki Shift tuşu, öğretici koşulları ve kare atlama regresyonu.
- `tests/settings_calibration.gd`: kalibrasyon, ayar kaydı, bozuk kayıtlar ve sessiz mod.
- `tests/play_tour.gd`: gerçek ses saati, fizik ve tuş olaylarıyla canlı otomatik tur.
- `tests/render_tour.gd`: menü / oyun / sonuç ekranları için deterministik görsel QA.

Oynamak için Python veya numpy gerekmez. Müzik WAV dosyası projede hazırdır.

## Paket üretme

Godot **4.7.2**, eşleşen Windows / Web export template'leri ve paket kontrolü için
Python 3 gerekir. Hazır oyunu çalıştırmak için Python gerekmez.
`tools/fetch_templates.py` resmî paketi SHA512 ile doğrulayıp gerekli şablonları kurar.

PowerShell: `./tools/build_release.ps1 -Godot "C:/path/to/godot_console.exe"`.
Godot PATH'teyse veya `GODOT` ortam değişkeni tanımlıysa parametre gerekmez.
Betik önce üç test grubunu çalıştırır; script hatası veya başarısız kontrol varsa durur.
Ardından Windows ve single-threaded Web sürümlerini üretir, lisansları ekler ve zip'ler.

- `exports/packages/KittyhmSkate-Windows.zip`: exe, pck ve lisanslar.
- `exports/packages/KittyhmSkate-Web.zip`: itch.io HTML oyunu; index.html kökte.
- `.qa/test-*.log`: son otomatik kontrol çıktıları (Git'e eklenmez).
- `exports/packages/package-checksums.json`: paket boyutları ve SHA256 değerleri.

Web'i `file://` ile açma. Yerel test için:
`python -m http.server 8765 --bind 127.0.0.1 --directory exports/web`.
Ardından tarayıcıda http://127.0.0.1:8765/ aç. Klavye gereklidir.

## Game Off 2026

[Jam sayfası](https://itch.io/jam/game-off-2026), tema: **SHIFT**.
Yorumumuz: Shift ile ritim tutan kedi, müziğin drop'unda değişen şehir.
Kaynak kod için public GitHub deposu ve itch.io üzerinden oyun teslimi gereklidir.
Teslim: 1 Aralık 2026, 13:37 PST / 22:37 Europe/Warsaw.

Kaynak kod [rubarbulut/KittyhmSkate](https://github.com/rubarbulut/KittyhmSkate)
deposunda herkese açıktır. itch.io oyun sayfası ve jam teslimi henüz tamamlanmadı.
Yayın sayfası metni ve yükleme adımları `JAM_PAGE.md` içindedir.
Sürüm kapsamı ve doğrulama özeti `RELEASE_NOTES.md` içindedir.

## Lisanslar

Proje kodu, kodla çizilen grafikler ve sentezlenen demo müziği: MIT, bkz. `LICENSE`.
Silkscreen yazı tipi: SIL Open Font License 1.1, bkz. `assets/fonts/OFL.txt`.
Ek bilgi: `CREDITS.md`.
