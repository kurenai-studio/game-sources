# Estado actual — Rompecabezas esférico triangular

## Resumen

Existe un prototipo jugable en navegador basado en Three.js. El modo actual
usa el icosaedro base (`n=1`): 20 caras triangulares, 20 huecos y 19 esferas.
El tablero inicia resuelto y la partida comienza al pulsar **Desordenar
puzzle**.

## Regla geométrica

Cada vértice del icosaedro base tiene exactamente cinco caras incidentes. La
topología permite dos asignaciones independientes:

- Cada grupo de cinco caras alrededor de un vértice contiene los números 1, 2,
  3, 4 y 5 una sola vez.
- Ese mismo grupo contiene los cinco colores una sola vez.
- Color y número son atributos independientes; la posición se identifica por
  la combinación de ambos.
- Una cara pertenece a tres grupos de cinco, uno por cada vértice que la forma.

La asignación se calcula en [target-labels.mjs](../src/core/target-labels.mjs) y
se verifica automáticamente. Los colores visibles son rojo, amarillo, verde,
azul y morado.

## Flujo de juego

1. La esfera aparece resuelta como referencia visual.
2. **Desordenar puzzle** aplica una secuencia de movimientos legales y reinicia
   el contador a cero.
3. El botón queda deshabilitado mientras el tablero está desordenado.
4. El jugador rota la esfera para localizar el hueco y las caras relevantes.
5. Un primer clic selecciona una cara y muestra su objetivo.
6. Un segundo clic en la misma cara cancela la selección.
7. Un segundo clic en otra cara solo mueve una esfera si las caras comparten una
   arista y exactamente una de ellas es el hueco. En cualquier otro caso, la
   selección pasa a la segunda cara sin mover piezas.
8. Al volver al estado resuelto, se habilita de nuevo el botón de desordenar.

Antes de iniciar se puede elegir la dificultad:

- Fácil: 10 movimientos de mezcla.
- Medio: 25 movimientos.
- Difícil: 40 movimientos.
- Experto: 60 movimientos.

El selector queda bloqueado durante la partida. Estas profundidades aumentan la
dificultad práctica, pero todavía no representan una distancia óptima calculada
desde la solución.

## Información de la interfaz

El panel muestra únicamente datos relevantes para la decisión:

- Movimientos realizados.
- Cara seleccionada.
- Color y número objetivo de la cara.
- Coincidencia independiente de color y número de la esfera que ocupa la cara.
- Advertencia cuando mover una esfera puede perder una coincidencia parcial o
  completa.

La esfera seleccionada y sus tres vecinas muestran un borde interno neón:

- Verde: coinciden color y número.
- Amarillo: coincide solo color o solo número.
- Rojo: no coinciden ni color ni número.
- Blanco: la cara es el hueco vacío y no tiene esfera que comparar.

Las placas numéricas de las esferas usan el mismo color que la esfera, con
contraste suficiente para leer el número sin ocultar su identidad cromática.

La interfaz también incluye un layout responsive para teléfonos: el panel se
convierte en una tarjeta inferior, respeta las áreas seguras del dispositivo,
mantiene controles táctiles de tamaño cómodo y desactiva el scroll de página
durante los gestos de rotación. La cámara calcula su distancia para encajar el
tablero en el ancho disponible y el panel puede contraerse para recuperar área
de juego.

## Arquitectura y archivos principales

- [triangular-sphere.mjs](../src/core/triangular-sphere.mjs): genera la
  topología del icosaedro.
- [target-labels.mjs](../src/core/target-labels.mjs): calcula números y colores
  independientes.
- [puzzle-state.mjs](../src/core/puzzle-state.mjs): estado inmutable,
  movimientos, resolución y desorden legal.
- [app.mjs](../src/ui/app.mjs): escena Three.js, interacción y panel.
- [index.html](../public/index.html): HUD y estilos de la interfaz.
- `specs/CONTRACT-01` a `CONTRACT-05`: contratos de ejecución de las
  capacidades implementadas.

## Ejecutar localmente

```bash
npm install
npm run dev
```

Después abrir `http://127.0.0.1:4173/`.

Comandos de verificación:

```bash
npm test
npm run ui:check
npm run check
python scripts/preflight.py
```

## Pendiente

- Generalizar la asignación de color y número para niveles subdivididos (`n>1`),
  donde también aparecen vértices de grado 6.
- Añadir dificultad configurable, mezclado más exigente, temporizador y
  búsqueda de solución mínima.
- Refinar arte, cámara inicial, animaciones y presentación final.
