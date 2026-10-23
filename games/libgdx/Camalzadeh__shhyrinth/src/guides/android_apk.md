# Shhyrinth — APK Necə Çıxarmaq Olar? (Android Build)

Hazırda proyekt yalnız **Desktop** və **HTML** modulları ilə konfiqurasiya olunub. APK (Android paket) çıxarmaq üçün aşağıdakı addımları yerinə yetirmək lazımdır.

## ⚠️ Vacib Qeyd
Bu proyekt libGDX ilə hazırlanıb, lakin Android modulu hələ əlavə edilməyib. APK çıxarmaq üçün əvvəlcə Android modulunu proyektə inteqrasiya etməlisiniz.

## 1. Android Modulunun Əlavə Edilməsi
LibGDX Setup tool istifadə edərək yeni bir android modulu yaratmaq və ya manual olaraq `android/` qovluğunu əlavə etmək olar.

### Lazım olanlar:
1. **Android SDK:** Kompüterinizdə Android SDK quraşdırılmış olmalıdır.
2. **build.gradle Yeniləməsi:** Ana `build.gradle` faylına Android üçün asılılıqlar (dependencies) əlavə edilməlidir.

## 2. APK Hazırlanması (Build)
Android modulu əlavə edildikdən sonra APK-nı aşağıdakı əmrlərlə çıxara bilərsiniz:

### Debug APK (Test üçün):
```bash
./gradlew android:assembleDebug
```
Bu əmr `android/build/outputs/apk/debug/` qovluğunda `android-debug.apk` faylını yaradacaq.

### Release APK (Mağaza üçün):
```bash
./gradlew android:assembleRelease
```
*Qeyd: Release APK üçün imzalama (signing) konfiqurasiyası tələb olunur.*

## 3. Emulyatorda və ya Telefondan Başlatmaq
Əgər telefonunuz kompüterə bağlıdırsa və ya emulyator açıqdırsa, birbaşa bu əmrlə işə sala bilərsiniz:
```bash
./gradlew android:installDebug android:run
```

---

## 🆘 Əgər Android Modulu Yoxdursa Nə Etməli?
Əgər özünüz bu modulu əlavə etməkdə çətinlik çəkirsinizsə, libGDX-in rəsmi sənədlərinə baxaraq (https://libgdx.com/wiki/app/gradle-setup) proyekti yenidən "setup" edərkən "Android" seçimini işarələməyiniz tövsiyə olunur.
