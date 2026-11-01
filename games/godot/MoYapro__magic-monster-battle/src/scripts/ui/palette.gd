class_name Palette
extends RefCounted

# --- Screen chrome ---
const COLOR_BG             := Color(0.07, 0.08, 0.09)
const COLOR_HEADER_BG      := Color(0.08, 0.09, 0.11)
const COLOR_BORDER         := Color(0.22, 0.26, 0.30)
const COLOR_PANEL          := Color(0.10, 0.12, 0.14)
const COLOR_SECTION        := Color(0.45, 0.52, 0.60)

# --- Text ---
const COLOR_TEXT_BRIGHT    := Color(0.85, 0.90, 0.95)
const COLOR_TEXT_DIM       := Color(0.50, 0.57, 0.65)
const COLOR_TEXT_STAT      := Color(0.65, 0.72, 0.80)

# --- HP / health ---
const COLOR_HP_FULL        := Color(0.20, 0.75, 0.30)
const COLOR_HP_LOW         := Color(0.85, 0.20, 0.15)
const COLOR_HP_BG          := Color(0.10, 0.11, 0.13)
const COLOR_HP_LOSS        := Color(0.85, 0.15, 0.12, 0.88)
const COLOR_HP_LABEL       := Color(0.65, 0.80, 0.65)

# --- Targeting ---
const COLOR_TARGET_AVAILABLE := Color(1.0, 0.85, 0.2)
const COLOR_TARGET_HOVER     := Color(0.95, 0.18, 0.18)
const COLOR_TARGET_FLASH     := Color(1.0, 0.45, 0.1, 0.9)

# --- Widget panels (MageDisplay / ManaDisplay) ---
const COLOR_WIDGET_BG      := Color(0.15, 0.17, 0.19)
const COLOR_WIDGET_BORDER  := Color(0.38, 0.42, 0.48)
const COLOR_WIDGET_DEAD    := Color(0.35, 0.06, 0.06)

# --- Mana ---
const COLOR_MANA           := Color(0.35, 0.70, 1.00)
const COLOR_MANA_DROPLET   := Color(0.25, 0.50, 0.90)
const COLOR_MANA_EMPTY     := Color(0.13, 0.20, 0.32)
const COLOR_MANA_BORDER    := Color(0.40, 0.62, 1.00)
const COLOR_MANA_LABEL     := Color(0.40, 0.50, 0.65)

# --- Shield bar ---
const COLOR_SHIELD_FILL    := Color(0.40, 0.65, 1.00, 0.70)
const COLOR_SHIELD_EDGE    := Color(0.55, 0.80, 1.00)

# --- Wand display ---
const COLOR_WAND_BG          := Color(0.12, 0.13, 0.15)
const COLOR_WAND_BG_BORDER   := Color(0.35, 0.40, 0.46)
const COLOR_WAND_SLOT_BODY   := Color(0.20, 0.23, 0.26)
const COLOR_WAND_SLOT_TIP    := Color(0.26, 0.18, 0.08)
const COLOR_WAND_BORDER_BODY := Color(0.42, 0.48, 0.55)
const COLOR_WAND_BORDER_TIP  := Color(0.85, 0.65, 0.20)
const COLOR_WAND_EDGE        := Color(0.45, 0.50, 0.58)
const COLOR_PIP_FILLED       := Color(0.35, 0.70, 1.00)
const COLOR_PIP_EMPTY        := Color(0.18, 0.22, 0.27)
const COLOR_ACTIVE_BORDER    := Color(0.35, 0.70, 1.00)

# --- Bomb icon drawing ---
const COLOR_BOMB_BODY        := Color(0.14, 0.14, 0.17)
const COLOR_BOMB_RIM         := Color(0.78, 0.78, 0.82)
const COLOR_BOMB_SHINE       := Color(1.0, 1.0, 1.0, 0.28)
const COLOR_BOMB_FUSE        := Color(0.68, 0.56, 0.30)
const COLOR_BOMB_SPARK       := Color(1.0, 0.82, 0.18)
const COLOR_BOMB_SPARK_HOT   := Color(1.0, 1.0, 0.80)
const COLOR_BOMB_SLOT_FILL   := Color(0.35, 0.22, 0.05, 0.50)
const COLOR_BOMB_SLOT_BORDER := Color(0.62, 0.44, 0.14, 0.88)

# --- Enemy grid ---
const COLOR_GRID_CELL        := Color(0.18, 0.20, 0.22)
const COLOR_GRID_BORDER      := Color(0.45, 0.50, 0.55)
const COLOR_GRID_HP          := Color(0.8, 0.95, 0.8)
const COLOR_GRID_INTENT      := Color(1.0, 0.85, 0.3)
const COLOR_GRID_SHIELD_TEXT := Color(1.0, 0.75, 0.35)
const COLOR_GRID_FROZEN      := Color(0.6, 0.85, 1.0)
const COLOR_GRID_BLOCK       := Color(0.5, 0.8, 1.0)

# --- Status effects ---
const COLOR_STATUS_POISON := Color(0.50, 0.20, 0.65)
const COLOR_STATUS_FIRE   := Color(0.95, 0.42, 0.05)
const COLOR_STATUS_WET    := Color(0.25, 0.55, 0.90)
const COLOR_STATUS_PUDDLE := Color(0.20, 0.45, 0.75, 0.35)

# --- Floating damage ---
const COLOR_DAMAGE_HIT      := Color(1.0, 0.95, 0.7)
const COLOR_DAMAGE_FIZZLE   := Color(0.6, 0.6, 0.6)
const COLOR_DAMAGE_BACKFIRE := Color(1.0, 0.3, 0.2)
const COLOR_TEXT_SHADOW     := Color(0.0, 0.0, 0.0, 0.85)

# --- Tooltips ---
const COLOR_TOOLTIP_BG      := Color(0.07, 0.09, 0.11, 0.97)
const COLOR_TOOLTIP_BORDER  := Color(0.25, 0.30, 0.35)
const COLOR_TOOLTIP_NAME    := Color(0.92, 0.92, 0.88)
const COLOR_TOOLTIP_BODY    := Color(0.65, 0.70, 0.75)
const COLOR_TOOLTIP_STATS   := Color(0.82, 0.82, 0.82)
const COLOR_TOOLTIP_SECTION := Color(0.55, 0.62, 0.70)

# --- Debug bar ---
const COLOR_DEBUG_BG    := Color(0.08, 0.09, 0.10)
const COLOR_DEBUG_SEP   := Color(0.25, 0.28, 0.32)
const COLOR_DEBUG_LABEL := Color(0.55, 0.62, 0.70)

# --- Level-up screen ---
const COLOR_GAIN           := Color(0.35, 0.85, 0.45)
const COLOR_OPTION_BG      := Color(0.13, 0.16, 0.18)
const COLOR_SELECTED_BG    := Color(0.12, 0.30, 0.18)
const COLOR_SELECTED_BORDER := Color(0.30, 0.80, 0.40)

# --- Loot screen ---
const COLOR_SLOT_EMPTY       := Color(0.12, 0.14, 0.16)
const COLOR_SLOT_BORDER      := Color(0.20, 0.24, 0.28)
const COLOR_DROP_HIGHLIGHT   := Color(1.00, 0.85, 0.20, 0.12)
const COLOR_DROP_BORDER      := Color(1.00, 0.85, 0.20, 0.80)
const COLOR_WAND_CARD        := Color(0.18, 0.28, 0.42)
const COLOR_WAND_CARD_BORDER := Color(0.38, 0.55, 0.78)

# --- Game over screen ---
const COLOR_GAME_OVER_BG    := Color(0.08, 0.04, 0.04)
const COLOR_GAME_OVER_TITLE := Color(0.90, 0.15, 0.10)
const COLOR_GAME_OVER_SUB   := Color(0.65, 0.55, 0.55)
