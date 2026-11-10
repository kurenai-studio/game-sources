extends Node

var bought_tower = null;
var highlighted_tower = null;
var tower_list = []

@onready var money = 1500;
@onready var fuel = 5;
@onready var wave = -1;
@onready var curr_wave = null;

var money_lb
var fuel_lb

@onready var buy_butts = get_tree().get_first_node_in_group("BuyButt").get_children();
@onready var waves = get_tree().get_first_node_in_group("Spawner").get_children();
@onready var wave_lb = get_tree().get_first_node_in_group("Wave")

func _ready():
	money_lb = get_tree().get_first_node_in_group("Money")
	fuel_lb = get_tree().get_first_node_in_group("Fuel")
	
	wave_lb.text = str(wave+1,"/",waves.size()-1)
	
	update_curr()
	new_wave()

func update_curr(money_in = 0, fuel_in = 0):
	money += money_in
	fuel += fuel_in
	
	for i in buy_butts:
		i.disabled = (i.cost > money);
	
	money_lb.text = str(money);
	fuel_lb.text = str(fuel);

# cheat codes
func _input(event):
	if event.is_action_pressed("MoneyGlitch"):
		update_curr(1000,0)
	
	if Input.is_action_just_pressed("Back"):
		Global.highlighted_tower = null;

# triggers next spawner in list
func new_wave():
	if wave < waves.size()-1:
		wave += 1;
		curr_wave = waves[wave];
		wave_lb.text = str(wave,"/",waves.size()-1)
		if wave > 0:
			curr_wave.start_wave()
		else:
			curr_wave.show_wave_notif()
