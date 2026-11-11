# Buraco Político — UI/UX & Visual Direction Specification

**Target Engine:** Godot 4.x (Single-Player Mobile Arcade)
**Primary Viewport:** `540×960` Portrait (1:1 or 2x integer pixel scaling from `270×480` internal sub-grid where appropriate, with crisp `540×960` UI canvas)
**Core Loop:** 90-second arcade round in a stylized Brasília civic plaza (*Esplanada dos Buracos*). Move a political black hole to swallow props from campaign flyers (`Santinhos`) and pastel carts up to ministerial sedans and brutalist concrete domes.

---

## 1. Three Cohesive Design Directions Compared

| Screen / Aspect | Direction A: *"Diário Oficial & Charge"* (Editorial Satire Print & Pixel) | Direction B: *"Urna Eletrônica 1998"* (Retro Civic Terminal) | Directionas C: *"Plantão Brasília"* (Sensationalist TV Breaking News) |
| :--- | :--- | :--- | :--- |
| **Visual Metaphor** | Brazilian political cartoon supplements (*O Pasquim*, *Folha Ilustrada* charges), newsprint textures, rubber stamps (`DEFERIDO` / `CPI INSTAURADA`), Niemeyer brutalist curves in high-contrast ink & tropical editorial colors. | Beige plastic 90s Brazilian electronic voting machine (*Urna*) + monochrome LCD green screen + tactile physical numeric keypad buttons (`CONFIRMA`, `CORRIGE`, `BRANCO`). | Over-the-top cable news broadcast (*Plantão Urgente*), red/gold metallic lower-thirds, scrolling ticker tape, flashing sirens, helicopter cam HUD. |
| **Main Menu** | Front-page newspaper header (*"CORREIO DO BURACO - EDIÇÃO EXTRA"*); live plaza background where an idle hole swallows falling campaign flyers; bold ink-stamped `JOGAR (URNA ABERTA)` CTA. | Full-screen beige Urna bezel framing a small viewport; players press physical numeric keys and the green `CONFIRMA` button to start. | Breaking news studio overlay with dramatic headline banner and live "aerial helicopter feed" of the plaza behind glass graphics. |
| **Fictional Political Character Selection** | **"Cédula de Candidatura" Dossier Cards:** Halftone-framed pixel portraits with satirical party numbers, campaign slogans, and rubber-stamped perk badges. Feels like flipping through satirical voter guides. | LCD character readout on left, physical keypad on right where typing `99`, `13`, `22` etc. loads candidate stats with authentic *Urna* chime. | TV election debate split-screen podiums with live approval rating bars and ticker quotes. |
| **Gameplay HUD** | Top editorial masthead bar (Score as `VERBA DESVIADA R$`, 90s countdown as `FIM DO MANDATO`), bottom-left or floating thumb joystick, bottom-right size tier badge (`NÍVEL: VEREADOR` → `SUPREMO`) with next-prop silhouette preview. | Thick plastic frame around screen edges (reduces playable plaza visibility by ~22%), green LCD score readout at top. | Heavy lower-third broadcast banner at bottom (blocks thumb drag zone), LIVE bug at top-right, breaking news alerts popping mid-match. |
| **Pause Modal** | **"Pedido de Vista / Liminar":** Manilla folder & clip overlay with a red `SUSPENSO` stamp; clean `RETOMAR SESSÃO`, `REINICIAR`, and `ÁUDIO` toggles. | Darkened LCD screen showing `SESSÃO SUSPENSA - AGUARDANDO MESÁRIO` with physical button prompts. | `"INTERVALO COMERCIAL"` static TV bars overlay with broadcast control buttons. |
| **Results Screen** | **"Boletim de Urna / Capa do Dia Seguinte":** Dynamic newspaper front page headline based on final hole size, itemized receipt of swallowed props (*Prestação de Contas*), high score stamp, and instant `NOVA ELEIÇÃO` button. | Thermal-paper printed *Boletim de Urna* receipt scrolling vertically out of the top of the machine, ending in the iconic `FIM` screen and chime. | Election night projection board (*"APURAÇÃO 100%"*) with pie charts and pundit commentary box. |
| **Pros & Cons** | **Pros:** Maximum playable plaza visibility, rich Brazilian cultural personality, effortless readability on mobile, great contrast against sunlit Niemeyer concrete. **Cons:** Requires disciplined ink-border styling so paper panels stay crisp. | **Pros:** Iconic Brazilian nostalgia and sound design. **Cons:** Heavy plastic bezels waste precious `540×960` portrait screen real estate; monochrome LCD limits prop/tier color coding. | **Pros:** High energy and urgency. **Cons:** Lower-third banners collide with bottom-thumb virtual joystick ergonomics; visual clutter fatigues eyes over 90s rounds. |

---

## 2. Selected Direction: Direction A — *"Diário Oficial & Charge"* (with Urna Tactile Accents)

**Why Direction A wins:**
1. **Unobstructed Vertical Field of View:** In a 90-second hole-growing game on mobile (`540×960`), players need maximum vertical lookahead to spot fleeing sedans, food carts, and patrols across the plaza. Direction A keeps HUD elements compact, high-contrast, and tucked into top/corner editorial strips.
2. **Instant Satirical Readability:** Merging **Brazilian editorial cartoon ink-and-paper framing** (*charge política*) with **tactile Urna Eletrônica button colors** (`#1B9E4B` *Confirma Green*, `#F26419` *Corrige Orange*, `#F7F3E8` *Branco Paper*) gives the game an unmistakable Brazilian identity without sacrificing modern arcade clarity.
3. **Pixel Art Synergy:** Thick `2px` dark ink outlines (`#18141E`), warm newsprint cards (`#F5EFE0`), and sunlit Brasília travertine stone (`#E6DEC8`) make vibrant pixel-art props and candidate portraits pop immediately at small mobile sizes.

---

## 3. Fictional Satirical Candidates (Character Selection Roster)

Each candidate modifies the **Hole Rim Visual** (the ring around the black hole) and provides a satirical passive/visual flavor:

1. **Dep. Waldemar da Emenda (Partido do Buraco Nacional — `PBN 99`)**
   - **Archetype:** Old-school congressional budget pork-barrel veteran in an oversized charcoal suit with a overflowing briefcase.
   - **Slogan:** *"Se cabe no orçamento, cabe no buraco!"*
   - **Hole Rim Style:** Gold-trimmed mahogany parliamentary desk ring with flying `R$` banknotes.
   - **Trait / Flavor:** **Orçamento Secreto** (+10% score from civic infrastructure & benches).
2. **Doutora Vânia do Voucher (Movimento Reforma Já — `MRJ 40`)**
   - **Archetype:** Technocratic lobbyist with giant pearl glasses, laminated pie charts, and a laser pointer.
   - **Slogan:** *"Privatiza o asfalto, terceiriza a cratera!"*
   - **Hole Rim Style:** Caution yellow-and-black privatization tape (`OBRA CONCEDIDA`) spinning around the event horizon.
   - **Trait / Flavor:** **Taxa de Conveniência** (+8% movement speed while at Tier 1–2).
3. **Cabo Trovão da Motociata (Frente Patriota Sideral — `FPS 77`)**
   - **Archetype:** Sunglasses indoors, sash worn over a neon windbreaker, shouting into a megaphone.
   - **Slogan:** *"Quem não cair no buraco é comunista!"*
   - **Hole Rim Style:** Green-and-yellow striped tire-tread vortex with miniature hazard flashers.
   - **Trait / Flavor:** **Buzinaço Geral** (Vehicles & motorcycles award +15% growth points).
4. **Prof. Breno Bicicletinha (Coletivo Ciranda Solar — `CCS 50`)**
   - **Archetype:** Linen shirt, mate gourd (*cuia*), tote bag full ofurbanism manifestos, perpetually gesturing with both hands.
   - **Slogan:** *"Um buraco holístico, cicloviário e dialético!"*
   - **Hole Rim Style:** Painted red bike-lane stencil border with falling Ipê-amarelo petals.
   - **Trait / Flavor:** **Nota de Repúdio** (Starts with +5% initial hole radius; swallows campaign flyers from slightly further away).

---

## 4. Exact Color Palette

### UI & Editorial Surfaces
| Role | Name | Hex | Usage |
| :--- | :--- | :--- | :--- |
| **Primary Paper Surface** | *Jornal Creme* | `#F5EFE0` | Card backgrounds, dossier panels, newspaper results sheet |
| **Secondary Surface** | *Diário Envelhecido* | `#E4D9C3` | Recessed slots, unselected tabs, stat table alternating rows |
| **Deep Ink Outline / Void** | *Nanquim Supremo* | `#18141E` | `2px`–`3px` borders, drop shadows (`4px` hard offset), hole core interior |
| **Muted Ink Text** | *Grafite de Repartição* | `#4A4453` | Subtitles, secondary labels, prop descriptions |
| **Primary CTA (Urna Green)** | *Verde Confirma* | `#1B9E4B` | Primary action buttons (`JOGAR`, `CONFIRMAR CANDIDATO`, `NOVA ELEIÇÃO`), highlight border `#2BD968` |
| **Warning / Secondary CTA** | *Laranja Corrige* | `#F26419` | `CORRIGE / VOLTAR`, pause button, last-15-seconds timer alert |
| **Stamp / Danger Accent** | *Vermelho Cassação* | `#D92B3A` | Rubber stamps (`CASSADO`, `URGENTE`, `RECORDE`), locked prop silhouettes |
| **Civic Gold / Currency** | *Ouro Emenda* | `#F4B41A` | Score numbers (`R$`), star ratings, tier-up flash, high-score crown |
| **Brasília Sky Accent** | *Azul Planalto* | `#1D63B8` | Header masthead ribbon, tier progress bar fill |

### Brasília Plaza Environment Reference Palette (For HUD Contrast)
- **Sunlit Niemeyer Concrete / Plaza Tile:** `#EAE3D2` with `#CFC4AE` grout lines (ensures the `#18141E` hole core and dark-outlined HUD always have >10:1 contrast).
- **Reflecting Pool Water (*Espelho d'Água*):** `#2E8BC0` with `#73C2FB` pixel specular highlights.
- **Cerrado Grass & Buriti Palms:** `#4E8C3A` (mid) / `#2F5E22` (shadow).
- **Ipê Trees (Visual Landmarks):** `#F4B41A` (Yellow Ipê) and `#D6458B` (Pink Ipê).

---

## 5. Typography & Hierarchy

All fonts must render with **sharp pixel/bitmap alignment or crisp inked display geometry** and remain legible on small mobile screens.

| Tier | Recommended Free Font (OFL) | Fallback | Size (`540×960` canvas) | Tracking / Style | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display / Headlines** | **Press Start 2P** or **Silkscreen Bold** | **Rubik Mono One** | `24px` – `32px` | `0px`, All-Caps, `2px` `#18141E` outline + `3px` hard shadow | Game Logo, Newspaper Main Headline, `FIM DE MANDATO!`, Tier-Up Banner |
| **HUD Numerals & Timer** | **JetBrains Mono ExtraBold** (or **Silkscreen Bold**) | **Chakra Petch Bold** | `22px` – `28px` | Tabular numerals (`tnum`), crisp `2px` dark outline | 90s Timer (`01:30`), Score (`R$ 142.500`), Multiplier (`3x`), Urna Party Numbers (`99`) |
| **UI Body / Dossiers** | **Chakra Petch SemiBold** (or **Pixelify Sans**) | **Public Sans Bold** | `15px` – `18px` | Line-height `1.25x`, dark ink `#18141E` on `#F5EFE0` | Candidate slogans, perk descriptions, prop receipt list |
| **Stamps & Micro Labels** | **Silkscreen Regular** | **Chakra Petch ExtraBold** | `11px` – `13px` | All-Caps, rotated `-6°` for stamps | `VERBA DESVIADA`, `TAMANHO ATUAL`, `TOQUE PARA ARRASTAR` |

---

## 6. Touch Sizing & Mobile Ergonomics (`540×960` Base)

- **Minimum Touch Target:** **`52×52 px`** on the `540×960` canvas (exceeds 48dp mobile accessibility guideline).
- **Primary CTA Button Size:** **`280×64 px`** (centered bottom) or **`220×60 px`** (paired buttons), with a `4px` hard bottom shadow that depresses by `+3px` on touch press.
- **Safe Area Insets:**
  - **Top Safe Margin:** `36px` from top edge (protects against front-camera notches/status bars).
  - **Bottom Safe Margin:** `28px` from bottom edge (protects against OS home indicator swipe bars).
  - **Horizontal Safe Margin:** `16px` left/right padding.
- **Thumb Zone Allocation:**
  - **Bottom 60% of screen (`Y: 380` to `Y: 932`)** during gameplay is a **100% unobstructed virtual joystick / touch-drag surface**. Touching anywhere on the screen during gameplay immediately anchors the dynamic floating drag indicator—no interactive buttons are placed in the bottom half during active rounds.
  - **Pause Button (`52×52 px`)** is placed at **Top-Right (`X: 472, Y: 44`)** where it cannot be accidentally triggered by the player's steering thumb.

---

## 7. Portrait `540×960` Layout & Landscape Adaptive Specs

### 7.1 Portrait `540×960` Screen-by-Screen Coordinates

```
+--------------------------------------------------+ (0,0)
| [SAFE AREA 36px]                                 |
| +----------------------------------------------+ |
| | VERBA: R$ 48.200   [ 01:14 ]   [|| PAUSE 52] | | Y: 40..104 (Top Masthead HUD)
| +----------------------------------------------+ |
| | [TIER BAR: NÍVEL 3 - DEPUTADO ██████░░] [NEXT]| | Y: 108..140 (Sub-strip)
| +----------------------------------------------+ |
|                                                  |
|                                                  |
|             PLAYABLE BRASÍLIA PLAZA              |
|            (78% Unobstructed Screen)             |
|                                                  |
|                  (  O  ) <-- Player Hole         |
|                BURACO POLÍTICO                   |
|                                                  |
|                                                  |
|                  ( + ) <-- Floating Drag Ring    |
|                            (Only while touching) |
|                                                  |
| [SAFE AREA 28px]                                 |
+--------------------------------------------------+ (540,960)
```

1. **Main Menu (`540×960`):**
   - **Top Masthead (`Y: 48..230`):** Newspaper header banner (`508×172 px`) with *"EDIÇÃO EXTRA — BRASÍLIA"* kicker, stacked pixel-art title **BURACO POLÍTICO**, and animated hole graphic eating the letter "O".
   - **Center Showcase (`Y: 240..620`):** Live interactive plaza preview (`508×360 px` framed window or full-bleed background) showing the currently selected candidate's hole swallowing props in real time.
   - **Candidate Quick-Pill (`Y: 636..716`):** `460×80 px` card showing active candidate portrait (`64×64`), name, and `TROCAR CANDIDATO` button (`#F26419`).
   - **Primary Action Stack (`Y: 736..910`):**
     - `JOGAR (90s)` Button: `340×72 px` in Urna Green (`#1B9E4B`), centered at `X: 100..440, Y: 740..812`.
     - Secondary Row (`Y: 828..884`): Two `162×54 px` buttons side-by-side (`RECORDES` and `ÁUDIO / OPÇÕES`).

2. **Character Selection — *"Cédula de Candidatura"* (`540×960`):**
   - **Header (`Y: 44..110`):** `"ESCOLHA SEU CANDIDATO"` title banner with `VOLTAR` (`52×52 px`) at top-left.
   - **2×2 Candidate Grid (`Y: 124..544`):** Four selectable cards (`240×198 px` each, `16px` gap) showing `96×96 px` pixel portrait, 2-digit Urna number badge (`99`, `40`, `77`, `50`), and candidate short name. Selected card gets a `4px` `#1B9E4B` outline and angled red rubber stamp `ELEITO`.
   - **Dossier Inspector Panel (`Y: 560..816`):** `508×256 px` newsprint panel (`#F5EFE0`) displaying full satirical bio, campaign slogan in quotes, a `64×64 px` preview of their custom Hole Rim skin, and bold Perk badge.
   - **Confirm Bar (`Y: 832..904`):** Full-width Urna-style `CONFIRMA CANDIDATO` button (`420×68 px`, `#1B9E4B`) with authentic Urna double-beep audio cue.

3. **Gameplay HUD (`540×960`):**
   - **Top Editorial Bar (`X: 16..524, Y: 40..104`):**
     - **Left (`X: 16..200`):** Score box (`VERBA DESVIADA` micro-label + `R$ 000.000` counter in `#F4B41A` on `#18141E` pill).
     - **Center (`X: 210..330`):** Prominent countdown clock badge (`120×64 px`). Normal state: `#F5EFE0` bg with `#18141E` digits. Under 15 seconds: pulses `#D92B3A` red with camera shake tick.
     - **Right (`X: 472..524`):** `52×52 px` tactile Pause button (`||`).
   - **Tier & Next-Target Strip (`X: 16..460, Y: 108..142`):**
     - Horizontal progress bar (`340×28 px`) showing current political rank (`NÍVEL 1: PANFLETEIRO` → `NÍVEL 2: VEREADOR` → `NÍVEL 3: DEPUTADO` → `NÍVEL 4: MINISTRO` → `NÍVEL 5: BURACO SUPREMO`).
     - Next Swallable Prop Silhouette (`40×40 px` badge at right of bar): Shows the next prop size unlock (e.g., silhouette of a Pastel Cart → Sedan → Congress Dome) so players always have a visual short-term goal.
   - **Floating Touch Joystick (`Dynamic`):** Invisible when idle; on touch-down, spawns a low-opacity (`35%`) `96×96 px` dotted editorial ring at the touch origin with a `36×36 px` directional nub.

4. **Pause Modal — *"Liminar do STF"* (`540×960`):**
   - Dimmed backdrop (`#18141E` at `70%` opacity).
   - Centered `440×460 px` paper dossier card (`X: 50..490, Y: 250..710`) with a tilted red stamp `SESSÃO SUSPENSA`.
   - Displays current score, time remaining, and 3 stacked `360×60 px` buttons:
     1. `RETOMAR MANDATO` (`#1B9E4B` Green)
     2. `NOVA ELEIÇÃO (REINICIAR)` (`#F26419` Orange)
     3. `ABANDONAR PLENÁRIO (MENU)` (`#E4D9C3` Neutral)
   - Bottom toggle strip for `SOM FX` and `MÚSICA` (`172×52 px` each).

5. **Results Screen — *"Manchete do Dia Seguinte"* (`540×960`):**
   - Styled as a full front-page newspaper (`508×840 px`, `X: 16..524, Y: 44..884`).
   - **Dynamic Headline (`Y: 64..170`):** Changes by final tier achieved:
     - Tier 1–2: *"BURACO TÍMIDO SÓ ENGOLIU SANTINHO E COXINHA"*
     - Tier 3–4: *"CRATERA PARLAMENTAR LEVA CARROS OFICIAIS E KOMBIS"*
     - Tier 5: *"BURACO SUPREMO ENGOLIU BRASÍLIA INTEIRA EM 90 SEGUNDOS!"*
   - **Hero Summary (`Y: 180..360`):** Candidate portrait celebrating + Final Score (`VERBA TOTAL`) + Diameter in meters (`42,8m`) + `NOVO RECORDE!` red stamp if applicable.
   - **Itemized Receipt — *"Prestação de Contas"* (`Y: 372..680`):** Scrollable or top-5 visual list of swallowed items with icons and counts (e.g., `34x Santinho Eleitoral`, `12x Carrinho de Pastel`, `6x Sedan Ministerial`, `1x Cúpula do Congresso`).
   - **Bottom CTAs (`Y: 700..864`):**
     - `NOVA ELEIÇÃO (JOGAR DE NOVO)` (`440×68 px`, `#1B9E4B` Urna Green).
     - Secondary row: `TROCAR CANDIDATO` (`212×56 px`, `#F26419`) + `MENU` (`212×56 px`, `#E4D9C3`).

### 7.2 Landscape Adaptive Recommendations (`960×540` Support)

If the viewport switches to landscape (`960×540`) on tablets, foldables, or desktop builds, use Godot `Container` / anchor rules so the UI adapts cleanly without stretching:

- **Camera FoV Adjustment:** Lock the 3D/2D camera's **minimum visible world radius** (or `keep_height` with dynamic side padding) so landscape players do not gain an unfair sightline advantage over portrait players.
- **Gameplay HUD in Landscape:**
  - Move the **Score + Tier Bar** to a compact **Top-Left cluster (`280×84 px` at `X: 20, Y: 20`)**.
  - Keep the **90s Countdown Clock** centered at **Top-Center (`X: 420..540, Y: 16`)**.
  - Keep the **Pause Button** at **Top-Right (`X: 888, Y: 20`)**.
  - This leaves 100% of the vertical center channel clear so the player can still see props above and below the hole.
- **Menus & Results in Landscape (`960×540`):**
  - Reflow vertical stacks into a **2-Column Editorial Spread (`Left Column 440px` + `Right Column 440px`)**:
    - *Character Select:* Left column holds the 2×2 Candidate Grid; Right column holds the Dossier Inspector + `CONFIRMA` button.
    - *Results Screen:* Left column shows the Newspaper Headline, Candidate Portrait, and Final Score; Right column shows the *"Prestação de Contas"* prop receipt and replay buttons.

---

## 8. Transitions, Micro-Interactions & Satirical Juice

1. **Screen-to-Screen Transition — *"Engolido pelo Buraco"* (0.45s):**
   - Instead of a generic fade, starting a match expands a circular iris mask (`#18141E` with a jagged comic-ink rim) from the center of the `JOGAR` button until it swallows the entire screen, then irises open centered on the player's hole in the Brasília plaza.
2. **Rubber Stamp Slam (0.18s):**
   - Selecting a candidate, pausing, or hitting a new high score slams a rubber stamp down from `2.2x` scale to `1.0x` (`cubic_out`) with a `4px` screen nudge and a crisp ink-pad thud + dust puff particles.
3. **Tier-Up Celebration — *"Subiu de Cargo!"* (0.6s non-blocking):**
   - When the hole grows to the next political rank, the hole rim flashes `#F4B41A` gold, a comic ribbon slides across the top-center (`PROMOVIDO A DEPUTADO!`), and previously too-large props on screen pulse briefly with a green outline to signal they are now edible.
4. **Prop Swallow Feedback:**
   - Every swallowed prop spawns a rising pixel pop-up (`+R$ 100`, `+R$ 2.500`) in `#F4B41A` with `#18141E` outline that drifts up `24px` over `0.4s`.
   - High-value props (Official Sedans, Monuments) trigger a `0.08s` subtle camera shake and confetti of miniature banknotes.
5. **Final 10 Seconds — *"Fim do Mandato"*:**
   - Timer badge alternates `#D92B3A` and `#F5EFE0` every second; an editorial red vignette softly pulses at the outer `12px` screen border; at `00:00`, a giant `FIM` banner (styled after the classic Urna Eletrônica end screen) slams into center screen before unfurling the front-page Results newspaper.

---

## 9. PixelLab Asset Specifications

All pixel art assets should be authored with **consistent light source (top-left at 45°)**, **crisp `1px` dark ink outlines (`#18141E`)**, and **zero semi-transparent anti-aliasing on outer silhouettes**.

### 9.1 Fictional Candidate Portraits (Character Select & HUD)
- **Canvas Size:** `96×96 px` (Character Select / Results) + `48×48 px` cropped head badge (HUD).
- **View / Framing:** `3/4` bust portrait, exaggerated Brazilian editorial caricature proportions (expressive eyebrows, glasses/sashes, hand gesture in foreground).
- **States Needed per Candidate (2 frames):**
  1. `idle_confident`: Campaign smile / pointing gesture.
  2. ` manic_laugh`: Wide-eyed celebration used on Tier-Up and Results screen.
- **Asset List (4 candidates × 2 states = 8 sprites):**
  - `cand_waldemar_96.png` (Oversized suit, gold lapel pin, overflowing leather briefcase)
  - `cand_vania_96.png` (Teal blazer, oversized pearl glasses, privatization chart clipboard)
  - `cand_trovao_96.png` (Aviator sunglasses, presidential-style sash over windbreaker, megaphone)
  - `cand_breno_96.png` (Rolled-up linen shirt, mate gourd, red bicycle helmet under arm)

### 9.2 Player Hole & Candidate Rim Skins (Top-Down / High-Angle Oblique)
- **Canvas Size:** `128×128 px` base sprite (scales cleanly across Tiers 1–5 via shader/nine-slice ring or 3 discrete resolution LODs: `64×64`, `128×128`, `256×256`).
- **Structure:**
  - **Inner Core:** Deep `#18141E` void with a subtle 4-frame swirling pixel dithering spiral (`#2B2336`).
  - **Outer Rim Overlay (4 skins):**
    1. `hole_rim_default_asphalt.png`: Cracked Brasília asphalt & concrete chunks.
    2. `hole_rim_waldemar_gold.png`: Mahogany wood trim + orbiting `R$` bills.
    3. `hole_rim_vania_tape.png`: Diagonal yellow/black `PRIVATIZADO` barrier tape.
    4. `hole_rim_trovao_tire.png`: Green/yellow tire treads + flashing amber beacon pixels.
    5. `hole_rim_breno_ciclovia.png`: Red bike-lane dashed border + yellow Ipê petals.

### 9.3 Brasília Plaza Swallable Props (High-Angle `3/4` Top-Down Oblique)
Grouped by **Swallow Tier** so silhouettes and pixel dimensions scale logically as the hole grows:

| Tier | Prop ID | Pixel Size | Visual Description (PixelLab Prompt Direction) | Score Value |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1 (Tiny)** | `prop_santinho_pile` | `16×16 px` | Scattered colorful paper campaign flyers (`santinhos`) on pavement | `R$ 50` |
| **Tier 1 (Tiny)** | `prop_cone_transito` | `16×24 px` | Orange and white striped Brazilian traffic cone | `R$ 100` |
| **Tier 1 (Tiny)** | `prop_maleta_dinheiro` | `24×24 px` | Brown leather briefcase bursting with green/gold banknotes | `R$ 300` |
| **Tier 2 (Small)** | `prop_cidadao_terno` | `24×32 px` | 4-frame waddling lobbyist/aide in suit holding coffee & folder | `R$ 450` |
| **Tier 2 (Small)** | `prop_carrinho_pastel` | `32×32 px` | Stainless steel street cart with red-and-white awning (`PASTEL & CALDO DE CANA`) | `R$ 800` |
| **Tier 2 (Small)** | `prop_urna_stand` | `32×32 px` | White voting booth table with a beige Urna Eletrônica on top | `R$ 1.200` |
| **Tier 3 (Medium)** | `prop_kombi_som` | `48×64 px` | Classic white/blue Brazilian van covered in giant rooftop campaign loudspeakers | `R$ 2.500` |
| **Tier 3 (Medium)** | `prop_sedan_oficial` | `48×64 px` | Glossy black ministerial sedan with bronze license plate & miniature hood flag | `R$ 4.000` |
| **Tier 3 (Medium)** | `prop_ipe_amarelo` | `64×64 px` | Vibrant golden-yellow flowering Ipê tree with circular shadow | `R$ 3.500` |
| **Tier 4 (Large)** | `prop_trio_eletrico` | `80×96 px` | Neon-lit campaign sound truck with giant candidate banner on the side | `R$ 10.000` |
| **Tier 4 (Large)** | `prop_estatua_justica` | `64×96 px` | Stylized white brutalist blindfolded statue on concrete pedestal | `R$ 15.000` |
| **Tier 5 (Mega)** | `prop_anexo_ministerio` | `128×128 px` | Modernist green-glass rectangular ministry block on white Niemeyer columns | `R$ 35.000` |
| **Tier 5 (Mega)** | `prop_cupula_congresso` | `160×128 px` | Iconic white modernist bowl/dome structure inspired by the National Congress plaza | `R$ 100.000` |

### 9.4 UI Nine-Slice Frames, Stamps & Icons
- **9-Slice Editorial Paper Card (`ui_card_paper_9slice.png`):** `48×48 px` (`16px` corners), `#F5EFE0` fill, `2px` `#18141E` ink border, `4px` solid `#18141E` bottom-right drop shadow, subtle halftone dot texture in corners.
- **9-Slice Urna Action Button (`ui_btn_urna_green_9slice.png`, `ui_btn_urna_orange_9slice.png`, `ui_btn_urna_white_9slice.png`):** `48×48 px` (`12px` corners), beveled 90s plastic top highlight, `4px` dark base lip that compresses to `1px` in `_pressed` state.
- **Rubber Stamps (`ui_stamp_eleito.png`, `ui_stamp_cassado.png`, `ui_stamp_recorde.png`):** `128×48 px`, distressed red ink (`#D92B3A`) rectangular border with grunge pixel knockouts.
- **HUD Icons (`24×24 px` & `32×32 px`):**
  - `icon_clock_mandato.png`: Gold pocket watch / parliamentary gavel timer.
  - `icon_verba_cifrao.png`: Bag of money with bold `R$` emblem.
  - `icon_pause_gavel.png`: Pause bars (`||`) flanked by a judge's gavel.
  - `icon_trophy_urna.png`: Golden Urna Eletrônica trophy for high scores.

### 9.5 Plaza Ground Tileset (`tileset_esplanada.png`)
- **Tile Size:** `32×32 px` modular grid.
- **Tiles Required (16-tile compact atlas):**
  - **Portuguese Mosaic / Concrete Plaza (`4 tiles`):** Sunlit cream travertine slabs (`#EAE3D2`) with subtle geometric wave pattern.
  - **Espelho d'Água (Reflecting Pool) (`5 tiles`):** Deep civic blue water (`#2E8BC0`) + white concrete pool coping edges (N/S/E/W/Corners).
  - **Monumental Axis Asphalt (`4 tiles`):** Dark gray road (`#3A3842`) with yellow dashed lane markings and white pedestrian crosswalk stripes.
  - **Cerrado Lawn (`3 tiles`):** Warm tropical grass (`#4E8C3A`) with red-earth border transition.
