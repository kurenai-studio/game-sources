extends Control

var tower
@onready var name_label = $NameLabel
@onready var damage_amo_label = $DamageAmoLabel
@onready var texture_rect = $TextureRect
@onready var energy_bar : TextureProgressBar = $EnergyBar
@onready var upgrade_butts = $UpgradeButts
@onready var target_button = $TargetButton

# updates damage output and energy if selected
func _physics_process(delta):
	tower = Global.highlighted_tower
	if tower != null:
		visible = true;
		name_label.text = tower.type
		damage_amo_label.text = str(tower.damage+tower.buff_bonus)
		energy_bar.max_value = tower.energy_max
		energy_bar.value = tower.energy
	else:
		visible = false

# drains or fuels robot, doesn't lower past minimum
func _on_fuel_button_pressed():
	if Global.fuel >= 1:
		Global.update_curr(0,-1)
		tower.energy = clampf(tower.energy+10,1,tower.energy_max);

func _on_drain_button_pressed():
	if tower.energy >= 21:
		Global.update_curr(0,1)
		tower.energy = clampf(tower.energy-20,1,tower.energy_max)

func update_gui():
	var butts = upgrade_butts.get_children()
	tower = Global.highlighted_tower
	
	for i in range(4):
		butts[i].disabled = false
		
		var upgrade = tower.upgrade_opts[i]
		var value = tower.get(upgrade)
		var new_value = 0
		var up_text = "???: "
		
		# fetches specific upgradable stat, displays what it will inprove and for what cost
		match upgrade:
			"damage":
				new_value = max(int(value/4)+value, value+1)
				up_text = "Damage: "
			"energy_consumpt":
				new_value = value-0.05
				up_text = "Energy Consumption: "
				if new_value < .5:
					butts[i].text = up_text+"SOLD!"
					butts[i].disabled = true
					continue
			"rotation_delta":
				new_value = value+0.002
				up_text = "Rotation Speed: "
			"pierce":
				new_value = value+1;
				up_text = "Pierce: "
			"acceleration":
				new_value = value+0.002
				up_text = "Acceleration: "
			"min_fire_rate":
				new_value = value-0.005
				up_text = "Min. Fire Rate: "
				if new_value < .05:
					butts[i].text = up_text+"SOLD!"
					butts[i].disabled = true
					continue
			"buff":
				new_value = value+2
				up_text = "Music Strength: "
			"proj_lifespan":
				new_value = value+0.01
				up_text = "Volume: "
			"proj_size":
				new_value = value+0.01
				up_text = "Bomb Radius: "
			"proj_speed":
				new_value = value+75
				up_text = "Projectile Speed: "
			"effect_rate":
				new_value = value-0.02
				up_text = "Fire DPS: ";
				if new_value < .1:
					butts[i].text = up_text+"SOLD!"
					butts[i].disabled = true
					continue
		
		butts[i].text = str(up_text,value," -> ", new_value, "\n$", 20)
		butts[i].upgrade = upgrade
		butts[i].new_value = new_value
		butts[i].cost = 20
	
	#Update target butt
	target_button.text = tower.targeting


func upgrade_tower(upg, new_val):
	tower.set(upg, new_val)
	update_gui()


func _on_target_button_pressed():
	var tower = Global.highlighted_tower
	match tower.targeting:
		"First":
			tower.targeting = "Last"
		"Last":
			tower.targeting = "Weak"
		"Weak":
			tower.targeting = "Strong"
		"Strong":
			tower.targeting = "First"
	target_button.text = tower.targeting
