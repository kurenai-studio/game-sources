## Design System Moderno KINFIRE — v1.0

### Paleta de Cores Premium

**Primárias (Dark Fantasy)**
- Ouro Premium: `#d4af37` (destacado, ativo)
- Ouro Escuro: `#c4a860` (bordas, secundário)
- Ouro Dim: `#6b5d3f` (sutil, background)

**Secundárias (Gamut)**
- Vermelho Vivo: `#e74c3c` (vida, perigo, crítico)
- Vermelho Escuro: `#c0392b` (status crítico)
- Azul Vivo: `#3498db` (recurso, informação)
- Azul Escuro: `#2980b9` (secundário)
- Verde Vivo: `#2ecc71` (sucesso, buff, cura)
- Verde Escuro: `#27ae60` (completado)
- Roxo Vivo: `#9b59b6` (mágico, essência)
- Roxo Escuro: `#8e44ad` (lendário)

**Neutras (Premium Dark)**
- Fundo Principal: `#0d0804` (muito escuro)
- Fundo Painel: `#1a1410` (escuro)
- Fundo Hover: `#2a241a` (interativo)
- Texto Primário: `#e8e8e8` (branco quente)
- Texto Secundário: `#b0a080` (ouro suave)
- Texto Desabilitado: `#6b6050` (cinza ouro)
- Borda: `#3d352b` (sutil)
- Borda Ativa: `#d4af37` (ouro)

**Raridades**
- Comum: `#7f8c8d` (cinza neutro)
- Incomum: `#2ecc71` (verde)
- Raro: `#3498db` (azul)
- Épico: `#9b59b6` (roxo)
- Lendário: `#e74c3c` (vermelho ouro)
- Único: `#f39c12` (laranja ouro)

### Tipografia

- **Display**: Serif elegante, 32–48px, 600 bold (títulos/logos)
- **Heading**: Sans-serif, 20–28px, 600 bold (seções)
- **Body**: Sans-serif, 14–16px, 400 regular (conteúdo)
- **Caption**: Sans-serif, 10–12px, 400 regular (legends/tooltips)
- **Mono**: Monospace, 12–14px, 500 (valores/código)

### Espaçamento (8px grid)

- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- 2xl: 48px

### Componentes Base

#### Button
- Normal: border 1px `#3d352b`, bg `#1a1410`, text `#e8e8e8`
- Hover: border `#d4af37`, bg `#2a241a`, text `#d4af37` (lift 2px)
- Active: border `#d4af37`, bg `#0d0804`, text `#d4af37` (scale 0.98)
- Disabled: border `#6b6050`, bg `#0d0804`, text `#6b6050` (opacity 0.5)

#### Input
- border 1px `#3d352b`, bg `#1a1410`, text `#e8e8e8`
- Focus: border `#d4af37`, bg `#0d0804`, glow `#d4af37` 0.2 alpha
- Caret: `#d4af37`

#### Panel
- bg `rgba(13, 8, 4, 0.95)`, border 1px `#3d352b`
- Corners: 8px radius
- Shadow: `0 8px 16px rgba(0, 0, 0, 0.6)`
- Hover: border `#6b5d3f`

#### Badge/Chip
- bg `rgba(212, 175, 55, 0.1)`, border 1px `#6b5d3f`, text `#d4af37`
- Padding: 4px 12px
- Radius: 12px

#### Progress Bar
- bg `rgba(26, 20, 16, 0.8)`, border 1px `#3d352b`
- Fill HP: gradient `#e74c3c` → `#c0392b`
- Fill Resource: gradient `#3498db` → `#2980b9`
- Fill XP: gradient `#d4af37` → `#c4a860`
- Height: 8px, radius 2px
- Segments: 4 marcas a cada 25%

### Animações

- **Pop In**: scale 0.8 → 1.0, opacity 0.5 → 1.0, easing back_out, 0.3s
- **Pop Out**: scale 1.0 → 0.8, opacity 1.0 → 0.5, easing back_in, 0.2s
- **Lift Hover**: translate (0, -2px), duration 0.15s, easing out_quad
- **Pulse**: scale 1.0 ↔ 1.05, opacity 1.0 ↔ 0.8, duration 2.0s loop
- **Fade In**: opacity 0 → 1.0, duration 0.3s
- **Fade Out**: opacity 1.0 → 0, duration 0.2s
- **Slide Left**: translate (100%, 0) → (0, 0), duration 0.4s, easing out_quad
- **Slide Right**: translate (0, 0) → (100%, 0), duration 0.3s, easing in_quad

### Shadows

- **Subtle**: `0 2px 4px rgba(0, 0, 0, 0.3)`
- **Normal**: `0 8px 16px rgba(0, 0, 0, 0.5)`
- **Elevated**: `0 16px 32px rgba(0, 0, 0, 0.7)`
- **Glow**: `0 0 16px rgba(212, 175, 55, 0.3)`

### Micros

- **Sound**: click (soft pop), hover (subtle chime), error (buzz)
- **Haptic**: pulse na ação confirmada
- **Feedback**: toast de 3s para ações ("Equipado!", "Vendido!")

---

**Este design system é aplicado em todo painel, menu e HUD do jogo.**
