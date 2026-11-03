# Handball — Arcade, gestos y tutorial

[**JUGAR / ARCADE / TUTORIAL**](https://mreyese.github.io/handball-threejs-demo/)

Versión **PLAYTEST F9**, opcional mediante `?arcade&f9=on`, para probar preparación del tiro, cámara y contactos. La ruta Arcade habitual conserva el comportamiento F8.
La aceptación humana sigue pendiente; no se declara aceptado el hito completo.

Este repositorio publica únicamente el juego compilado en HTML, CSS y JavaScript,
metadatos de versión y las instrucciones públicas. El navegador descarga JavaScript
minificado para ejecutar el juego. No se publican TypeScript original, mapas de
código, dependencias, pruebas, trazas ni datos de jugadores.

## Cómo jugar

- **ARCADE:** mueve al jugador con el joystick izquierdo; mantén y desplaza TIRO
  con la otra mano para apuntar y cargar. Suelta para lanzar un DIRECT. Vuelve al
  centro para cancelar y empieza un contacto nuevo para volver a tirar. Puedes
  tocar en cualquier orden o mover, levantar y apuntar con un dedo.
  En escritorio puedes usar WASD o flechas y el ratón. El jugador bota al moverse
  y recoge el balón para tirar. La cámara mantiene la portería y al jugador visibles.
- **JUGAR:** conserva la modalidad clásica de cinco tiros.
- **TUTORIAL:** demuestra los gestos; puedes saltarlo o jugar al terminar.

Gestos técnicos disponibles en JUGAR y TUTORIAL:

- **DIRECT:** empieza abajo y desliza hacia arriba; inclina para apuntar.
- **LOB:** sube y termina con un pequeño gancho hacia abajo.
- **BOUNCE:** baja y vuelve a subir formando una V. También admite un inicio alto
  fuera de los paneles del HUD si completas la V.
- **ROSCA:** sube, dibuja una barriga a izquierda o derecha y vuelve subiendo.
  El final apunta y la barriga controla el giro.
- **FEINT:** amaga lateralmente, frena o invierte y levanta. No consume un tiro.
  Empieza un gesto nuevo para lanzar.

Ninguna técnica garantiza un gol. Los resultados proceden de contactos físicos;
el balón completo debe cruzar dentro de la portería. Un contacto previo con el
suelo, portero, poste o larguero no anula por sí solo un gol.

## Enlaces de prueba

- [Menú](https://mreyese.github.io/handball-threejs-demo/)
- [Arcade](https://mreyese.github.io/handball-threejs-demo/?arcade)
- [Tutorial](https://mreyese.github.io/handball-threejs-demo/?tutorial&seed=71)

Prueba especialmente los dos dedos simultáneos, cambios rápidos de dirección,
ambas roscas, LOB, V-BOUNCE, FEINT seguido de tiro, vertical/horizontal y cinco
lanzamientos seguidos de reinicio. Comprueba la comodidad de la cámara y el bote.

## Prueba F9 y estado de validación

- [F9: soltar para lanzar](https://mreyese.github.io/handball-threejs-demo/?arcade&f9=on)
- [F9: temporizador automático experimental](https://mreyese.github.io/handball-threejs-demo/?arcade&f9=on&timeout=hard)
- Compilación sin mapas de código, comprobación TypeScript y 410 pruebas unitarias aprobadas.
- El paquete exacto se prueba con ratón y eventos táctiles nativos: un lanzamiento aceptado y resuelto por modalidad, sin grabación de gestos.
- Esta publicación incorpora cambios locales aún sin commit en el repositorio de origen; `sourceSha` identifica su commit base.
- No se repitieron las puertas completas de regresión, capturas o rendimiento para esta publicación. Los fallos heredados descritos en versiones anteriores siguen pendientes; no se declara que estén resueltos.
- Prueba ambos órdenes de contacto, movimiento mientras apuntas, cancelación, vertical/horizontal y reinicio tras cinco tiros. Compara el temporizador normal con el automático.
- **F9_HUMAN_ACCEPTED: NO. FULL_MILESTONE_ACCEPTED: NO.**

`site/release.json` registra la procedencia y los hashes SHA-256 del paquete.
Las versiones compiladas anteriores permanecen en el historial para recuperación.

[MIT License](LICENSE). Three.js conserva su licencia MIT en el paquete.
