import random

import numpy as np
import pygame

TAM_BLOQUE = 20
VELOCIDAD = 40

# Acciones: 0 arriba, 1 abajo, 2 izquierda, 3 derecha
DIRECCIONES = [[0, -TAM_BLOQUE], [0, TAM_BLOQUE], [-TAM_BLOQUE, 0], [TAM_BLOQUE, 0]]


class SnakeGame:
    def __init__(self, w=640, h=480, mostrar=True):
        self.w = w
        self.h = h
        self.mostrar = mostrar
        if self.mostrar:
            pygame.init()
            self.display = pygame.display.set_mode((self.w, self.h))
            pygame.display.set_caption("IA Snake - Q-Learning")
            self.clock = pygame.time.Clock()
        self.reset()

    def reset(self):
        self.direction = [TAM_BLOQUE, 0]  # Empieza moviéndose a la derecha
        cabeza = [self.w // 2, self.h // 2]
        self.serpiente = [cabeza,
                          [cabeza[0] - TAM_BLOQUE, cabeza[1]],
                          [cabeza[0] - 2 * TAM_BLOQUE, cabeza[1]]]
        self.puntuacion = 0
        self._colocar_comida()
        self.interaccion_frame = 0
        self.done = False

    def _colocar_comida(self):
        while True:
            x = random.randint(0, (self.w - TAM_BLOQUE) // TAM_BLOQUE) * TAM_BLOQUE
            y = random.randint(0, (self.h - TAM_BLOQUE) // TAM_BLOQUE) * TAM_BLOQUE
            if [x, y] not in self.serpiente:
                self.comida = [x, y]
                return

    def get_state(self):
        """Estado de 12 valores (0 o 1). Con tan pocos valores cabe en una tabla."""
        x, y = self.serpiente[0]
        b = TAM_BLOQUE

        estado = [
            # Peligro justo al lado: izquierda, derecha, arriba, abajo
            self.es_colision([x - b, y]), self.es_colision([x + b, y]),
            self.es_colision([x, y - b]), self.es_colision([x, y + b]),

            # Dónde está la comida respecto a la cabeza
            self.comida[0] < x, self.comida[0] > x,
            self.comida[1] < y, self.comida[1] > y,

            # Dirección actual
            self.direction == DIRECCIONES[2], self.direction == DIRECCIONES[3],
            self.direction == DIRECCIONES[0], self.direction == DIRECCIONES[1],
        ]
        return np.array(estado, dtype=int)

    def es_colision(self, pt=None):
        if pt is None:
            pt = self.serpiente[0]
        # Pared
        if pt[0] < 0 or pt[0] >= self.w or pt[1] < 0 or pt[1] >= self.h:
            return True
        # Su propio cuerpo
        return pt in self.serpiente[1:]

    def step(self, action):
        self._procesar_eventos()
        self.interaccion_frame += 1

        # No se permite dar media vuelta: se sigue en la misma dirección
        nueva_dir = DIRECCIONES[action]
        if nueva_dir != [-self.direction[0], -self.direction[1]]:
            self.direction = nueva_dir

        cabeza = self.serpiente[0]
        self.serpiente.insert(0, [cabeza[0] + self.direction[0], cabeza[1] + self.direction[1]])

        # Muere si choca o si lleva demasiado tiempo sin avanzar (evita bucles infinitos)
        if self.es_colision() or self.interaccion_frame > 100 * len(self.serpiente):
            self.done = True
            return self.get_state(), -100, self.done

        if self.serpiente[0] == self.comida:
            self.puntuacion += 1
            recompensa = 50
            self._colocar_comida()
        else:
            self.serpiente.pop()
            recompensa = -0.25  # Pequeño castigo por paso para que no se entretenga

        self._dibujar()
        return self.get_state(), recompensa, self.done

    def _procesar_eventos(self):
        """Atiende los eventos de la ventana para que no se congele y se pueda cerrar."""
        if not self.mostrar:
            return
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                raise SystemExit

    def _dibujar(self):
        if not self.mostrar:
            return
        self.display.fill((0, 0, 0))
        for pt in self.serpiente:
            pygame.draw.rect(self.display, (0, 255, 0), pygame.Rect(pt[0], pt[1], TAM_BLOQUE, TAM_BLOQUE))
        pygame.draw.rect(self.display, (255, 0, 0),
                         pygame.Rect(self.comida[0], self.comida[1], TAM_BLOQUE, TAM_BLOQUE))
        pygame.display.flip()
        self.clock.tick(VELOCIDAD)
