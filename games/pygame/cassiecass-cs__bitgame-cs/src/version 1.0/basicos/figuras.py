# Copyright (C) 2026 Cassie Cass
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


"""
Version: 1.0
Author: Cassie Cass
License: GNU General Public License v3.0 (GPLv3)

--
"""
import pygame


# Clase base abstracta para representar cualquier figura con dimensiones y posición
class Figura:
    
    def __init__(self, ancho: int, alto: int, x: int, y: int, color):
        
        self.ANCHO = ancho
        self.ALTO = alto
        self.X = x
        self.Y = y
        self.COLOR = color
        
# Subclase de Figura especializada en rectángulos con soporte para colisiones de Pygame
class Rectangulo(Figura):
    
    def __init__(self, ancho: int, alto: int, x: int, y: int, color):
        super().__init__(ancho, alto, x, y, color)
        
        self.FORMA = pygame.Rect(self.X, self.Y, self.ANCHO, self.ALTO)
    
    def obtenerFigura(self):
        
        return self.FORMA
    
# Clase Cuadrado que hereda el comportamiento del rectángulo
class Cuadrado(Rectangulo):
    
    def __init__(self, ancho: int, alto: int, x: int, y: int, color):
        super().__init__(ancho, alto, x, y, color)