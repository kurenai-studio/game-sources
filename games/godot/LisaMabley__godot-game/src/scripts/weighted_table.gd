class_name WeightedTable

var items: Array[Dictionary] = []
var weight_sum = 0


func add_item(item, weight: int, id: String):
	if item == null:
		push_error("Cannot add a null item to WeightedTable.")
		return

	items.append({ "item": item, "weight": weight, "id": id })
	weight_sum += weight


func remove_item(item_to_remove):
	items = items.filter(func (item): return item["item"] != item_to_remove )
	weight_sum = 0
	for item in items:
		weight_sum += item["weight"]


func has_item_id(id: String) -> bool:
	return items.any(func (item): return item["id"] == id)


func update_item_weight(id_to_update, new_weight: int):
	for item in items:
		if item["id"] == id_to_update:
			var old_weight = item["weight"]
			item["weight"] = new_weight
			weight_sum += (new_weight - old_weight)


func pick_item(exclude: Array = []):
	var available_items: Array[Dictionary] = items
	var available_weight_sum = weight_sum

	if exclude.size() > 0:
		available_items = []
		available_weight_sum = 0
	
		for item in items:
			if item["item"] in exclude:
				continue
		
			available_items.append(item)
			available_weight_sum += item["weight"]

	if available_items.is_empty() or available_weight_sum <= 0:
		return null
	
	var chosen_weight = randi_range(1, available_weight_sum)
	var iteration_sum = 0
	for item in available_items:
		iteration_sum += item["weight"]
		if chosen_weight <= iteration_sum:
			return item["item"]
