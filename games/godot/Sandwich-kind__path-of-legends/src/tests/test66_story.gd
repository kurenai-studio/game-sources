extends SceneTree
# История: новая игра → сундук → экипировка → свитки → бой → сохранение.
var main
var f := 0
var held := {}
var sm: StoryMode
var shots := ""          # если задано — сохраняет снимки экрана в эту папку

func _initialize() -> void:
	shots = OS.get_environment("SHOTS")
	if shots != "":
		Config.SHOW_TOUCH_ON_PC = true
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n

func snap(name: String) -> void:
	if shots == "":
		return
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(shots + "/" + name + ".png")

func _process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		3:
			main._on_mode_chosen("story")
		10:
			snap("st_slots")
			main.show_story_creator(3)
		14:
			var cr: StoryCreator
			for n in main.world.get_children():
				if n is StoryCreator: cr = n
			cr._step("hair", 1)
			cr._step("beard", 1)
			cr._step("beard", 1)
			cr._step("mark", 1)
		20:
			snap("st_creator")
			for n in main.world.get_children():
				if n is StoryCreator: n._start()
		24:
			for n in main.world.get_children():
				if n is StoryMode: sm = n
			print("started: ", sm != null, " hp=", sm.hero.hp, "/", sm.hero.max_hp, " mana=", sm.kit.mana, " inv=", sm.data["inventory"].size())
		60:
			var aw0 := []
			for k in sm._bandits:
				aw0.append(sm._bandits[k].aware)
			print("bandits aware at start: ", aw0, " pos ok: ", sm._bandits.values()[0].position.round())
			snap("st_field")
			# подходим к сундуку
			sm.hero.position.x = 650
		70:
			print("near: ", sm._near.kind if sm._near else "none")
			press("p1_interact", 2)
		76:
			snap("st_chest")
			var ch: StoryChest
			for n in main.world.get_children():
				if n is StoryChest: ch = n
			print("chest overlay=", ch != null, " paused=", paused, " in chest=", sm.chest_items("start_chest").size())
			ch._move("c", 0)                       # взять одну вещь
			print("after one: inv=", sm.data["inventory"].size(), " chest=", sm.chest_items("start_chest").size())
			ch._take_all()
		80:
			snap("st_chest2")
			for n in main.world.get_children():
				if n is StoryChest: n.queue_free()
			print("inv after chest=", sm.data["inventory"].size(), " quest=", sm.data["quests"]["awakening"])
		90:
			for id in ["iron_helm", "chainmail", "guard_greaves", "leather_boots", "leather_gloves", "traveler_cape",
					"copper_ring", "fang_amulet", "short_sword", "hunting_bow"]:
				sm.equip(id)
			print("armor=", sm.kit.stats["armor"], " hp max=", sm.hero.max_hp, " quest=", sm.data["quests"]["awakening"])
			for id in ["scroll_fireball", "scroll_dash", "scroll_heal", "scroll_rage"]:
				print(sm.use_item(id))
			print("slots=", sm.data["slots"], " ult=", sm.data["ult"], " hero abilities=", sm.hero.abilities)
		100:
			sm.open_inventory()
		106:
			snap("st_inv_armor")
			_inv()._set_tab("melee")
		110:
			var inv := _inv()
			inv._sel = "0"
			for i in sm.data["inventory"].size():
				if sm.data["inventory"][i]["id"] == "short_sword": inv._sel = str(i)
			inv._refresh()
		114:
			snap("st_inv_melee")
			_inv()._set_tab("abilities")
		118:
			_inv()._sel_ability = "fireball"
			_inv()._refresh()
		122:
			snap("st_inv_abil")
			_inv()._set_tab("stats")
		126:
			snap("st_inv_stats")
			_inv().queue_free()
		130:
			print("paused after close: ", paused)
			sm.hero.position.x = 1330
		140:
			press("p1_shoot", 200)
		260:
			snap("st_fight")
		345:
			print("sword skill=", sm.data["skills"]["sword"], " warmup=", sm.data["quests"]["warmup"])
			press("p1_ranged", 60)
		420:
			print("arrows left=", sm.count("arrows"), " bow skill=", sm.data["skills"]["bow"])
			sm.kit.mana = 100
			press("p1_a1", 2)
		440:
			snap("st_fireball")
		460:
			press("p1_a2", 2)
		480:
			sm.hero.ult_charge = 999
			press("p1_ult", 2)
		500:
			print("rage=", sm.kit.rage_t, " magic skill=", sm.data["skills"]["magic"])
			sm.hero.position.x = 2700
		560:
			press("p1_shoot", 200)
		700:
			snap("st_bandits")
		540:
			var aw := []
			for k in sm._bandits:
				aw.append(sm._bandits[k].aware)
			print("bandits aware before approach: ", aw)
		780:
			var alive := 0
			for k in sm._bandits:
				if is_instance_valid(sm._bandits[k]) and sm._bandits[k].is_alive(): alive += 1
			print("bandits alive=", alive, " level=", sm.data["level"], " xp=", sm.data["xp"], " hero hp=", sm.hero.hp, " bq=", sm.data["quests"]["bandits"])
			sm.hero.position.x = 3740
		800:
			press("p1_interact", 2)
		810:
			print("cellar quest=", sm.data["quests"]["awakening"])
			snap("st_cellar")
			sm.hud.close_dialog()
			sm.open_quests()
		816:
			snap("st_quests")
			for n in main.world.get_children():
				if n is StoryQuestLog: n.queue_free()
		820:
			sm.open_menu()
		824:
			snap("st_pause")
			for n in main.world.get_children():
				if n is StoryPause: n._settings()
		828:
			snap("st_settings")
			for n in main.world.get_children():
				if n is StoryPause: n.queue_free()
		832:
			sm.save_game()
			var d := StorySave.load_slot(3)
			print("saved: lvl=", d["level"], " eq=", d["equipped"].size(), " learned=", d["learned"], " pos=", d["world"]["pos"])
			main.show_story_slots()
		840:
			snap("st_slots2")
			main.start_story(3, StorySave.load_slot(3))
		850:
			for n in main.world.get_children():
				if n is StoryMode: sm = n
			print("reload chest items=", sm.chest_items("start_chest").size(), " chest opened=", sm.props[1].opened, " hp=", sm.hero.hp, " eq melee=", sm.data["equipped"].get("melee"))
			StorySave.delete_slot(3)
			print("deleted: ", not StorySave.exists(3))
			return true
	return false

func _inv() -> StoryInventory:
	for n in main.world.get_children():
		if n is StoryInventory: return n
	return null
