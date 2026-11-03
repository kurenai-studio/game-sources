// AUTO-GENERADO por tools/game-export.js desde GAME.md — NO EDITAR A MANO.
// Regenerar con:  node tools/game-export.js
// profile: monster-rpg
window.GAME = {
  "generatedFrom": "GAME.md",
  "profile": "monster-rpg",
  "name": "Game Project",
  "description": "Escenario mínimo de arranque para el proyecto.",
  "platform": {
    "mode": "demo",
    "cols": 10,
    "rows": 8,
    "screenW": 160,
    "screenH": 128
  },
  "palettesCount": 2,
  "TYPE_CHART": {
    "NORMAL": {}
  },
  "MOVES": {
    "TACKLE": {
      "type": "NORMAL",
      "power": 5
    }
  },
  "SPECIES": {
    "STARTER": {
      "type": "NORMAL",
      "maxhp": 20,
      "moves": [
        "TACKLE"
      ]
    },
    "WILD": {
      "type": "NORMAL",
      "maxhp": 14,
      "moves": [
        "TACKLE"
      ],
      "wild": true
    }
  },
  "WILD_LIST": [
    {
      "name": "WILD",
      "maxhp": 14,
      "sprite": "generic",
      "type": "NORMAL",
      "moves": [
        {
          "name": "TACKLE",
          "type": "NORMAL",
          "power": 5
        }
      ]
    }
  ],
  "EVOLUTIONS": {},
  "TRAINERS": {},
  "PALETTES": [
    [
      [
        8,
        17,
        7
      ],
      [
        12,
        22,
        10
      ],
      [
        15,
        25,
        12
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ],
      [
        18,
        28,
        14
      ]
    ],
    [
      [
        12,
        22,
        10
      ],
      [
        6,
        6,
        8
      ],
      [
        16,
        18,
        20
      ],
      [
        24,
        26,
        28
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ],
      [
        31,
        31,
        31
      ]
    ]
  ],
  "SPRITE_PALETTES": [
    [
      [
        0,
        0,
        0
      ],
      [
        1,
        1,
        1
      ],
      [
        6,
        20,
        8
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ],
      [
        31,
        22,
        16
      ]
    ]
  ],
  "SPRITES": {},
  "ITEMS": {},
  "ENCOUNTERS": {
    "field": [
      {
        "name": "WILD",
        "maxhp": 14,
        "sprite": "generic",
        "type": "NORMAL",
        "moves": [
          {
            "name": "TACKLE",
            "type": "NORMAL",
            "power": 5
          }
        ]
      }
    ]
  },
  "MAPS": {},
  "OVERWORLD": {
    "field": {}
  },
  "PLAYER": {
    "starter": "STARTER",
    "level": 1,
    "start": {
      "x": 24,
      "y": 24
    }
  },
  "TILE_ART": {},
  "TEXT": {
    "intro": "Escenario mínimo de arranque."
  },
  "SFX": {},
  "ECONOMY": {
    "startMoney": 0,
    "prices": {}
  },
  "BALANCE": {
    "catchBase": 0.4,
    "catchScale": 0.5,
    "xpCurveMul": 1.5,
    "encounterRate": 0.2
  },
  "TILES": {
    "16": {
      "name": "grass",
      "solid": false
    },
    "17": {
      "name": "wall",
      "solid": true
    },
    "18": {
      "name": "tall_grass",
      "solid": false,
      "encounter": true
    },
    "46": {
      "name": "mat",
      "solid": false
    }
  },
  "SOLID_TILES": [
    17
  ]
};
