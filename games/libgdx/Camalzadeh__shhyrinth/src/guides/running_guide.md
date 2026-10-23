# Shhyrinth — Oyunu Necə Başlatmalı? (How to Run)

Bütün platformalar üçün **Java 17 Development Kit (JDK 17)** lazımdır.

## 🖥 Desktop (Kompüter üzərindən)
Masaüstü versiyanı başlatmağın bir neçə yolu var.

### 1. Qısa Yollar (Ən Rahat Yol)
Proyekt qovluğunda sizin üçün iki yeni fayl yaratdım:
- **`PC-de-Baslat.bat`**: Desktop versiyasını birbaşa açır.
- **`Web-de-Baslat.bat`**: Veb (brauzer) versiyasını modul olaraq başlatır.

Sadəcə bu fayllara iki dəfə klikləyərək oyunu başlada bilərsiniz.

### 2. Gradle vasitəsilə
Proyektin olduğu ana qovluqda bu əmri daxil edin:
```bash
gradlew.bat desktop:run
```

### 2. JAR faylını işə salmaq
Əgər artıq *build* olunubsa:
1. `desktop/build/libs/` qovluğuna keçin.
2. `java -jar desktop-1.0.jar` əmrini işlədin.

---

## 🌐 Brauzer üzərindən (HTML/GWT)
Bu oyun həm də veb-sayt kimi brauzerdə işləyə bilər.

### 1. Yerli olaraq başlatmaq
```bash
./gradlew html:superDev
```
Bu əmr brauzerdə yerli server açacaq ki, oyunu veb-sayt kimi test edə biləsiniz.

### 2. Veb faylları hazırlamaq
```bash
./gradlew html:dist
```
Bu əmr `html/build/dist/` qovluğuna statik HTML, JS və CSS fayllarını toplayacaq. Bu faylları istənilən veb-hospitala yükləyə bilərsiniz.

---

## 🏗 Ümumi Build (Quraşdırma)
Bütün modulları *build* etmək üçün:
```bash
./gradlew build
```
Fayllar müvafiq modulların içindəki `build/libs/` qovluqlarında yaranacaq.
