class_name RunItems
extends RefCounted
## Items and docks during a run. Mirrors the itemAt, dockAt, carrying and delivered parts of
## simulate.ts. A delivery is its index in the level's `deliveries`. The automaton carries at most
## one item (`carrying`, an index or -1) and `delivered` holds the dropped ones.


## The run state for a level's deliveries: cell to delivery index, for items and for docks.
static func tables(level: Dictionary) -> Dictionary:
	var items := {}
	var docks := {}
	var deliveries: Array = level.get("deliveries", [])
	for i in deliveries.size():
		var item: Array = deliveries[i]["item"]
		var dock: Array = deliveries[i]["dock"]
		items[Vector2i(int(item[0]), int(item[1]))] = i
		docks[Vector2i(int(dock[0]), int(dock[1]))] = i
	return {"items": items, "docks": docks}


## True when an item is still to be delivered.
static func pending(run: Dictionary) -> bool:
	return (run["delivered"] as Dictionary).size() < (run["items"] as Dictionary).size()


## Drops the carried item on its dock, or takes the item lying on the cell (only with empty hands).
## Returns "ITEM_DROPPED", "ITEM_TAKEN", or "" when nothing happened.
static func settle(run: Dictionary, cell: Vector2i) -> String:
	var docks: Dictionary = run["docks"]
	if docks.has(cell) and docks[cell] == run["carrying"]:
		(run["delivered"] as Dictionary)[run["carrying"]] = true
		run["carrying"] = -1
		return "ITEM_DROPPED"
	var items: Dictionary = run["items"]
	if (
		items.has(cell)
		and run["carrying"] < 0
		and not (run["delivered"] as Dictionary).has(items[cell])
	):
		run["carrying"] = items[cell]
		return "ITEM_TAKEN"
	return ""
