# ارتقای پروژه‌ی آنریل به بازیِ «واقعاً شبیه بازی» — با اَسِت‌های رایگان

این راهنما فرض می‌کند پروژه‌ی C++ در همین ریپو را باز کرده‌ای و در ادیتور Play می‌گیری (آرنای رویه‌ای با کپسول و کره). هدف: رساندنِ همان بازی به کیفیتی که در تریلرهای آنریل می‌بینی — در **۴ تا ۶ ساعت کار** و با **هزینه‌ی صفر**.

> قانون طلایی: در آنریل، «شبیه بازی بودن» ۸۰٪ از اَسِت (مدل، انیمیشن، متریال، صدا) و ۲۰٪ از کد می‌آید. کد فعلی اسکلت است؛ این سند همان ۸۰٪ را تأمین می‌کند.

---

## ۰) نقشه‌ی راه (چه چیزی، از کجا، به چه ترتیب)

| مرحله | کار | منبع رایگان | زمان |
|---|---|---|---|
| ۱ | محیط: زمین/دیوار/پروپ با متریال PBR | **Quixel Megascans** (رایگان برای UE) | ۱ ساعت |
| ۲ | کاراکتر + انیمیشن locomotion و attack | **Mixamo** (رایگان، بدون کارت اعتباری) | ۱.۵ ساعت |
| ۳ | سلاح/افکت/صدا | **Fab** (فیلتر Free) + **Kenney** / **freesound** | ۱ ساعت |
| ۴ | نور و اتمسفر سینمایی | Lumen + Post Process (در خود انجین) | ۱ ساعت |
| ۵ | Niágara: افکت ضربه/مرگ/کور | محتوای خود انجین + **Niagara Fluids** (رایگان) | ۱ ساعت |
| ۶ | صدا و موسیقی | **Mixkit / Pixabay Audio** + MetaSounds | ۰.۵ ساعت |

---

## ۱) Quixel Megascans + Fab — محیط

از سال ۲۰۲۴ Megascans از Bridge به **Fab** منتقل شده و همچنان برای استفاده در UE رایگان است.

1. در ادیتور: `Edit → Plugins` → **Fab** را فعال کن و اکاونت Epic را وصل کن.
2. داخل ادیتور پنجره‌ی **Fab** را باز کن → فیلتر **Free** (یا از سایت https://fab.com و قیمت «Free»).
3. این‌ها را بگیر (همه رایگان و سبک‌اند):
   - **Surface**: `Concrete Slabs`, `Sci-Fi Panel`, `Metal Plate`, `Gravel Floor`
   - **Decal**: `Warning Stripes`, `Scorch Mark`, `Paint Splatter`
   - **3D Asset**: هر `Sci-Fi Crate / Barrel / Pipe / Barrier`
4. در پنجره‌ی Fab → دکمه‌ی **Add to Project** → پروژه‌ی `ArenaRunner` را انتخاب کن (خودش در `Content/` می‌نشیند).
5. در `Content/Arena/` یک مپ بساز و:
   - زمین: یک `Plane` بزرگ → متریال `Concrete Slabs` با `Tiling = 0.05`
   - دور آرنا: `Static Mesh` های Fab را در حلقه بچین (به‌جای دیوارهای کد) و در `ArenaGameMode.h` مقدار `WallSegments` را ۰ نکن؛ به‌جایش `CreateArenaWalls()` را غیرفعال کن (`ArenaRadius` را نگه دار چون اسپاون‌ها به آن وابسته‌اند).
6. مپ را در `Config/DefaultEngine.ini` ثبت کن:
   ```ini
   EditorStartupMap=/Game/Arena/ArenaMap
   GameDefaultMap=/Game/Arena/ArenaMap
   ```

> نکته‌ی مهم: **فیزیک کف** را حتماً `BlockAll` بگذار و یک `PlayerStart` در مرکز مپ بگذار.

---

## ۲) Mixamo — کاراکتر و انیمیشن (بزرگ‌ترین جهش کیفیت)

1. برو به https://www.mixamo.com (اکانت Adobe رایگان).
2. تب **Characters** → یکی را انتخاب کن (مثلاً `X Bot` یا `Y Bot` برای شروع، یا اسکن واقعی) → **Download** با فرمت **FBX Binary**، `T-Pose`.
3. تب **Animations** → این‌ها را تک‌تک دانلود کن (همه `Without Skin`، ۳۰fps):
   - `Idle`, `Running`, `Sprint` (یا `Fast Run`), `Jump` (یا `Falling Idle`), `Landing`
   - `Sword Slash` ×۳ (برای کمبوی سه‌ضربه), `Dodge` (برای دش), `Death` (برای باس/مرگ بازیکن)
4. در ادیتور: همه‌ی FBXها را با هم در `Content/Characters/` بکش و `Import All`.
   - در پنجره‌ی import برای کاراکتر: `Skeletal Mesh = true`, `Import Animations = true`, `Create Physics Asset = true`
   - برای انیمیشن‌ها: `Skeleton` را روی اسکلتون همان کاراکتر بگذار.
5. `IK Rig` + `IK Retargeter` بساز (UE5): `Content → Right click → Animation → IK Rig` روی کاراکتر، بعد برای هر انیمیشن ری‌تارگت کن. (اگر همه از Mixamo باشند، اسکلتون یکسان است و معمولاً لازم نیست.)
6. یک **Animation Blueprint** (`ABP_Player`) بساز:
   - `Locomotion` state machine با بلند‌ها: `Speed > 0 → Run`, `!IsFalling → Jump`, `Speed == 0 → Idle`
   - `Attack` slot: مونتاژهای سه‌گانه را در `DefaultSlot` قرار بده و با `Play Montage` از کد صدا بزن.
7. کاراکتر C++ را به مش واقعی وصل کن — کد آماده در ادامه.

### کد آماده: جایگزینی مش‌های کد با مش اسکلتی

```cpp
// ArenaCharacter.h — اضافه کن
UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Visuals")
TObjectPtr<USkeletalMeshComponent> CharacterMesh;

UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Visuals")
TObjectPtr<UAnimMontage> AttackMontage;
```

```cpp
// ArenaCharacter.cpp — داخل سازنده
#include "Components/SkeletalMeshComponent.h"

// به‌جای BodyMesh/HeadMesh فعلی
CharacterMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("CharacterMesh"));
CharacterMesh->SetupAttachment(GetCapsuleComponent());
CharacterMesh->SetRelativeLocation(FVector(0.f, 0.f, -96.f));
CharacterMesh->SetRelativeRotation(FRotator(0.f, -90.f, 0.f));
// سپس در Blueprint فرزند کاراکتر: SkeletalMesh = SK_Player, AnimClass = ABP_Player

// و در BodyMesh/HeadMesh: SetVisibility(false) یا کلاً حذف کن
```

```cpp
// وقتی حمله انجام می‌شود (مثلاً در یک متد InputAttack)
if (AttackMontage)
{
    PlayAnimMontage(AttackMontage);
}
```

> اگر می‌خواهی فقط با Blueprint جلو بروی: از `AArenaCharacter` یک Blueprint بساز (`BP_Player`) و در آن `BodyMesh`/`HeadMesh` را hide کن، یک `SkeletalMeshComponent` اضافه کن و مونتاژ را با `Play Anim Montage` صدا بزن. GameMode را هم به `BP_Player` وصل کن.

---

## ۳) افکت‌ها، صدا و سلاح

- **Niagara** (داخل انجین): `Content Browser → Add → Niagara System → (template)`:
  - `Fountain` را کپی کن → رنگ فیروزه‌ای → برای «جمع‌شدن کور» (`Spawn System At Location` از `AArenaCollectible::OnSphereOverlap`)
  - `Explosion` را کپی کن → برای مرگ هانتر و `Wardens` باس
- صدا: https://pixabay.com/sound-effects/ (رایگان، بدون انتساب اجباری) — `impact`, `whoosh`, `ui pickup`, `boss roar`
  - در `Content/Audio/` بریز، `Sound Cue` بساز و با `UGameplayStatics::PlaySoundAtLocation` پخش کن
- محیط: `Cine Camera` + `Post Process Volume`:
  - `Exposure → Metering Mode: Manual` (مقدار ۱) تا نور تثبیت شود
  - `Bloom: 0.35`, `Vignette: 0.45`, `Chromatic Aberration: 0.2`, `Lens Flare: 0.1`
  - `Color Grading → Contrast: 1.15`, `Saturation: 1.1`, `Shadows` را به آبی ببر
- نور: `Directional Light` با `Intensity ~ 8`, `Atmosphere Sun Light: true` + `Skylight` + `Exponential Height Fog` (Fog Density 0.015)

---

## ۴) سیستم‌هایی که در نسخه‌ی وب ساختم و می‌توانی به C++ منتقل کنی

نسخه‌ی وب (`Web/src/game.js`) این‌ها را دارد؛ معادل C++ خواسته‌ای را بگو تا مستقیماً تولید کنم:

| سیستم | جایی در کد وب | معادل UE |
|---|---|---|
| کمبوی ۳ ضربه + بافر ورودی | `Player.tryAttack` | `PlayAnimMontage` + `AnimNotify` + `AsyncTask` |
| دش (Dash) با i-frame | `Player.tryDash` | `CharacterMovement::Launch` + `SetActorEnableCollision(false)` |
| کمبو ضربه (multiplier) | `addComboKill` | `AGameState` + HUD widget |
| انواع دشمن (HUNTER/CHARGER/SPITTER) | `Enemy` | سه `ACharacter/APawn` + `AIController` + Behavior Tree |
| باس با شوک‌ویو و احضار | `Enemy` نوع boss | `AArenaBoss` + `Niagara + RadialForce` |
| آپگرید بین ویوها | `UPGRADES` | `UDataAsset` + UMG |

---

## ۵) چک‌لیست بیلد نهایی

- [ ] `Lumen` روشن (`Project Settings → Rendering → Dynamic Global Illumination: Lumen`)
- [ ] `Virtual Shadow Maps` روشن
- [ ] `Nanite` برای مش‌های Fab (پیش‌فرض روشن است)
- [ ] `Motion Blur` 0.25 و `Anti-Aliasing: TSR`
- [ ] `Sound Class` و `Master` روی ۰.۸ (بازی‌های آنریلی معمولاً بلندتر از حد می‌شوند)
- [ ] پکیج تست روی سخت‌افزار هدف (`Platforms → Windows → Package Project`)

---

## ۶) اگر خواستی قدم بعدی را من بنویسم

بگو کدام را اول تولید کنم (همه در همین ریپو کامیت می‌شود):

1. `AArenaBoss` کامل در C++ (فازها، شوک‌ویو، احضار هانتر)
2. `UComboComponent` (کمبو + بافر ورودی + مونتاژ)
3. `UDataAsset` آپگریدها + ویجت UMG
4. `AIController` + Behavior Tree برای سه نوع دشمن
5. اسکریپت پایتون ادیتور برای چیدن خودکار پروپ‌ها در حلقه‌ی آرنا (به‌جای کار دستی)
