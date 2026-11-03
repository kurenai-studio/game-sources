# Contrato 01 — Núcleo topológico de la esfera triangular

Prerrequisitos: [DEFINITION.md](../DEFINITION.md) cerrado y GAME Protocol
operativo. Este contrato fija la representación matemática que usarán el
rompecabezas y la interfaz Three.js.

> Capa: este es un **contrato de ejecución** (nivel proyecto). La implementación
> queda separada de Three.js para que las reglas puedan probarse sin navegador.

## T1 — Generar la topología del icosaedro subdividido

Falta una representación ejecutable de las caras triangulares, sus vértices y
sus adyacencias.

FIX/OBJETIVO: `createTriangularSphere(subdivision)` devuelve una topología
determinista de una esfera basada en un icosaedro subdividido. La frecuencia
`n` produce exactamente `20 × n²` caras, cada cara tiene tres vecinos y la
subdivisión conserva 12 vértices de grado 5; los demás vértices interiores tienen
grado 6.

## T2 — Exponer movimientos por adyacencia

El núcleo debe permitir que la lógica del rompecabezas consulte los movimientos
posibles sin conocer detalles de renderizado.

FIX/OBJETIVO: cada cara contiene los identificadores de sus tres caras vecinas,
la relación es recíproca y no existen auto-adyacencias ni duplicados.

## Criterios de aceptación

- [ ] `npm test` termina con exit 0 y todos los tests de
  `tests/triangular-sphere-core.test.mjs` pasan.
- [ ] Para `n=1`, el resultado contiene 12 vértices y 20 caras triangulares.
- [ ] Para `n=2`, el resultado contiene 42 vértices y 80 caras triangulares.
- [ ] Cada cara tiene exactamente tres vecinos y cada relación es recíproca.
- [ ] Para `n=2`, la distribución de grados de vértices es 12 vértices de grado
  5 y 30 vértices de grado 6.
- [ ] La salida es determinista para la misma frecuencia y no depende de Three.js,
  navegador, red ni estado global.
- [ ] `python scripts/validate_specs.py specs` termina con exit 0.
- [ ] Final: las validaciones KDD y GAME Protocol existentes siguen verdes.

## Restricciones

- Tocar SOLO: `src/core/triangular-sphere.mjs`,
  `tests/triangular-sphere-core.test.mjs`, `package.json` y este contrato.
- No añadir dependencias de runtime para el núcleo; Three.js se integrará en una
  tarea posterior de presentación.
- La API pública debe devolver datos serializables y no debe mutar sus argumentos.
- No commitear. Si algo no se puede sin romper otro criterio, PARAR y reportar.
- ABORTAR SI: la construcción exige alterar GAME Protocol, requiere red durante
  las pruebas, o la topología no puede satisfacer simultáneamente `20 × n²`,
  tres vecinos por cara y la distribución geométrica esperada; documentar la
  evidencia y marcar BLOQUEADO.

## Checklist antes de delegar

- [x] RECON corrido: Node.js, Python, suite GAME Protocol, workflow y archivos
  destino fueron comprobados en el repositorio.
- [x] Los entregables fueron comprobados como libres antes de asignarlos.
- [x] Cada criterio de aceptación tiene comando o propiedad verificable.
- [x] Red-team hecho: contar caras sin comprobar adyacencias no satisface la
  intención; los tests comprueban reciprocidad, grados y determinismo.
- [x] Perímetro de archivos declarado.
- [x] Condiciones de aborto explícitas.
