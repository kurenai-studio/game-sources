# Guía de colaboración y evolución segura

Esta guía define cómo añadir funcionalidades sin romper reglas, interacción o
comportamientos que ya están implementados.

## 1. Antes de modificar

Leer en este orden:

1. [`DEFINITION.md`](../DEFINITION.md): propósito, arquitectura y límites.
2. [`docs/diseño-del-juego.md`](diseño-del-juego.md): reglas visibles y alcance
   actual.
3. [`docs/estado-actual.md`](estado-actual.md): comportamiento implementado.
4. [`knowledge/index.md`](../knowledge/index.md): contexto KDD disponible.
5. Los contratos relacionados en [`specs/`](../specs/).
6. El código y las pruebas que cubren la capacidad que se va a tocar.

No se debe comenzar modificando código solo a partir de una descripción
informal. Primero hay que identificar qué regla existente podría verse afectada.

## 2. Qué documento usar

### `DEFINITION.md`

Define el producto y su arquitectura. Se modifica solo cuando cambia el alcance
fundamental del proyecto, no para describir cada detalle de implementación.

### `knowledge/`

Contiene conocimiento estable: geometría, decisiones de diseño, arquitectura y
reglas que deben permanecer consultables por cualquier colaborador o agente.

### `specs/`

Contiene contratos de ejecución. Cada contrato debe explicar:

- Qué comportamiento falta o se quiere preservar.
- Qué archivos puede tocar el cambio.
- Qué criterios verificables deben cumplirse.
- Qué pruebas o comandos sirven como evidencia.
- Qué condiciones obligan a detenerse.

Si una contribución cambia una regla observable, primero se debe crear o
actualizar su contrato y después implementar.

### `tests/`

Son la protección contra regresiones. Una prueba debe congelar una propiedad
importante, no únicamente comprobar que una función devuelve un valor cómodo.
Para el núcleo del juego se deben cubrir especialmente:

- No mutación del estado anterior.
- Vecindad correcta de los movimientos.
- Rechazo de movimientos ilegales.
- Estado resuelto y desordenado.
- Un único hueco.
- Reglas de color y número por grupo de cinco.

## 3. Flujo recomendado para una contribución

### Paso 1 — Formular el cambio

Escribir qué problema resuelve, qué comportamiento cambia y qué comportamiento
debe permanecer igual. Si la solicitud es ambigua, documentar la decisión
adoptada antes de programar.

### Paso 2 — Crear un contrato pequeño

Agregar un contrato en `specs/` con un perímetro explícito. Evitar contratos
grandes que mezclen geometría, estado, UI y dificultad en una sola tarea.

Un cambio de UI puede limitarse a `src/ui/app.mjs` y `public/index.html`; un
cambio de reglas debe incluir el núcleo y sus pruebas. No se deben modificar
archivos fuera del perímetro sin actualizar el contrato.

### Paso 3 — Escribir primero las pruebas

Añadir pruebas que fallen con el comportamiento anterior y que expresen la regla
nueva. Solo después implementar el cambio mínimo necesario.

### Paso 4 — Implementar por capas

1. Reglas puras en `src/core/`, sin Three.js ni DOM.
2. Pruebas del núcleo.
3. Integración de la UI en `src/ui/` y `public/`.
4. Verificación visual en el navegador.
5. Actualización de documentación y contrato.

La interfaz no debe convertirse en la fuente de verdad de la geometría o del
estado. Debe consumir el núcleo existente.

### Paso 5 — Ejecutar las validaciones

Como mínimo:

```bash
npm run ui:check
npm test
npm run check
python scripts/preflight.py
git diff --check
```

Si el cambio afecta la interfaz, comprobar también manualmente:

- Carga inicial.
- Flujo normal de interacción.
- Estados vacíos, resueltos y desordenados.
- Rotación y zoom.
- Consola del navegador sin errores.

### Paso 6 — Revisar regresiones

Antes de aceptar el cambio, comparar:

- Qué archivos se tocaron.
- Qué contratos y pruebas protegen esos archivos.
- Si se conservaron las reglas de movimiento y resolución.
- Si la documentación sigue describiendo el comportamiento real.
- Si los cambios visuales no ocultan información del juego.

## 4. Reglas de seguridad del proyecto

- No cambiar silenciosamente `n=1` por una topología subdividida: en `n>1`
  aparecen vértices de grado 6 y la regla actual de grupos de cinco ya no aplica
  literalmente.
- No asignar color o número por una secuencia visual arbitraria: ambos deben
  respetar las restricciones de cada grupo de cinco.
- No mover esferas arbitrariamente durante el desorden: el estado mezclado debe
  ser alcanzable mediante movimientos legales.
- No permitir que un clic aislado mueva una esfera: la interacción usa dos
  clics y valida adyacencia y hueco.
- No usar el hexágono, la UI o una animación como fuente de reglas; la fuente es
  el núcleo puro.
- No eliminar una prueba para hacer pasar un cambio. Si una regla cambió,
  actualizar explícitamente contrato, prueba y documentación.
- No commitear cambios de un colaborador sin revisar el alcance y los gates.

## 5. Cómo trabajar con agentes

Los agentes deben leer `.agents/AGENTS.md` y el contrato asignado antes de
actuar. La solicitud a un agente debe incluir:

- Objetivo concreto.
- Contrato que gobierna el trabajo.
- Perímetro de archivos.
- Comandos de prueba.
- Evidencia esperada.

Un agente no debe ampliar el alcance por iniciativa propia. Si descubre que la
implementación requiere cambiar una regla, un archivo fuera del perímetro o una
decisión de diseño no resuelta, debe detenerse y reportarlo.

## 6. Criterio de aceptación

Una contribución está lista solo cuando:

1. El comportamiento nuevo está descrito.
2. Las pruebas protegen el comportamiento nuevo y el anterior.
3. Los contratos y su perímetro están actualizados.
4. La UI fue verificada si aplica.
5. `npm test`, `npm run check` y `python scripts/preflight.py` pasan.
6. La documentación coincide con el código real.

La regla práctica es: ningún cambio se considera una mejora si funciona en su
caso feliz pero puede romper silenciosamente una propiedad que ya estaba
garantizada.
