// AUTO-GENERADO por tools/game-export.js desde GAME.md — NO EDITAR A MANO.
// Regenerar con:  node tools/game-export.js
// profile: voxel
window.GAME = {
  "generatedFrom": "GAME.md",
  "profile": "voxel",
  "name": "The Bathrooms",
  "description": "Mundo liminal de baños infinitos capturado en VHS: azulejos enfermizos, moho, luz fluorescente muerta. Sin objetivos, sin salida.",
  "platform": {
    "chunkSize": 18,
    "cellSize": 2,
    "wallHeight": 3,
    "playerSpeed": 3.4,
    "playerRadius": 0.3,
    "viewChunks": 2,
    "eyeHeight": 1.6,
    "audio": {
      "refDist": 4,
      "maxDist": 28
    },
    "texts": {
      "title": "The Bathrooms",
      "rec": "REC",
      "hint": "WASD para caminar, mouse para mirar, Shift para correr"
    }
  },
  "palettesCount": 0,
  "MATERIALS": {
    "TILE_WALL": {
      "color": [
        150,
        156,
        130
      ]
    },
    "TILE_FLOOR": {
      "color": [
        120,
        122,
        102
      ]
    },
    "GROUT": {
      "color": [
        66,
        64,
        52
      ]
    },
    "STALL": {
      "color": [
        104,
        122,
        98
      ]
    },
    "PORCELAIN": {
      "color": [
        226,
        224,
        212
      ]
    },
    "MIRROR": {
      "color": [
        98,
        122,
        120
      ]
    },
    "WATER": {
      "color": [
        88,
        108,
        98
      ]
    },
    "MOLD": {
      "color": [
        52,
        66,
        44
      ]
    },
    "GRIME": {
      "color": [
        92,
        80,
        64
      ]
    },
    "CEILING": {
      "color": [
        176,
        172,
        150
      ]
    },
    "LIGHT_ON": {
      "color": [
        232,
        228,
        180
      ]
    },
    "LIGHT_DEAD": {
      "color": [
        110,
        112,
        108
      ]
    },
    "PAPER": {
      "color": [
        214,
        210,
        196
      ]
    },
    "PIPE": {
      "color": [
        104,
        106,
        102
      ]
    },
    "METAL": {
      "color": [
        126,
        128,
        124
      ]
    },
    "TRASH": {
      "color": [
        72,
        68,
        56
      ]
    },
    "CURTAIN": {
      "color": [
        178,
        176,
        158
      ]
    },
    "RUST": {
      "color": [
        120,
        78,
        54
      ]
    }
  },
  "PREFABS": {
    "wall_slab": {
      "size": [
        8,
        9,
        1
      ],
      "fill": "TILE_WALL"
    },
    "floor_slab": {
      "size": [
        8,
        1,
        8
      ],
      "fill": "TILE_FLOOR"
    },
    "ceiling_slab": {
      "size": [
        8,
        1,
        8
      ],
      "fill": "CEILING"
    },
    "toilet_tank": {
      "size": [
        4,
        5,
        2
      ],
      "fill": "PORCELAIN"
    },
    "toilet_bowl": {
      "size": [
        4,
        3,
        3
      ],
      "fill": "PORCELAIN"
    },
    "toilet_seat": {
      "size": [
        4,
        1,
        4
      ],
      "fill": "PORCELAIN"
    },
    "toilet_foot": {
      "size": [
        2,
        1,
        2
      ],
      "fill": "PORCELAIN"
    },
    "stall_side": {
      "size": [
        1,
        9,
        8
      ],
      "fill": "STALL"
    },
    "stall_back": {
      "size": [
        8,
        9,
        1
      ],
      "fill": "STALL"
    },
    "stall_door": {
      "size": [
        4,
        7,
        1
      ],
      "fill": "STALL"
    },
    "sink_basin": {
      "size": [
        6,
        2,
        4
      ],
      "fill": "PORCELAIN"
    },
    "faucet_stem": {
      "size": [
        1,
        2,
        1
      ],
      "fill": "METAL"
    },
    "faucet_spout": {
      "size": [
        1,
        1,
        2
      ],
      "fill": "METAL"
    },
    "mirror_panel": {
      "size": [
        6,
        5,
        1
      ],
      "fill": "MIRROR",
      "cells": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 5,
          "y": 0,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 5,
          "y": 4,
          "z": 0,
          "m": "MOLD"
        }
      ]
    },
    "urinal_back": {
      "size": [
        4,
        6,
        1
      ],
      "fill": "PORCELAIN"
    },
    "urinal_basin": {
      "size": [
        4,
        3,
        2
      ],
      "fill": "PORCELAIN"
    },
    "urinal_lip": {
      "size": [
        4,
        1,
        1
      ],
      "fill": "PORCELAIN"
    },
    "pipe_segment": {
      "size": [
        1,
        4,
        1
      ],
      "fill": "PIPE"
    },
    "pipe_short": {
      "size": [
        1,
        3,
        1
      ],
      "fill": "PIPE"
    },
    "grime_patch": {
      "size": [
        2,
        1,
        1
      ],
      "fill": "GRIME"
    },
    "grime_streak": {
      "size": [
        1,
        3,
        1
      ],
      "fill": "GRIME"
    },
    "water_puddle": {
      "size": [
        4,
        1,
        4
      ],
      "fill": "WATER"
    },
    "water_pool": {
      "size": [
        3,
        1,
        3
      ],
      "fill": "WATER"
    },
    "bin_body": {
      "size": [
        4,
        5,
        4
      ],
      "fill": "METAL"
    },
    "paper_heap": {
      "size": [
        3,
        2,
        3
      ],
      "fill": "PAPER"
    },
    "paper_wad": {
      "size": [
        1,
        1,
        1
      ],
      "fill": "PAPER"
    },
    "dispenser_box": {
      "size": [
        3,
        4,
        1
      ],
      "fill": "METAL"
    },
    "light_tube": {
      "size": [
        6,
        1,
        1
      ],
      "fill": "LIGHT_ON"
    },
    "light_tube_dead": {
      "size": [
        6,
        1,
        1
      ],
      "fill": "LIGHT_DEAD"
    },
    "shower_tray": {
      "size": [
        6,
        1,
        6
      ],
      "fill": "PORCELAIN"
    },
    "shower_riser": {
      "size": [
        1,
        8,
        1
      ],
      "fill": "METAL"
    },
    "shower_head": {
      "size": [
        2,
        1,
        2
      ],
      "fill": "METAL"
    },
    "shower_rail": {
      "size": [
        6,
        1,
        1
      ],
      "fill": "METAL"
    },
    "shower_curtain": {
      "size": [
        6,
        5,
        1
      ],
      "fill": "CURTAIN",
      "cells": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "GRIME"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "GRIME"
        }
      ]
    },
    "dryer_body": {
      "size": [
        4,
        3,
        2
      ],
      "fill": "METAL"
    },
    "dryer_hood": {
      "size": [
        2,
        1,
        2
      ],
      "fill": "METAL"
    },
    "dryer_nozzle": {
      "size": [
        2,
        1,
        1
      ],
      "fill": "METAL"
    },
    "bucket_body": {
      "size": [
        4,
        4,
        3
      ],
      "fill": "METAL",
      "cells": [
        {
          "x": 0,
          "y": 1,
          "z": 1,
          "m": "RUST"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "RUST"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "RUST"
        }
      ]
    },
    "bucket_water": {
      "size": [
        3,
        1,
        2
      ],
      "fill": "WATER"
    },
    "mop_seg": {
      "size": [
        1,
        1,
        1
      ],
      "fill": "PIPE"
    },
    "mop_head": {
      "size": [
        2,
        2,
        1
      ],
      "fill": "GRIME"
    },
    "bench_board": {
      "size": [
        12,
        1,
        3
      ],
      "fill": "STALL"
    },
    "bench_leg": {
      "size": [
        2,
        2,
        3
      ],
      "fill": "METAL"
    }
  },
  "STRUCTURES": {
    "toilet_unit": {
      "place": [
        {
          "prefab": "toilet_foot",
          "at": [
            1,
            0,
            3
          ]
        },
        {
          "prefab": "toilet_tank",
          "at": [
            0,
            3,
            0
          ]
        },
        {
          "prefab": "toilet_bowl",
          "at": [
            0,
            1,
            2
          ]
        },
        {
          "prefab": "toilet_seat",
          "at": [
            0,
            4,
            2
          ]
        },
        {
          "prefab": "water_pool",
          "at": [
            0,
            0,
            2
          ]
        },
        {
          "prefab": "grime_patch",
          "at": [
            1,
            2,
            4
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            3,
            3,
            1
          ]
        }
      ]
    },
    "stall_unit": {
      "place": [
        {
          "prefab": "floor_slab",
          "at": [
            0,
            0,
            0
          ]
        },
        {
          "prefab": "stall_side",
          "at": [
            0,
            1,
            0
          ]
        },
        {
          "prefab": "stall_side",
          "at": [
            7,
            1,
            0
          ]
        },
        {
          "prefab": "stall_back",
          "at": [
            0,
            1,
            0
          ]
        },
        {
          "prefab": "stall_door",
          "at": [
            1,
            3,
            7
          ]
        },
        {
          "prefab": "toilet_tank",
          "at": [
            2,
            1,
            1
          ]
        },
        {
          "prefab": "toilet_bowl",
          "at": [
            2,
            1,
            3
          ]
        },
        {
          "prefab": "toilet_seat",
          "at": [
            2,
            4,
            3
          ]
        },
        {
          "prefab": "water_pool",
          "at": [
            1,
            0,
            4
          ]
        }
      ]
    },
    "sink_unit": {
      "place": [
        {
          "prefab": "mirror_panel",
          "at": [
            1,
            8,
            0
          ]
        },
        {
          "prefab": "sink_basin",
          "at": [
            1,
            4,
            1
          ]
        },
        {
          "prefab": "faucet_stem",
          "at": [
            3,
            6,
            1
          ]
        },
        {
          "prefab": "faucet_spout",
          "at": [
            3,
            6,
            2
          ]
        },
        {
          "prefab": "water_pool",
          "at": [
            2,
            5,
            1
          ]
        },
        {
          "prefab": "pipe_segment",
          "at": [
            3,
            0,
            2
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            1,
            1,
            4
          ]
        }
      ]
    },
    "urinal_unit": {
      "place": [
        {
          "prefab": "wall_slab",
          "at": [
            0,
            0,
            0
          ]
        },
        {
          "prefab": "urinal_back",
          "at": [
            2,
            3,
            1
          ]
        },
        {
          "prefab": "urinal_basin",
          "at": [
            2,
            3,
            2
          ]
        },
        {
          "prefab": "urinal_lip",
          "at": [
            2,
            3,
            3
          ]
        },
        {
          "prefab": "water_pool",
          "at": [
            2,
            4,
            2
          ]
        },
        {
          "prefab": "pipe_short",
          "at": [
            3,
            0,
            1
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            3,
            1,
            1
          ]
        }
      ]
    },
    "bin_full": {
      "place": [
        {
          "prefab": "bin_body",
          "at": [
            2,
            0,
            2
          ]
        },
        {
          "prefab": "paper_heap",
          "at": [
            2,
            5,
            2
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            1,
            0,
            2
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            5,
            0,
            3
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            2,
            0,
            6
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            4,
            1,
            1
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            1,
            0,
            5
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            6,
            1,
            5
          ]
        }
      ]
    },
    "dispenser_empty": {
      "place": [
        {
          "prefab": "dispenser_box",
          "at": [
            2,
            5,
            0
          ]
        },
        {
          "prefab": "paper_wad",
          "at": [
            3,
            4,
            0
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            3,
            2,
            0
          ]
        }
      ]
    },
    "light_fixture": {
      "place": [
        {
          "prefab": "ceiling_slab",
          "at": [
            0,
            1,
            0
          ]
        },
        {
          "prefab": "light_tube",
          "at": [
            1,
            0,
            2
          ]
        },
        {
          "prefab": "light_tube_dead",
          "at": [
            1,
            0,
            4
          ]
        }
      ]
    },
    "shower_unit": {
      "place": [
        {
          "prefab": "wall_slab",
          "at": [
            0,
            0,
            0
          ]
        },
        {
          "prefab": "shower_tray",
          "at": [
            1,
            0,
            1
          ]
        },
        {
          "prefab": "shower_riser",
          "at": [
            1,
            1,
            0
          ]
        },
        {
          "prefab": "shower_head",
          "at": [
            1,
            7,
            1
          ]
        },
        {
          "prefab": "shower_rail",
          "at": [
            1,
            7,
            5
          ]
        },
        {
          "prefab": "shower_curtain",
          "at": [
            1,
            2,
            5
          ]
        },
        {
          "prefab": "water_pool",
          "at": [
            2,
            0,
            2
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            1,
            3,
            1
          ]
        }
      ]
    },
    "dryer_unit": {
      "place": [
        {
          "prefab": "wall_slab",
          "at": [
            0,
            0,
            0
          ]
        },
        {
          "prefab": "dryer_body",
          "at": [
            2,
            3,
            1
          ]
        },
        {
          "prefab": "dryer_hood",
          "at": [
            3,
            6,
            1
          ]
        },
        {
          "prefab": "dryer_nozzle",
          "at": [
            3,
            2,
            1
          ]
        },
        {
          "prefab": "grime_streak",
          "at": [
            3,
            0,
            1
          ]
        }
      ]
    },
    "mop_bucket": {
      "place": [
        {
          "prefab": "bucket_body",
          "at": [
            1,
            0,
            1
          ]
        },
        {
          "prefab": "bucket_water",
          "at": [
            1,
            3,
            1
          ]
        },
        {
          "prefab": "mop_seg",
          "at": [
            4,
            3,
            2
          ]
        },
        {
          "prefab": "mop_seg",
          "at": [
            4,
            4,
            2
          ]
        },
        {
          "prefab": "mop_seg",
          "at": [
            5,
            5,
            2
          ]
        },
        {
          "prefab": "mop_seg",
          "at": [
            5,
            6,
            2
          ]
        },
        {
          "prefab": "mop_seg",
          "at": [
            6,
            7,
            2
          ]
        },
        {
          "prefab": "mop_head",
          "at": [
            5,
            7,
            2
          ]
        },
        {
          "prefab": "water_puddle",
          "at": [
            0,
            0,
            4
          ]
        }
      ]
    },
    "bench_unit": {
      "place": [
        {
          "prefab": "bench_board",
          "at": [
            0,
            2,
            0
          ]
        },
        {
          "prefab": "bench_leg",
          "at": [
            1,
            0,
            0
          ]
        },
        {
          "prefab": "bench_leg",
          "at": [
            8,
            0,
            0
          ]
        },
        {
          "prefab": "grime_patch",
          "at": [
            4,
            2,
            0
          ]
        }
      ]
    }
  },
  "VOXELS": {
    "toilet_unit": {
      "count": 101,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          3,
          7,
          5
        ]
      },
      "voxels": [
        {
          "x": 1,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 3,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 5,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 6,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 7,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 3,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 6,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 7,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 2,
          "z": 4,
          "m": "GRIME"
        },
        {
          "x": 1,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 4,
          "m": "GRIME"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 0,
          "y": 0,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "WATER"
        }
      ]
    },
    "stall_unit": {
      "count": 382,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          7,
          9,
          7
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 4,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 5,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 6,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 1,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 1,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 1,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 2,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 2,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 3,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 3,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 3,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 3,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 4,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 5,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 6,
          "m": "TILE_FLOOR"
        },
        {
          "x": 4,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 4,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 5,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 6,
          "m": "TILE_FLOOR"
        },
        {
          "x": 5,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 4,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 5,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 6,
          "m": "TILE_FLOOR"
        },
        {
          "x": 6,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 0,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 1,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 2,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 3,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 4,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 5,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 6,
          "m": "TILE_FLOOR"
        },
        {
          "x": 7,
          "y": 0,
          "z": 7,
          "m": "TILE_FLOOR"
        },
        {
          "x": 0,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 3,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 4,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 5,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 6,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 1,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 3,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 4,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 5,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 6,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 7,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 8,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 9,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 9,
          "z": 7,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 1,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 1,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 1,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 1,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 1,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 1,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 1,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 1,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 1,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 6,
          "m": "PORCELAIN"
        }
      ]
    },
    "sink_unit": {
      "count": 89,
      "bounds": {
        "min": [
          1,
          0,
          0
        ],
        "max": [
          6,
          12,
          4
        ]
      },
      "voxels": [
        {
          "x": 1,
          "y": 8,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 1,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 1,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 1,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 1,
          "y": 12,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 2,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 2,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 2,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 2,
          "y": 12,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 3,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 3,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 3,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 3,
          "y": 12,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 4,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 4,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 4,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 4,
          "y": 12,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 5,
          "y": 8,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 5,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 5,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 5,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 5,
          "y": 12,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 6,
          "y": 8,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 6,
          "y": 9,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 6,
          "y": 10,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 6,
          "y": 11,
          "z": 0,
          "m": "MIRROR"
        },
        {
          "x": 6,
          "y": 12,
          "z": 0,
          "m": "MOLD"
        },
        {
          "x": 1,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 4,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 5,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 6,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 1,
          "y": 1,
          "z": 4,
          "m": "GRIME"
        },
        {
          "x": 1,
          "y": 2,
          "z": 4,
          "m": "GRIME"
        },
        {
          "x": 1,
          "y": 3,
          "z": 4,
          "m": "GRIME"
        }
      ]
    },
    "urinal_unit": {
      "count": 126,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          7,
          8,
          4
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 8,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 8,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 8,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 6,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 7,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 8,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 4,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 4,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 4,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 4,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 4,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 1,
          "m": "PIPE"
        },
        {
          "x": 3,
          "y": 1,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "GRIME"
        }
      ]
    },
    "bin_full": {
      "count": 103,
      "bounds": {
        "min": [
          1,
          0,
          1
        ],
        "max": [
          6,
          6,
          6
        ]
      },
      "voxels": [
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 5,
          "y": 0,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 4,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 5,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 6,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 6,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 6,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 5,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 6,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 6,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 3,
          "y": 6,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 5,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 6,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 6,
          "z": 3,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 6,
          "z": 4,
          "m": "PAPER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "PAPER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 6,
          "m": "PAPER"
        },
        {
          "x": 4,
          "y": 1,
          "z": 1,
          "m": "PAPER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 5,
          "m": "PAPER"
        },
        {
          "x": 6,
          "y": 1,
          "z": 5,
          "m": "PAPER"
        }
      ]
    },
    "dispenser_empty": {
      "count": 15,
      "bounds": {
        "min": [
          2,
          2,
          0
        ],
        "max": [
          4,
          8,
          0
        ]
      },
      "voxels": [
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "GRIME"
        }
      ]
    },
    "light_fixture": {
      "count": 76,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          7,
          1,
          7
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 0,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 2,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 3,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 4,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 5,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 6,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 0,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 1,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 2,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 3,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 4,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 5,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 6,
          "m": "CEILING"
        },
        {
          "x": 7,
          "y": 1,
          "z": 7,
          "m": "CEILING"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 4,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 5,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 6,
          "y": 0,
          "z": 2,
          "m": "LIGHT_ON"
        },
        {
          "x": 1,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        },
        {
          "x": 3,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        },
        {
          "x": 4,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        },
        {
          "x": 5,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        },
        {
          "x": 6,
          "y": 0,
          "z": 4,
          "m": "LIGHT_DEAD"
        }
      ]
    },
    "shower_unit": {
      "count": 151,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          7,
          8,
          6
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 4,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 5,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 6,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 8,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 0,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 0,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 2,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 3,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 0,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 0,
          "z": 3,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 4,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 4,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 5,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 1,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 2,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 3,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 4,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 5,
          "m": "PORCELAIN"
        },
        {
          "x": 6,
          "y": 0,
          "z": 6,
          "m": "PORCELAIN"
        },
        {
          "x": 1,
          "y": 7,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 6,
          "y": 7,
          "z": 5,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 5,
          "m": "MOLD"
        },
        {
          "x": 1,
          "y": 3,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 1,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 1,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 1,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 2,
          "y": 2,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 2,
          "y": 3,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 2,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 2,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 2,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 3,
          "y": 2,
          "z": 5,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 3,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 3,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 3,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 3,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 4,
          "y": 2,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 4,
          "y": 3,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 4,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 4,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 4,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 5,
          "y": 2,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 5,
          "y": 3,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 5,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 5,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 5,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 6,
          "y": 2,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 6,
          "y": 3,
          "z": 5,
          "m": "GRIME"
        },
        {
          "x": 6,
          "y": 4,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 6,
          "y": 5,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 6,
          "y": 6,
          "z": 5,
          "m": "CURTAIN"
        },
        {
          "x": 1,
          "y": 3,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 1,
          "y": 4,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 1,
          "y": 5,
          "z": 1,
          "m": "GRIME"
        }
      ]
    },
    "dryer_unit": {
      "count": 104,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          7,
          8,
          2
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 0,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 1,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 3,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 4,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 5,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 6,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 0,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 1,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 3,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 4,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 5,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 6,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 7,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 7,
          "y": 8,
          "z": 0,
          "m": "TILE_WALL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 5,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 5,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 5,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 3,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 4,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 5,
          "y": 5,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 6,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 6,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 4,
          "y": 2,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 1,
          "m": "GRIME"
        },
        {
          "x": 3,
          "y": 1,
          "z": 1,
          "m": "GRIME"
        }
      ]
    },
    "mop_bucket": {
      "count": 71,
      "bounds": {
        "min": [
          0,
          0,
          1
        ],
        "max": [
          6,
          8,
          7
        ]
      },
      "voxels": [
        {
          "x": 1,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 2,
          "m": "RUST"
        },
        {
          "x": 1,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 3,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 3,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 1,
          "m": "RUST"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 3,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 3,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 3,
          "y": 3,
          "z": 1,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 3,
          "z": 2,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 0,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 1,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 2,
          "m": "RUST"
        },
        {
          "x": 4,
          "y": 2,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 3,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 4,
          "y": 3,
          "z": 3,
          "m": "METAL"
        },
        {
          "x": 4,
          "y": 4,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 5,
          "y": 5,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 5,
          "y": 6,
          "z": 2,
          "m": "PIPE"
        },
        {
          "x": 6,
          "y": 7,
          "z": 2,
          "m": "GRIME"
        },
        {
          "x": 5,
          "y": 7,
          "z": 2,
          "m": "GRIME"
        },
        {
          "x": 5,
          "y": 8,
          "z": 2,
          "m": "GRIME"
        },
        {
          "x": 6,
          "y": 8,
          "z": 2,
          "m": "GRIME"
        },
        {
          "x": 0,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 0,
          "y": 0,
          "z": 7,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 1,
          "y": 0,
          "z": 7,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 2,
          "y": 0,
          "z": 7,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 4,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 5,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 6,
          "m": "WATER"
        },
        {
          "x": 3,
          "y": 0,
          "z": 7,
          "m": "WATER"
        }
      ]
    },
    "bench_unit": {
      "count": 60,
      "bounds": {
        "min": [
          0,
          0,
          0
        ],
        "max": [
          11,
          2,
          2
        ]
      },
      "voxels": [
        {
          "x": 0,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 0,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 2,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 3,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 0,
          "m": "GRIME"
        },
        {
          "x": 4,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 4,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 0,
          "m": "GRIME"
        },
        {
          "x": 5,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 5,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 6,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 7,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 8,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 8,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 8,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 9,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 9,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 9,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 10,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 10,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 10,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 11,
          "y": 2,
          "z": 0,
          "m": "STALL"
        },
        {
          "x": 11,
          "y": 2,
          "z": 1,
          "m": "STALL"
        },
        {
          "x": 11,
          "y": 2,
          "z": 2,
          "m": "STALL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 1,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 2,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 0,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 1,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 8,
          "y": 1,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 0,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 0,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 0,
          "z": 2,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 1,
          "z": 0,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 1,
          "z": 1,
          "m": "METAL"
        },
        {
          "x": 9,
          "y": 1,
          "z": 2,
          "m": "METAL"
        }
      ]
    }
  }
};
