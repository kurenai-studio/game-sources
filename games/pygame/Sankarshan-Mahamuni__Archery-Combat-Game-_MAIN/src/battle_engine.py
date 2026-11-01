
# Core balanced battle engine (30 arrows, synergy & effectiveness)

import random

# ----------------------------
# 30 arrows: repeated elements, varied damage and theme
# ----------------------------
WEAPONS = [
    {"name":"Fire Arrow","Damage":30,"Element":"Fire"},
    {"name":"Lava Arrow","Damage":34,"Element":"Fire"},
    {"name":"Solar Arrow","Damage":36,"Element":"Fire"},
    {"name":"Ice Arrow","Damage":25,"Element":"Ice"},
    {"name":"Frost Arrow","Damage":27,"Element":"Ice"},
    {"name":"Glacier Arrow","Damage":30,"Element":"Ice"},
    {"name":"Water Arrow","Damage":28,"Element":"Water"},
    {"name":"Aqua Arrow","Damage":26,"Element":"Water"},
    {"name":"Mist Arrow","Damage":25,"Element":"Water"},
    {"name":"Shock Arrow","Damage":28,"Element":"Electric"},
    {"name":"Thunder Arrow","Damage":32,"Element":"Electric"},
    {"name":"Storm Arrow","Damage":29,"Element":"Electric"},
    {"name":"Wind Arrow","Damage":22,"Element":"Air"},
    {"name":"Cyclone Arrow","Damage":33,"Element":"Air"},
    {"name":"Gale Arrow","Damage":24,"Element":"Air"},
    {"name":"Stone Arrow","Damage":31,"Element":"Earth"},
    {"name":"Gravity Arrow","Damage":33,"Element":"Earth"},
    {"name":"Quake Arrow","Damage":35,"Element":"Earth"},
    {"name":"Poison Arrow","Damage":20,"Element":"Toxin"},
    {"name":"Venom Arrow","Damage":26,"Element":"Toxin"},
    {"name":"Acid Arrow","Damage":24,"Element":"Toxin"},
    {"name":"Shadow Arrow","Damage":27,"Element":"Dark"},
    {"name":"Curse Arrow","Damage":30,"Element":"Dark"},
    {"name":"Blood Arrow","Damage":34,"Element":"Dark"},
    {"name":"Holy Arrow","Damage":28,"Element":"Light"},
    {"name":"Radiant Arrow","Damage":32,"Element":"Light"},
    {"name":"Sun Arrow","Damage":35,"Element":"Light"},
    {"name":"Plasma Arrow","Damage":36,"Element":"Chaos"},
    {"name":"Spirit Arrow","Damage":30,"Element":"Spirit"},
    {"name":"Metal Arrow","Damage":33,"Element":"Metal"},
]

WEAPON_MAP = {w["name"]: w for w in WEAPONS}
WEAPON_NAMES = [w["name"] for w in WEAPONS]

print(" Weapon map : ", WEAPON_MAP)

# ----------------------------
# Enhanced Elemental Effectiveness - Intuitive Rock-Paper-Scissors Logic
# Strong advantages (2.0x), moderate advantages (1.5x), neutral (1.0x), disadvantages (0.5x)
# ----------------------------
EFFECTIVENESS = {
    # Fire interactions
    ("Fire","Ice"): 2.0,      # Fire melts ice
    ("Fire","Water"): 0.5,    # Water extinguishes fire
    ("Fire","Earth"): 1.5,    # Fire burns earth
    ("Fire","Air"): 1.5,      # Fire needs air to burn
    ("Fire","Metal"): 1.5,    # Fire melts metal
    ("Fire","Toxin"): 1.5,    # Fire burns toxins
    ("Fire","Dark"): 1.5,     # Fire dispels darkness
    ("Fire","Light"): 1.0,    # Fire and light are neutral
    ("Fire","Electric"): 1.0, # Fire and electric are neutral
    ("Fire","Spirit"): 1.0,   # Fire and spirit are neutral
    ("Fire","Chaos"): 1.0,    # Fire and chaos are neutral
    
    # Water interactions
    ("Water","Fire"): 2.0,    # Water extinguishes fire
    ("Water","Electric"): 0.5, # Electric conducts through water
    ("Water","Earth"): 1.5,   # Water erodes earth
    ("Water","Ice"): 1.0,     # Water and ice are related
    ("Water","Air"): 1.0,     # Water and air are neutral
    ("Water","Metal"): 1.0,   # Water and metal are neutral
    ("Water","Toxin"): 1.5,   # Water dilutes toxins
    ("Water","Dark"): 1.0,    # Water and dark are neutral
    ("Water","Light"): 1.0,   # Water and light are neutral
    ("Water","Spirit"): 1.0,  # Water and spirit are neutral
    ("Water","Chaos"): 1.0,   # Water and chaos are neutral
    
    # Electric interactions
    ("Electric","Water"): 2.0, # Electric conducts through water
    ("Electric","Metal"): 2.0, # Electric conducts through metal
    ("Electric","Earth"): 0.5, # Earth grounds electricity
    ("Electric","Air"): 1.5,   # Electric creates lightning in air
    ("Electric","Fire"): 1.0,  # Electric and fire are neutral
    ("Electric","Ice"): 1.0,   # Electric and ice are neutral
    ("Electric","Toxin"): 1.0, # Electric and toxin are neutral
    ("Electric","Dark"): 1.0,  # Electric and dark are neutral
    ("Electric","Light"): 1.0, # Electric and light are neutral
    ("Electric","Spirit"): 1.0, # Electric and spirit are neutral
    ("Electric","Chaos"): 1.0, # Electric and chaos are neutral
    
    # Earth interactions
    ("Earth","Air"): 2.0,     # Earth blocks air
    ("Earth","Electric"): 1.5, # Earth grounds electricity
    ("Earth","Fire"): 0.5,    # Fire burns earth
    ("Earth","Water"): 0.5,   # Water erodes earth
    ("Earth","Ice"): 1.5,     # Earth freezes ice
    ("Earth","Metal"): 1.0,   # Earth and metal are related
    ("Earth","Toxin"): 1.5,   # Earth absorbs toxins
    ("Earth","Dark"): 1.0,    # Earth and dark are neutral
    ("Earth","Light"): 1.0,   # Earth and light are neutral
    ("Earth","Spirit"): 1.0,  # Earth and spirit are neutral
    ("Earth","Chaos"): 1.0,   # Earth and chaos are neutral
    
    # Air interactions
    ("Air","Earth"): 0.5,     # Earth blocks air
    ("Air","Fire"): 0.5,      # Air feeds fire
    ("Air","Electric"): 0.5,  # Air conducts lightning
    ("Air","Water"): 1.0,     # Air and water are neutral
    ("Air","Ice"): 1.5,       # Air creates wind chill
    ("Air","Metal"): 1.0,     # Air and metal are neutral
    ("Air","Toxin"): 1.5,     # Air disperses toxins
    ("Air","Dark"): 1.0,      # Air and dark are neutral
    ("Air","Light"): 1.0,     # Air and light are neutral
    ("Air","Spirit"): 1.0,    # Air and spirit are neutral
    ("Air","Chaos"): 1.0,     # Air and chaos are neutral
    
    # Light vs Dark (classic opposition)
    ("Light","Dark"): 2.0,    # Light dispels darkness
    ("Dark","Light"): 2.0,    # Dark absorbs light
    
    # Toxin interactions
    ("Toxin","Light"): 1.5,   # Toxin corrupts light
    ("Toxin","Dark"): 1.5,    # Toxin enhances darkness
    ("Toxin","Fire"): 0.5,    # Fire burns toxins
    ("Toxin","Water"): 0.5,   # Water dilutes toxins
    ("Toxin","Earth"): 0.5,   # Earth absorbs toxins
    ("Toxin","Air"): 0.5,     # Air disperses toxins
    ("Toxin","Ice"): 1.0,     # Toxin and ice are neutral
    ("Toxin","Electric"): 1.0, # Toxin and electric are neutral
    ("Toxin","Metal"): 1.0,   # Toxin and metal are neutral
    ("Toxin","Spirit"): 1.0,  # Toxin and spirit are neutral
    ("Toxin","Chaos"): 1.0,   # Toxin and chaos are neutral
    
    # Special elements
    ("Spirit","Metal"): 1.5,  # Spirit transcends metal
    ("Metal","Spirit"): 0.5,  # Metal grounds spirit
    ("Chaos","Fire"): 1.5,    # Chaos amplifies fire
    ("Chaos","Ice"): 1.5,     # Chaos amplifies ice
    ("Chaos","Water"): 1.5,   # Chaos amplifies water
    ("Chaos","Electric"): 1.5, # Chaos amplifies electric
    ("Chaos","Earth"): 1.5,   # Chaos amplifies earth
    ("Chaos","Air"): 1.5,     # Chaos amplifies air
    ("Chaos","Toxin"): 1.5,   # Chaos amplifies toxin
    ("Chaos","Dark"): 1.5,    # Chaos amplifies dark
    ("Chaos","Light"): 1.5,   # Chaos amplifies light
    ("Chaos","Spirit"): 1.5,  # Chaos amplifies spirit
}

def get_effectiveness(att_elem, def_elem):
    return EFFECTIVENESS.get((att_elem, def_elem), 1.0)

# ----------------------------
# Enhanced Synergy System - Intuitive Combo Logic
# ----------------------------
# Elemental combinations that work well together
SYNERGY_CHAINS = [
    # Natural combinations
    {"Fire", "Air", "Electric"},    # Storm combo - fire needs air, creates lightning
    {"Water", "Ice", "Electric"},   # Freeze combo - water becomes ice, conducts electric
    {"Earth", "Metal", "Fire"},     # Forge combo - earth provides metal, fire shapes it
    {"Light", "Spirit", "Air"},     # Divine combo - light and spirit flow through air
    {"Dark", "Toxin", "Earth"},     # Corruption combo - dark toxins seep into earth
    {"Chaos", "Electric", "Fire"},  # Destruction combo - chaos amplifies energy
    {"Water", "Earth", "Air"},      # Nature combo - natural elements
    {"Fire", "Light", "Spirit"},    # Purification combo - fire purifies with light
]

# Elemental opposites that clash
OPPOSITE_PAIRS = [
    {"Fire", "Water"},
    {"Light", "Dark"},
    {"Earth", "Air"},
    {"Spirit", "Metal"},
    {"Toxin", "Light"},
]

def synergy_multiplier(combo_names):
    elems = [WEAPON_MAP[n]["Element"] for n in combo_names]
    unique = set(elems)
    
    # Perfect synergy: All same element (mono-element combo)
    if len(unique) == 1:
        return 2.0  # Strong mono-element bonus
    
    # Check for perfect synergy chains
    for chain in SYNERGY_CHAINS:
        if chain.issubset(unique):
            return 1.8  # Perfect synergy chain
    
    # Check for partial synergy (2 out of 3 from a chain)
    for chain in SYNERGY_CHAINS:
        overlap = chain.intersection(unique)
        if len(overlap) == 2:
            return 1.4  # Partial synergy
    
    # Check for elemental opposites (clash penalty)
    for pair in OPPOSITE_PAIRS:
        if pair.issubset(unique):
            return 0.6  # Clash penalty
    
    # Two same elements + one different (focus combo)
    for e in unique:
        if elems.count(e) == 2:
            return 1.3  # Focus combo bonus
    
    # All different elements (diversity bonus)
    if len(unique) == 3:
        return 1.1  # Small diversity bonus
    
    return 1.0  # No synergy

def combo_base_damage(combo_names):
    return sum(WEAPON_MAP[n]["Damage"] for n in combo_names)

def element_effectiveness(attack_combo, defense_combo):
    atk_elems = [WEAPON_MAP[n]["Element"] for n in attack_combo]
    def_elems = [WEAPON_MAP[n]["Element"] for n in defense_combo]
    total = 0.0
    count = 0
    for a in atk_elems:
        for d in def_elems:
            total += get_effectiveness(a, d)
            count += 1
    return (total / count) if count>0 else 1.0

def combo_power(combo_names, vs_defense_combo):
    base = combo_base_damage(combo_names)
    syn = synergy_multiplier(combo_names)
    elem_eff = element_effectiveness(combo_names, vs_defense_combo)
    # slight randomness to avoid perfect determinism
    return base * syn * elem_eff 

def resolve_round(player_combo, ai_combo, debug=False):
    """
    Both combos (length 3) -> compute player_power, ai_power, net damage and winner.
    Damage applied = abs(player_power - ai_power) to weaker side.
    """
    player_power = combo_power(player_combo, vs_defense_combo=ai_combo)
    ai_power = combo_power(ai_combo, vs_defense_combo=player_combo)
    net = abs(player_power - ai_power)
    if player_power > ai_power:
        winner = "Player"
        damage_to_ai = net
        damage_to_player = 0.0
    elif ai_power > player_power:
        winner = "AI"
        damage_to_player = net
        damage_to_ai = 0.0
    else:
        winner = "Tie"
        damage_to_ai = damage_to_player = 0.0

    details = {
        "player_combo": player_combo,
        "ai_combo": ai_combo,
        "player_power": player_power,
        "ai_power": ai_power,
        "net_damage": net,
        "winner": winner,
        "damage_to_ai": damage_to_ai,
        "damage_to_player": damage_to_player
    }
    if debug:
        details.update({
            "player_base": combo_base_damage(player_combo),
            "ai_base": combo_base_damage(ai_combo),
            "player_syn": synergy_multiplier(player_combo),
            "ai_syn": synergy_multiplier(ai_combo),
            "player_elem_eff": element_effectiveness(player_combo, ai_combo),
            "ai_elem_eff": element_effectiveness(ai_combo, player_combo),
        })
    return details

# If run directly, small demo
if __name__ == "__main__":

    print("Weapon Map : " , WEAPON_MAP)
    p = ["Fire Arrow","Lava Arrow","Wind Arrow"]
    a = ["Water Arrow","Ice Arrow","Stone Arrow"]
    print(resolve_round(p,a,debug=True))
