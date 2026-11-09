"""
Main package for Coatl.
Provides UI and Gameplay utilities.
"""

__version__ = "2.0.0"
__author__ = "Lando Icaza C."

from .configs import *
from .game import Game
from .splash import *

__all__ = ["Color", "Configs", "Font", "Game", "show_splash_screen"]
