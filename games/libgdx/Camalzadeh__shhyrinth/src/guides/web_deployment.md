# Shhyrinth — Veb (Web) Versiyasını Necə Yerləşdirməli? (Deployment)

Oyunun veb versiyasını hazırladıqdan keyin (Build), onu hər kəsə açıq şəkildə internetdə yerləşdirmək olduqca asandır.

## 🛠 Web Build Haradadır?
Əgər `Build-All.bat` və ya `./gradlew html:dist` əmrini işlətmisinizsə, bütün fayllar bu qovluqda yaranacaq:
`html/build/dist/`

Bu qovluğun içində:
- `index.html` (Əsas səhifə)
- `assets/` (Şəkillər, səslər və s.)
- `WEB-INF/` və digər `.js` faylları olacaq.

---

## 🚀 Harada "Deploy" Etmək Olar? (Hosting Seçimləri)

### 1. GitHub Pages (Pulsuz və ən məşhur)
Əgər oyununuz GitHub-dadırsa:
1. `html/build/dist` qovluğunun içindəki hər şeyi proyektin `docs` qovluğuna və ya ayrıca bir `gh-pages` branch-ına kopyalayın.
2. GitHub-da proyektin **Settings -> Pages** bölməsinə gedin.
3. Mənbə olaraq bu qovluğu seçin. Oyun canlı olacaq!

### 2. Vercel və ya Netlify (Ən asan)
1. [Vercel](https://vercel.com) və ya [Netlify](https://netlify.com) saytına gedin.
2. `html/build/dist` qovluğunu sadəcə brauzerdə saytın üstünə "Drag & Drop" (Sürüklə-burax) edin.
3. Cəmi bir neçə saniyəyə sizə internet ünvanı (link) veriləcək.

### 3. Firebase Hosting
Əgər Google mühitindən istifadə etmək istəyirsinizsə:
```bash
firebase init hosting
firebase deploy
```
*(Qeyd: Public directory olaraq `html/build/dist` seçməlisiniz).*

---

## ⚠️ Yerli Brauzer Problemi (Localhost)
Veb build-i daxildə yandırmaq üçün birbaşa `index.html` klikləmək bəzən düzgün işləməyə bilər (təhlükəsizlik qaydalarına görə). Bunun üçün brauzerdə (localhost) açmaq məsləhətdir.

Veb versiyanı daxildə test etmək üçün:
```bash
./gradlew html:superDev
```
Və ya VS Code-da (Live Server əlavəsi ilə) `html/build/dist/index.html` faylını açın.
