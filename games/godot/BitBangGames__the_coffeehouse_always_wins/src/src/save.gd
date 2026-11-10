class_name Save
extends Resource

@export var __round: int = 1
@export var __cups: int = 0
@export var __max_cups: int = 0
@export var __min: int = 0
@export var __points: int = 0

@export var __inventory: PackedByteArray = []
@export var __bean_deck: PackedByteArray = Consts.BEAN_BASE_DECK.duplicate()
@export var __bean_idx: int = 0
@export var __ingr_deck: PackedByteArray = Consts.INGR_BASE_DECK.duplicate()
@export var __ingr_idx: int = 0

func _init() -> void:
	if (__inventory.resize(Consts.INVENTORY_SIZE)):
		Main.get_singleton().exit()

func get_round() -> int:
	return __round

func set_round(val: int) -> void:
	__round = val
	Main.get_singleton().update_time()

func init_round(round_num: int = 1) -> void:
	set_round(round_num)
	if (__round == 1):
		set_max_cups( Consts.MAX_CUPS_BASE)
		__inventory.fill(Consts.Item.NONE)
		Main.get_singleton().update_inventory()

		Main.get_singleton().init_managers_note()
		
	set_min(1 << (__round + 1))
	set_points(0)
	set_cups(__max_cups)

	__bean_deck = shuffle_pba(__bean_deck)
	__bean_idx = 0
	__ingr_deck = shuffle_pba(__ingr_deck)
	__ingr_idx = 0

	Main.get_singleton().play_sound("sfx_ding")

func get_cups() -> int:
	return __cups

func set_cups(val: int) -> void:
	__cups = val
	Main.get_singleton().update_cups()

func get_max_cups() -> int:
	return __max_cups

func set_max_cups(val: int) -> void:
	__max_cups = val

func get_min() -> int:
	return __min

func set_min(val: int) -> void:
	__min = val
	Main.get_singleton().update_cups()

func get_points() -> int:
	return __points

func set_points(val: int) -> void:
	__points = val
	Main.get_singleton().update_points()

func item_effect(item: Consts.Item) -> void:
	match item:
		Consts.Item.LIGHT_ROAST:
			set_points(__points + 0b100000)
		Consts.Item.MEDIUM_ROAST:
			set_points(__points + 0b10000)
		Consts.Item.DARK_ROAST:
			set_points(__points + 0b1000)
		Consts.Item.UNROASTED:
			set_points(__points + __min)

		Consts.Item.MILK:
			set_points(__points - 0b10)
		Consts.Item.CREAM:
			set_points(__points - 0b1000)
		Consts.Item.HALF_AND_HALF:
			set_points(__points - 0b100)
		Consts.Item.SUGAR:
			set_points(__points - 0b1100)
		Consts.Item.SWEETENER:
			set_points(__points - 0b110)
		Consts.Item.HONEY:
			set_points(__points - 0b10000)
		Consts.Item.ALMOND_MILK:
			set_points(__points + 0b10)
		Consts.Item.SOY_MILK:
			set_points(__points + 0b1000 if (randi() & 1) else __points - 0b1000)
		Consts.Item.TEA:
			set_points(__points - 0b11000)
		Consts.Item.CHOCOLATE_MILK:
			set_points(__points - (0b100*__round))
		Consts.Item.BANANA:
			__max_cups += 1
			set_cups(__cups + 1)

func get_inventory() -> PackedByteArray:
	return __inventory

func inv_is_empty() -> bool:
	for i: int in Consts.INVENTORY_SIZE:
		if (__inventory[i] != Consts.Item.NONE):
			return false

	return true

func shuffle_pba(pba: PackedByteArray) -> PackedByteArray:
	var arr: Array = Array(pba)
	arr.shuffle()
	return PackedByteArray(arr)

func stock_beans() -> void:
	var beans_left: int = Consts.BEANS_AMOUNT

	for i: int in __inventory.size():
		if (beans_left == 0):
			break

		if (__inventory[i] == Consts.Item.NONE):
			beans_left -= 1
			__inventory.set(i, __bean_deck[__bean_idx])
			__bean_idx += 1
			__bean_idx %= (__bean_deck.size())

	Main.get_singleton().update_inventory()
	Main.get_singleton().play_sound("sfx_select")

func stock_ingrs() -> void:
	var ingrs_left: int = Consts.INGRS_AMOUNT

	for i: int in __inventory.size():
		if (ingrs_left == 0):
			break

		if (__inventory[i] == Consts.Item.NONE):
			ingrs_left -= 1
			__inventory.set(i, __ingr_deck[__ingr_idx])
			__ingr_idx += 1
			__ingr_idx %= (__ingr_deck.size())

	Main.get_singleton().update_inventory()
	Main.get_singleton().play_sound("sfx_select")

func save_game() -> Error:
	return ResourceSaver.save(self, Consts.SAVE_PATH)
