# 30 NOCHES

Juego 2D de supervivencia en un bosque, hecho con **HTML5 Canvas y JavaScript puro**.
No usa librerías, motores, frameworks, cuentas ni servicios externos: todo el arte, el
mundo, el audio y la lógica se generan por código.

Despiertas en un bosque después de un accidente. Tienes 30 noches para reparar la
antena de rescate y escapar. De día exploras, recolectas, fabricas y construyes.
De noche viene a por ti... y sobre todo, va a por tu generador.

---

## 1. Requisitos

- Un navegador moderno (Chrome, Edge, Firefox, Safari). Cualquiera con soporte de
  Canvas 2D y Web Audio.
- Python 3 (o cualquier servidor HTTP estático) para servir la carpeta.

No hay build, ni `npm install`, ni compilación: son ficheros estáticos.

## 2. Cómo ejecutar

Desde la carpeta `30-noches`:

```bash
python -m http.server 8000
```

Y abre <http://localhost:8000>.

Alternativas válidas:

```bash
npx serve .          # Node
php -S localhost:8000
```

También funciona **abriendo `index.html` directamente** (doble clic): el juego usa
scripts clásicos, no módulos ES, así que no hay problemas de CORS. Lo único que puede
fallar en `file://` es `localStorage` (algunos navegadores lo bloquean); el juego está
preparado para seguir funcionando sin guardado.

> IMPORTANTE: si abres el fichero con `file://`, algunos navegadores restringen el
> guardado. Usa el servidor HTTP si quieres que las partidas se conserven.

## 3. Controles

| Tecla | Acción |
|---|---|
| `W` `A` `S` `D` | Moverse (8 direcciones, velocidad constante) |
| Ratón | Apuntar |
| Clic izquierdo | Atacar / disparar |
| `E` | Interactuar: recolectar, recoger componentes, reparar generador, abrir/cerrar puertas, usar el banco |
| `B` | Menú de construcción (previsualización verde/roja) |
| `C` | Fabricar / inventario |
| `1` `2` `3` `4` | Objetos de acceso rápido (medicina, kit de reparación, bomba, linterna) |
| `F` | Encender / apagar la linterna |
| `Q` | Cambiar de arma equipada |
| `Esc` | Pausa, cerrar un menú o cancelar la construcción |
| `M` | Ampliar el minimapa |

Mientras hay un menú abierto la simulación se detiene por completo (no hay ataques
accidentales al pulsar botones) y al cerrarlo los controles vuelven a funcionar.

## 4. Mecánicas

### El ciclo día/noche

- **Día**: 70 s. Exploras, recolectas, fabricas, construyes y reparas.
- **Noche**: 55 s. Llegan las oleadas.
- Ciclo completo: 125 s → la campaña de 30 noches dura unos **62 minutos**.

Al amanecer recibes puntos de investigación y materiales, y las criaturas se retiran.
Si el generador llega a 0, la partida termina en derrota.

### La luz tiene un coste

La linterna ilumina el bosque, pero su batería se agota y **el Cazador de luz va
directamente hacia cualquier fuente de luz**: tu linterna, las lámparas de la base o el
generador. Apagar la luz en el momento justo es una decisión de supervivencia.

Las lámparas iluminan, pero atraen. El generador es la fuente de luz más brillante
que tienes.

### Recursos

Madera (árboles), Piedra (rocas), Chatarra (cajas, vehículos, ruinas) y Hierbas
(arbustos). Los árboles y las rocas necesitan varios golpes; las cajas se abren de
una vez. Cuando un recurso se agota desaparece del mapa.

### Fabricación

Recetas data-driven en `js/crafting.js` (`RECIPES`). Coste real, comprobación de
materiales, requisitos (banco de trabajo / horno **construidos en la base**) y
desbloqueos por investigación. No se cobra nada si la receta no es válida.

| Objeto | Coste | Requisitos |
|---|---|---|
| Hacha de piedra | 5 madera, 2 piedra | — |
| Lanza | 4 madera, 2 piedra | — |
| Medicina | 2 hierbas | — |
| Kit de reparación | 3 chatarra, 2 madera | — |
| Linterna | 4 chatarra, 2 madera | — |
| Arco (+ flechas) | 4 madera, 3 chatarra | banco de trabajo + investigación «Arco de monte» |
| Pistola improvisada (+ munición) | 8 chatarra, 3 piedra | banco de trabajo + investigación «Armería básica» |
| Bastón eléctrico / Rifle de pernos / Bombas | 10 chatarra, 3 madera / 18 chatarra, 6 piedra / 5 chatarra, 1 madera | horno + investigación «Electroquímica» |

Los muros y las trampas **no** se fabrican: se colocan directamente desde el menú de
construcción (tecla `B`), que es donde aparece su coste.

El kit de reparación repara el generador o una estructura dañada (120 puntos). Si no
hay nada que reparar cerca, **no se gasta**. La antena no se repara con kits: exige los
tres componentes y 20 chatarra + 10 piedra (tecla `E` en la base).

### Construcción

| Estructura | Coste | Función |
|---|---|---|
| Muro de madera | 5 madera | Bloquea a las criaturas, tiene vida y se rompe |
| Trampa de pinchos | 4 madera, 2 piedra | Daña a quien la pisa (con cooldown por criatura) |
| Lámpara | 6 madera, 3 chatarra | Ilumina la base y atrae cazadores de luz |
| Puerta | 8 madera | La abres tú con `E`; las criaturas tienen que romperla |
| Banco de trabajo | 8 madera, 4 chatarra | Desbloquea recetas, recarga torretas y linterna |
| Torreta | 10 madera, 8 chatarra | Dispara sola a los enemigos (munición interna) |
| Horno | 15 madera, 10 piedra, 8 chatarra | Desbloquea recetas de alto nivel |

La colocación se valida: no se puede construir sobre ti, sobre el generador, sobre la
antena, sobre otro objeto, ni tapar el acceso a la base (se comprueba con un recorrido
de la cuadrícula). La lámpara, la puerta, el banco, la torreta y el horno se desbloquean
**fabricándolos** (tecla `C`) y se pueden colocar las veces que quieras: al continuar
una partida los desbloqueos se guardan y no hay que recraftearlos.

### Enemigos

| Enemigo | Comportamiento |
|---|---|
| **Acechador** | Básico. Va al generador, golpea lo que le estorba y te ataca si te acercas |
| **Corredor** | Muy rápido y frágil; atraviesa las defensas |
| **Tanque** | Lento y resistente; abre brechas en los muros (×2.4 de daño a estructuras) |
| **Lanzador** | Mantiene la distancia y escupe bilis a distancia |
| **Cazador de luz** | Localiza y destruye fuentes de luz |
| **Élites** | Variantes de los anteriores con más vida, daño y recompensas |

La curva introduce un tipo base nuevo por tranche (corredor en la noche 3, tanque en la
8, lanzador en la 10, cazador de luz en la 14) y variantes de élite desde la 19. A
partir de la noche 19, la probabilidad de que un enemigo de la oleada sea de élite
sube con la dificultad (`difficultyFor(day).eliteChance`).

Los enemigos usan **A\*** sobre una cuadrícula de navegación (las rutas se cachean y se
recalculan como mucho cada ~0.6 s, nunca en cada fotograma) y tienen una detección de
atascos que los desvia si se quedan pillados contra una pared.

### Jefes

Noches **5, 10, 15, 20, 25 y 30**. Cada uno tiene fases, patrones telegrafiados
(aviso visual antes de atacar) y una ventana de recuperación en la que es vulnerable.

| Noche | Jefe | Patrones |
|---|---|---|
| 5 | EL MAZACOTE | Carga y onda sísmica |
| 10 | EL SALTADOR | Saltos, lluvia de proyectiles, cambios de objetivo |
| 15 | MADRE DE LA BABA | Lluvia, onda sísmica e invocación |
| 20 | ROMPEBASES | Asedio a las defensas (×4.5 de daño a estructuras) |
| 25 | EL DEVORADOR | 5 fases que combinan todos los patrones |
| 30 | LA ENTIDAD | 6 fases: carga, invocación, barrido, asedio… |

### Objetivo de la campaña

1. Conseguir los tres componentes: **batería** (vehículo accidentado), **circuito**
   (búnker) y **transmisor** (torre de vigilancia).
2. Reparar la antena en la base (20 chatarra + 10 piedra).
3. Sobrevivir a la noche 30 y derrotar a la Entidad.
4. Volver a la antena y **activar la señal** (tecla `E`).

La victoria **no** se activa sola al acabar el temporizador: hay que cumplir los
requisitos.

### Mejoras y progresión

- **Mejoras temporales**: al derrotar a un jefe (y cada 5 noches) eliges 1 de 3
  (más daño, más velocidad, más recolección, más vida, estructuras más resistentes,
  torretas mejores, curación mejorada, materiales más baratos, criticos…). Se pierden
  al morir.
- **Investigación permanente**: los puntos de investigación (RP) se ganan al sobrevivir
  noches, derrotar jefes y completar objetivos, y **se conservan aunque mueras**.
  Se gastan en el menú principal para desbloquear recetas, mejorar el inicio de la
  partida o subir la recolección.

### Eventos aleatorios

Tormenta, apagón, niebla densa, materiales raros, élite adelantada, caja de suministros,
noche agresiva, munición abandonada e interferencia de radio (revela un punto de
interés). Cada evento tiene duración, efectos mecánicos y limpieza al terminar.

## 5. Estructura de archivos

```
30-noches/
├── index.html          Estructura del canvas, HUD y todos los menús
├── style.css           Interfaz oscura y adaptable
├── og.png              Cartel para redes sociales (1200×630)
├── vercel.json         Cabeceras de seguridad (listo para desplegar, no desplegado)
├── LICENSE             MIT
├── README.md
└── js/
    ├── main.js         Arranque, bucle rAF, desbloqueo de audio
    ├── config.js       Constantes: mundo, tiempos, balance, curva de dificultad
    ├── game.js         Estados, coordinación, reglas de la campaña
    ├── input.js        Teclado y ratón (pulsaciones consumidas por fotograma)
    ├── renderer.js     Dibujado del mundo, entidades, clima e iluminación
    ├── camera.js       Cámara suave y conversiones de coordenadas
    ├── world.js        Generación procedural, colisiones, navegación
    ├── resources.js    Nodos recolectables y su agotamiento
    ├── inventory.js    Recursos, objetos, munición, armas
    ├── player.js       Estado y comportamiento del protagonista
    ├── crafting.js     Recetas data-driven y fabricación
    ├── weapons.js      Estadísticas de armas
    ├── projectiles.js  Proyectiles y explosiones
    ├── enemies.js      Tipos de criatura, gestor y dibujado
    ├── enemyAI.js      Percepción, objetivos y A*
    ├── bosses.js       Jefes, fases y patrones
    ├── buildings.js    Estructuras, colocación, trampas, torretas, puertas
    ├── combat.js       Daño, impactos, muerte y recompensas
    ├── dayNight.js     Temporizador de fases
    ├── events.js       Eventos aleatorios
    ├── upgrades.js     Mejoras temporales
    ├── progression.js  Investigación permanente y opciones
    ├── quests.js       Objetivos, componentes y antena
    ├── lighting.js     Máscara de oscuridad y halogenos
    ├── particles.js    Partículas con pool fijo
    ├── audio.js        Efectos sintetizados con Web Audio
    ├── ui.js           HUD, menús, notificaciones, minimapa
    ├── save.js         Guardado/validación en localStorage
    └── utils.js        Matemáticas, RNG reproducible, colisiones, eventos
```

Todos los módulos se registran en un espacio de nombres global `TN` (`TN.World`,
`TN.Game`…) con scripts clásicos, en el orden en que aparecen en `index.html`.
No hay dependencias circulares: `game.js` es el único que conoce a todos los demás.

## 6. Guardados

Dos guardados independientes en `localStorage`:

- `tn30.save.v1` → **partida en curso**: semilla del mundo, día, fase, temporizador,
  posición y vida del jugador, inventario, arma, mejoras temporales, estado de los
  nodos de recursos, edificios y su vida, construcciones desbloqueadas, generador,
  misiones, componentes de la antena, enemigos activos, jefe en combate, jefes ya
  derrotados, eventos y estadísticas.
- `tn30.meta.v1` → **progresión permanente**: investigación, desbloqueos, récords,
  estadísticas acumuladas y opciones. **No se sobrescribe al reiniciar una expedición.**

Se guarda automáticamente cada 20 s, al cambiar de fase, al derrotar a un jefe y al
cerrar la pestaña. Al cargar se validan los datos: si la partida es inválida o de
otra versión, se avisa y se puede empezar una nueva en lugar de bloquear el juego.
El botón «Continuar» solo se habilita si hay una partida válida.

## 7. Modo de desarrollo

Se activa con `?debug=1` en la URL o desde **Opciones → Modo desarrollo**.

| Tecla | Acción |
|---|---|
| `F1` | Mostrar/ocultar coordenadas y datos de depuración |
| `F2` | Saltar a la siguiente fase (día/noche) |
| `F3` | Añadir materiales de prueba |
| `F4` | Invocar un enemigo |
| `F5` | Invocar al jefe del día actual |
| `F6` | Teletransportarse a la base |
| `F7` | Modo dios |

Las teclas de depuración que tocan la partida (`F2`-`F6`) solo actúan con una
expedición en marcha; en el menú principal se ignoran.

Además, **Opciones → Duración del ciclo** permite acortar las fases para probar
(125 s normal, 31 s en pruebas, 10 s en depuración). La campaña siempre dura 30
noches: solo cambia lo que dura cada una.

Desde la consola del navegador, `TN_GAME` da acceso al estado de la partida.

## 8. Dónde cambiar el balance

Todo el balance está centralizado en `js/config.js`:

- `WORLD` — tamaño del mundo y tamaño de la cuadrícula.
- `TIME` — duración de día, noche, amanecer y atardecer.
- `PLAYER` — vida, velocidad, alcance de interacción.
- `GENERATOR` / `ANTENNA` — vida y costes de reparación.
- `FLASHLIGHT` — radio, batería y consumo.
- `WAVES` — límite de enemigos simultáneos y distancia de aparición.
- `difficultyFor(day)` — **la curva de las 30 noches**: vida, daño, tamaño de la
  oleada, intervalo entre oleadas, tipos de enemigo disponibles y probabilidad de
  élite. Es el único sitio que hay que tocar para reequilibrar la campaña.

Las recetas están en `js/crafting.js` (`RECIPES`), las armas en `js/weapons.js`
(`WEAPONS`), las estructuras en `js/buildings.js` (`BUILDINGS`), los jefes en
`js/bosses.js` (`BOSSES`) y las mejoras en `js/upgrades.js` (`UPGRADES`) y
`js/progression.js` (`RESEARCH`).

## 9. Notas técnicas

- Bucle con `requestAnimationFrame` y `deltaTime` en segundos; los saltos de tiempo
  tras perder el foco se limitan a 0.1 s. Ningún valor de juego depende de los FPS.
- Partículas con pool fijo (900), sin asignaciones por fotograma.
- Colisiones por subdivisión del desplazamiento y resolución círculo/rectángulo
  contra un hash espacial de obstáculos.
- Navegación A\* sobre una cuadrícula de 75×75 con rutas cacheadas por enemigo.
- La iluminación se calcula en un canvas aparte a media resolución y se compone
  sobre la escena (mascara de oscuridad + halos cálidos).
- El audio se sintetiza con Web Audio y solo se inicializa tras la primera
  interacción del usuario (política de los navegadores). Se puede silenciar desde
  Opciones.

## 10. Despliegue

**El juego NO está desplegado en ningún sitio.** Son ficheros estáticos, así que
sirve en cualquier hosting. `vercel.json` queda preparado (pero sin desplegar) con las
cabeceras de seguridad: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`,
`Strict-Transport-Security` y `Permissions-Policy`.

Para publicarlo en Vercel:

```bash
npx vercel deploy --prod
```

Al publicarlo hay que actualizar en `index.html` las URLs de `<link rel="canonical">`,
`og:url` y `og:image` (ahora apuntan al dominio de ejemplo y al PNG del propio
repositorio).

En GitHub, `.github/workflows/ci.yml` comprueba la sintaxis de todos los `.js` con
`node --check` en cada push y pull request a `main` (sin instalar dependencias).

## 11. Créditos

Diseño y programación: Ilias Bou. Todo el contenido (código, arte, sonido) es
original de este proyecto y se genera en tiempo de ejecución.

Licencia **MIT** (ver `LICENSE`).
