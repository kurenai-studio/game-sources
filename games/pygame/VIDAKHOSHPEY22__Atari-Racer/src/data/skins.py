from collections import namedtuple
from core.settings import BLUE, RED, GREEN, YELLOW, PURPLE, ORANGE

Skin = namedtuple("Skin", "name color type speed_bonus")

CAR_SKINS = [
    Skin("Azure Sedan", BLUE, "sedan", 1.0),
    Skin("Crimson Sport", RED, "sedan", 1.1),
    Skin("Forest SUV", GREEN, "suv", 0.95),
    Skin("Solar Sedan", YELLOW, "sedan", 1.15),
    Skin("Amethyst SUV", PURPLE, "suv", 1.0),
    Skin("Ember Truck", ORANGE, "truck", 0.9),
    Skin("Glacier White", (230, 230, 235), "sedan", 1.08),
    Skin("Onyx Black", (25, 25, 30), "sedan", 1.12),
    Skin("Titanium SUV", (140, 160, 175), "suv", 0.97),
    Skin("Sovereign Gold", (212, 175, 55), "sedan", 1.13),
]
