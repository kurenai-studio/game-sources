# Rompecabezas esférico triangular — Definición

## Qué es

Un rompecabezas 3D de ordenamiento en una esfera basada en un icosaedro
subdividido, donde el jugador coloca cada esfera en el hueco triangular de su
color utilizando movimientos adyacentes.

## Arquitectura

El proyecto tendrá un núcleo reutilizable de lógica de juego y una interfaz 3D
que lo consume:

- **Datos de juego:** `GAME.md` será la fuente declarativa de niveles, colores,
  subdivisión y configuración, validada y exportada mediante GAME Protocol.
- **Núcleo de reglas:** representará los triángulos, sus adyacencias, las
  posiciones de las esferas, la posición vacía, los movimientos válidos, el
  mezclado y las métricas de la partida.
- **Interfaz 3D:** una aplicación web basada inicialmente en Three.js. Permitirá
  rotar la esfera para buscar posiciones, aceptando que la rotación oculte
  temporalmente otros espacios.
- **Validación:** KDD documentará y verificará las reglas del núcleo y la
  coherencia entre los datos declarativos y el artefacto generado.

La superficie de cada nivel será un icosaedro subdividido con frecuencia `n`,
que produce `20 × n²` caras triangulares. Cada cara será un hueco y tendrá tres
vecinos por arista; habrá una posición vacía y una esfera menos que huecos.

## Capacidades objetivo

- Representar la esfera triangular en 3D y permitir su rotación interactiva.
- Mostrar huecos triangulares con colores únicos.
- Mostrar esferas colocadas en los huecos y una posición vacía.
- Permitir mover una esfera un espacio por vez hacia la posición vacía cuando
  ambas caras comparten una arista.
- Detectar y mostrar cuándo el tablero está resuelto.
- Contabilizar movimientos y permitir buscar la solución con el mínimo posible.
- Generar configuraciones iniciales aleatorias, procurando que las esferas
  queden alejadas de sus huecos correspondientes.
- Ofrecer niveles de dificultad aumentando la frecuencia de subdivisión y, por
  tanto, el número de caras y esferas.
- Ofrecer un modo temporizado con un tiempo máximo entre movimientos.
- Mantener separadas las reglas verificables del juego y su representación 3D.

## Por qué es un caso válido / motivación real

El proyecto convierte una idea de rompecabezas físico en una experiencia 3D
interactiva. La rotación de la esfera añade una decisión espacial importante:
para encontrar un movimiento puede ser necesario sacrificar la visibilidad de
otras zonas del tablero. El reto combina planificación, memoria visual y
orientación espacial, y la medición de movimientos y tiempo permite comparar
soluciones.

GAME Protocol permite expresar el contenido y la configuración del juego como
datos, mientras KDD ayuda a mantener verificables las reglas de adyacencia,
movimiento, mezclado y resolución a medida que aumente la complejidad.

## Fuera de alcance

- No se define todavía una campaña, historia, personajes ni progresión narrativa.
- No se define todavía una plataforma de distribución concreta fuera del navegador.
- No se fija todavía un algoritmo definitivo para garantizar que el mezclado sea
  óptimo o que produzca siempre la máxima distancia posible.
- No se fijan todavía el diseño visual final, la interfaz de menús, el audio ni
  los efectos gráficos.
- No se implementa todavía el motor, la interfaz Three.js ni los contratos de
  desarrollo; esos detalles pertenecen a la fase PLAN y a sus tareas.
