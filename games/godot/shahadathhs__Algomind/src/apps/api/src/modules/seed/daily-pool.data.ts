// The daily challenge pool: levels that are published but not in the campaign, so a player meets
// each one only on its day. Boards are text rows like the campaign's (see starter-campaign.data.ts).
// Every limit equals the shortest program; a loop level's plain program is at least twice as long.
// Made with scripts/level-lab and checked by the seed (validator and solver) and by tests.
// The JSON below stays plain JSON (prettier-ignore) so the level lab can read it.

// prettier-ignore
export const DAILY_POOL = [
  {
    "slug": "daily-alder",
    "title": "Alder",
    "difficulty": "easy",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 9,
    "rows": [
      "......",
      ".G....",
      "......",
      ".####.",
      "......",
      ".^...."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-birch",
    "title": "Birch",
    "difficulty": "medium",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 13,
    "rows": [
      "..G...",
      "......",
      "..####",
      "......",
      "##....",
      ".^...."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-cedar",
    "title": "Cedar",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 15,
    "rows": [
      "........",
      "..######",
      "........",
      "..G.....",
      "#####...",
      "........",
      ".######.",
      "^......."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-dune",
    "title": "Dune",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 18,
    "rows": [
      "####..G.",
      "###..##.",
      "###.###.",
      "#...###.",
      "#.#####.",
      "..#####.",
      ".######.",
      "^......."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-elm",
    "title": "Elm",
    "difficulty": "medium",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 13,
    "rows": [
      "########",
      "########",
      "########",
      "###.G.##",
      "##..#.##",
      "#..##.##",
      "..###.##",
      "^.....##"
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-fern",
    "title": "Fern",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 16,
    "rows": [
      "###.G.##",
      "###.#.##",
      "##..#.##",
      "#..##.##",
      "#.###.##",
      "..###.##",
      ".####.##",
      "^.....##"
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-gorse",
    "title": "Gorse",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 15,
    "rows": [
      ".......",
      "G......",
      "##.....",
      ".......",
      ".####..",
      ".......",
      "..>...."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-heath",
    "title": "Heath",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 16,
    "rows": [
      ".......",
      ".#...G.",
      ".#...##",
      ".#.....",
      ".####..",
      ".......",
      ".<....."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-iris",
    "title": "Iris",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 15,
    "rows": [
      "G......",
      ".......",
      ".#.....",
      ".#.....",
      ".####..",
      ".#.....",
      ".#..^.."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-juniper",
    "title": "Juniper",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 17,
    "rows": [
      "...G...",
      "###....",
      "####...",
      ".......",
      ".......",
      "..#####",
      "...^..."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-kelp",
    "title": "Kelp",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT"
    ],
    "maxCommands": 16,
    "rows": [
      "......G.",
      "..######",
      "........",
      "...####.",
      "....#.#.",
      "....####",
      "....#.#.",
      "v...#.#."
    ],
    "hints": [
      "Plan the whole route before you add tiles."
    ]
  },
  {
    "slug": "daily-larch",
    "title": "Larch",
    "difficulty": "easy",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 5,
    "rows": [
      "######G",
      "#####..",
      "####..#",
      "###..##",
      "##..###",
      "#..####",
      ">.#####"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-moss",
    "title": "Moss",
    "difficulty": "easy",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 7,
    "rows": [
      "G#########",
      "....######",
      "###....###",
      "######...<"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-nettle",
    "title": "Nettle",
    "difficulty": "easy",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 7,
    "rows": [
      "######v",
      "######.",
      "####...",
      "####.##",
      "##...##",
      "##.####",
      "G..####"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-oak",
    "title": "Oak",
    "difficulty": "easy",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 7,
    "rows": [
      "######..G",
      "######.##",
      "####...##",
      "####.####",
      "##...####",
      "##.######",
      "...######",
      ".########",
      "^########"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-pine",
    "title": "Pine",
    "difficulty": "medium",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 9,
    "rows": [
      "v###",
      ".###",
      ".###",
      ".###",
      ".###",
      "..##",
      "#..#",
      "##..",
      "###.",
      "###.",
      "###G"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-quince",
    "title": "Quince",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 12,
    "rows": [
      "G...########",
      "###.########",
      "###...######",
      "#####.######",
      "#####...####",
      "#######.###v",
      "#######...#.",
      "#########.#.",
      "#########..."
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-reed",
    "title": "Reed",
    "difficulty": "medium",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 10,
    "rows": [
      "G########",
      ".########",
      ".########",
      ".########",
      "..#######",
      "#..######",
      "##..#####",
      "###..####",
      "####....<"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  },
  {
    "slug": "daily-sage",
    "title": "Sage",
    "difficulty": "hard",
    "commands": [
      "MOVE_FORWARD",
      "TURN_LEFT",
      "TURN_RIGHT",
      "REPEAT"
    ],
    "maxCommands": 12,
    "rows": [
      "...#######",
      ".#.#######",
      ".#...#####",
      ".###.#####",
      "^###...###",
      "######.###",
      "######...G"
    ],
    "hints": [
      "Look for the part that repeats, then say it once."
    ]
  }
] as const;
