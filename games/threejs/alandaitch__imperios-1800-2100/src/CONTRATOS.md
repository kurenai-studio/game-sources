# CONTRATOS — Imperios 1800–2100

Leé esto **entero** antes de escribir una línea. Cada módulo lo escribe un agente
distinto **en paralelo**. Si rompés un contrato, rompés el juego de otro.

## Reglas duras

1. **Solo tocás los archivos que se te asignan.** Nunca edites `src/main.js`,
   `src/core/*`, `src/data/*`, `src/render/Renderer.js` ni `src/render/CamaraRTS.js`
   salvo que tu tarea lo diga explícitamente.
2. **Todo el texto visible al usuario va en español rioplatense neutro** (sin voseo
   forzado en la UI; nombres propios y descripciones ya están en `src/data/`).
   Los identificadores de código también van en español.
3. **Cero assets externos.** No `fetch`, no CDN, no imágenes ni modelos binarios.
   Todas las texturas y geometrías son **procedurales** (canvas 2D, ruido, BufferGeometry).
4. **Three.js `0.185.1`**, imports `import * as THREE from 'three'` y
   `three/examples/jsm/...`. ES modules. JavaScript plano (no TypeScript).
5. **Rendimiento**: objetivo 60 fps con 200+ unidades. Usá `InstancedMesh`,
   geometrías fusionadas (`BufferGeometryUtils.mergeGeometries`), materiales
   compartidos y `frustumCulled`. Nunca crees materiales o geometrías por frame.
6. **Determinismo**: toda aleatoriedad sale de `ctx.rng` / `ctx.ruido` (`src/core/RNG.js`).
   Nunca `Math.random()` en generación de mundo o de mallas.
7. Todo sistema exporta una clase con `{ nombre, orden, fijo?(dt,ctx), cada?(dtReal,alfa,ctx) }`.
   `fijo` corre a 20 Hz (lógica). `cada` corre por frame (visual/interpolación).

## Ejes y unidades

- Mundo en **metros**. Plano XZ, **Y = arriba** (convención de Three.js).
- El mapa es cuadrado y centrado en el origen: va de `-tam/2` a `+tam/2`.
- Rejilla de navegación: **1 celda = 2 m**.
- Una unidad de infantería mide ~1.8 m de alto. Una Sede Municipal ocupa 5×5 celdas = 10×10 m.
- Ángulos: `rot` es yaw en radianes, 0 = mirando hacia +X.

## El objeto `ctx`

Está documentado en `src/core/Ctx.js`. Es el **único** puente entre módulos.
Nunca importes un módulo hermano por su ruta; pedilo por `ctx.<nombre>`.
Las fábricas puras de `src/art/` y las tablas de `src/data/` **sí** se importan directo.

## APIs que otros módulos ya dan por sentadas

```js
// src/world/Terreno.js
terreno.altura(x, z) -> number            // altura del suelo en metros
terreno.pendiente(x, z) -> number         // 0..1
terreno.bioma(x, z) -> 'pradera'|'bosque'|'montana'|'desierto'|'playa'|'agua'
terreno.transitable(x, z) -> boolean
terreno.intersectar(raycaster) -> {x,y,z}|null
terreno.tam -> number                     // lado del mapa en metros
terreno.malla -> THREE.Mesh

// src/render/Cielo.js
cielo.horaDelDia -> 0..24 (setter)
cielo.setEdad(n)                          // cambia paleta atmosférica por edad
cielo.sol -> THREE.DirectionalLight
cielo.dirSol -> THREE.Vector3

// src/art/ProceduralTextures.js
texturas.obtener(clave) -> { map, normalMap, roughnessMap, aoMap }   // THREE.Texture
texturas.material(clave, opciones?) -> THREE.MeshStandardMaterial    // cacheado

// src/art/UnidadFabrica.js
crearMallaUnidad(claveUnidad, edad, ctx) -> { grupo: THREE.Group, partes: {...}, animar(fase, estado, dt) }
// src/art/EdificioFabrica.js
crearMallaEdificio(claveEdificio, edad, ctx) -> { grupo: THREE.Group, altura: number }
// src/art/NaturalezaFabrica.js
crearArbol(tipo, rng, ctx) -> THREE.Group ; crearRoca(...) ; crearAcantilado(...)

// src/sim/Navegacion.js
nav.camino(x0,z0,x1,z1, radio) -> Array<{x,z}> | null
nav.bloquear(x,z,ancho,alto, valor)
nav.esLibre(x,z,radio) -> boolean

// src/sim/Economia.js
eco.recursos[jugador] -> { alimento, materiales, capital, energia }
eco.mods[jugador] -> objeto de modificadores (ver src/data/tecnologias.js)
eco.puedePagar(jugador, coste) -> boolean
eco.pagar(jugador, coste) -> boolean
eco.pob[jugador] -> { actual, tope }

// src/render/VistaEntidades.js
vista.registrar(id)       // crea la representación visual de una entidad
vista.quitar(id)
vista.mallaDe(id) -> THREE.Object3D | null

// src/render/Efectos.js
efectos.disparo(x,y,z, dirX,dirZ, tipo)
efectos.impacto(x,y,z, tipo, fuerza)
efectos.explosion(x,y,z, radio)
efectos.polvo(x,y,z, cantidad)
efectos.humoContinuo(objeto3D, intensidad)

// src/audio/MotorAudio.js
audio.sfx(clave, {x, z, volumen}) // todo procedural, WebAudio
audio.musicaEdad(n)

// src/core/EventBus.js  (import { bus })
bus.emit('entidad:creada', id) | 'entidad:muerta' {id, porJugador}
bus.emit('recurso:depositado', {jugador, recurso, cantidad})
bus.emit('edad:avanzada', {jugador, edad})
bus.emit('seleccion:cambio', Set<id>)
bus.emit('aviso', {texto, tipo:'info'|'alerta'|'error'})
```

## Calidad visual — la vara

El juego se compara **lado a lado con Age of Empires II: Definitive Edition**.
Un crítico externo mira capturas a ciegas y dice cuál se ve mejor. Apuntá a:

- Silueta legible desde la cámara de juego (zoom típico: 70–90 m de distancia,
  elevación ~50°). Si a esa distancia una unidad es una mancha, está mal.
- Color: paleta cálida y saturada en el terreno, unidades con color de jugador
  claramente visible en al menos 30% de su silueta.
- Densidad: nada de suelos vacíos. Pasto, piedritas, matas, variación de tinte.
- Sombras nítidas y contacto (AO) en la base de todo objeto.
- Detalle silueteado, no solo textura: aleros, chimeneas, antenas, barandas.
