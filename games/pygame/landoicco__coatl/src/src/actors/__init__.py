"""
Actors package for Coatl.
Provides classes implementing the behavior of all actors that appear in the game.
"""

__version__ = "2.0.0"
__author__ = "Lando Icaza C."

from .fruit import Fruit
from .snake import Snake

__all__ = ["Fruit", "Snake"]
