# bitgame-cs
Juego arcade de plataformas desarrollado en Python con Pygame bajo una arquitectura modular y orientada a objetos (POO). Controlas a una unidad de datos que debe esquivar flujos de bits corrompidos que caen del sistema, aplicando física de gravedad y temporizadores en tiempo real para sobrevivir. Proyecto de código abierto bajo licencia GNU GPL v3

# Mi Primer Juego en Python con Pygame

Un divertido juego de arcade de un solo bit desarrollado con arquitectura modular orientada a objetos (POO) usando **Python** y **Pygame**. Controlas a una unidad de datos que debe esquivar flujos de bits corrompidos que caen del sistema para evitar una corrupción crítica.

---

## Características

- **Arquitectura Modular (POO):** Código limpio y separado en clases especializadas para el manejo de colores, figuras geométricas, física de gravedad, entidades y bucle principal.
- **Física Realista:** Sistema de aceleración por gravedad aplicado al jugador y a los obstáculos de datos.
- **Control de Tiempos Independiente:** Uso de milisegundos reales mediante temporizadores dedicados para la generación de enemigos y conteo de puntaje.
- **Software Libre:** Distribuido bajo la licencia **GNU GPL v3.0**, garantizando que el código permanezca libre y abierto.

---

## Estructura del Proyecto

El proyecto está organizado de manera modular en paquetes y módulos independientes:

```text
mi_juego/
│
├── basicos/
│   ├── colores.py      # Gestión y registro dinámico de colores RGB
│   ├── figuras.py      # Clases base para figuras geométricas y rectángulos
│   └── gravedad.py     # Manejador de aceleración vertical por gravedad
│
├── elementos/
│   ├── bloque.py       # Entidad de los bits corrompidos que caen
│   ├── jugador.py      # Entidad del jugador (movimiento y saltos)
│   ├── labels.py       # Renderizado y gestión de texto en pantalla
│   └── temporizador.py # Control de intervalos basado en ticks de reloj
│
└── game.py             # Motor principal, bucle del juego (Game Loop) y ejecución
