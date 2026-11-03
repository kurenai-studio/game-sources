	import { repeat } from "../core/util.ts";
import { COLOR_BLUE, COLOR_CYAN, COLOR_GREEN, COLOR_ORANGE, COLOR_RED, COLOR_VIOLET, COLOR_YELLOW } from "./colors.ts";
import { BALLOON, CLOOD, CLOUD, NPC, offset, SHARD, type LevelDescriptor } from "./levelSchema.ts";
import { obj_pillar10, obj_pillar5, obj_npc1, obj_pillar16, obj_box3x3, obj_wall, obj_wallEdge, obj_roof } from "./objects.gen.ts";

export default [
	// [SHARD, COLOR_VIOLET, [[0, 3, -5], [0, 3, -15], [0, 10, -15], [0, 3, 0], [0, 3, 10]]],

	// * Starting area
	[CLOUD, 0, [-20, -20], [20, 20], true],
	...repeat(7).flatMap(
		(i) =>
			[
				[
					obj_pillar16,
					[
						Math.cos((i / 7) * Math.PI * 2) * 17,
						0,
						Math.sin((i / 7) * Math.PI * 2) * 17,
					],
					[0, 0, 0],
					COLOR_RED + i
				],
			] satisfies LevelDescriptor,
	),
	[NPC, obj_npc1, [-8, 0, -8], 225, "The bifrost has shattered and scattered!"],
	[NPC, obj_npc1, [10, 0, 10], 45, "Please great Neighdall! Find the lost rainbow shards all!", -7],
	[obj_box3x3, [15, 0, -12]],
	[NPC, obj_npc1, [15, 3, -12], 135, "Every shard collected increases your flair.\\nTry pressing JUMP in mid-air!", 1],

	// * Shard 1
	[CLOOD, 0, [0, 32], [5, 8]],
	[CLOOD, 4, [11, 32], [8, 5]],
	[CLOOD, 8, [5, 42], [15, 5], true],

	[obj_pillar16, [0, 8.5, 42], [0, 0, 90]],

	[CLOUD, 8, [-35, 25], [-15, 45], true],
	[obj_pillar10, [-18.5, 8.5, 28], [0, 0, 90]],
	[obj_pillar5, [-33, 8.5, 28]],
	[BALLOON, [-33, 14, 36]],
	[obj_pillar10, [-33, 8.5, 42]],
	[BALLOON, [-33, 16, 50]],

	[CLOOD, 16, [-33, 65], [45, 10], true],
	[NPC, obj_npc1, [-50, 16, 68], -45, "If you want to make this jump, you'll need a long gallop-up"],
	[obj_box3x3, [-11.75, 16, 64]],
	[obj_box3x3, [-12, 16, 67.5], , COLOR_GREEN],
	[obj_box3x3, [-11.5, 19, 66], , COLOR_GREEN],
	...repeat(3).flatMap(
		(y) =>
			[
				[obj_wallEdge, [-82, 15 + y * 4, 60], [0, 180, 0]],
				[obj_wall, [-76, 15 + y * 4, 60]],
				[obj_wallEdge, [-70, 15 + y * 4, 60],],

				[obj_wallEdge, [-82, 15 + y * 4, 70], [0, 180, 0]],
				[obj_wall, [-76, 15 + y * 4, 70]],
				[obj_wallEdge, [-70, 15 + y * 4, 70],],

				[obj_wallEdge, [-69, 15 + y * 4, 71], [0, -90, 0]],
				[obj_wall, [-69, 15 + y * 4, 65], [0, 90, 0]],
				[obj_wallEdge, [-69, 15 + y * 4, 59], [0, 90, 0]],

				[obj_wallEdge, [-83, 15 + y * 4, 71], [0, -90, 0]],
				[obj_wall, [-83, 15 + y * 4, 65], [0, 90, 0]],
				[obj_wallEdge, [-83, 15 + y * 4, 59], [0, 90, 0]],
			] satisfies LevelDescriptor,
	),
	[obj_roof, [-76, 27, 65]],
	[CLOOD, 15, [-76, 65], [16, 12]],


	...offset([-30, 10, 0], [
		[CLOUD, 16, [-50, 8], [-40, 25], true],
		[CLOUD, 16, [-50, 35], [-40, 56]],

		[obj_pillar16, [-45, 8, -10]],
		[obj_pillar10, [-45, 8, -13]],
		[obj_pillar16, [-45, 19, -13]],
		[CLOOD, 8, [-45, -11.5], [4, 7]],
		// [obj_pillar16, [-49, 12, -13]],
		// [CLOOD, 12, [-49, -13], [3, 3]],
		// [obj_pillar16, [-41, 12, -13]],
		// [CLOOD, 12, [-41, -13], [3, 3]],

		[CLOOD, 15, [-20, -16], [26, 8], true],
		[SHARD, COLOR_GREEN, [-15, 18, -16]],
		[NPC, obj_npc1, [-28, 15, -19], 135, "See that wasn't so hard, you found the first shard!"],
	]),
	[CLOOD, 20, [-30, -16], [8, 8], true],

	// * Path to shard 2
	[CLOUD, 2, [40, -10], [60, 0]],
	[obj_box3x3, [55, 2, -8], , COLOR_GREEN],
	[obj_box3x3, [55.2, 5, -7.5], , COLOR_GREEN],
	[NPC, obj_npc1, [55, 8, -8], 90, "You know what's really exciting?\\nPressing JUMP while rainbow-riding!"],

	[CLOOD, 9, [80, 30], [8, 8], true],
	[obj_box3x3, [82, 9, 32], , COLOR_GREEN],

	[CLOOD, 5, [80, 80], [3, 3]],
	[obj_pillar16, [80, 5, 80], , COLOR_GREEN],

	// * Shard 2
	...offset([0, 10, 0], [
		[CLOUD, 16, [25, 100], [45, 155], true],
		[obj_pillar5, [35, 16, 102], , COLOR_GREEN], // R
		[obj_pillar5, [43, 16, 110], , COLOR_GREEN], // L
		// [NPC, obj_npc1, [28, 16, 118], -45, "It's a work in progress! Try coming back later!"],
		[NPC, obj_npc1, [28, 16, 120], -45, "We used to kiss every day.\\nNow the rainbow is gone, we're all out of gay!"], // gays
		[NPC, obj_npc1, [28.5, 16, 122], -45, "We used to kiss every day.\\nNow the rainbow is gone, we're all out of gay!"], // gays

		[obj_box3x3, [42, 16, 130], , COLOR_GREEN],
		[obj_box3x3, [40, 16, 133.5], , COLOR_YELLOW],
		[obj_box3x3, [41, 19, 132], , COLOR_YELLOW],

		...offset([10, 0, 0], [
			...repeat(7).flatMap(y => [
				[obj_wall, [20, 20 + y * 4, 160]],
				[obj_wall, [26, 20 + y * 4, 160]],
				[obj_wallEdge, [32, 20 + y * 4, 160],],
				[obj_wallEdge, [14, 20 + y * 4, 160], [0, 180, 0]],
			] satisfies LevelDescriptor),
			[BALLOON, [15, 51, 160]],
			[BALLOON, [20, 51, 160]],
			[BALLOON, [25, 51, 160]],
			[BALLOON, [30, 51, 160]],

			[CLOOD, 35, [23, 146], [9, 9], true],
			[CLOOD, 35, [23, 120], [9, 15], true],
			[CLOOD, 35, [23, 90], [9, 25], true],
			[NPC, obj_npc1, [24, 35, 80], 180, "With your new yellow flair\\nyou can press JUMP even more times in the air!", 2],

			[CLOOD, 55, [23, 120], [9, 9], true],
			[SHARD, COLOR_YELLOW, [23, 55, 120]],
		]),
	]),

	// * Path to shard 3
	[CLOOD, 35, [20, -8], [12, 18], true],
	[obj_box3x3, [22, 35, -9], , COLOR_YELLOW],

	// * Shard 3
	...repeat(7).flatMap(y => [
		[obj_wall, [16, 40 + y * 4, -50]],
		[obj_wall, [22, 40 + y * 4, -50]],
		[obj_wallEdge, [28, 40 + y * 4, -50],],
		[obj_wallEdge, [10, 40 + y * 4, -50], [0, 180, 0]],
	] satisfies LevelDescriptor),
	[CLOUD, 40, [10, -51], [28, -49]],

	[CLOOD, 60, [60, -45], [10, 10], true],
	[NPC, obj_npc1, [63, 60, -49], 135, "I was seeking the treasure at the end of the rainbow.\\nNow the friends I made along the way are all I have to show."],

	[obj_pillar10, [60, 70, -10], , COLOR_YELLOW],
	[CLOOD, 70, [60, -10], [3, 3]],
	[BALLOON, [60, 84, -10]],

	[obj_pillar16, [60, 80, 30], , COLOR_CYAN],
	[CLOOD, 80, [60, 30], [3, 3]],
	[BALLOON, [60, 100, 30]],

	[BALLOON, [60, 105, 40]],
	[BALLOON, [60, 110, 50]],
	[CLOOD, 110, [60, 60], [7, 7]],
	[CLOOD, 115, [30, 60], [7, 7], true],
	[SHARD, COLOR_CYAN, [30, 116, 60]],

	// * Shard 4 (ORANGE)
	[obj_pillar10, [-43, 100, 143], , COLOR_CYAN],
	[CLOOD, 100, [-43, 143], [3, 3]],
	[CLOOD, 111, [-43, 143], [3, 3], true],

	[obj_pillar16, [-130, 89, 100], , COLOR_ORANGE],
	[CLOOD, 89, [-130, 100], [3, 3]],
	[BALLOON, [-134, 102, 96]],
	[NPC, obj_npc1, [-134, 105.5, 96], -135, "Thank you Neighdall!\\nBut our shard is on another pillar!", -4],
	[NPC, obj_npc1, [-134, 105.5, 96], -135, "Never mind, I guess it was on this pillar after all...", 4],

	[SHARD, COLOR_ORANGE, [
		[-130, 107, 100],
		[-130, 107, 155],
		[-90, 110, 160],
		[-75, 85, 140],
		[-90, 90, 110],
		[-105, 95, 80],
		[-130, 107, 100]
	]],

	[BALLOON, [-135, 102, 110]],

	[BALLOON, [-130, 102, 155]], // shard 1
	[obj_pillar5, [-130, 93, 155]],
	[CLOOD, 93, [-130, 155], [3, 3]],

	[BALLOON, [-123, 102, 145]],

	[BALLOON, [-90, 105, 160]], // shard 2

	[BALLOON, [-75, 80, 140]], // shard 3
	[BALLOON, [-58, 95, 135]],
	[BALLOON, [-90, 85, 110]], // shard 4
	[BALLOON, [-105, 90, 80]], // shard 5

	// * Shard 5 (BLUE)
	[CLOOD, 100, [-100, -40], [10, 10], true],
	[obj_box3x3, [-103, 100, -43], , COLOR_ORANGE],
	[obj_box3x3, [-103.5, 103, -43.25], , COLOR_ORANGE],
	[NPC, obj_npc1, [-103, 100, -40], -135, "I have always been color blind,\\nso this whole debacle isn't something I pay any mind."],

	...repeat(10).flatMap(
		(y) =>
			[
				[obj_wallEdge, [-115, 100 + y * 4, -65 - 6], [0, 90, 0]],
				[obj_wall, [-115, 100 + y * 4, -65], [0, 90, 0]],
				[obj_wallEdge, [-115, 100 + y * 4, -65 + 6], [0, -90, 0]],

				[obj_wallEdge, [-85, 120 + y * 4, -75 - 6], [0, 90, 0]],
				[obj_wall, [-85, 120 + y * 4, -75], [0, 90, 0]],
				[obj_wallEdge, [-85, 120 + y * 4, -75 + 6], [0, -90, 0]],

				[obj_wallEdge, [-100 - 6, 140 + y * 4, -90], [0, 180, 0]],
				[obj_wall, [-100, 140 + y * 4, -90]],
				[obj_wallEdge, [-100 + 6, 140 + y * 4, -90],],
			] satisfies LevelDescriptor,
	),
	[BALLOON, [-115, 143, -65]],
	[BALLOON, [-115, 143, -60]],
	[BALLOON, [-115, 143, -70]],

	[BALLOON, [-85, 163, -75]],
	[BALLOON, [-85, 163, -70]],
	[BALLOON, [-85, 163, -80]],

	[BALLOON, [-100, 183, -90]],
	[BALLOON, [-105, 183, -90]],
	[BALLOON, [-95, 183, -90]],

	...repeat(4).flatMap(
		(y) =>
			[
				[obj_wallEdge, [-130 - 6, 170 + y * 4, -60], [0, 180, 0]],
				[obj_wall, [-130, 170 + y * 4, -60]],
				[obj_wallEdge, [-130 + 6, 170 + y * 4, -60],],

				[obj_wallEdge, [-130 - 6, 170 + y * 4, -50], [0, 180, 0]],
				[obj_wall, [-130, 170 + y * 4, -50]],
				[obj_wallEdge, [-130 + 6, 170 + y * 4, -50],],

				[obj_wallEdge, [-137, 170 + y * 4, -55 - 6], [0, 90, 0]],
				[obj_wall, [-137, 170 + y * 4, -55], [0, 90, 0]],
				[obj_wallEdge, [-137, 170 + y * 4, -55 + 6], [0, -90, 0]],

				[obj_wallEdge, [-123, 170 + y * 4, -55 - 6], [0, 90, 0]],
				[obj_wall, [-123, 170 + y * 4, -55], [0, 90, 0]],
				[obj_wallEdge, [-123, 170 + y * 4, -55 + 6], [0, -90, 0]],
			] satisfies LevelDescriptor,
	),
	[obj_roof, [-130, 186, -55]],
	[CLOOD, 170, [-130, -55], [16, 12]],

	[CLOOD, 185, [-100, -10], [6, 6], true],
	[SHARD, COLOR_BLUE, [-100, 186, -10]],

	[CLOUD, 186, [-60, -30], [-30, -20]],
	[BALLOON, [-15, 186, -25]],
	[BALLOON, [0, 189, -25]],
	[BALLOON, [15, 192, -20]],
	[BALLOON, [25, 195, -10]],

	[obj_pillar16, [40, 190, -5], , COLOR_GREEN],
	[BALLOON, [40, 210, -5]],
	[CLOOD, 190, [40, -5], [3, 3]],

	[obj_pillar16, [60, 200, 30], , COLOR_YELLOW],
	[BALLOON, [60, 220, 30]],
	[CLOOD, 200, [60, 30], [3, 3]],

	[obj_pillar16, [60, 220, 60], , COLOR_CYAN],
	[BALLOON, [60, 240, 60]],
	[CLOOD, 220, [60, 60], [3, 3]],

	[obj_pillar16, [60, 240, 90], , COLOR_ORANGE],
	[BALLOON, [60, 260, 90]],
	[CLOOD, 240, [60, 90], [3, 3]],

	[obj_pillar16, [30, 260, 100], , COLOR_BLUE],
	[BALLOON, [30, 280, 100]],
	[CLOOD, 260, [30, 100], [3, 3]],

	[obj_pillar16, [0, 280, 100], , COLOR_RED],
	[SHARD, COLOR_RED, [0, 300, 100]],
	[CLOOD, 297, [0, 100], [3, 3]],
	[CLOOD, 280, [0, 100], [3, 3]],

	[CLOOD, 310, [-75, 25], [7, 7]],
	[SHARD, COLOR_VIOLET, [
		[-75, 315, 25],
		// [5, 5, 0],
		[10, 20, -13],
		[-75, 48, -13],
		[12, 56, -54],
		[33.5, 70, 160],
		[-75, 90, 140],
		[-90, 23, 66],
		[60, 90, 45],
		[10, 20, -13],
	]],

	// ...repeat(4).flatMap(
	// 	(y) =>
	// 		[
	// 			[obj_wallEdge, [-130 - 6, 170 + y * 4, -60], [0, 180, 0]],
	// 			[obj_wall, [-130, 170 + y * 4, -60]],
	// 			[obj_wallEdge, [-130 + 6, 170 + y * 4, -60],],
	// 		] satisfies LevelDescriptor,
	// ),



] satisfies LevelDescriptor;
