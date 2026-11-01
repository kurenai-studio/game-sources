class_name HowToMore
extends RefCounted
## The how-to-play sections for the later mechanics: the counter, nested loops, breadcrumbs with
## else-if chains, and the goal of visiting every cell. Plain words, no questions.

const SECTIONS: Array[Dictionary] = [
	{
		"title": "THE COUNTER",
		"rows":
		[
			{
				"icon": "inc",
				"name": "INC",
				"text": "Adds one to the counter N, up to 11. It does not move the automaton."
			},
		],
		"text":
		(
			"Some levels have a counter called N. N starts at 1 on every run and INC adds one. "
			+ "Select the count tile of a REPEAT and tap plus past 11 to count with N. The loop "
			+ "reads N when it starts and runs that many rounds, whatever happens to N inside it. "
			+ "While the program runs, N shows beside the tape caption."
		)
	},
	{
		"title": "LOOPS IN LOOPS",
		"rows": [],
		"text":
		(
			"Some levels let a loop hold one more loop. While a loop is open, tap REPEAT or UNTIL "
			+ "again to start the inner loop. Tap END LOOP to close the inner loop, then again to "
			+ "close the outer one. Two levels is the most. The inner loop runs all its rounds "
			+ "in every round of the outer loop, so 3 rounds around 4 rounds is 12 rounds in all."
		)
	},
	{
		"title": "BREADCRUMBS",
		"rows":
		[
			{
				"icon": "mark",
				"name": "MARK",
				"text": "Drops a breadcrumb: an arrow on this cell that points to the cell behind."
			},
			{
				"icon": "fresh_ahead",
				"name": "NEW",
				"text": "True when the cell ahead, left or right has no breadcrumb yet."
			},
			{
				"icon": "back_ahead",
				"name": "BACK",
				"text": "True when that cell is the one this cell's breadcrumb points to."
			},
		],
		"text":
		(
			"A cell keeps its first breadcrumb. Select an IF sensor and tap it again to cycle "
			+ "through the sensors. After ELSE, tap ELSE IF to put another decision in the else. "
			+ "A chain holds up to six. END IF closes the whole chain."
		)
	},
	{
		"title": "VISIT EVERY CELL",
		"rows": [],
		"text":
		(
			"Some boards have no target. The level is solved the moment the automaton has entered "
			+ "every open cell, the start included. The board shows the cells entered so far and "
			+ "the counter reads how many, such as 12 / 30 CELLS. A failure says how many are left."
		)
	},
]


## Adds the sections to the list of the how-to-play screen.
static func add(list: VBoxContainer) -> void:
	for section in SECTIONS:
		list.add_child(UiKit.label(section["title"], 14, Palette.MUTE, 3))
		for row: Dictionary in section["rows"]:
			list.add_child(HowToRow.make(row["icon"], row["name"], row["text"]))
		var text := UiKit.label(section["text"], 16, Palette.INK, 0)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(text)
