class_name Config
# Общие настройки игры: размеры экрана и карт, цвета команд.

const W := 1152.0          # ширина экрана и арены дуэли
const H := 648.0           # высота экрана и арены дуэли
const MW := 2800.0         # ширина карты одиночного режима
const MH := 1100.0         # высота карты одиночного режима

const BTN := 62.0          # размер экранной кнопки
const PANEL := 142.0       # высота нижней панели с кнопками (в пикселях экрана)
static var SHOW_TOUCH_ON_PC := false   # true — показывать экранные кнопки и на компьютере

const OUTLINE_P1 := Color(0.2, 0.5, 1.0)   # синий — игрок 1
const OUTLINE_P2 := Color(1.0, 0.2, 0.2)   # красный — игрок 2
const NO_OUTLINE := Color(0, 0, 0, 0)

# Настоящий размер экрана в игровых пикселях. Высота всегда около 648,
# а ширина зависит от телефона: на широких экранах она больше 1152.
static func screen(n: Node) -> Vector2:
	return n.get_viewport().get_visible_rect().size

# Нужны ли экранные кнопки: на телефоне да, на компьютере без сенсорного экрана — нет
# Можно ли вообще играть касаниями (телефон или включено на компьютере)
static func can_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or SHOW_TOUCH_ON_PC

# Показывать ли экранные кнопки прямо сейчас: на телефоне — да, но пока играют
# геймпадом, они спрятаны (коснулся экрана — появились, нажал кнопку геймпада — спрятались)
static func touch() -> bool:
	return can_touch() and not (Pad.connected() and Pad.using_pad)

# Сколько места внизу экрана занимает панель кнопок (0, если кнопок нет или они поверх игры)
static func panel() -> float:
	return PANEL if can_touch() and bool(StorySettings.get_value("touch_panel")) else 0.0

# Экранные кнопки на полосе снизу (как раньше) или прямо поверх игры
static func touch_panel() -> bool:
	return bool(StorySettings.get_value("touch_panel"))
