"""Escalado de dificultad de las incursiones según el nivel de incursión (persistente, empieza en 1)."""
import config as C


def enemy_scale(level):
    """Vida y daño de los enemigos: +10% por nivel."""
    return 1.0 + C.INCURSION_ENEMY_SCALE * (level - 1)


def kind_weights(level):
    """Composición: al principio solo Scouts; después soldados, tanques y por último Arietes."""
    if level <= 2:
        return {"scout": 1.0}
    if level <= 4:
        return {"scout": 7.0, "soldier": 3.0}
    if level <= 6:
        return {"scout": 4.0, "soldier": 3.5, "tank": 2.5}
    return {"scout": 3.0, "soldier": 3.0, "tank": 2.5, "ariete": 1.5}


def pick_kinds(level, count, rng):
    weights = kind_weights(level)
    return rng.choices(list(weights), weights=list(weights.values()), k=count)


def patrol_size(level):
    """Tamaño de cada grupo que custodia un alijo: 3 al principio y +1 por nivel hasta 7."""
    return min(7, 2 + level)


def roamer_groups(level):
    """Patrullas errantes que recorren salas y pasillos: 2, y una más en los niveles 4 y 7."""
    return 2 + (level >= 4) + (level >= 7)


def roamer_size(level):
    return max(2, patrol_size(level) - 1)


def reinforcement_size(level):
    """Enemigos que acuden al abrir un alijo."""
    return 2 + level // 3


def vault_loot(level, rng):
    """Chatarra que suelta la cámara fuerte además del módulo: 150-200 a nivel 1, escalada como el resto del botín."""
    lo, hi = C.INCURSION_TECH_VAULT_LOOT
    return round(rng.randrange(lo, hi + 1, 5) * loot_growth(level))


def nest_kinds(level, rng):
    """Guardia del nido: grupo normal + extra, con la composición de 2 niveles por encima y al menos 2 no-scouts."""
    kinds = pick_kinds(level + C.INCURSION_TECH_NEST_BOOST, patrol_size(level) + C.INCURSION_TECH_NEST_EXTRA, rng)
    need = C.INCURSION_TECH_NEST_HEAVY - sum(1 for k in kinds if k != "scout")
    for i, k in enumerate(kinds):
        if need <= 0:
            break
        if k == "scout":
            kinds[i] = "soldier"
            need -= 1
    return kinds


def loot_growth(level):
    return 1 + C.INCURSION_LOOT_GROWTH * (level - 1)


def loot_per_deposit(level):
    """Botín medio de un alijo a este nivel."""
    return round(sum(C.INCURSION_LOOT_RANGE) / 2 * loot_growth(level))


def loot_amounts(level, count, rng):
    """Botín de cada alijo de la incursión: entre 120 y 180 por alijo a nivel 1, y el conjunto dentro de 350-500
    (el último alijo se ajusta al margen que deja la suma). Todo en múltiplos de 5; después sube con el nivel."""
    lo, hi = C.INCURSION_LOOT_RANGE
    tmin, tmax = C.INCURSION_LOOT_TOTAL
    amounts = []
    for i in range(count):
        a, b = lo, hi
        if i == count - 1:                                   # el último: lo que falta para entrar en el total
            done = sum(amounts)
            fit = (max(lo, tmin - done), min(hi, tmax - done))
            if fit[0] <= fit[1]:                             # con otro número de alijos puede no haber margen
                a, b = fit
        amounts.append(rng.randrange(a, b + 1, 5))
    k = loot_growth(level)
    return [round(v * k) for v in amounts]


def scrap_value(level, base=None):
    """Valor de una chatarra a este nivel (+10% por nivel); `base` = lo que suelta el enemigo (por defecto 25)."""
    return round((C.SCRAP_VALUE if base is None else base) * (1 + C.INCURSION_SCRAP_GROWTH * (level - 1)))


def part_chance(level, heavy=False):
    """Probabilidad de soltar una pieza del chasis de AURA; las unidades pesadas llevan el doble."""
    p = min(C.INCURSION_PART_MAX, C.INCURSION_PART_BASE + C.INCURSION_PART_GROWTH * (level - 1))
    return min(1.0, 2 * p) if heavy else p
