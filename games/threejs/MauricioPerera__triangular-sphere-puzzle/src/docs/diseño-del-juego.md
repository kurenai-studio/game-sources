# Diseño del juego — Rompecabezas esférico triangular

## 1. Concepto

Es un rompecabezas lógico 3D inspirado en el cubo de Rubik. El tablero es una
esfera construida a partir de un icosaedro y sus caras triangulares funcionan
como huecos. Las esferas se desplazan entre huecos vecinos hasta regresar a su
posición objetivo.

La cámara orbital permite rotar el tablero. Esto introduce una dimensión
espacial adicional: una posición puede estar disponible físicamente, pero quedar
oculta desde el ángulo actual.

## 2. Geometría actual

El modo implementado utiliza el icosaedro base, frecuencia `n=1`:

- 20 caras triangulares.
- 12 vértices.
- 5 caras incidentes en cada vértice.
- 3 caras vecinas por cada cara.
- 20 huecos.
- 19 esferas y un hueco vacío.

La relación de vecindad se obtiene compartiendo una arista, no por proximidad
visual.

## 3. Identidad de las posiciones

Cada cara tiene dos atributos independientes:

- Un número del 1 al 5.
- Un color: rojo, amarillo, verde, azul o morado.

Para cada grupo de cinco caras que comparten un vértice:

1. Los números 1, 2, 3, 4 y 5 aparecen exactamente una vez.
2. Los cinco colores aparecen exactamente una vez.

Una cara pertenece a tres grupos de cinco porque tiene tres vértices. La esfera
que corresponde a una cara conserva sus dos atributos objetivo.

## 4. Flujo de juego

1. El tablero aparece resuelto como referencia visual.
2. El jugador elige una dificultad.
3. **Desordenar puzzle** aplica una secuencia de movimientos legales y reinicia
   el contador a cero.
4. El selector y el botón se bloquean durante la partida.
5. El jugador rota la esfera y selecciona caras para mover las esferas.
6. Al volver al estado resuelto, se habilita una nueva partida.

## 5. Dificultades actuales

| Nivel | Movimientos de mezcla |
| --- | ---: |
| Fácil | 10 |
| Medio | 25 |
| Difícil | 40 |
| Experto | 60 |

El nivel medio es el seleccionado inicialmente. Estas cantidades representan
profundidad práctica, no una distancia óptima calculada desde la solución.

## 6. Reglas de movimiento

La interacción utiliza selección en dos clics:

1. El primer clic selecciona una cara y muestra sus datos.
2. El segundo clic sobre la misma cara cancela la selección.
3. El segundo clic sobre otra cara mueve una esfera únicamente si ambas caras
   comparten una arista y exactamente una de ellas es el hueco.
4. Si el movimiento no es válido, la selección pasa a la segunda cara sin mover
   ninguna esfera.

El movimiento intercambia una esfera con el hueco. El estado anterior no se
modifica.

## 7. Panel de juego

El panel muestra movimientos, cara seleccionada, objetivo de color y número,
coincidencias independientes de color y número, advertencias de pérdida de
progreso y dificultad.

La advertencia de pérdida no bloquea una jugada, pero informa cuando mover una
esfera puede destruir una coincidencia parcial o completa.

## 8. Indicadores visuales

Cada esfera muestra una placa numérica del mismo color que la esfera. La placa
respeta la profundidad 3D y usa contraste suficiente para leer el número.

Al seleccionar una cara se muestran bordes internos neón en esa cara y sus tres
vecinas:

- Verde: coinciden número y color.
- Amarillo: coincide solo uno.
- Rojo: no coincide ninguno.
- Blanco: la cara es el hueco vacío y no hay esfera que comparar.

Los bordes tienen un grosor aproximado de 5 píxeles y desaparecen al cancelar o
cambiar la selección.

## 9. Condición de victoria

El tablero está resuelto cuando existe un único hueco vacío y cada esfera ocupa
la cara que le corresponde. En ese estado coinciden color y número en todas las
caras ocupadas y se habilita una nueva mezcla.

## 10. Arquitectura técnica

- `src/core/triangular-sphere.mjs`: genera vértices, caras y vecinos.
- `src/core/target-labels.mjs`: calcula las coloraciones independientes.
- `src/core/puzzle-state.mjs`: estado inmutable, movimientos, resolución y
  mezcla legal.
- `src/ui/app.mjs`: escena Three.js, cámara, selección, placas, bordes y panel.
- `public/index.html`: estructura y estilos de la interfaz.
- `game/GAME.md`: configuración declarativa validada por GAME Protocol.
- `specs/`: contratos de ejecución KDD.

La interfaz es responsive: en teléfonos el panel se presenta como una tarjeta
inferior contraíble, la cámara adapta su encuadre al ancho disponible y el
canvas conserva los gestos táctiles de Three.js.

## 11. Ejecución y validación

```bash
npm install
npm run dev
```

Abrir `http://127.0.0.1:4173/`.

```bash
npm test
npm run ui:check
npm run check
python scripts/preflight.py
```

## 12. Alcance

### Implementado

- Tablero 3D de 20 caras.
- 19 esferas y hueco único.
- Color y número independientes.
- Mezcla legal con cuatro dificultades.
- Selección segura en dos clics.
- Coincidencias parciales y advertencias de pérdida.
- Bordes neón locales.
- Resolución y contador de movimientos.

### Pendiente

- Niveles subdivididos `n>1` con vértices de grado 6.
- Mezcla que mida o maximice la distancia real a la solución.
- Temporizador, puntuación y mejores marcas.
- Animaciones, audio, efectos y diseño visual final.
- Solver y cálculo de solución mínima.
