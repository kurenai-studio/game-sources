ACHIEVEMENTS = [
    {
        "id": "first_coin",
        "name": "Pocket Change",
        "desc": "Collect your first coin",
        "check": lambda s: s.get("coins_collected", 0) >= 1,
    },
    {
        "id": "coin_100",
        "name": "Coin Collector",
        "desc": "Collect 100 coins lifetime",
        "check": lambda s: s.get("coins_collected", 0) >= 100,
    },
    {
        "id": "coin_1000",
        "name": "Coin Hoarder",
        "desc": "Collect 1000 coins lifetime",
        "check": lambda s: s.get("coins_collected", 0) >= 1000,
    },
    {
        "id": "combo_12",
        "name": "Chain Reaction",
        "desc": "Reach a x2.5 combo",
        "check": lambda s: s.get("best_combo", 0) >= 12,
    },
    {
        "id": "combo_25",
        "name": "Unstoppable",
        "desc": "Reach a x4 combo",
        "check": lambda s: s.get("best_combo", 0) >= 25,
    },
    {
        "id": "boost_10",
        "name": "Nitro Junkie",
        "desc": "Use boost 10 times",
        "check": lambda s: s.get("boosts_used", 0) >= 10,
    },
    {
        "id": "score_500",
        "name": "Rookie Racer",
        "desc": "Score 500 in one run",
        "check": lambda s: s.get("high_score", 0) >= 500,
    },
    {
        "id": "score_2000",
        "name": "Road Legend",
        "desc": "Score 2000 in one run",
        "check": lambda s: s.get("high_score", 0) >= 2000,
    },
    {
        "id": "runs_25",
        "name": "Dedicated Driver",
        "desc": "Play 25 runs",
        "check": lambda s: s.get("runs_played", 0) >= 25,
    },
    {
        "id": "near_miss_50",
        "name": "Close Call",
        "desc": "Rack up 50 near misses",
        "check": lambda s: s.get("near_misses", 0) >= 50,
    },
]
