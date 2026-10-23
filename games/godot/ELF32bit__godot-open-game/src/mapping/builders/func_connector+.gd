# random starting map for the maze
const START_MAPS: PackedStringArray = [
	"start",
]

# special maps that will seal the unused connectors
# add `maze_ignore` property to all entities in such maps
const SEALING_MAPS: PackedStringArray = [
]

# all maps that can spawn after the start map
const MIDDLE_MAPS: PackedStringArray = [
]

# maps that act as exits from the maze
const EXIT_MAPS: PackedStringArray = [
]

# can be overwritten by the `next` property of the func_connector
# can be deleted entirely to use an equal priority table instead
const NEXT_MAP_WEIGHTS: Dictionary = {
}
