# 🐍 Snake con Q-Learning tabular

Agente que aprende a jugar al **Snake** por sí solo usando **Q-Learning** clásico, con una tabla de valores Q. El juego está hecho desde cero con **Pygame**.

Fue mi primer proyecto de aprendizaje por refuerzo. La continuación, que sustituye la tabla por una red neuronal, está en [Snake con Deep Q-Learning](https://github.com/PauCalvoJ/snake-deep-q-learning).

<!-- Aquí puedes añadir un GIF del agente jugando: ![demo](demo.gif) -->

## 🚀 Uso

Requiere Python 3.10 o superior.

```bash
git clone https://github.com/PauCalvoJ/snake-q-learning.git
cd snake-q-learning
pip install -r requirements.txt
```

| Comando | Qué hace |
|---|---|
| `python main.py --rapido --partidas 1500` | Entrena sin ventana (unos segundos) y guarda `modelo_snake.pkl` |
| `python main.py` | Entrena viendo la ventana. Si ya hay modelo, continúa desde él |
| `python main.py --jugar` | Muestra al modelo guardado jugando, sin entrenar |
| `python main.py --jugar --rapido --partidas 200` | Evalúa el modelo en 200 partidas |

## 🧠 Cómo funciona

### Estado (12 valores, todos 0 o 1)
- **Peligro justo al lado** en cada dirección (pared o cuerpo).
- **Posición de la comida** respecto a la cabeza.
- **Dirección actual** de la serpiente.

Como cada valor es 0 o 1, hay como mucho 2¹² = 4096 estados posibles, y en la práctica el agente solo visita unos 250. Por eso cabe en una tabla.

### Acciones
Moverse arriba, abajo, izquierda o derecha. Si la acción es dar media vuelta, se ignora y sigue recto.

### Recompensas
| Evento | Recompensa |
|---|---|
| Comer | +50 |
| Morir (chocar o pasar demasiado tiempo sin comer) | −100 |
| Cada paso | −0.5 |

### Aprendizaje
La tabla es un diccionario `estado → [Q(arriba), Q(abajo), Q(izquierda), Q(derecha)]`. Tras cada paso se actualiza con la regla de Q-learning:

```
Q(s, a) ← Q(s, a) + α · (r + γ · max Q(s', a') − Q(s, a))
```

Si la partida termina, el objetivo es solo `r`.

La exploración es **ε-greedy**: ε empieza en 1 (todo al azar) y se multiplica por 0.995 al final de cada partida, hasta un mínimo de 0.01.

| Hiperparámetro | Valor |
|---|---|
| α (tasa de aprendizaje) | 0.1 |
| γ (descuento) | 0.95 |
| Decaimiento de ε | 0.995 por partida |

## 📈 Resultados

Entrenando 1500 partidas y evaluando después 200 sin exploración (`--jugar`), repetido 12 veces:

| | Valor |
|---|---|
| Puntuación media | ≈ 31 (entre 27 y 37 según el entrenamiento) |
| Récord | entre 63 y 77 |

Probé también a quitar la dirección del estado (8 valores en vez de 12) y la media sale prácticamente igual. El límite real es otro: el agente solo ve lo que tiene justo al lado, así que cuando la serpiente es larga acaba encerrándose a sí misma. Para superar ese límite hay que darle más información al agente, que es lo que hace la [versión con Deep Q-Learning](https://github.com/PauCalvoJ/snake-deep-q-learning).

## 📁 Estructura

```
├── main.py        # Entrenar o jugar (argumentos de línea de comandos)
├── Agent.py       # Agente: tabla Q, exploración, guardar y cargar
└── SnakeGame.py   # Juego y cálculo del estado y las recompensas
```

El modelo se guarda con `pickle`, así que no está incluido en el repositorio: se genera al entrenar. No cargues archivos `.pkl` de fuentes que no sean de confianza, porque pueden ejecutar código.

## 📄 Licencia

[MIT](LICENSE)
