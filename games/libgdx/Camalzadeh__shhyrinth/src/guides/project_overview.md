# Shhyrinth — Layihə Haqqında (Project Overview)

**Shhyrinth** libGDX çərçivəsində (framework) Java 17+ istifadə edilməklə hazırlanmış 2D fantastik labirint oyunudur. Layihə Object-Oriented Programming (Obyekt-Yönümlü Proqramlaşdırma) kursunun yekun tapşırığı kimi UFAZ tələbələri tərəfindən hazırlanıb.

## 🏰 Oyunun Mahiyyəti
Oyunçunun əsas vəzifəsi 5 fərqli labirint səviyyəsini (level) keçməkdir. Bu yolda:
- **Düşmənlərlə mübarizə:** Atəş və buz cadularından istifadə edərək düşmənləri məhv etmək olar.
- **Açarların toplanması:** Hər səviyyəni bitirmək və portala daxil olmaq üçün ən azı 5 açar toplamaq lazımdır.
- **Sandıqların açılması:** Sandıqlardan açar, müxtəlif iksirlər (potion) və ya heç nə çıxmaya bilər.
- **İksirlərdən istifadə:** Canı (Healing), mananı (Mana) bərpa etmək və ya zirehi (Armor) gücləndirmək üçün iksirlər movcuddur.

## 🛠 Texnoloji Struktur
- **Engine (Mühərrik):** [LibGDX](https://libgdx.com)
- **Dil:** Java 17+
- **Build Tool:** Gradle
- **Platformalar:** Desktop (Windows, macOS, Linux) və Web (HTML5/GWT).

## 📂 Qovluq Quruluşu
- `core/`: Oyunun əsas kodu (bütün platformalar üçün ortaq hissə).
- `desktop/`: Masaüstü kompüterlər üçün başlatma moduludur (launcher).
- `html/`: Brauzer üzərindən oynamaq üçün GWT modulu.
- `assets/`: Şəkillər, səslər və fontlar kimi resurslar.
- `docs/`: Hazırda oxuduğunuz sənədlər toplusu.
