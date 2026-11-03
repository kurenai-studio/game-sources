import { repeat } from "../core/util.ts";
import {
	COLOR_BLACK,
	COLOR_BLUE,
	COLOR_CYAN,
	COLOR_DARKGREY,
	COLOR_FIXED_BLUE,
	COLOR_FIXED_GREEN,
	COLOR_FIXED_RED,
	COLOR_GREEN,
	COLOR_LIGHTGREY,
	COLOR_ORANGE,
	COLOR_OUTLINE,
	COLOR_PEACH,
	COLOR_PINK,
	COLOR_RAINBOW,
	COLOR_RED,
	COLOR_VIOLET,
	COLOR_WHITE,
	COLOR_YELLOW,
} from "./colors.ts";
import type { ObjectDescriptor, ObjectNode } from "./objectsSchema.d.ts";

const side = (s: number) => (s < 0 ? "R" : "L");

export default [
	{
		name: "gizmo",
		nodes: [
			{
				shape: "pill",
				color: COLOR_FIXED_RED,
				euler: [0, 0, -90],
				bottomRadius: 0.05,
				height: 2.0,
				children: [
					{
						shape: "pill",
						translate: [0, 2, 0],
						height: 0.5,
						bottomRadius: 0.125,
						topRadius: 0,
					}
				]
			},
			{
				shape: "pill",
				color: COLOR_FIXED_GREEN,
				euler: [0, 0, 0],
				bottomRadius: 0.05,
				height: 2.0,
				children: [
					{
						shape: "pill",
						translate: [0, 2, 0],
						height: 0.5,
						bottomRadius: 0.125,
						topRadius: 0,
					}
				]
			},
			{
				shape: "pill",
				color: COLOR_FIXED_BLUE,
				euler: [90, 0, 0],
				bottomRadius: 0.05,
				height: 2.0,
				children: [
					{
						shape: "pill",
						translate: [0, 2, 0],
						height: 0.5,
						bottomRadius: 0.125,
						topRadius: 0,
					}
				]
			}
		]
	},
	{
		// ? unicorn
		name: "unicorn",
		nodes: [
			{
				translate: [0, 0, 2],
				slotName: "hornPivot",
				children: [
					{
						translate: [0, 0, -3],
						slotName: "body",
						children: [
							...[-1, 1].flatMap((s): ObjectNode[] => [
								{
									// hind legs
									shape: "pill",
									color: COLOR_WHITE,
									translate: [s * 0.2, 0, 0],
									euler: [190, 0, 0],
									bottomRadius: 0.5,
									height: 0.7,
									topRadius: 0.2,
									slotName: "hindLeg" + side(s),
									children: [
										{
											shape: "pill",
											euler: [0, 0, 0],
											translate: [0, 0.7, 0],
											bottomRadius: 0.2,
											height: 0.2,
											slotName: "hindKnee" + side(s),
											children: [
												{
													shape: "pill",
													translate: [0, 0.2, 0],
													euler: [-20, 0, 0],
													bottomRadius: 0.2,
													height: 0.4,
													topRadius: 0.1,
													slotName: "hindHeel" + side(s),
													children: [
														{
															shape: "box", // hooves
															translate: [0, 0.4, 0],
															euler: [10, 0, 0],
															color: COLOR_DARKGREY,
															a1: 0.2,
															b2: 0.4,
														},
													],
												},
											],
										},
									],
								},
								{
									// fore legs
									shape: "pill",
									color: COLOR_WHITE,
									translate: [s * 0.2, 0, 1.2],
									euler: [180, 0, 0],
									bottomRadius: 0.2,
									height: 1.0,
									topRadius: 0.1,
									slotName: "foreLeg" + side(s),
									children: [
										{
											shape: "pill",
											translate: [0, 1.0, 0],
											bottomRadius: 0.1,
											height: 0.4,
											topRadius: 0.1,
											slotName: "foreLegBow" + side(s),
											children: [
												{
													shape: "box", // hooves
													translate: [0, 0.4, 0],
													color: COLOR_DARKGREY,
													a1: 0.2,
													height: 0.2,
													b2: 0.4,
												},
											],
										},
									],
								},
							]),
							{
								shape: "pill", // body
								euler: [90, 0, 0],
								bottomRadius: 0.55,
								topRadius: 0.45,
								height: 1,
								color: COLOR_WHITE,
							},
							{
								translate: [0, 0, 1.2], // neck
								slotName: "neck",
								euler: [45, 0, 0],
								shape: "pill",
								bottomRadius: 0.45,
								topRadius: 0.3,
								height: 1.0,
								children: [
									{
										shape: "pill", // head
										slotName: "head",
										translate: [0, 1, 0],
										euler: [90, 0, 0],
										bottomRadius: 0.3,
										topRadius: 0.2,
										height: 0.75,
										children: [-1, 1].flatMap((s): ObjectNode[] => [
											{
												shape: "pill", // eyes
												translate: [s * (0.3 + 0.01), 0.2, -0.15],
												color: COLOR_OUTLINE,
												bottomRadius: 0.05,
											},
											{
												shape: "pill", // ears
												euler: [-120, 0, 0],
												translate: [s * 0.1, 0, 0],
												color: COLOR_WHITE,
												bottomRadius: 0.2,
												height: 0.5,
												topRadius: 0.01,
											},
										]),
									},
									{
										shape: "pill", // horn
										translate: [0, 1.3, 0.1],
										color: COLOR_RAINBOW,
										height: 0.8,
										bottomRadius: 0.1,
										topRadius: 0,
										newObjectIndex: true,
									},
									{
										shape: "pill", // mane
										translate: [0, 0.4, -0.2],
										euler: [15, 0, 0],
										bottomRadius: 0.4,
										topRadius: 0.3,
										height: 0.6,
									},
								],
							},
							{
								shape: "pill", // tail
								slotName: "tail",
								newObjectIndex: true,
								color: COLOR_RAINBOW,
								translate: [0, 0.1, -0.5],
								euler: [-170, 0, 0],
								bottomRadius: 0.1,
								height: 0.33,
								topRadius: 0.2,
								children: [
									{
										shape: "pill",
										slotName: "tail2",
										translate: [0, 0.33, 0],
										bottomRadius: 0.2,
										height: 0.33,
										children: [
											{
												shape: "pill",
												slotName: "tail3",
												translate: [0, 0.33, 0],
												bottomRadius: 0.2,
												height: 0.33,
												topRadius: 0.1,
											},
										],
									},
								],
							},
						],
					},
				],
			},
		],
	},
	// {
	// 	name: "unitSphere",
	// 	nodes: [
	// 		{
	// 			shape: "pill",
	// 			color: COLOR_WHITE,
	// 			bottomRadius: 0.5,
	// 		},
	// 	],
	// },
	// {
	// 	name: "unitCube",
	// 	nodes: [
	// 		{
	// 			shape: "box",
	// 			color: COLOR_WHITE,
	// 			a1: 1,
	// 		},
	// 	],
	// },
	// {
	// 	name: "cube2x2x1",
	// 	nodes: [
	// 		{
	// 			shape: "box",
	// 			color: COLOR_WHITE,
	// 			a1: 2,
	// 			b1: 2,
	// 			height: 1,
	// 			collision: true,
	// 		},
	// 	],
	// },
	// {
	// 	name: "cube32x32x1",
	// 	nodes: [
	// 		{
	// 			shape: "box",
	// 			color: COLOR_WHITE,
	// 			a1: 32,
	// 			height: 1,
	// 			collision: true,
	// 		},
	// 	],
	// },
	{
		name: "pillar16", // ? pillar16
		nodes: [
			{
				translate: [0, 1.25, 0],
				shape: "pill",
				bottomRadius: 1.5,
				height: 16  - 1.125 * 2,
				collision: true,
				visible: false,
			},
			{
				color: COLOR_WHITE,
				translate: [0, -.5, 0],
				shape: "box",
				a1: 3.5,
				height: .75,
				a2: 3,
				collision: true,
			},
			{
				translate: [0, 16, 0],
				shape: "box",
				a1: 3,
				height: .75,
				a2: 3.5,
				collision: true,
			},
			...repeat(16).map((i): ObjectNode => ({
				euler: [0, (360 * i) / 16, 0],
				children: [
					{
						shape: "pill",
						newObjectIndex: true,
						bottomRadius: 0.25,
						height: 16,
						translate: [0, 0, 1],
					},
				],
			})),
		],
	},
	{
		name: "pillar10", // ? pillar10
		nodes: [
			{
				translate: [0, 1.25, 0],
				shape: "pill",
				bottomRadius: 1.5,
				height: 10  - 1.125 * 2,
				collision: true,
				visible: false,
			},
			{
				color: COLOR_WHITE,
				translate: [0, -.5, 0],
				shape: "box",
				a1: 3.5,
				height: .75,
				a2: 3,
				collision: true,
			},
			{
				translate: [0, 10, 0],
				shape: "box",
				a1: 3,
				height: .75,
				a2: 3.5,
				collision: true,
			},
			...repeat(16).map((i): ObjectNode => ({
				euler: [0, (360 * i) / 16, 0],
				children: [
					{
						shape: "pill",
						newObjectIndex: true,
						bottomRadius: 0.25,
						height: 10,
						translate: [0, 0, 1],
					},
				],
			})),
		],
	},
	{
		name: "pillar5",
		nodes: [
			{
				translate: [0, 1.25, 0],
				shape: "pill",
				bottomRadius: 1.5,
				height: 5  - 1.125 * 2,
				collision: true,
				visible: false,
			},
			{
				color: COLOR_WHITE,
				translate: [0, -.5, 0],
				shape: "box",
				a1: 3.5,
				height: .75,
				a2: 3,
				collision: true,
			},
			{
				translate: [0, 5, 0],
				shape: "box",
				a1: 3,
				height: .75,
				a2: 3.5,
				collision: true,
			},
			...repeat(16).map((i): ObjectNode => ({
				euler: [0, (360 * i) / 16, 0],
				children: [
					{
						shape: "pill",
						newObjectIndex: true,
						bottomRadius: 0.25,
						height: 5,
						translate: [0, 0, 1],
					},
				],
			})),
		],
	},
	{
		name: "wall",
		nodes: [
			{
				shape: "box",
				height: 4,
				a1: 6,
				b1: 2,
				a2: 6,
				b2: 2,
				collision: true,
				visible: false,
			},
			{
				shape: "box",
				translate: [0, 0, 0.1],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				color: COLOR_PEACH,
			},
			{
				shape: "box",
				translate: [3, 0, 0],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				newObjectIndex: true
			},
			{
				shape: "box",
				translate: [-3, 0, -0.1],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				newObjectIndex: true
			},
			{
				shape: "box",
				translate: [-1.5, 2, 0.1],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				newObjectIndex: true
			},
			{
				shape: "box",
				translate: [1.5, 2, 0],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				newObjectIndex: true
			}
		]
	},
	{
		name: "wallEdge",
		nodes: [
			{
				shape: "box",
				translate: [-1.5/2, 0, -0.1],
				height: 2,
				a1: 1.5,
				color: COLOR_PEACH,
				collision: true,
			},
			{
				shape: "box",
				translate: [-1.5, 2, 0.1],
				height: 2,
				a1: 3,
				b1: 1.5,
				a2: 3,
				b2: 1.5,
				collision: true,
				newObjectIndex: true,
			}
		]
	},
	{
		name: "roof",
		nodes: [
			{
				shape: "box",
				height: 0.75,
				a1: 16,
				b1: 12,
				a2: 15,
				b2: 11,
				color: COLOR_LIGHTGREY,
				collision: true,
			}
		]
	},
	{
		name: "npc1", // * NPC 1
		nodes: [
			{
				slotName: "body",
				translate: [0, 1, 0],
				shape: "pill",
				bottomRadius: 0.5,
				topRadius: 0.4,
				height: 0.5,
				color: COLOR_PEACH,
				collision: true,
				children: [
					{
						slotName: "head",
						translate: [0, 1.25, 0],
						shape: "pill",
						bottomRadius: 0.6,
						topRadius: 0.75,
						height: 0.25,
						collision: true,
						children: [
							...[-1, 1].map(
								(s) =>
									({
										// ears
										shape: "pill",
										translate: [s * 0.5, 0.75, 0],
										euler: [0, 0, s * -20],
										bottomRadius: 0.4,
										topRadius: 0.2,
										height: 0.3,
									}) satisfies ObjectNode,
							),
							{
								// nose
								translate: [0, 0.125, -0.75],
								euler: [-90, 0, 0],
								shape: "pill",
								bottomRadius: 0.2,
								topRadius: 0.125,
								height: 0.25,
								newObjectIndex: true,
								color: COLOR_PINK,
							},
							{
								color: COLOR_OUTLINE,
							},
							...[-1, 1].map(
								(s) =>
									({
										// eyes
										shape: "pill",
										translate: [s * 0.4, 0.25, -0.6],
										bottomRadius: 0.05,
										height: 0.05,
									}) satisfies ObjectNode,
							),
						],
					},
					...[-1, 1].flatMap((s) => [
						{
							// arms
							shape: "pill",
							slotName: "upperArm" + side(s),
							translate: [s * 0.4, 0.5, 0],
							euler: [0, 0, s * -90],
							bottomRadius: 0.075,
							height: 0.5,
							children: [
								{
									shape: "pill",
									slotName: "lowerArm" + side(s),
									translate: [0, 0.5, 0],
									bottomRadius: 0.075,
									height: 0.5,
								},
							],
						} satisfies ObjectNode,
					]),
				],
			},
			...[-1, 1].flatMap((s) => [
				{
					// legs
					shape: "pill",
					slotName: "lowerLeg" + side(s),
					translate: [s * 0.4, 0, 0],
					bottomRadius: 0.075,
					height: 0.5,
					children: [
						{
							shape: "pill",
							slotName: "upperLeg" + side(s),
							translate: [0, 0.5, 0],
							bottomRadius: 0.075,
							height: 0.5,
						},
					],
				} satisfies ObjectNode,
			]),
		],
	},
	{ // * balloon
		name: "balloon",
		nodes: [
			{
				shape: "pill",
				slotName: "balloon",
				color: COLOR_PINK,
				bottomRadius: 1.75,
				topRadius: 2.5,
				height: 1.0,
				collision: true,
			},
			{
				shape: "box",
				translate: [0, -3, 0],
				a1: 0.75,
				color: COLOR_PEACH,
			},
			{
				shape: "pill",
				translate: [0, -2.25, 0],
				bottomRadius: 0.1,
				height: 0.1,
			},
			{
				shape: "pill",
				translate: [-0.1, -2, 0],
				bottomRadius: 0.05,
			},
			{
				shape: "pill",
				translate: [0.1, -2, 0],
				bottomRadius: 0.05,
			},
			{
				shape: "pill",
				translate: [0, -2.125, -0.1],
				bottomRadius: 0.05,
				color: COLOR_PINK,
			},
			{
				color: COLOR_OUTLINE,
			},
			{
				shape: "pill",
				translate: [-.75/2, -2.25, -.75/2],
				bottomRadius: 0.05,
				height: 3,
			},
			{
				shape: "pill",
				translate: [-.75/2, -2.25, .75/2],
				bottomRadius: 0.05,
				height: 3,
			},
			{
				shape: "pill",
				translate: [.75/2, -2.25, -.75/2],
				bottomRadius: 0.05,
				height: 3,
			},
			{
				shape: "pill",
				translate: [.75/2, -2.25, .75/2],
				bottomRadius: 0.05,
				height: 3,
			},
		]
	},
	{ // * box
		name: "box3x3",
		nodes: [
			{
				shape: "box",
				color: COLOR_PEACH,
				translate: [0, 0, -1.25],
				a1: 3,
				b1: 0.5,
				height: 0.5,
				a2: 3,
				b2: 0.5,
			},
			{
				shape: "box",
				translate: [0, 0, 1.25],
				a1: 3,
				b1: 0.5,
				height: 0.5,
				a2: 3,
				b2: 0.5,
			},
			{
				shape: "box",
				translate: [-1.25, 0, 0],
				a1: 0.5,
				b1: 3,
				height: 0.5,
				a2: 0.5,
				b2: 3,
			},
			{
				shape: "box",
				translate: [1.25, 0, 0],
				a1: 0.5,
				b1: 3,
				height: 0.5,
				a2: 0.5,
				b2: 3,
			},
			{
				shape: "box",
				translate: [0, 2.5, -1.25],
				a1: 3,
				b1: 0.5,
				height: 0.5,
				a2: 3,
				b2: 0.5,
			},
			{
				shape: "box",
				translate: [0, 2.5, 1.25],
				a1: 3,
				b1: 0.5,
				height: 0.5,
				a2: 3,
				b2: 0.5,
			},
			{
				shape: "box",
				translate: [-1.25, 2.5, 0],
				a1: 0.5,
				b1: 3,
				height: 0.5,
				a2: 0.5,
				b2: 3,
			},
			{
				shape: "box",
				translate: [1.25, 2.5, 0],
				a1: 0.5,
				b1: 3,
				height: 0.5,
				a2: 0.5,
				b2: 3,
			},
			{
				shape: "box",
				translate: [1.25, 0, 1.25],
				a1: 0.5,
				b1: 0.5,
				height: 3,
			},
			{
				shape: "box",
				translate: [1.25, 0, -1.25],
				a1: 0.5,
				b1: 0.5,
				height: 3,
			},
			{
				shape: "box",
				translate: [-1.25, 0, 1.25],
				a1: 0.5,
				b1: 0.5,
				height: 3,
			},
			{
				shape: "box",
				translate: [-1.25, 0, -1.25],
				a1: 0.5,
				b1: 0.5,
				height: 3,
			},
			{
				shape: "box",
				newObjectIndex: true,
				collision: true,
				translate: [0, 0.125, 0],
				a1: 2.75,
				b1: 2.75,
				height: 2.75,
			}
		]
	}
] satisfies ObjectDescriptor[];
