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

# Temporizador basado en milisegundos reales (independiente de los FPS) para intervalos de tiempo
class Temporizador:
    def __init__(self, intervalo_milisegundos):
        self.intervalo = intervalo_milisegundos
        self.tiempo_ultimo = pygame.time.get_ticks()

    def es_momento(self):
        tiempo_actual = pygame.time.get_ticks()
       
        if tiempo_actual - self.tiempo_ultimo >= self.intervalo:
            self.tiempo_ultimo = tiempo_actual
            return True
        return False
