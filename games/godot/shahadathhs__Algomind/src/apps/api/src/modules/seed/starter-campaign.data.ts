// The starter campaign: twenty worlds, forty-eight chapters, one hundred thirteen levels, in play order.
// Source of truth for the seed. Boards are text rows: `.` floor, `#` wall, `G` target, and `^ > v <`
// for the automaton and its facing. The JSON below is read by scripts/level-lab/cli.mjs (check), so
// it stays plain JSON: prettier must not reformat it.
//
// Every limit is at least the shortest program (the seed checks this with the solver and fails
// loudly otherwise). Every level offers all the movement commands (Move, Left, Right). World 3
// adds Repeat, and world 4 offers Repeat until in its place. World 1 and chapter "Budgets" allow
// exactly the shortest program; chapter "Detours" leaves a little slack. In worlds 3 and 4 every
// limit equals the loop par: the plain program is longer than the limit, so each level needs its
// loop (a test checks this). Worlds 5 (Decisions) and 6 (Wall follower) offer Repeat until and If;
// their levels carry the reference `solution` (the exact solver does not search If), the limit is
// that solution's slots, and the best program without If is at least 1.5 times the limit. World 7
// (Procedures) offers Repeat and Proc, carries the reference `solution` the same way, and the best
// program without Proc is at least 1.3 times the limit. World 8 (Debug) offers every tool and puts
// a broken program on the tape (`startProgram`); the level carries its fix as the reference
// `solution`, the start program must not already solve it, and the limit fits both programs. World 9
// (Generalize) offers every tool and gives each level 2 to 4 test boards (`extraBoards`, rows like
// `rows`): one program must solve them all, and the best program for the first board alone must
// fail on another board. World 13 (Patrol) gives each level 1 or 2 guards (`patrols`) that walk a fixed route
// by step number; the limit equals the shortest program found by the exact search over (cell, facing, step).
// World 14 (Keys) puts keys and doors on the board (`locks`): a door blocks until its key has been entered; the
// search adds the keys held to the state, and the last chapter adds a guard.
// World 15 (Delivery) puts crates and docks on the board (`deliveries`): the automaton carries one crate at a time,
// a crate is dropped by entering its dock, and the target counts once every crate is delivered; the search
// adds what is carried and what is delivered to the state. Its last chapter has a key and a guard.
// World 16 (Switches) puts switches and gates on the board (`switches`): entering a switch flips its gate every
// time, a gate may start open (`open`), and the search adds the switches flipped to the state. Its last chapter has a
// crate and a guard.
// World 17 (Ice and belts) puts ice (`ice`) and belts (`belts`) on the board: a move onto ice slides on while the way is
// free, a belt carries the automaton one cell after an action; the search moves through the same World code as the
// simulator. Its last chapter adds a guard.
// World 18 (Teleporters) puts teleporter pairs on the board (`teleports`): entering one end puts the automaton on the
// other end in the same step. Its last chapter adds a guard.
// World 19 (Recursion) lists the mechanic `recursion`: a procedure may CALL (itself or another procedure), and a CALL
// may carry a sensor (`when`), which is the base case. Levels carry the reference `solution`; the limit is its slots, and
// the best program without PROC is at least 1.3 times the limit.
// World 20 (Capstone) adds no mechanic: each level puts two to four tiles of worlds 13 to 18 on one board (five have a
// guard), offers movement only, and its limit is the exact par from the search; every tile must matter (a test
// removes each one and the par must drop).

// prettier-ignore
export const CAMPAIGN = {
  "worlds": [
    {
      "title": "Basics",
      "description": "Instructions run in order, one after another.",
      "chapters": [
        {
          "title": "Moves",
          "levels": [
            {
              "slug": "first-step",
              "title": "First step",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 2,
              "rows": [
                ".....",
                ".....",
                "..G..",
                ".....",
                "..^.."
              ],
              "hints": [
                "Tap Move twice, then Run."
              ]
            },
            {
              "slug": "beside-the-wall",
              "title": "Beside the wall",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 4,
              "rows": [
                ".....",
                ".###.",
                "G...<",
                ".###.",
                "....."
              ],
              "hints": [
                "The walls on both sides are not in your way. Keep moving."
              ]
            }
          ]
        },
        {
          "title": "Turns",
          "levels": [
            {
              "slug": "first-turn",
              "title": "First turn",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 7,
              "rows": [
                ".....",
                "...G.",
                ".....",
                ".....",
                "^...."
              ],
              "hints": [
                "A turn changes the direction Move goes in.",
                "Move up first, then turn right."
              ]
            },
            {
              "slug": "turn-around",
              "title": "Turn around",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 5,
              "rows": [
                ".....",
                "..^..",
                ".....",
                ".....",
                "..G.."
              ],
              "hints": [
                "The target is behind you.",
                "Two turns make a half turn."
              ]
            },
            {
              "slug": "two-corners",
              "title": "Two corners",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "rows": [
                "....G",
                "####.",
                ".....",
                ".####",
                "^...."
              ],
              "hints": [
                "Each wall has one gap, on the opposite side."
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Routes",
      "description": "Look at the whole board, then choose a route.",
      "chapters": [
        {
          "title": "Detours",
          "levels": [
            {
              "slug": "around-the-wall",
              "title": "Around the wall",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 13,
              "rows": [
                "......",
                "......",
                "...G..",
                "...###",
                "......",
                ".....^"
              ],
              "hints": [
                "Go around the wall. The way around is longer than it looks."
              ]
            },
            {
              "slug": "dead-end",
              "title": "Dead end",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "rows": [
                ".......",
                "G#....#",
                ".#....#",
                ".#....#",
                "###...#",
                ".#....#",
                "....>.."
              ],
              "hints": [
                "One way looks open and leads nowhere. Check where it ends."
              ]
            },
            {
              "slug": "two-ways",
              "title": "Two ways",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 15,
              "rows": [
                "........",
                ".......#",
                "....G...",
                "........",
                "....####",
                "........",
                ".......#",
                ".......>"
              ],
              "hints": [
                "Two routes work. One needs fewer tiles."
              ]
            }
          ]
        },
        {
          "title": "Budgets",
          "levels": [
            {
              "slug": "fewer-turns",
              "title": "Fewer turns",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 12,
              "rows": [
                ".......",
                "...G...",
                ".......",
                "####...",
                ".......",
                ".#..##.",
                ".#..>.."
              ],
              "hints": [
                "Fewer cells is not always fewer tiles. Turns count as tiles."
              ]
            },
            {
              "slug": "gauntlet",
              "title": "Gauntlet",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "rows": [
                "........",
                "#.#.....",
                "#.#....G",
                "#.#.....",
                "#.######",
                "#.#.....",
                "..#####.",
                ">.....#."
              ],
              "hints": [
                "Work backward from the target."
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Loops",
      "description": "Say a pattern once and repeat it.",
      "chapters": [
        {
          "title": "Repeat",
          "levels": [
            {
              "slug": "say-it-once",
              "title": "Say it once",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 2,
              "rows": [
                ".....",
                "..G..",
                ".....",
                ".....",
                ".....",
                ".....",
                ".....",
                ".....",
                "..^.."
              ],
              "hints": [
                "Repeat runs the tiles inside it again and again.",
                "Put Move inside the loop, then set the rounds with plus and minus."
              ]
            },
            {
              "slug": "run-turn-run",
              "title": "Run, turn, run",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 5,
              "rows": [
                ".......",
                ".....G.",
                ".......",
                ".......",
                ".......",
                ".......",
                "^......"
              ],
              "hints": [
                "A loop can sit between other tiles.",
                "Tap End loop to go back to adding single tiles."
              ]
            },
            {
              "slug": "stairs",
              "title": "Stairs",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 5,
              "rows": [
                "#####G",
                "####..",
                "###..#",
                "##..##",
                "#..###",
                ">.####"
              ],
              "hints": [
                "Look for the part that repeats over and over."
              ]
            }
          ]
        },
        {
          "title": "Patterns",
          "levels": [
            {
              "slug": "run-and-climb",
              "title": "Run and climb",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 9,
              "rows": [
                "####v",
                "####.",
                "####.",
                "###..",
                "##..#",
                "#..##",
                "..###",
                ".####",
                ".####",
                ".####",
                "G####"
              ],
              "hints": [
                "Some moves come before the pattern. Add them before or after the loop."
              ]
            },
            {
              "slug": "climb-and-run",
              "title": "Climb and run",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 10,
              "rows": [
                "v#########",
                ".#########",
                ".#########",
                "...#######",
                "##.#######",
                "##...#####",
                "####.#####",
                "####...###",
                "######.###",
                "######...G"
              ],
              "hints": [
                "A loop needs only one pass of the pattern. The rounds do the rest."
              ]
            },
            {
              "slug": "final-climb",
              "title": "Final climb",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT"
              ],
              "maxCommands": 12,
              "rows": [
                "###>...",
                "######.",
                "####...",
                "####.##",
                "##...##",
                "##.####",
                "...####",
                ".######",
                ".######",
                "G######"
              ],
              "hints": [
                "Find the pattern, the rounds, and what comes after."
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Until",
      "description": "Run until something stops you.",
      "chapters": [
        {
          "title": "Run to the wall",
          "levels": [
            {
              "slug": "to-the-wall",
              "title": "To the wall",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL"
              ],
              "maxCommands": 2,
              "rows": [
                ".........",
                ">.......G",
                "........."
              ],
              "hints": [
                "Repeat until runs its tiles again and again, and stops when a wall is straight ahead.",
                "Put Move inside it. You do not need to count the cells."
              ]
            },
            {
              "slug": "any-distance",
              "title": "Any distance",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL"
              ],
              "maxCommands": 5,
              "rows": [
                ".....G",
                "......",
                "......",
                "......",
                "......",
                "......",
                "......",
                "^....."
              ],
              "hints": [
                "A loop ends when the way ahead is blocked. Then the program goes on to the next tile.",
                "Run to the wall, turn, then run to the next wall."
              ]
            },
            {
              "slug": "the-hall",
              "title": "The hall",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL"
              ],
              "maxCommands": 7,
              "rows": [
                "###########",
                "########..G",
                "########.##",
                ">........##",
                "###########"
              ],
              "hints": [
                "Each loop ends at a wall. Turn there and start the next loop.",
                "A loop can hold more than a move. Look at the last stretch."
              ]
            }
          ]
        },
        {
          "title": "Corridors",
          "levels": [
            {
              "slug": "steps-to-the-wall",
              "title": "Steps to the wall",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL"
              ],
              "maxCommands": 5,
              "rows": [
                "########",
                "######.G",
                "#####..#",
                "####..##",
                "###..###",
                "##..####",
                "#..#####",
                ">.######"
              ],
              "hints": [
                "The same four tiles climb every step. Put them inside one loop.",
                "The loop ends by itself at the top of the stairs."
              ]
            },
            {
              "slug": "round-and-in",
              "title": "Round and in",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL"
              ],
              "maxCommands": 14,
              "rows": [
                ".........",
                ".#######.",
                ".#G#####.",
                ".#.#####.",
                ".#.#####.",
                ".#.#####.",
                ".#.#####.",
                ".#.#####.",
                "^#......."
              ],
              "hints": [
                "Every side of the spiral is a run to a wall.",
                "Five runs, with a turn at each corner."
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Decisions",
      "description": "Choose by what you sense.",
      "chapters": [
        {
          "title": "Look",
          "levels": [
            {
              "slug": "look-ahead",
              "title": "Look ahead",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 4,
              "maxSteps": 100,
              "rows": [
                ".......",
                ".#####.",
                ".#..G#.",
                ".#.###.",
                ".#.###.",
                ".#.###.",
                "^#....."
              ],
              "hints": [
                "If asks a question about the cell ahead. Move when it is clear, turn when it is not.",
                "Put the whole decision inside Repeat until goal."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "left-hall",
              "title": "Left hall",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 4,
              "maxSteps": 150,
              "rows": [
                ".......",
                ".#####.",
                ".#...#.",
                ".#.#.#.",
                ".#G#.#.",
                ".###.#.",
                ".....#^"
              ],
              "hints": [
                "This hall turns left every time it ends. Move when the way is clear, turn left when it is not.",
                "The same question as before, with the other answer."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "first-door",
              "title": "First door",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 5,
              "maxSteps": 120,
              "rows": [
                "######G###",
                "######.###",
                "######.###",
                "######.###",
                ">........."
              ],
              "hints": [
                "Ask about the left side. A door on the left is where to turn.",
                "When the door is there, turn and step through it. Otherwise move."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_LEFT",
                      "then": [
                        {
                          "op": "TURN_LEFT"
                        },
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Both sides",
          "levels": [
            {
              "slug": "both-ways",
              "title": "Both ways",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 100,
              "rows": [
                "##......G##",
                "##.########",
                "##.....####",
                "######.####",
                "#......####",
                "#.#########",
                "#....######",
                "####.######",
                ".....######",
                ".##########",
                "^##########"
              ],
              "hints": [
                "The bends go both ways. Ask about the right side first, then about the way ahead.",
                "Turn right when the right side is clear. Otherwise move, or turn left."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "follow-the-bends",
              "title": "Follow the bends",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 220,
              "rows": [
                "####....###",
                "####.##.###",
                "####G##.###",
                "#######...#",
                "#########.#",
                "######....#",
                "######.####",
                "######.####",
                "####...####",
                "###..######",
                ">...#######"
              ],
              "hints": [
                "The corridor bends both ways, by different amounts. Ask about the right side first.",
                "Turn right when the right side is clear. Otherwise move, or turn left."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Wall follower",
      "description": "Keep a hand on the wall.",
      "chapters": [
        {
          "title": "Right hand",
          "levels": [
            {
              "slug": "small-maze",
              "title": "Small maze",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 110,
              "rows": [
                "G..#...",
                "##.#.#.",
                "...#.#.",
                ".#####.",
                ".#.....",
                ".#.###.",
                "...#>.."
              ],
              "hints": [
                "Keep a hand on the right wall and walk. It finds the way out of any maze like this.",
                "The two decisions from the last level are all you need."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "square-maze",
              "title": "Square maze",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 120,
              "rows": [
                ">....#...",
                "####.###.",
                "..G#...#.",
                ".#####.#.",
                ".#...#...",
                ".#.#.###.",
                "...#...#.",
                ".###.###.",
                "...#....."
              ],
              "hints": [
                "Keep a hand on the right wall and walk. It finds the way out of any maze like this.",
                "The two decisions from the last level are all you need."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "big-maze",
              "title": "Big maze",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 200,
              "rows": [
                "G#>........",
                ".#####.###.",
                ".....#...#.",
                "####.###.#.",
                "...#.#...#.",
                ".###.#.###.",
                "...#.#.#...",
                ".#.#.#.#.#.",
                ".#...#.#.#.",
                ".#######.#.",
                ".........#."
              ],
              "hints": [
                "Keep a hand on the right wall and walk. It finds the way out of any maze like this.",
                "The two decisions from the last level are all you need."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Other ways",
          "levels": [
            {
              "slug": "left-hand",
              "title": "Left hand",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 132,
              "rows": [
                "###########",
                "#G..#...#.#",
                "###.#.#.#.#",
                "#.#...#...#",
                "#.#######.#",
                "#...#...#.#",
                "#.#.#.#.#.#",
                "#^#...#...#",
                "###########"
              ],
              "hints": [
                "Keep the other hand on the wall. Ask about the left side first.",
                "Turn left when the left side is clear. Otherwise move, or turn right."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_LEFT",
                      "then": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "facing-away",
              "title": "Facing away",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 137,
              "rows": [
                "###########",
                "#G..#....^#",
                "###.#.#.###",
                "#...#.#...#",
                "#.#######.#",
                "#.#.....#.#",
                "#.#.###.#.#",
                "#...#.....#",
                "###########"
              ],
              "hints": [
                "The automaton starts facing a wall. The same rule still works from any start.",
                "Right side first, then the way ahead."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Procedures",
      "description": "Name a part and use it again.",
      "chapters": [
        {
          "title": "Name it",
          "levels": [
            {
              "slug": "first-part",
              "title": "First part",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 14,
              "maxSteps": 100,
              "rows": [
                "G#########",
                ".#####...#",
                "..#....#.#",
                "#...####..",
                "#########^"
              ],
              "hints": [
                "Find the part that comes back. Name it once, then call it where it belongs.",
                "Proc defines a part and Call runs it. A call costs one slot."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_LEFT"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "used-again",
              "title": "Used again",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 16,
              "maxSteps": 100,
              "rows": [
                "#######...#",
                "###.....#.#",
                "....#####.#",
                ".########..",
                "..########.",
                "#.########G",
                "#^#########"
              ],
              "hints": [
                "Find the part that comes back. Name it once, then call it where it belongs.",
                "Proc defines a part and Call runs it. A call costs one slot."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "part-with-a-loop",
              "title": "Part with a loop",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 12,
              "maxSteps": 100,
              "rows": [
                "##.....##",
                "#..###..#",
                "..#####..",
                ".#######.",
                "^#######.",
                "########.",
                "#######..",
                "######..#",
                "####G..##"
              ],
              "hints": [
                "Look for a part you can say with a loop, then name the whole part.",
                "A loop can stand inside a procedure."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "REPEAT",
                      "count": 3,
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_RIGHT"
                        },
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            }
          ]
        },
        {
          "title": "Parts",
          "levels": [
            {
              "slug": "loop-inside",
              "title": "Loop inside",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 14,
              "maxSteps": 100,
              "rows": [
                "G#########",
                "...#######",
                "##..######",
                "###.######",
                "###...####",
                "#####..###",
                "######.###",
                "######.###",
                "######...#",
                "########..",
                "#########^"
              ],
              "hints": [
                "Look for a part you can say with a loop, then name the whole part.",
                "A loop can stand inside a procedure."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": 2,
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_LEFT"
                        },
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_RIGHT"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "two-parts",
              "title": "Two parts",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 19,
              "maxSteps": 110,
              "rows": [
                "###.....####",
                "###.###..###",
                "##..####..##",
                "#..######...",
                "..#########.",
                "^#########..",
                "#########..#",
                "########..##",
                "########.###",
                "#######G.###"
              ],
              "hints": [
                "Two different parts come back. Give each its own name.",
                "The procedures are A and B. Define a part before you call it."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": 3,
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_RIGHT"
                        },
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "PROC",
                  "name": "B",
                  "body": [
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "B"
                },
                {
                  "op": "CALL",
                  "name": "B"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "longer-part",
              "title": "Longer part",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "PROC"
              ],
              "maxCommands": 20,
              "maxSteps": 110,
              "rows": [
                "######...###",
                "######.#..##",
                "####...##.##",
                "###..####...",
                "###.#######.",
                "#...######..",
                "..######^..#",
                ".###########",
                "G###########"
              ],
              "hints": [
                "Look for a part you can say with a loop, then name the whole part.",
                "A loop can stand inside a procedure."
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "REPEAT",
                      "count": 2,
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_LEFT"
                        },
                        {
                          "op": "MOVE_FORWARD"
                        },
                        {
                          "op": "TURN_RIGHT"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_LEFT"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_LEFT"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "MOVE_FORWARD"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Debug",
      "description": "The program is already on the tape. Find what is wrong with it.",
      "chapters": [
        {
          "title": "Counts and ends",
          "levels": [
            {
              "slug": "off-by-one",
              "title": "Off by one",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 2,
              "maxSteps": 120,
              "rows": [
                "#########",
                ">.......G",
                "#########"
              ],
              "hints": [
                "Run it and see where the automaton stops.",
                "The loop runs one round too few."
              ],
              "startProgram": [
                {
                  "op": "REPEAT",
                  "count": 7,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ],
              "solution": [
                {
                  "op": "REPEAT",
                  "count": 8,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "missing-turn",
              "title": "Missing turn",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 5,
              "maxSteps": 120,
              "rows": [
                "....G",
                ".....",
                ".....",
                ".....",
                "^...."
              ],
              "hints": [
                "Run it. The automaton reaches the wall and cannot go on.",
                "The route bends, and the program never turns."
              ],
              "startProgram": [
                {
                  "op": "REPEAT",
                  "count": 4,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "REPEAT",
                  "count": 4,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ],
              "solution": [
                {
                  "op": "REPEAT",
                  "count": 4,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "REPEAT",
                  "count": 4,
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "never-ends",
              "title": "Never ends",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 2,
              "maxSteps": 120,
              "rows": [
                "#######",
                "#.....#",
                ">.....G",
                "#.....#",
                "#######"
              ],
              "hints": [
                "Run it and watch: the automaton only turns on the spot.",
                "The loop runs until the goal, but nothing moves it there."
              ],
              "startProgram": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                }
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Branches and parts",
          "levels": [
            {
              "slug": "wrong-way-round",
              "title": "Wrong way round",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 4,
              "maxSteps": 150,
              "rows": [
                "#######",
                ".....G#",
                ".######",
                ".######",
                ".######",
                "^######"
              ],
              "hints": [
                "Run it. The automaton gets to the bend and turns the wrong way.",
                "Which way does the hall bend?"
              ],
              "startProgram": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "wrong-part",
              "title": "Wrong part",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 12,
              "maxSteps": 120,
              "rows": [
                ".....",
                ".....",
                ".....",
                "...G.",
                ".....",
                ".....",
                "^...."
              ],
              "hints": [
                "Part A is one step of the stairs. Which part does the program call?",
                "The program calls the part that only moves forward."
              ],
              "startProgram": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                },
                {
                  "op": "PROC",
                  "name": "B",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "REPEAT",
                  "count": 3,
                  "body": [
                    {
                      "op": "CALL",
                      "name": "B"
                    }
                  ]
                }
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                },
                {
                  "op": "PROC",
                  "name": "B",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "REPEAT",
                  "count": 3,
                  "body": [
                    {
                      "op": "CALL",
                      "name": "A"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Generalize",
      "description": "One program has to solve every board.",
      "chapters": [
        {
          "title": "Sizes",
          "levels": [
            {
              "slug": "any-length",
              "title": "Any length",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 2,
              "maxSteps": 100,
              "rows": [
                "###",
                ">G#",
                "###"
              ],
              "extraBoards": [
                [
                  "#######",
                  ">.....G",
                  "#######"
                ],
                [
                  "##########",
                  ">........G",
                  "##########"
                ]
              ],
              "hints": [
                "The same program has to solve every board. Do not count the cells.",
                "Run until the wall, whatever the length."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "BLOCKED",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "any-staircase",
              "title": "Any staircase",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 5,
              "maxSteps": 100,
              "rows": [
                "##G",
                "#..",
                ">.#"
              ],
              "extraBoards": [
                [
                  "####G",
                  "###..",
                  "##..#",
                  "#..##",
                  ">.###"
                ],
                [
                  "######G",
                  "#####..",
                  "####..#",
                  "###..##",
                  "##..###",
                  "#..####",
                  ">.#####"
                ]
              ],
              "hints": [
                "One flight of stairs is the same four moves again and again.",
                "Let the loop end by itself at the top."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "BLOCKED",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "any-corner",
              "title": "Any corner",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 5,
              "maxSteps": 100,
              "rows": [
                "##G",
                "##.",
                ">.."
              ],
              "extraBoards": [
                [
                  "######G",
                  "######.",
                  "######.",
                  ">......"
                ],
                [
                  "####G",
                  "####.",
                  "####.",
                  "####.",
                  "####.",
                  "####.",
                  "####.",
                  "####.",
                  ">...."
                ]
              ],
              "hints": [
                "Run to the wall, turn, run to the next wall. The lengths do not matter.",
                "Each board bends the same way."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "BLOCKED",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "TURN_LEFT"
                },
                {
                  "op": "REPEAT_UNTIL",
                  "until": "BLOCKED",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Shapes",
          "levels": [
            {
              "slug": "any-bend",
              "title": "Any bend",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 100,
              "rows": [
                "####G",
                "####.",
                "##...",
                "##.##",
                ">..##"
              ],
              "extraBoards": [
                [
                  ">....##",
                  "####.##",
                  "####.##",
                  "####.##",
                  "####..G"
                ],
                [
                  "#G####",
                  "#.####",
                  "#.####",
                  "#.....",
                  "#####.",
                  "#####^"
                ]
              ],
              "hints": [
                "The bends go different ways on every board. Ask the board, do not memorise it.",
                "Right side first, then the way ahead."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "any-maze",
              "title": "Any maze",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 120,
              "rows": [
                "G#>....",
                ".#####.",
                ".#...#.",
                ".#.#.#.",
                "...#.#.",
                "####.#.",
                "......."
              ],
              "extraBoards": [
                [
                  "G#.......",
                  ".#.#.###.",
                  ".#^#.#.#.",
                  ".###.#.#.",
                  "...#.#...",
                  "##.#.#.##",
                  ".....#..."
                ],
                [
                  ">....#...",
                  "####.###.",
                  "..G#...#.",
                  ".#####.#.",
                  ".#...#...",
                  ".#.#.###.",
                  "...#...#.",
                  ".###.###.",
                  "...#....."
                ]
              ],
              "hints": [
                "Keep a hand on the right wall. It works in every maze like these.",
                "Three boards, one program."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "every-board",
              "title": "Every board",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "IF",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 170,
              "rows": [
                "..G",
                "...",
                "^.."
              ],
              "extraBoards": [
                [
                  "#########",
                  ">.......G",
                  "#########"
                ],
                [
                  "G#.....#.",
                  ".###.#.#.",
                  ".#...#...",
                  ".#.#####.",
                  ".#.#v#...",
                  ".#.#.#.##",
                  "...#.#.#.",
                  "####.#.#.",
                  "........."
                ],
                [
                  "........",
                  ".######.",
                  ".#...G#.",
                  ".#.####.",
                  ".#.####.",
                  ".#.####.",
                  ".#.####.",
                  "^#......"
                ]
              ],
              "hints": [
                "Rooms, halls, mazes and spirals: the rule is the same.",
                "Every board has to reach its target with the one program."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Counters",
      "description": "A number that grows with every lap.",
      "chapters": [
        {
          "title": "Growing",
          "levels": [
            {
              "slug": "wider-steps",
              "title": "Wider steps",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 8,
              "maxSteps": 100,
              "rows": [
                "##########G",
                "######.....",
                "######.####",
                "###....####",
                "###.#######",
                "#...#######",
                "#.#########",
                ">.#########"
              ],
              "hints": [
                "Each step is one cell wider than the one before.",
                "Count up with Count after each step, and let Repeat read the count."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "growing-diagonal",
              "title": "Growing diagonal",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 8,
              "maxSteps": 100,
              "rows": [
                "G..######",
                "##.######",
                "##.######",
                "##.######",
                "##....###",
                "#####.###",
                "#####.###",
                "#####...#",
                "#######.#",
                "#######..",
                "########^"
              ],
              "hints": [
                "Both legs of each stair grow by one every time.",
                "A loop inside a loop is allowed here. Repeat can count with N."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "tall-steps",
              "title": "Tall steps",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 8,
              "maxSteps": 100,
              "rows": [
                "########v",
                "######...",
                "######.##",
                "####...##",
                "####.####",
                "####.####",
                "##...####",
                "##.######",
                "##.######",
                "##.######",
                "...######",
                "G########"
              ],
              "hints": [
                "The rise stays two cells while the run grows.",
                "Count up once per step, so the next run is longer."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Spirals",
          "levels": [
            {
              "slug": "small-spiral",
              "title": "Small spiral",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 9,
              "maxSteps": 110,
              "rows": [
                "##......",
                "##.####.",
                "##.#..#.",
                "G#.#^.#.",
                ".#.##.#.",
                ".#....#.",
                ".######.",
                "........"
              ],
              "hints": [
                "Each lap is wider than the last. Count up twice per lap.",
                "Walk N cells, turn, walk N cells, turn, then count up."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "INC"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "left-spiral",
              "title": "Left spiral",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 9,
              "maxSteps": 140,
              "rows": [
                "#########G",
                "#########.",
                "........#.",
                ".######.#.",
                ".#....#.#.",
                ".#.#>.#.#.",
                ".#.####.#.",
                ".#......#.",
                ".########.",
                ".........."
              ],
              "hints": [
                "The same spiral, turning the other way.",
                "Two counts per lap keep a wall between the laps."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "INC"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            },
            {
              "slug": "big-spiral",
              "title": "Big spiral",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT",
                "REPEAT_UNTIL",
                "INC"
              ],
              "requires": [
                "nested_loops"
              ],
              "maxCommands": 9,
              "maxSteps": 170,
              "rows": [
                "............",
                ".##########.",
                ".#........#G",
                ".#.######.##",
                ".#.#....#.##",
                ".#.#.<#.#.##",
                ".#.####.#.##",
                ".#......#.##",
                ".########.##",
                "..........##"
              ],
              "hints": [
                "A big spiral is still the same short program.",
                "Let the outer loop run until the goal."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "REPEAT",
                      "count": "N",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "INC"
                    },
                    {
                      "op": "INC"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Memory",
      "description": "Leave a mark so you never walk in circles.",
      "chapters": [
        {
          "title": "Breadcrumbs",
          "levels": [
            {
              "slug": "first-loop",
              "title": "First loop",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 200,
              "rows": [
                "v#.....",
                ".#.#.##",
                ".#.#...",
                ".#.#.#.",
                "...#G#.",
                "##.###.",
                "......."
              ],
              "extraBoards": [
                [
                  "v#.....",
                  ".#.####",
                  ".#.....",
                  ".#####.",
                  "....G#.",
                  "#.##.#.",
                  "......."
                ]
              ],
              "hints": [
                "The maze has a loop, so a hand on the wall goes round for ever.",
                "Drop a breadcrumb in each cell and step only on cells that have none."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "three-mazes",
              "title": "Three mazes",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 370,
              "rows": [
                ">..#.....",
                "##.#.#.#.",
                ".....#...",
                ".#####.#.",
                ".....#.#.",
                "####.#.#.",
                ".#...G.#.",
                ".#.###.#.",
                ".......#."
              ],
              "extraBoards": [
                [
                  ">......",
                  "#.####.",
                  ".....G.",
                  ".######",
                  "...#...",
                  "##.###.",
                  "......."
                ],
                [
                  ">........",
                  "##..####.",
                  ".....#..G",
                  ".###.#.##",
                  "...#.#.#.",
                  "##.#.#.#.",
                  "...#....."
                ]
              ],
              "hints": [
                "Dead ends cost steps, not slots.",
                "The breadcrumb always points back along the way you came."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "long-halls",
              "title": "Long halls",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 360,
              "rows": [
                "v#.........",
                ".#.#####G#.",
                ".......#.#.",
                "######.###.",
                ".#...#.#...",
                ".#...#.#...",
                "...#.....#."
              ],
              "extraBoards": [
                [
                  ">....#...",
                  "####.#.#.",
                  "...#...#.",
                  ".#.#.###.",
                  ".#.#...G.",
                  "##.##.##.",
                  ".........",
                  ".#######.",
                  "........."
                ]
              ],
              "hints": [
                "Look ahead for a fresh cell before anything else.",
                "Long halls are just more of the same."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Dead ends",
          "levels": [
            {
              "slug": "many-dead-ends",
              "title": "Many dead ends",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 440,
              "rows": [
                ">..........",
                "#.####.###.",
                ".....#.....",
                ".#.###.####",
                ".#...#.....",
                ".###.#####.",
                ".#.#...#...",
                ".#.#.#.G.##",
                ".....#....."
              ],
              "extraBoards": [
                [
                  ">..#...",
                  "##.#.#.",
                  "...#.#.",
                  ".#.###.",
                  ".#..G#.",
                  ".###.#.",
                  "......."
                ],
                [
                  ">........",
                  "####.###.",
                  "......G#.",
                  ".##.####.",
                  ".#...#...",
                  ".#.#.#.##",
                  "...#....."
                ]
              ],
              "hints": [
                "Every dead end is visited once.",
                "Back out of a dead end by following the breadcrumb."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "large-mazes",
              "title": "Large mazes",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 390,
              "rows": [
                ">........#.",
                "########.#.",
                ".....#...#.",
                ".##.##.###.",
                ".#.........",
                ".#.#######.",
                ".....#.....",
                ".###.##G.#.",
                ".........#."
              ],
              "extraBoards": [
                [
                  "v#...#.....",
                  ".###...###.",
                  "...#...#...",
                  "##.###.#.#.",
                  ".#...G.#.#.",
                  ".###.#.#.#.",
                  "...#.#.....",
                  ".#.#.###.#.",
                  ".#.......#."
                ],
                [
                  "v#...#...",
                  ".#.###.#.",
                  ".#.....#.",
                  ".#######.",
                  ".......G.",
                  "###.###..",
                  ".....#...",
                  ".#.#.#.##",
                  "...#....."
                ]
              ],
              "hints": [
                "A bigger maze changes the steps, not the program.",
                "If it feels slow, it is still finishing."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "slug": "tangle",
              "title": "Tangle",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF",
                "MARK"
              ],
              "maxCommands": 21,
              "maxSteps": 460,
              "rows": [
                ">....#...#.",
                "#.##.#.#.#.",
                "...#.......",
                "##.#######.",
                ".........#.",
                ".#########.",
                ".......#...",
                ".#####.G.##",
                ".#...#...#.",
                ".###.#.#...",
                ".....#....."
              ],
              "extraBoards": [
                [
                  ">..#.....",
                  "##.#.###.",
                  ".......#.",
                  ".####..#.",
                  ".#...G.#.",
                  ".#.#####.",
                  ".#.....#.",
                  ".#.###.#.",
                  "...#....."
                ],
                [
                  "v#.........",
                  ".###.###..#",
                  ".......#...",
                  "###.##G###.",
                  ".....#...#.",
                  ".###.###.#.",
                  "...#......."
                ]
              ],
              "hints": [
                "The goal can be anywhere in the maze.",
                "The search reaches every cell it can."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "MARK"
                    },
                    {
                      "op": "IF",
                      "when": "FRESH_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "IF",
                          "when": "FRESH_RIGHT",
                          "then": [
                            {
                              "op": "TURN_RIGHT"
                            },
                            {
                              "op": "MOVE_FORWARD"
                            }
                          ],
                          "else": [
                            {
                              "op": "IF",
                              "when": "FRESH_LEFT",
                              "then": [
                                {
                                  "op": "TURN_LEFT"
                                },
                                {
                                  "op": "MOVE_FORWARD"
                                }
                              ],
                              "else": [
                                {
                                  "op": "IF",
                                  "when": "BACK_AHEAD",
                                  "then": [
                                    {
                                      "op": "MOVE_FORWARD"
                                    }
                                  ],
                                  "else": [
                                    {
                                      "op": "IF",
                                      "when": "BACK_RIGHT",
                                      "then": [
                                        {
                                          "op": "TURN_RIGHT"
                                        },
                                        {
                                          "op": "MOVE_FORWARD"
                                        }
                                      ],
                                      "else": [
                                        {
                                          "op": "IF",
                                          "when": "BACK_LEFT",
                                          "then": [
                                            {
                                              "op": "TURN_LEFT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ],
                                          "else": [
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "TURN_RIGHT"
                                            },
                                            {
                                              "op": "MOVE_FORWARD"
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Sweep",
      "description": "Visit every cell, and waste no steps.",
      "chapters": [
        {
          "title": "Rooms",
          "levels": [
            {
              "slug": "small-room",
              "title": "Small room",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 11,
              "maxSteps": 22,
              "rows": [
                ">....",
                ".....",
                "....."
              ],
              "hints": [
                "Visit every cell. There is no target to reach.",
                "Run to the wall, step over, run back. Keep going until every cell is done."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                }
              ],
              "requires": [
                "nested_loops"
              ]
            },
            {
              "slug": "big-room",
              "title": "Big room",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 11,
              "maxSteps": 129,
              "rows": [
                "...........",
                "...........",
                "...........",
                "...........",
                "...........",
                "...........",
                "...........",
                "^.........."
              ],
              "hints": [
                "Every row is the same move. Only the number of rows changes.",
                "A tight step limit means no wandering."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                }
              ],
              "requires": [
                "nested_loops"
              ]
            }
          ]
        },
        {
          "title": "Halls",
          "levels": [
            {
              "slug": "comb",
              "title": "Comb",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 11,
              "maxSteps": 72,
              "rows": [
                ">......",
                ".######",
                ".......",
                ".######",
                ".......",
                ".######",
                "......."
              ],
              "hints": [
                "Each tooth is a dead end. Walk it to the end and back.",
                "The spine on the left joins the teeth."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "TURN_RIGHT"
                    },
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "TURN_LEFT"
                    }
                  ]
                }
              ],
              "requires": [
                "nested_loops"
              ]
            },
            {
              "slug": "spiral-hall",
              "title": "Spiral hall",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 4,
              "maxSteps": 96,
              "rows": [
                ">..........",
                "##########.",
                ".........#.",
                ".#######.#.",
                ".#.....#.#.",
                ".#.###.#.#.",
                ".#.#...#.#.",
                ".#.#####.#.",
                ".#.......#.",
                ".#########.",
                "..........."
              ],
              "hints": [
                "The hall bends the same way every time.",
                "Run until the wall, turn, repeat."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "REPEAT_UNTIL",
                      "until": "BLOCKED",
                      "body": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ]
                    },
                    {
                      "op": "TURN_RIGHT"
                    }
                  ]
                }
              ],
              "requires": [
                "nested_loops"
              ]
            },
            {
              "slug": "maze-sweep",
              "title": "Maze sweep",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "REPEAT_UNTIL",
                "IF"
              ],
              "maxCommands": 6,
              "maxSteps": 130,
              "rows": [
                ">....#...",
                "####.###.",
                "...#...#.",
                ".#####.#.",
                ".#...#...",
                ".#.#.###.",
                "...#...#.",
                ".###.###.",
                "...#....."
              ],
              "hints": [
                "Visit every cell of the maze, dead ends too.",
                "A hand on the right wall passes every cell of a maze like this."
              ],
              "solution": [
                {
                  "op": "REPEAT_UNTIL",
                  "until": "GOAL",
                  "body": [
                    {
                      "op": "IF",
                      "when": "CLEAR_RIGHT",
                      "then": [
                        {
                          "op": "TURN_RIGHT"
                        }
                      ],
                      "else": []
                    },
                    {
                      "op": "IF",
                      "when": "CLEAR_AHEAD",
                      "then": [
                        {
                          "op": "MOVE_FORWARD"
                        }
                      ],
                      "else": [
                        {
                          "op": "TURN_LEFT"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Patrol",
      "description": "A guard walks a fixed route. Each action is one step, and the guard moves with it.",
      "chapters": [
        {
          "title": "Dodge",
          "levels": [
            {
              "slug": "first-guard",
              "title": "First guard",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 8,
              "maxSteps": 120,
              "rows": [
                ">.....",
                "......",
                "....G."
              ],
              "hints": [
                "Run it. The guard moves one cell every time the automaton acts.",
                "Go around the guard, not through it."
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      2,
                      0
                    ],
                    [
                      3,
                      0
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "cross-the-beat",
              "title": "Cross the beat",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 11,
              "maxSteps": 120,
              "rows": [
                ".......",
                ">.....G",
                "......."
              ],
              "hints": [
                "The guard crosses the whole column and comes back.",
                "Take the way past its ends."
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      3,
                      0
                    ],
                    [
                      3,
                      1
                    ],
                    [
                      3,
                      2
                    ]
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Rings",
          "levels": [
            {
              "slug": "wait-for-it",
              "title": "Wait for it",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 7,
              "maxSteps": 120,
              "rows": [
                "......",
                ">....G",
                "......"
              ],
              "hints": [
                "The guard walks a ring: right, down, left, up.",
                "A turn is a step too. Turning left then right is a wait of two steps."
              ],
              "patrols": [
                {
                  "pattern": "loop",
                  "cells": [
                    [
                      2,
                      0
                    ],
                    [
                      3,
                      0
                    ],
                    [
                      3,
                      1
                    ],
                    [
                      2,
                      1
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "gate-keeper",
              "title": "Gate keeper",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 13,
              "maxSteps": 120,
              "rows": [
                ">.....",
                "#.###.",
                "...#..",
                "......",
                "..#..G"
              ],
              "hints": [
                "The guard stands where the right-hand passage meets the room.",
                "Reach the passage when the guard is at the other end."
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      5,
                      1
                    ],
                    [
                      5,
                      2
                    ],
                    [
                      5,
                      3
                    ]
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Two guards",
          "levels": [
            {
              "slug": "two-beats",
              "title": "Two beats",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 14,
              "maxSteps": 140,
              "rows": [
                ">.....",
                "#.###.",
                "...#..",
                "......",
                "#.#..G"
              ],
              "hints": [
                "Each guard has its own rhythm.",
                "A route that is safe from one may meet the other."
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      1,
                      0
                    ],
                    [
                      2,
                      0
                    ],
                    [
                      3,
                      0
                    ]
                  ]
                },
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      0,
                      3
                    ],
                    [
                      1,
                      3
                    ],
                    [
                      2,
                      3
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "crossing-paths",
              "title": "Crossing paths",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 18,
              "maxSteps": 160,
              "rows": [
                ">..#...",
                "...#...",
                "...#...",
                "......G"
              ],
              "hints": [
                "The guard in the ring moves every step, even while the automaton turns.",
                "Count steps, not cells."
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      1,
                      0
                    ],
                    [
                      1,
                      1
                    ]
                  ]
                },
                {
                  "pattern": "loop",
                  "cells": [
                    [
                      4,
                      2
                    ],
                    [
                      5,
                      2
                    ],
                    [
                      5,
                      3
                    ],
                    [
                      4,
                      3
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Keys",
      "description": "A door stays shut until the automaton has taken its key. Plan the order.",
      "chapters": [
        {
          "title": "First keys",
          "levels": [
            {
              "slug": "first-key",
              "title": "First key",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "maxSteps": 120,
              "rows": [
                "..#..",
                ">...G",
                "..#.."
              ],
              "hints": [
                "The door in the gap is shut. Run it and see where it stops.",
                "Take the key first. Entering its cell picks it up."
              ],
              "locks": [
                {
                  "key": [
                    0,
                    0
                  ],
                  "door": [
                    2,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "side-room",
              "title": "Side room",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 11,
              "maxSteps": 120,
              "rows": [
                "...#..",
                ">....G",
                "...#.."
              ],
              "hints": [
                "A key opens one door and stays held for the rest of the run.",
                "The key lies off the straight way."
              ],
              "locks": [
                {
                  "key": [
                    0,
                    2
                  ],
                  "door": [
                    3,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Two doors",
          "levels": [
            {
              "slug": "two-doors",
              "title": "Two doors",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 14,
              "maxSteps": 120,
              "rows": [
                "..#.#.G",
                ">......",
                "..#.#.."
              ],
              "hints": [
                "Each key opens only its own door.",
                "The second key lies between the doors."
              ],
              "locks": [
                {
                  "key": [
                    1,
                    2
                  ],
                  "door": [
                    2,
                    1
                  ]
                },
                {
                  "key": [
                    3,
                    1
                  ],
                  "door": [
                    4,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "maze-gate",
              "title": "Maze gate",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 15,
              "maxSteps": 120,
              "rows": [
                "#.#.###",
                "#.#.#.G",
                ">.....#",
                "#...#.."
              ],
              "hints": [
                "The door is in the corridor and the key is in the dead end above it.",
                "Go in, turn round, and come out with the key."
              ],
              "locks": [
                {
                  "key": [
                    1,
                    0
                  ],
                  "door": [
                    2,
                    2
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Guarded",
          "levels": [
            {
              "slug": "guarded-key",
              "title": "Guarded key",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 17,
              "maxSteps": 120,
              "rows": [
                "...#...",
                ">.....G",
                "...#..."
              ],
              "hints": [
                "A guard walks the column past the door.",
                "Take the key, then time the way through."
              ],
              "locks": [
                {
                  "key": [
                    1,
                    2
                  ],
                  "door": [
                    3,
                    1
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      5,
                      0
                    ],
                    [
                      5,
                      1
                    ],
                    [
                      5,
                      2
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "keys-and-a-guard",
              "title": "Keys and a guard",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 140,
              "rows": [
                "..#.#.G",
                ">......",
                "..#.#.#"
              ],
              "hints": [
                "The guard walks near the first key.",
                "Count steps: a turn is a step too."
              ],
              "locks": [
                {
                  "key": [
                    1,
                    2
                  ],
                  "door": [
                    2,
                    1
                  ]
                },
                {
                  "key": [
                    3,
                    1
                  ],
                  "door": [
                    4,
                    1
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      0,
                      0
                    ],
                    [
                      1,
                      0
                    ],
                    [
                      1,
                      1
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Delivery",
      "description": "Pick up a crate by walking onto it, then drop it on the corner marks. The target counts only after every delivery.",
      "chapters": [
        {
          "title": "First parcels",
          "levels": [
            {
              "slug": "first-parcel",
              "title": "First parcel",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 9,
              "maxSteps": 120,
              "rows": [
                "#.#..",
                ">...G",
                "..#.."
              ],
              "hints": [
                "Walk onto the crate to pick it up. It rides with the automaton.",
                "Drop it by walking onto the corner marks. Then the target counts."
              ],
              "deliveries": [
                {
                  "item": [
                    1,
                    1
                  ],
                  "dock": [
                    3,
                    0
                  ]
                }
              ]
            },
            {
              "slug": "behind-the-start",
              "title": "Behind the start",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "maxSteps": 120,
              "rows": [
                "...#.",
                ">...G",
                "...#."
              ],
              "hints": [
                "Reaching the target with the crate undelivered ends the run.",
                "The crate is behind the automaton."
              ],
              "deliveries": [
                {
                  "item": [
                    0,
                    0
                  ],
                  "dock": [
                    3,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Two parcels",
          "levels": [
            {
              "slug": "two-parcels",
              "title": "Two parcels",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 14,
              "maxSteps": 120,
              "rows": [
                "#..#.",
                ">...G",
                "#...."
              ],
              "hints": [
                "Each crate goes to its own corner marks.",
                "Hands hold one crate: drop the first before taking the second."
              ],
              "deliveries": [
                {
                  "item": [
                    1,
                    0
                  ],
                  "dock": [
                    1,
                    2
                  ]
                },
                {
                  "item": [
                    2,
                    2
                  ],
                  "dock": [
                    2,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "full-hands",
              "title": "Full hands",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 120,
              "rows": [
                "..#...",
                ">....G",
                "..#..."
              ],
              "hints": [
                "A crate walked over while carrying another stays where it lies.",
                "Deliver one, then come back for the other."
              ],
              "deliveries": [
                {
                  "item": [
                    1,
                    1
                  ],
                  "dock": [
                    4,
                    2
                  ]
                },
                {
                  "item": [
                    3,
                    1
                  ],
                  "dock": [
                    4,
                    0
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "In the way",
          "levels": [
            {
              "slug": "behind-the-door",
              "title": "Behind the door",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 15,
              "maxSteps": 120,
              "rows": [
                "#.#..",
                ">...G",
                "#.#.."
              ],
              "hints": [
                "The crate lies behind the door, and the key is off the straight way.",
                "Take the key, open the door, then drop the crate on the corner marks before the target."
              ],
              "deliveries": [
                {
                  "item": [
                    3,
                    1
                  ],
                  "dock": [
                    3,
                    0
                  ]
                }
              ],
              "locks": [
                {
                  "key": [
                    1,
                    0
                  ],
                  "door": [
                    2,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "guarded-parcel",
              "title": "Guarded parcel",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 15,
              "maxSteps": 120,
              "rows": [
                "...#..",
                ">....G",
                "...#.#"
              ],
              "hints": [
                "The guard walks the column next to the crate.",
                "Count the guard's steps. A turn in place also takes a step."
              ],
              "deliveries": [
                {
                  "item": [
                    0,
                    0
                  ],
                  "dock": [
                    2,
                    1
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      1,
                      0
                    ],
                    [
                      1,
                      1
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Switches",
      "description": "A switch flips its gate every time it is entered. Count the passes.",
      "chapters": [
        {
          "title": "First switches",
          "levels": [
            {
              "slug": "first-switch",
              "title": "First switch",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "maxSteps": 120,
              "rows": [
                "#.##.",
                ">...G",
                "#.##."
              ],
              "hints": [
                "The gate is shut. Run it and see where it stops.",
                "Step on the switch to open the gate. Stepping on it again shuts it."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    0
                  ],
                  "gate": [
                    2,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "twice-over",
              "title": "Twice over",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "maxSteps": 120,
              "rows": [
                ".#...",
                ">...G",
                ".#..."
              ],
              "hints": [
                "The gate starts open, and the switch lies on the only way in.",
                "The switch flips every time it is entered. Enter it twice."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    1
                  ],
                  "gate": [
                    2,
                    1
                  ],
                  "open": true
                }
              ]
            }
          ]
        },
        {
          "title": "Two gates",
          "levels": [
            {
              "slug": "two-gates",
              "title": "Two gates",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 14,
              "maxSteps": 120,
              "rows": [
                "#.#.#",
                ">...G",
                "#.#.#"
              ],
              "hints": [
                "Each switch works its own gate.",
                "One switch lies on the way and flips its gate as you pass."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    0
                  ],
                  "gate": [
                    3,
                    1
                  ]
                },
                {
                  "switch": [
                    1,
                    1
                  ],
                  "gate": [
                    2,
                    1
                  ]
                }
              ]
            },
            {
              "slug": "flip-flop",
              "title": "Flip flop",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 120,
              "rows": [
                ".#.#.",
                ">...G",
                ".#.#."
              ],
              "hints": [
                "A switch on the way can shut a gate that was open.",
                "Count how many times each switch is entered."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    1
                  ],
                  "gate": [
                    2,
                    1
                  ],
                  "open": true
                },
                {
                  "switch": [
                    2,
                    0
                  ],
                  "gate": [
                    3,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "In the way",
          "levels": [
            {
              "slug": "gate-and-crate",
              "title": "Gate and crate",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 120,
              "rows": [
                "..##.",
                ">...G",
                "..##."
              ],
              "hints": [
                "The switch lies on the way there and on the way back.",
                "Each pass flips the gate. Count the passes."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    1
                  ],
                  "gate": [
                    2,
                    1
                  ]
                }
              ],
              "deliveries": [
                {
                  "item": [
                    3,
                    1
                  ],
                  "dock": [
                    1,
                    0
                  ]
                }
              ]
            },
            {
              "slug": "gate-and-guard",
              "title": "Gate and guard",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 120,
              "rows": [
                "#.#...",
                ">....G",
                "..#..."
              ],
              "hints": [
                "The guard walks the corridor beyond the gate.",
                "Open the gate early, then time the last stretch."
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    0
                  ],
                  "gate": [
                    2,
                    1
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      4,
                      1
                    ],
                    [
                      4,
                      2
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Ice and belts",
      "description": "Ice keeps the automaton sliding and belts carry it on. Work out where each action leaves it.",
      "chapters": [
        {
          "title": "Ice",
          "levels": [
            {
              "slug": "first-slide",
              "title": "First slide",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 3,
              "maxSteps": 120,
              "rows": [
                "....G..",
                ">....#.",
                "......."
              ],
              "hints": [
                "A move onto ice slides on: the automaton stops at a wall or on the first cell that is not ice.",
                "Let the ice carry you to the wall, then turn."
              ],
              "ice": [
                [
                  1,
                  1
                ],
                [
                  2,
                  1
                ],
                [
                  3,
                  1
                ],
                [
                  4,
                  1
                ]
              ]
            },
            {
              "slug": "three-ice-cells",
              "title": "Three ice cells",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 8,
              "maxSteps": 120,
              "rows": [
                "..##...",
                ">......",
                ".#G....",
                "...#..."
              ],
              "hints": [
                "A slide ends past the ice, on the first cell that is not ice.",
                "Plan the turn from where the slide stops, not from where it starts."
              ],
              "ice": [
                [
                  2,
                  1
                ],
                [
                  3,
                  1
                ],
                [
                  4,
                  1
                ]
              ]
            }
          ]
        },
        {
          "title": "Belts",
          "levels": [
            {
              "slug": "pushed-aside",
              "title": "Pushed aside",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 10,
              "maxSteps": 120,
              "rows": [
                "....#..",
                ".......",
                "..#..#.",
                ">.G..#."
              ],
              "hints": [
                "A belt carries the automaton one cell after the action that ends on it.",
                "A turn in place on a belt is carried too."
              ],
              "belts": [
                {
                  "cell": [
                    1,
                    2
                  ],
                  "direction": "north"
                },
                {
                  "cell": [
                    1,
                    3
                  ],
                  "direction": "north"
                }
              ]
            },
            {
              "slug": "belt-line",
              "title": "Belt line",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 8,
              "maxSteps": 120,
              "rows": [
                "#..##..",
                "#......",
                ">.G.#..",
                "......#"
              ],
              "hints": [
                "Belts act after every action, so a move can end a cell further on.",
                "Follow one action at a time: where it leaves you, then where the belt takes you."
              ],
              "belts": [
                {
                  "cell": [
                    1,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    2,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    3,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    1,
                    2
                  ],
                  "direction": "west"
                }
              ]
            }
          ]
        },
        {
          "title": "Together",
          "levels": [
            {
              "slug": "ice-and-belts",
              "title": "Ice and belts",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 13,
              "maxSteps": 120,
              "rows": [
                ".G.....",
                "#.....#",
                ">.#....",
                "......."
              ],
              "hints": [
                "A belt does not start a slide. Only a move onto ice does.",
                "The top row is ice, and the belts below carry you toward it."
              ],
              "ice": [
                [
                  3,
                  0
                ],
                [
                  4,
                  0
                ],
                [
                  5,
                  0
                ],
                [
                  6,
                  0
                ]
              ],
              "belts": [
                {
                  "cell": [
                    1,
                    1
                  ],
                  "direction": "south"
                },
                {
                  "cell": [
                    4,
                    1
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    5,
                    1
                  ],
                  "direction": "east"
                }
              ]
            },
            {
              "slug": "belts-and-a-guard",
              "title": "Belts and a guard",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 16,
              "maxSteps": 120,
              "rows": [
                "#..##..",
                "#......",
                ">.G.#..",
                "......."
              ],
              "hints": [
                "The guard walks the two cells beside the goal.",
                "A turn in place also takes a step, and a belt may carry you into the guard."
              ],
              "belts": [
                {
                  "cell": [
                    1,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    2,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    3,
                    3
                  ],
                  "direction": "east"
                },
                {
                  "cell": [
                    1,
                    2
                  ],
                  "direction": "west"
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      3,
                      1
                    ],
                    [
                      3,
                      2
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Teleporters",
      "description": "Entering one end of a pair puts the automaton on the other end, facing the same way. Plan the shortcut.",
      "chapters": [
        {
          "title": "First pairs",
          "levels": [
            {
              "slug": "first-portal",
              "title": "First portal",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 4,
              "maxSteps": 120,
              "rows": [
                ">..##G.",
                ".....#.",
                "......."
              ],
              "hints": [
                "Entering one end of a pair puts the automaton on the other end, in the same step.",
                "It arrives facing the same way. Turn after arriving."
              ],
              "teleports": [
                {
                  "a": [
                    6,
                    0
                  ],
                  "b": [
                    1,
                    0
                  ]
                }
              ]
            },
            {
              "slug": "far-corner",
              "title": "Far corner",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 5,
              "maxSteps": 120,
              "rows": [
                "#...#G.",
                ">.#.#..",
                ".##...."
              ],
              "hints": [
                "The pair works both ways.",
                "Look at which way you face when you arrive."
              ],
              "teleports": [
                {
                  "a": [
                    1,
                    1
                  ],
                  "b": [
                    6,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Two pairs",
          "levels": [
            {
              "slug": "two-pairs",
              "title": "Two pairs",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 8,
              "maxSteps": 120,
              "rows": [
                ">.#.#..",
                "....#.G",
                ".#...#.",
                "...#..."
              ],
              "hints": [
                "Each end leads only to the other end of its own pair.",
                "Arriving on a pair does not send you back."
              ],
              "teleports": [
                {
                  "a": [
                    5,
                    1
                  ],
                  "b": [
                    2,
                    3
                  ]
                },
                {
                  "a": [
                    5,
                    3
                  ],
                  "b": [
                    4,
                    3
                  ]
                }
              ]
            },
            {
              "slug": "hop-and-walk",
              "title": "Hop and walk",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 8,
              "maxSteps": 120,
              "rows": [
                "..#.#G.",
                "...#...",
                ">##..#.",
                "....##."
              ],
              "hints": [
                "One pair carries you across the wall. The other is a detour.",
                "Walk to the second pair from where the first one leaves you."
              ],
              "teleports": [
                {
                  "a": [
                    3,
                    2
                  ],
                  "b": [
                    0,
                    3
                  ]
                },
                {
                  "a": [
                    1,
                    1
                  ],
                  "b": [
                    6,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "With a guard",
          "levels": [
            {
              "slug": "guarded-portal",
              "title": "Guarded portal",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 13,
              "maxSteps": 120,
              "rows": [
                ">...#..",
                "...#...",
                "...#...",
                ".....#G"
              ],
              "hints": [
                "The guard walks beside the goal.",
                "Arriving on a cell the guard reaches in the same step is a hit."
              ],
              "teleports": [
                {
                  "a": [
                    0,
                    1
                  ],
                  "b": [
                    5,
                    0
                  ]
                },
                {
                  "a": [
                    2,
                    1
                  ],
                  "b": [
                    0,
                    2
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      5,
                      2
                    ],
                    [
                      6,
                      2
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Recursion",
      "description": "A procedure can call itself. Give the call a condition, and it stops when the condition is false.",
      "chapters": [
        {
          "title": "Calling itself",
          "levels": [
            {
              "slug": "long-hall",
              "title": "Long hall",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "PROC"
              ],
              "maxCommands": 4,
              "maxSteps": 200,
              "rows": [
                "............",
                ">..........G",
                "............"
              ],
              "hints": [
                "A procedure can call itself. Give that call a condition, and it stops when the condition is false.",
                "Move once, then call the procedure again while the way ahead is clear."
              ],
              "requires": [
                "recursion"
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_AHEAD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "hall-and-turn",
              "title": "Hall and turn",
              "difficulty": "easy",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 200,
              "rows": [
                "...........G",
                ">...........",
                "............"
              ],
              "hints": [
                "The same procedure can be called twice, with a turn between.",
                "The call inside it stops at the wall."
              ],
              "requires": [
                "recursion"
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_AHEAD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_LEFT"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            }
          ]
        },
        {
          "title": "Conditions",
          "levels": [
            {
              "slug": "right-and-ahead",
              "title": "Right and ahead",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 200,
              "rows": [
                ">...........",
                "...........#",
                "..........G."
              ],
              "hints": [
                "The call in a procedure can look ahead, left or right.",
                "Try a call that looks right, then a turn, then a call that looks ahead."
              ],
              "requires": [
                "recursion"
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_RIGHT"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_AHEAD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            }
          ]
        },
        {
          "title": "After the call",
          "levels": [
            {
              "slug": "return-trip",
              "title": "Return trip",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "PROC"
              ],
              "maxCommands": 6,
              "maxSteps": 200,
              "rows": [
                "#.........G.",
                ">...........",
                "#..........."
              ],
              "hints": [
                "What comes after the call runs when the call is over, once for each level.",
                "The deepest level finishes first, then the one above it."
              ],
              "requires": [
                "recursion"
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_AHEAD"
                    },
                    {
                      "op": "TURN_LEFT"
                    },
                    {
                      "op": "MOVE_FORWARD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            },
            {
              "slug": "snake",
              "title": "Snake",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT",
                "PROC"
              ],
              "maxCommands": 8,
              "maxSteps": 200,
              "rows": [
                ">.......",
                "#######.",
                "G......."
              ],
              "hints": [
                "One procedure walks one run. Use it again after each turn.",
                "Turn between the runs, in the same direction both times."
              ],
              "requires": [
                "recursion"
              ],
              "solution": [
                {
                  "op": "PROC",
                  "name": "A",
                  "body": [
                    {
                      "op": "MOVE_FORWARD"
                    },
                    {
                      "op": "CALL",
                      "name": "A",
                      "when": "CLEAR_AHEAD"
                    }
                  ]
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "CALL",
                  "name": "A"
                },
                {
                  "op": "TURN_RIGHT"
                },
                {
                  "op": "CALL",
                  "name": "A"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "Capstone",
      "description": "Every tool of the earlier worlds, two or more at a time.",
      "chapters": [
        {
          "title": "Two ideas",
          "levels": [
            {
              "slug": "frozen-key",
              "title": "Frozen key",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 14,
              "maxSteps": 120,
              "rows": [
                ">.#.....",
                "........",
                "....##..",
                ".......G",
                "..#....."
              ],
              "hints": [
                "The key is across the ice, and the door is shut until you have it.",
                "A slide ends past the ice. Plan the turn from where it stops."
              ],
              "locks": [
                {
                  "key": [
                    5,
                    4
                  ],
                  "door": [
                    6,
                    1
                  ]
                }
              ],
              "ice": [
                [
                  0,
                  3
                ],
                [
                  1,
                  3
                ],
                [
                  2,
                  3
                ]
              ]
            },
            {
              "slug": "gate-by-belt",
              "title": "Gate by belt",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "maxSteps": 120,
              "rows": [
                ".....#..",
                ">#....#G",
                "#.......",
                "#.#.....",
                "......#."
              ],
              "hints": [
                "The belt carries you after each action, and the gate waits for its switch.",
                "Find where the belt leaves you before you step on it."
              ],
              "switches": [
                {
                  "switch": [
                    4,
                    4
                  ],
                  "gate": [
                    7,
                    3
                  ]
                }
              ],
              "belts": [
                {
                  "cell": [
                    5,
                    2
                  ],
                  "direction": "south"
                }
              ]
            },
            {
              "slug": "portal-freight",
              "title": "Portal freight",
              "difficulty": "medium",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "maxSteps": 120,
              "rows": [
                ".#....G#",
                ">......#",
                "..#.....",
                "........",
                "........"
              ],
              "hints": [
                "Deliver the crate to its dock before the target counts.",
                "The pair of teleporters saves a long walk. Use it once."
              ],
              "deliveries": [
                {
                  "item": [
                    1,
                    4
                  ],
                  "dock": [
                    3,
                    2
                  ]
                }
              ],
              "teleports": [
                {
                  "a": [
                    3,
                    4
                  ],
                  "b": [
                    6,
                    1
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "Guarded",
          "levels": [
            {
              "slug": "key-gate-guard",
              "title": "Key, gate, guard",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "maxSteps": 120,
              "rows": [
                ">...#...",
                "....#...",
                "#...#..#",
                ".......G",
                "........"
              ],
              "hints": [
                "The guard walks beside the way to the target.",
                "The key opens the door and the switch opens the gate. Take both."
              ],
              "locks": [
                {
                  "key": [
                    1,
                    4
                  ],
                  "door": [
                    5,
                    4
                  ]
                }
              ],
              "switches": [
                {
                  "switch": [
                    2,
                    3
                  ],
                  "gate": [
                    2,
                    4
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      6,
                      2
                    ],
                    [
                      6,
                      3
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "slip-and-jump",
              "title": "Slip and jump",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 18,
              "maxSteps": 120,
              "rows": [
                "........",
                ".....#G#",
                ">.......",
                "#...#...",
                ".#...#.."
              ],
              "hints": [
                "Ice slides, a pair of teleporters jumps, and a guard watches the end.",
                "A slide that ends on a teleporter goes on through it."
              ],
              "ice": [
                [
                  4,
                  0
                ],
                [
                  5,
                  0
                ],
                [
                  6,
                  0
                ]
              ],
              "teleports": [
                {
                  "a": [
                    6,
                    4
                  ],
                  "b": [
                    6,
                    2
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      2,
                      2
                    ],
                    [
                      2,
                      3
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "belt-freight",
              "title": "Belt freight",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "maxSteps": 120,
              "rows": [
                ">.....G#",
                ".......#",
                "........",
                "........",
                ".......#"
              ],
              "hints": [
                "The belt carries you off the way to the dock.",
                "The guard crosses the cells below the crate."
              ],
              "belts": [
                {
                  "cell": [
                    1,
                    0
                  ],
                  "direction": "west"
                }
              ],
              "deliveries": [
                {
                  "item": [
                    3,
                    0
                  ],
                  "dock": [
                    2,
                    0
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      2,
                      1
                    ],
                    [
                      3,
                      1
                    ]
                  ]
                }
              ]
            }
          ]
        },
        {
          "title": "All together",
          "levels": [
            {
              "slug": "four-tools",
              "title": "Four tools",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 18,
              "maxSteps": 120,
              "rows": [
                ">.......",
                ".#..#..#",
                ".......#",
                "..#.....",
                ".......G"
              ],
              "hints": [
                "A key, a belt, a pair of teleporters and a guard share this board.",
                "Take the key first, then work out the belt."
              ],
              "locks": [
                {
                  "key": [
                    6,
                    1
                  ],
                  "door": [
                    1,
                    0
                  ]
                }
              ],
              "belts": [
                {
                  "cell": [
                    3,
                    2
                  ],
                  "direction": "north"
                }
              ],
              "teleports": [
                {
                  "a": [
                    4,
                    3
                  ],
                  "b": [
                    4,
                    4
                  ]
                }
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      6,
                      3
                    ],
                    [
                      6,
                      4
                    ]
                  ]
                }
              ]
            },
            {
              "slug": "everything",
              "title": "Everything",
              "difficulty": "hard",
              "commands": [
                "MOVE_FORWARD",
                "TURN_LEFT",
                "TURN_RIGHT"
              ],
              "maxCommands": 19,
              "maxSteps": 120,
              "rows": [
                "...#..G.",
                ".#......",
                "........",
                ">.......",
                "......#."
              ],
              "hints": [
                "Crate, switch, ice and guard together.",
                "The ice is in the way of the gate. The guard waits at the top."
              ],
              "deliveries": [
                {
                  "item": [
                    0,
                    0
                  ],
                  "dock": [
                    1,
                    0
                  ]
                }
              ],
              "switches": [
                {
                  "switch": [
                    1,
                    2
                  ],
                  "gate": [
                    4,
                    2
                  ]
                }
              ],
              "ice": [
                [
                  3,
                  1
                ],
                [
                  3,
                  2
                ],
                [
                  3,
                  3
                ]
              ],
              "patrols": [
                {
                  "pattern": "back_and_forth",
                  "cells": [
                    [
                      4,
                      0
                    ],
                    [
                      4,
                      1
                    ]
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
} as const;
