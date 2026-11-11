# Buraco Político — Visual & UI/UX Screenshot Review

- **Reviewer Role:** Visual & UI/UX Review Sub-Agent (read-only code & pixel inspection; only `docs/VISUAL-REVIEW.md` written)
- **Model Used:** `gemini-4-argon-high` (Antigravity harness in T3 Code)
- **Direction Reference:** [`docs/ui-direction.md`](ui-direction.md) (*Direction A — "Diário Oficial & Charge"* with *Urna Eletrônica* tactile accents)
- **Screenshots Inspected (`540×960` Portrait, Godot 4.5.1-stable GL Compatibility capture `2026-11-10T00:44:32Z`):**
  - [`docs/media/menu.png`](media/menu.png)
  - [`docs/media/selection.png`](media/selection.png)
  - [`docs/media/gameplay.png`](media/gameplay.png)
  - [`docs/media/pause.png`](media/pause.png)
  - [`docs/media/results.png`](media/results.png)
- **Verification Scope & Honesty Boundary:** All findings below are derived from direct pixel/scanline inspection of the latest `540×960` Godot-rendered PNG captures (`00:44:32Z`) and read-only inspection of [`scripts/main.gd`](../scripts/main.gd), [`scripts/ui_kit.gd`](../scripts/ui_kit.gd), and [`scripts/gameplay.gd`](../scripts/gameplay.gd). **No physical Android/iOS mobile device testing was performed or is claimed.**

---

## 1. Verified Baseline & Previously Fixed Issues (Confirmed in Latest `00:44:32Z` Captures)

The revised capture batch (`00:44:32Z`, seed `1794271361`, final score `22.362`) confirms that the root fixes are active and working:
1. **Hero Art Aspect Ratio & Frame Clipping (`menu.png`, `y=352..574`):** Congress pixel art (`192×160`) scales proportionally inside the `484×223 px` `UI.Hero` frame with `clip_contents = true` and a clean `2px` `#18141E` ink border.
2. **HUD Combo Multiplier & Canonical 6 Game Ranks (`gameplay.png`, `y=128..148`):** Rank readout (`NÍVEL 2 / PROMESSA DE OBRA`) uses the canonical 6-tier progression from `game_rules.gd`, and the right-aligned combo readout displays both chain and actual score multiplier (`COMBO … • …x`).
3. **Touch-to-Mouse Emulation (`project.godot`):** `pointing/emulate_mouse_from_touch=true` is enabled.
4. **Content Width Reserves Scrollbar (`484px` column):** `column.custom_minimum_size.x = 484` keeps all cards, rules, and CTAs within the `540px` viewport without horizontal clipping.
5. **Audio Mute Propagation:** `gameplay.sound_enabled` is synchronized at `_ready()` and on every `_toggle_audio()` call.

No P0/P1 blockers remain; the game loop, HUD, menus, pause flow, and results screen are functional and ship-ready. The findings below are **P2/P3 visual polish items** to tighten spacing, contrast, hierarchy, touch ergonomics, and cross-screen consistency.

---

## 2. Screen-by-Screen Visual Findings (Spacing, Contrast, Hierarchy, Touch, Consistency)

| ID | Severity | Screen(s) | Category | Concrete Pixel / Layout Evidence | Bounded Actionable Polish |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VR-01** | **P2** | `gameplay.png` | **Contrast & Readability** | In [`scripts/main.gd`](../scripts/main.gd#L187-L193), `rank_label` (`y=128..148, x=17..179`, `#18141E`) and `combo_label` (`y=133..143, x=426..522`, `#C92D3C` red, `16px`) float as bare unoutlined labels directly over the moving 2D playfield. In `gameplay.png`, `combo_label` renders directly over `#98B885` grass (**2.43:1** WCAG contrast) and `#547D60` perimeter trim; when the camera pans over `#6B8176` asphalt or `#6E9B73` planters, red-on-world contrast drops to **1.28:1–1.68:1**. | Wrap the `info` row + `progress_bar` inside a compact `#F5EFE0` or `#E4D9C3` paper sub-strip panel (`padding 6px 10px`, `2px` `#18141E` border), **or** add a `2px` `#F5EFE0` / `#18141E` font outline (`font_outline_color` + `outline_size = 3`) to `rank_label`, `combo_label`, and `hint_label`. |
| **VR-02** | **P2** | `gameplay.png` | **Spacing & Consistency** | In [`scripts/main.gd`](../scripts/main.gd#L194-L199), `progress_bar` sets `custom_minimum_size.y = 8`, but reuses `UI.style()`, which hardcodes `content_margin_top = 14` and `content_margin_bottom = 14` in [`scripts/ui_kit.gd`](../scripts/ui_kit.gd#L35-L36). As a result, `progress_bar` inflates to **`28px` tall (`y=158..185`)** instead of `8px`, and its borderless green `"fill"` StyleBox (`x=16..270`) paints over the `1px` `#18141E` border of the `"background"` StyleBox—leaving the filled left half (`x=16..270`) with **0px border** against the grass/concrete while the unfilled right half (`x=270..523`) has a `1px` dark border. | Create a dedicated compact `StyleBoxFlat` for `progress_bar` with `content_margin_top = 0`, `content_margin_bottom = 0`, `custom_minimum_size.y = 10`, and set `set_border_width_all(2)` with `border_color = UI.INK` on **both** `"background"` and `"fill"` StyleBoxes so the bar stays `10px` slim and framed end-to-end. |
| **VR-03** | **P2** | `menu.png`, `selection.png` vs `pause.png`, `results.png` | **Spacing & Cross-Screen Consistency** | On `menu.png` (`y=40..935`) and `selection.png` (`y=40..934`), total vertical content plus `margin_top=34` and `margin_bottom=28` reaches **`962–963px`**—overflowing the `960px` viewport by just **2–3px**. This triggers an always-visible `8px` vertical scrollbar track along the right edge (`x=532..539, y=0..959`) on `menu.png` and `selection.png`, shifting their `484px` column left by `4px` (`x=24..507`) compared to `pause.png` and `results.png` (`x=28..511`, no scrollbar) and encroaching slightly into the `28px` bottom safe margin (`25–26px` actual bottom clearance). | Reduce `column` separation in `_page()` from `14` to `12` (or reduce `Hero.custom_minimum_size.y` from `223` to `214` on Menu and card height from `232` to `224` on Selection) so all 4 screens fit inside `960px` with zero vertical overflow, identical `x=28..511` centering, and full `>=28px` bottom safe margin. |
| **VR-04** | **P2** | `selection.png` | **Contrast & Hierarchy** | In [`scripts/main.gd`](../scripts/main.gd#L118), candidate card party numbers (`21px` bold) and `13px` bottom badges render over `#E4D9C3` (`UI.PALE`) on unselected cards and `#D5E6CE` on the selected card. Specifically: Card 1 (`99 / PBN` in `#B66C19` orange on `#E4D9C3`) has only **2.92:1** contrast (below WCAG AA 3.0:1 for large/bold text and 4.5:1 for normal text); Card 2 (`50 / CCS` in `#197C43` green on `#E4D9C3`) has **3.75:1** contrast; and Card 0's `13px` micro-label `✓ ELEITO` (`#197C43` on `#D5E6CE`) has **4.00:1** contrast (below 4.5:1 for `13px` text). | Darken Waldemar's party accent from `#B66C19` to `#8C4D0B` (**5.05:1** on `#E4D9C3`), use `#125B31` for green text on `#D5E6CE` / `#E4D9C3` (**5.7:1–6.5:1**), or render the `✓ ELEITO` badge as a high-contrast inverted pill (`#F5EFE0` text on `#197C43` or `#C92D3C` stamp fill). |
| **VR-05** | **P3** | `menu.png`, `results.png` | **Visual Consistency & Alignment** | In `selection.png`, candidate portraits sit inside bordered cards, but on `menu.png` (`y=677..736`) and `results.png` (`y=300..425`), `UI.portrait()` is placed directly on the `#F5EFE0` page background without a border box. Because `vania.png` (`96×96`) has `16px` of transparent left padding (`opaque_bbox=(16, 0, 76, 95)`), the candidate strip on `menu.png` visually starts at `x=34` (instead of `x=24`) and the hero block on `results.png` visually starts at `x=48` (a `20px` visual indent relative to the `x=28` left edge of the masthead and `PRESTAÇÃO DE CONTAS` panel). Additionally, `total := HBoxContainer.new()` on `results.png` omits a `separation` override (defaulting to `4px`). | Wrap `UI.portrait()` on `menu.png` (`58×58`) and `results.png` (`118×118`) in a compact `PanelContainer` with `#E4D9C3` fill and `2px` `#18141E` border (`content_margin = 4`), and add `total.add_theme_constant_override("separation", 16)` in `show_results()`. |
| **VR-06** | **P3** | `pause.png` | **Hierarchy & Button Differentiation** | On `pause.png`, the headline `SESSÃO SUSPENSA.` (`72px`, `#C92D3C` on `#E4D9C3`, **3.83:1** contrast) is followed by 4 full-width `484×60 px` buttons (`y=384..665`), where buttons 2, 3, and 4 (`RECOMEÇAR ELEIÇÃO`, `VOLTAR À CAPA`, `SOM: ON`) share the exact same `#F5EFE0` secondary button styling and width, leaving a `239px` empty vertical gap at the bottom (`y=721..959`). | Pair `VOLTAR À CAPA` and `SOM: ON` side-by-side in a 2-column `HBoxContainer` (`236×60 px` each, matching the paired secondary row pattern on `results.png` `y=749..808`), and optionally give `RECOMEÇAR ELEIÇÃO` a warm secondary fill (`#E4D9C3` or `#F26419` accent border) so primary resume, restart, and utility actions have distinct visual hierarchy. |
| **VR-07** | **P3** | `menu.png`, `gameplay.png` | **Touch Sizing & Ergonomics** | All interactive buttons meet or exceed the `52×52 px` minimum touch target from `docs/ui-direction.md`: primary CTAs are `484×60 px`, selection cards are `154×232 px` (`10px` gap), `results.png` secondary buttons are `232×60 px` (`12px` gap), and `menu.png` utility buttons `TROCAR` (`86×60 px`) and `SOM: ON` (`85×60 px`) exceed `60px` height. However, on `gameplay.png`, the top-right Pause button (`Ⅱ`, `x=466..523, y=34..117`) stretches to **`58×84 px`** because it sits inside the same `HBoxContainer` as the `84px`-tall `score_box` and `timer_box`, making the pause button taller than wide and visually heavier than a compact corner icon button. | Set `pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER` (or match its height to `60×60 px` / `80×80 px` square) or reduce `score_box` / `timer_box` vertical padding (`content_margin_top/bottom = 8` instead of `14`) so the top HUD row height tightens from `84px` to `~66px`, freeing `18px` more vertical playfield lookahead. |

---

## 3. Summary Touch & Safe-Area Audit (`540×960` Canvas)

| Screen | Element | Measured Pixel Rect (`x, y, w × h`) | Meets `>=52×52 px` Target? | Safe-Area Notes (`Top >=34px`, `Bottom >=28px`, `Horiz >=16px`) |
| :--- | :--- | :--- | :--- | :--- |
| **`menu.png`** | `TROCAR` Button | `x=420..505, y=677..736` (`86×60 px`) | Yes | Right margin `35px` (next to `8px` scrollbar at `x=532..539`). |
| **`menu.png`** | `ABRIR O BURACO →` CTA | `x=24..507, y=751..810` (`484×60 px`) | Yes | Fits comfortably above bottom fold (`y=810`). |
| **`menu.png`** | `SOM: ON` Button | `x=421..505, y=825..884` (`85×60 px`) | Yes | Footer caption below reaches `y=935` (`25px` from bottom edge; see **VR-03**). |
| **`selection.png`** | 3 Candidate Cards (`0..2`) | `x=24..177`, `188..342`, `353..507`, `y=285..516` (`154×232 px` each, `10px` gap) | Yes | Generous 3-column tap targets; `10px` horizontal separation prevents fat-finger mis-taps. |
| **`selection.png`** | `CONFIRMA → JOGAR` CTA | `x=24..507, y=753..812` (`484×60 px`) | Yes | Aligned within `2px` vertically of Menu's primary CTA (`y=751` vs `y=753`). |
| **`selection.png`** | `← VOLTAR À CAPA` Button | `x=24..507, y=827..886` (`484×60 px`) | Yes | `15px` clear vertical gap below `CONFIRMA → JOGAR`. |
| **`gameplay.png`** | Pause Button (`Ⅱ`) | `x=466..523, y=34..117` (`58×84 px`) | Yes | Top margin `34px`, right margin `17px`; isolated from bottom-half thumb drag zone. |
| **`gameplay.png`** | Playfield / Virtual Stick | Full unobstructed bottom `77%` (`y=186..960`); idle ring at `x=30..146, y=790..906` | Yes | All HUD labels/bars use `MOUSE_FILTER_IGNORE`; steering works across the entire playfield. |
| **`pause.png`** | 4 Action Buttons | `x=28..511, y=384..665` (`484×60 px` each, `14px` gap) | Yes | Centered with `28px` left/right margins and `240px` bottom clearance. |
| **`results.png`** | `NOVA ELEIÇÃO →` CTA | `x=28..511, y=675..734` (`484×60 px`) | Yes | Prominent primary replay button. |
| **`results.png`** | `TROCAR CANDIDATO` & `CAPA` | `x=30..261` & `x=278..509, y=749..808` (`232×60 px` each, `16px` border-to-border gap) | Yes | Clean 50/50 split row; bottom tip text ends at `y=866` (`94px` bottom margin). |

---

## 4. Recommended Priority Order for Final Polish (If Time Permits)

1. **`VR-01` + `VR-02` (Gameplay HUD Sub-Strip & Progress Bar):** Highest visual payoff during the 90-second core loop—fixes the `1.28:1–2.43:1` red combo text contrast over grass/asphalt and shrinks the `28px` half-unbordered progress bar to a crisp `10px` ink-bordered bar.
2. **`VR-03` (Eliminate 2–3px Vertical Scrollbar Trigger on Menu & Selection):** Tightening `column` separation from `14` to `12` removes the unnecessary right-edge scrollbar track on `540×960` and locks all four editorial screens to identical `x=28..511` horizontal alignment.
3. **`VR-04` + `VR-05` (Selection Card Accent Contrast & Framed Portraits on Menu/Results):** Quick palette/container tweaks that bring all candidate badges above WCAG AA contrast and align the left edge of the candidate blocks on Menu and Results.

## Codex refinement and verification

The lead implemented VR-01 through VR-07 after this review: an opaque newsprint HUD sub-strip protects rank/combo contrast; the progress bar uses dedicated zero-margin bordered styles at 10px height; page spacing is 12px; candidate gold/green labels use darker ink; menu/results portraits have compact frames; pause utility actions share a row; the HUD pause control stays 60×60 and vertically centered. Fresh screenshots and the GIF were captured from this revised implementation. The full Godot suite, including 37 rendered UI checks, passed after the changes. These are implementation and desktop-rendering checks, not physical-device certification.
