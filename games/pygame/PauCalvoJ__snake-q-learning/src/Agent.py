import os
import pickle
import random

import numpy as np

LR = 0.1
GAMMA = 0.95
EPSILON_INICIAL = 1.0
EPSILON_MIN = 0.01
EPSILON_DECAY = 0.995  # se aplica al final de cada partida


class QAgent:
    def __init__(self, num_acciones=4):
        self.num_acciones = num_acciones
        self.qtable = {}  # estado (tupla) -> array con un valor Q por acción
        self.epsilon = EPSILON_INICIAL

    def _q(self, estado):
        """Devuelve los valores Q de un estado, creándolos a 0 si es nuevo."""
        return self.qtable.setdefault(tuple(estado), np.zeros(self.num_acciones))

    def choose_action(self, estado):
        if random.random() < self.epsilon:
            return random.randrange(self.num_acciones)
        return int(np.argmax(self._q(estado)))

    def learn(self, estado, accion, recompensa, proximo_estado, done):
        q = self._q(estado)
        # Si la partida terminó no hay futuro, el objetivo es solo la recompensa
        objetivo = recompensa if done else recompensa + GAMMA * np.max(self._q(proximo_estado))
        q[accion] += LR * (objetivo - q[accion])

    def fin_de_partida(self):
        self.epsilon = max(EPSILON_MIN, self.epsilon * EPSILON_DECAY)

    def guardar(self, ruta="modelo_snake.pkl"):
        with open(ruta, "wb") as f:
            pickle.dump({"q_table": self.qtable, "epsilon": self.epsilon}, f)
        print(f"--- Modelo guardado | Estados: {len(self.qtable)} | Epsilon: {self.epsilon:.2f} ---")

    def cargar(self, ruta="modelo_snake.pkl"):
        # Ojo: pickle puede ejecutar código, carga solo archivos generados por ti
        if not os.path.exists(ruta):
            print("--- No hay modelo previo. Empezando de cero ---")
            return False
        with open(ruta, "rb") as f:
            datos = pickle.load(f)
        self.qtable = datos["q_table"]
        self.epsilon = datos["epsilon"]
        print(f"--- Modelo cargado | Estados: {len(self.qtable)} | Epsilon: {self.epsilon:.2f} ---")
        return True
