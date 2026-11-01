# Assets gráficos

El juego funciona sin ninguno de estos archivos: si falta una imagen usa el dibujo procedural actual
y escribe un aviso discreto en la consola. Basta con copiar un PNG en su carpeta para que se use.
Formato: PNG con transparencia (canal alfa). Los retratos se escalan conservando su proporción.

| Carpeta | Archivos | Tamaño sugerido |
|---|---|---|
| `images/portraits/` | `operator.png`, `aura.png`, `vulcano.png` (retratos del códec; SISTEMA usa el del Operador) | 256 x 256 |
| `images/entities/` | sprites top-down del jugador, scouts, arietes y tanques | 64 x 64 |
| `images/structures/` | pilones, muros y torretas | 40 x 40 (baluarte 80 x 80) |
| `images/tiles/` | suelos de refugio, asfalto y búnker | 40 x 40 (repetibles) |

Por ahora solo los retratos están conectados al gestor (`src/core/asset_manager.py`).
