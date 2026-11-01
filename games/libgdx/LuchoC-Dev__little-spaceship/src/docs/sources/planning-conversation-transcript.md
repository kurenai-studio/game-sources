# Planificación juego espacial — conversación fuente completa

> Transcripción íntegra de la conversación de ChatGPT que originó `docs/planning/`.
> Origen: https://chatgpt.com/share/6a845ad4-30f0-83e9-87ad-f3c77a1ef87e
> Modelo: gpt-5-6-thinking · 107 mensajes · recuperada el 2026-08-18.
> Los IDs de turno citados en `docs/planning/09-source-map.md` corresponden a esta conversación.
> El cuerpo queda en español a propósito: es una transcripción literal y traducirla la falsearía.


## [1] user

```text
Quiero continuar la planificación de un proyecto nuevo. No escribas código, no crees archivos y no tomes decisiones técnicas definitivas todavía. Estamos en fase de descubrimiento/especificación: primero debemos aclarar visión, alcance y plataforma.

## Contexto y objetivo

Voy a crear un juego nuevo inspirado de forma personal en un juego espacial que hice cuando comenzaba a programar. No será un remake: el homenaje consiste en retomar Java y el tipo de proyecto, pero tanto las mecánicas como la estética, el contenido y la arquitectura pueden cambiar completamente.

El propósito principal no es practicar POO, aunque usaremos Java y habrá objetos donde tenga sentido. Quiero un proyecto funcional, publicable y presentable en portfolio, que refleje mi nivel actual después de años de experiencia. Me interesa una arquitectura moderna basada especialmente en:

- composición por encima de herencia;
- inyección de dependencias;
- eventos;
- otros patrones y arquitecturas que definiré más adelante.

No construiremos un sistema de UI desde cero. Todavía no está decidido si el juego será de escritorio o web.

## Decisiones ya tomadas

- El proyecto empieza 100% desde cero; no reutilizar código ni assets de los proyectos antiguos.
- Lenguaje principal: Java.
- Build tool: Maven.
- Alcance inicial: single-player y local.
- MVP:
  - menú;
  - sistema de niveles;
  - un único nivel completamente jugable, con todos los sistemas necesarios;
  - debe quedar listo para publicar/mostrar.
- Estilo visual buscado: retro / pixel-art.
- Dependencias permitidas si tienen licencias de uso público compatibles.
- El repo y los assets antiguos son solo referencia, no base de implementación.

## Incertidumbre principal: desktop vs web

Me atrae la web porque el jugador podría visitar una página y jugar sin instalar nada, pero no quiero pagar por un sitio de poco uso.

Investigación ya realizada:

- Un juego puramente cliente y estático puede alojarse gratis en GitHub Pages, Cloudflare Pages o Vercel.
- GitHub Pages sirve para repos públicos, con límites ampliamente suficientes para un juego chico.
- Cloudflare Pages Free también permite publicar sitios estáticos y no cobra transferencia de assets estáticos.
- Si el proyecto debe continuar siendo Java y ejecutarse en navegador, existe TeaVM, que compila Java a JavaScript/WebAssembly y funciona con Maven. Eso añade complejidad de integración con APIs del navegador/Canvas.
- Alternativa desktop: Java con un framework de juego; más directa técnicamente, pero requiere descarga.
- Alternativa web JS/TS: más natural para navegador, pero Java dejaría de ser el núcleo principal.

No recomendar una decisión definitiva aún sin entender mejor la experiencia deseada. Una idea aceptable es diseñar el dominio del juego de modo independiente de la plataforma y decidir el adaptador/motor después, pero antes de implementar.

## Referencias históricas inspeccionadas

### Repo V3 informado por el usuario

https://github.com/LuchoC00/ProyectitoNavecita

Lo publicado actualmente solo contiene un esqueleto:

- Java 17 con Maven.
- Ventana de 800×600 titulada “Lost Galaxian - Grupo 3 - v1”.
- Usa una librería externa `entorno.jar`.
- Tiene imágenes de fondo.
- No tiene lógica de juego ni entidades implementadas.
- El README lo llama “Proyecto jueguito 2.0”, así que la versión publicada no coincide claramente con el número mencionado por el usuario.
- No hay historial anterior visible que permita reconstruir las versiones 2–4.

### Repo V1 “jugable”

https://github.com/LuchoC00/Tp-Progra1

Sirve como referencia del estilo, no del código. Lo que expresa su código/recursos:

- Arcade espacial de pantalla fija, 800×600.
- Nave posicionada cerca del borde inferior y centrada.
- Movimiento horizontal con flechas izquierda/derecha; la nave se inclina visualmente al moverse y vuelve a apuntar hacia arriba al soltar.
- Asteroides que aparecen desde arriba o laterales y se desplazan en diagonal hacia abajo.
- Proyectil vertical hacia arriba, pensado como un único misil activo a la vez.
- Puntos al destruir asteroides; una meta de puntuación representaba victoria.
- Barra de vida sobre la nave.
- Aura/escudo al mantener Shift.
- Había clases o recursos previstos para enemigos y disparos enemigos (`Destructor`, `Ion`, `enemigo1.png`), pero no estaban integrados.
- En el `tick` de la versión publicada, varias llamadas importantes estaban comentadas, por lo que no hay que asumir que el repo refleja una versión final plenamente funcional.

Conclusión ya compartida con el usuario:

El ADN útil de la referencia es “nave abajo + amenazas desde arriba + esquivar + disparar + arcade espacial”, pero no existe obligación de conservar reglas ni contenido concreto.

### Licencias de assets antiguos

No reutilizar los assets históricos: incluyen imágenes de Star Wars y un fondo atribuido a Lucasfilm. Para una versión publicable, usar pixel-art propio o recursos con licencia explícita compatible, preferentemente CC0. Si se usan assets CC-BY u otros que exigen atribución, documentarla correctamente.

## Tono de la conversación

Responder en español rioplatense, de forma colaborativa, clara y sin sobrecargar. El usuario quiere planificar antes de construir. No crear spec, plan de archivos ni código hasta que él responda las preguntas pendientes y valide el rumbo.

No reiterar preguntas ya respondidas. Podés resumir lo entendido y continuar con las preguntas abiertas, usando el análisis de la V1 para hablar con precisión de “shooter espacial arcade”.

## Preguntas todavía abiertas

Necesitamos que el usuario responda gradualmente:

1. ¿Qué género y perspectiva imagina?
   Ejemplos: shooter espacial de vista superior, side-scroller, arena de supervivencia, roguelite, etc.

2. ¿Cómo sería una partida ideal de 5 a 10 minutos?
   Desde que inicia el nivel hasta que lo completa o pierde.

3. Para el primer nivel jugable del MVP, ¿qué sistemas son indispensables?
   Posibles: movimiento, disparo, enemigos, oleadas, colisiones, vida/daño, ítems o mejoras, jefe, objetivo de nivel, pausa, música/efectos.

4. ¿Qué tono visual y narrativo busca?
   Ejemplos: nave solitaria retro, sci-fi serio, arcade colorido, humor, etc.

5. ¿Controles?
   Solo teclado en PC, o también gamepad; y si llega a web, ¿móvil táctil?

6. ¿Qué debe demostrar en el portfolio además de estar terminado?
   Ejemplos: arquitectura modular, diseño de sistemas, testing, CI, accesibilidad, rendimiento, arte, documentación, despliegue.

7. Cuando dice que quiere algo “mucho mejor” que el proyecto viejo, ¿qué diferencia concreta espera?
   Código, acabado visual, profundidad de juego, despliegue, pruebas, todo, etc.

8. ¿MVP debe incluir guardado de progreso, ajustes de audio/controles y créditos, o se posterga?

9. ¿Repositorio y juego serán públicos desde el inicio?

10. ¿Hay fecha objetivo aproximada para el MVP publicable?

## Restricciones de proceso

- Estamos solamente planificando.
- No implementar ni generar archivos.
- No asumir que será desktop o web.
- No tratar el proyecto antiguo como base técnica.
- Cuando las respuestas vuelvan concreta la visión, primero presentar una especificación revisable para aprobación humana; después un plan técnico; luego tareas; y solo finalmente implementación.
```


## [2] assistant

Perfecto. Tomo todo esto como **estado actual del proyecto** y mantengo la conversación en descubrimiento: nada de código, estructura de carpetas, framework definitivo ni decisión desktop/web todavía.

Lo que ya está bastante claro es que no estás intentando “rehacer tu juego viejo”, sino construir un **shooter espacial nuevo que use aquella V1 como referencia emocional y de ADN**. Java también forma parte de ese homenaje, pero el objetivo real es que el resultado muestre tu nivel actual: diseño de sistemas, arquitectura, acabado y capacidad de llevar algo hasta publicación.

Yo avanzaría de a una capa por vez, porque varias de las preguntas pendientes dependen de la primera. Empecemos por definir **qué juego estamos haciendo realmente**.

Tomando la V1 como punto de partida, ¿qué género/perspectiva te atrae más hoy?

- **Shooter vertical arcade:** nave abajo, enemigos/amenazas arriba, movimiento principalmente lateral o libre. Es lo más cercano al ADN original.
- **Shoot 'em up vertical completo:** la nave puede moverse por toda la pantalla, aparecen formaciones y patrones de proyectiles, power-ups, minibosses, etc.
- **Arena shooter espacial:** cámara fija, pero la nave se mueve libremente en todas direcciones y las amenazas llegan desde distintos lados.
- **Roguelite arcade:** partidas cortas, mejoras durante la partida, builds distintas y cierta aleatoriedad.
- **Side-scroller espacial:** avance horizontal, más parecido a R-Type/Gradius.
- **Otra idea completamente distinta**, manteniendo solamente la temática espacial.

Y hay una segunda decisión que conviene responder junto con ésta: **¿querés que el nivel tenga desplazamiento del escenario o que sea una arena/pantalla relativamente fija?**

Por ejemplo, podríamos terminar definiendo algo como:

> “Shooter vertical arcade, movimiento libre dentro de la pantalla, escenario que avanza continuamente, enemigos por oleadas y un jefe al final.”

o algo mucho más cercano al original:

> “Arcade de pantalla fija, nave en la zona inferior, esquivar amenazas y sobrevivir/destruir objetivos hasta completar el nivel.”

No hace falta pensar todavía en arquitectura ni plataforma. Primero quiero que concretemos esa fantasía básica de juego.


## [3] user

Shoot 'em up vertical completo por niveles 
(Aunque en la versión final habrá más modos como infinito , supervivencia, etc)


Y como decis, vamos a dejar de definir arquitecturas y demás para concentrarnos primero en lo que tiene que hacer el juego


## [4] assistant

Perfecto. Entonces ya podemos fijar una primera definición funcional:

**El juego base será un shoot 'em up vertical completo, estructurado por niveles.** La nave tendrá movimiento libre dentro del área jugable, los enemigos aparecerán siguiendo secuencias/patrones y cada nivel tendrá un principio y un final definidos. Más adelante podrán existir modos alternativos como infinito, supervivencia u otros, pero **no condicionamos el MVP por esos modos todavía**.

Y sí: desde acá conviene separar completamente la conversación de arquitectura. Primero definimos **qué hace el juego, cómo se juega y qué experiencia queremos producir**. Después veremos cómo construirlo.

La siguiente pregunta importante es la partida ideal de un nivel del MVP.

Imaginá que ya abriste el juego, elegiste el nivel 1 y empezaste. ¿Qué te gustaría que ocurriera durante esos **5–10 minutos**?

Por ejemplo, podríamos tener algo del estilo:

**Inicio relativamente tranquilo → aparecen enemigos básicos → nuevas formaciones y tipos de ataque → aparece alguna amenaza especial → aumenta la intensidad → miniboss o sección difícil → jefe → victoria.**

Pero no quiero asumir esa estructura.

También me interesa saber qué papel querés que tenga el jugador. En un shoot 'em up pueden cambiar muchísimo las sensaciones según el foco: puede ser principalmente **esquivar proyectiles**, **destruir enemigos rápidamente**, **manejar recursos/poderes**, **buscar puntuación y combos**, o una mezcla.

Contame cómo te imaginás ese **primer nivel completo**, aunque sea de manera informal: qué hace el jugador desde que empieza hasta que gana o pierde. Con eso podemos empezar a descubrir el loop central del juego.


## [5] user

El schema más o menos lo que quiero para el primer nivel. No necesariamente tiene que ser esto, esto será para CN MVP. El inicio va a haber como una animación de tipo Pedro, que hay esas animaciones especiales en el inicio. Después habrá uno cinco o diez segundos que no habrá nada, solo el recorrido de la nave, y empezará como a ocurrir cosas, como si hubiese ataques o meteoritos o algo. Se verá como si estuviesen atacando en el fondo, y ahí empezarán a ir apareciendo los enemigos básicos. Y como decís, de a poco van a aparecer formaciones nuevas, equipo de ataque. De vez en cuando aparecerá un enemigo más fuerte. y mientras vas avanzando el nivel, debería ir subiendo un poco la dificultad. En algún momento debe aparecer un enemigo, o algo que represente bastante dificultad. Una vez derrotado eso, habrá como un tiempo de relajación de cinco o diez segundos, y bajará un poco la dificultad por un tiempo pequeño y después volverá a subir más rápidamente, hasta llegar a la parte del boss. Que por ahora no definiremos eso, pero así está. Una vez derrotado el jefe, aparecerá la pantalla de victoria o la animación de victoria, o la derrota si pierdes. Esto es todo. Hay un montón de cosas que no dije que tienen que pasar en algún momento, ya sea para MVP o para después. No dije que se van a poder elegir naves, no hablé nada de power-ups ni cosas relacionadas a eso, no hablé de stats, ni de puntuaciones. No hablé de un sistema que quiere implementar de transformaciones, que será como si se acoplasen mejoras en la nave, separado de los power-ups. Por ejemplo, un power-up hace que dispares más fuerte o que tenga más disparos, pero estos acoplamientos añadirían mejoras distintas, por ejemplo, disparo de misil, láser, etc. Y hay varias cosas todavía más que eso, todavía no dije, que las iré mencionando más adelante.


## [6] assistant

Sí, esto ya define bastante bien el **ritmo macro del nivel**, aunque todavía dejemos abiertos los sistemas concretos.

Yo lo resumiría así:

**Nivel 1 / MVP**
- Apertura con una animación o secuencia especial de entrada.
- 5–10 segundos de navegación tranquila para establecer ambiente y recorrido.
- Empiezan eventos de fondo: ataques, meteoritos, conflicto, señales de peligro.
- Entran los primeros enemigos básicos.
- Progresivamente aparecen nuevas formaciones, patrones de ataque y combinaciones de enemigos.
- Cada cierto tiempo aparece una amenaza más fuerte que rompe el ritmo normal.
- La dificultad va escalando gradualmente.
- Hay un encuentro importante a mitad o cerca del final del nivel —todavía sin definir qué será— que funciona como un pico de dificultad.
- Tras superarlo, hay unos segundos de descanso real.
- Luego la intensidad vuelve a crecer, esta vez más rápido.
- Se llega al boss.
- Victoria → secuencia/pantalla de victoria.
- Derrota → secuencia/pantalla de derrota.

Eso me gusta porque ya introduce algo importante: **el nivel no sería simplemente una curva de dificultad ascendente**, sino una secuencia de tensión → pico → descanso → nueva escalada → clímax. Para un shoot 'em up por niveles tiene bastante sentido.

Y también tomo como **sistemas pendientes**, no como decisiones cerradas: selección de naves, power-ups, estadísticas/puntuación y el sistema de transformaciones/acoplamientos. Sobre este último, entendí una distinción interesante: el *power-up* modifica temporalmente o amplifica capacidades existentes, mientras que un **acoplamiento** podría añadir directamente una capacidad nueva a la nave, como misiles, láser, drones, etc.

Por ahora no hace falta entrar ahí.

La siguiente capa que conviene definir es mucho más básica: **qué puede hacer el jugador con la nave durante el combate**.

Hasta ahora tenemos movimiento libre por la pantalla, pero todavía faltan cosas como:

1. ¿El disparo principal es automático mientras mantenés una tecla, o cada disparo requiere input?
2. ¿Querés que exista desde el principio algún tipo de **dash/esquive**, escudo o habilidad defensiva, o solamente movimiento?
3. ¿El contacto directo con enemigos/meteoritos hace daño igual que los proyectiles?
4. ¿Imaginás una nave con **barra de vida**, varias vidas, muerte de un golpe estilo arcade clásico, o alguna mezcla?
5. Y una bastante importante: ¿querés que el juego tienda más hacia **bullet hell** —muchos proyectiles y precisión al esquivar— o hacia un shoot 'em up más tradicional, donde importen por igual posicionamiento, matar enemigos rápido y esquivar?

Con esas respuestas podemos empezar a definir el **combate base**, que va a ser el núcleo sobre el que después encajan power-ups, acoplamientos, naves y enemigos.


## [7] user

Ok, voy a ir explicando, tú lo adaptas como quieras a cada una de las puntos. El disparo principal va a estar dependiendo de la nave o las aeronaves que tenga. Normalmente van a ser de disparo sostenido, pero calculo que habrá naves especiales que disparen más lento o que necesitamos que el jugador presione cada vez que quiera disparar o sistemas de carga. O sea, que tenga que presionar para cargar y al soltar dispare toda la energía que cargó. Y es necesario para el MVP, que es la nave básica solo sea disparo automático. Ok. Con respecto al punto 2, estaría bueno meter habilidades que van a ir dependiendo del tipo de nave que vaya. Algunas pueden tener como dijiste, escudo, sistema de defensa o arma especial. Igualmente puede que el escudo no sea especial de una nave, o el básico, o el escudo básico, sería solo un power-up. Con respecto al punto 3, todavía no sé cómo será, pero calculo que irá dependiendo del modo de juego. Todavía no sé si hacer que sea que la nave tenga un sistema de vidas o que tenga una cantidad de vida completa que recibirá más o menos daño según el tipo de nave o enemigo. Así que de esto queda como pendiente. Justamente el punto 4 habla de eso, así que necesitamos profundizar esto antes de seguir trabajando. Con respecto al punto 5, sí, esa era una de las cosas que iba a hablar más adelante. No sé si hacer un modo de juego aparte o que sea del principal, que el jugador vaya obteniendo como gemas o puntos en parte de la puntuación general. Y en algún momento, durante la partida, haber como una base, un portaaviones o algo donde el jugador pueda ir y elegir preparar una nave, añadir mejoras o algo especial durante el juego. Después, veré si con ese mismo sistema o otro, tener una tienda en el menú donde pueda comprar adquirir cosas relacionadas con el gameplay que sea dentro del juego con puntuación del juego.


## [8] assistant

Sí, acá ya aparecen varias decisiones de diseño importantes, pero todavía estamos en el nivel correcto: **comportamiento del juego**, no implementación.

Hay tres cosas que quedan bastante claras. Primero, el sistema de disparo debe estar ligado a la nave: para el MVP, la nave básica tendrá **disparo sostenido/automático**, pero el diseño general debe permitir más adelante disparos manuales, lentos, cargados o especiales. Segundo, las habilidades también dependerán de la nave o del equipamiento: algunas podrán tener escudo, defensa, arma especial u otras capacidades, sin asumir que todas esas cosas sean exclusivas de una nave. Y tercero, el sistema de supervivencia —vida, vidas, daño, muerte— queda deliberadamente abierto porque querés profundizarlo antes de avanzar.

Sobre lo último que mencionaste, yo lo separaría conceptualmente en **dos sistemas distintos**, porque cumplen funciones diferentes aunque usen una misma moneda o puntuación.

Uno sería **progresión dentro del nivel**. Durante una partida obtenés algún recurso —gemas, energía, chatarra, créditos de combate, lo que terminemos definiendo— y en ciertos momentos aparece una oportunidad de gastarlo. Por ejemplo, llegar a un portaaviones, estación o nave aliada y elegir entre reparar, cambiar algún componente, preparar otra nave, comprar temporalmente un arma, etc. Eso modifica **esa partida en curso**.

El otro sería **progresión entre partidas**. Desde el menú habría una tienda, hangar o sistema equivalente donde los puntos/recursos obtenidos jugando permiten desbloquear naves, componentes, mejoras u otro contenido permanente. Eso modifica lo que tenés disponible en partidas futuras.

No hace falta decidir ahora si ambos usan la misma moneda. De hecho, probablemente convenga dejarlo abierto hasta saber qué tan importante queremos que sea cada capa de progresión.

Pero antes de entrar en eso coincido con vos: hay que resolver el sistema de **vida/daño/muerte**, porque cambia muchísimo cómo se siente todo el juego.

Veo al menos tres modelos que encajarían con lo que estás imaginando:

**Modelo arcade clásico — vidas.** La nave puede aguantar muy poco o directamente un impacto. Perdés una vida y reaparecés. Es muy claro y arcade, pero hace que estadísticas como blindaje o resistencia tengan menos espacio.

**Modelo de HP — barra de integridad.** La nave tiene, por ejemplo, 100 de vida. Los proyectiles pequeños hacen poco daño, un misil mucho, una colisión puede ser devastadora. Diferentes naves pueden tener distinta resistencia. Acá tienen mucho más sentido armadura, escudos, reparación, power-ups defensivos y estadísticas.

**Modelo híbrido — HP + vidas.** Tenés una barra de vida para la nave actual y además una cantidad limitada de vidas/reintentos. Al llegar a 0 destruís la nave y consumís una vida. Esto mantiene el componente arcade, pero permite sistemas de daño bastante más ricos.

Por todo lo que acabás de describir —diferentes naves, estadísticas, escudos, mejoras, reparación posible durante un nivel, enemigos con distintas potencias— **el modelo de HP o el híbrido parecen darnos bastante más espacio de diseño** que morir simplemente por un impacto. No lo tomaría todavía como decisión.

Hay otra variante que podría quedar muy bien: separar **escudo e integridad de casco**. Por ejemplo, primero recibís daño en un escudo regenerable o recuperable y después en la vida real de la nave. Eso permitiría naves muy distintas: una frágil con gran escudo, una pesada con muchísimo casco, una rápida con poca resistencia, etc. Pero también añade una capa más que quizá no queramos cargar al MVP.

Así que yo frenaría exactamente acá y resolvería una sola pregunta:

**Cuando estés jugando el nivel y un enemigo te dispare, ¿qué sensación querés que tenga recibir un impacto?**

¿Algo grave donde pensás *“me quedan dos errores antes de morir”*, algo progresivo donde ves deteriorarse tu nave durante el nivel, o algo más permisivo donde vas absorbiendo daño y gestionando reparación/escudos?

Esa sensación nos va a llevar bastante naturalmente hacia vidas, HP o un híbrido.


## [9] user

Ok. El sistema de vida, yo creo que implementaría moge tres sistemas de vida. El modo de HP para algo, estilo de supervivencia, y el modo mixto para el modo de infinito. Y el principal será el modo básico de tipo vidas. Esto, nos, más tráfico para el principal. y hace que los power-ups sean más valiosos. Las power-ups como los acoplamientos, los escudos de los power-ups, serán afectados cuando el jugador recibe daño. Pero yo creo que este será el principal. Yo creo que el jugador, por lo menos en el principal, permite que lo lastimen y tenga que ir moviéndose y esquivando todos los ataques. Por lo que el sistema de dificultad debe cambiarse en el modo de juego.


## [10] assistant

Perfecto. Esto ya aclara bastante el **modelo de supervivencia por modo**, y además define mejor la identidad del modo principal.

Para el **modo principal por niveles**, la lógica sería arcade clásica: **sistema de vidas**, donde recibir daño representa un error importante y el foco está en moverse, leer patrones y esquivar. Eso hace que el jugador no pueda simplemente “tanquear” ataques y también vuelve mucho más valiosos los power-ups defensivos y los acoplamientos.

También queda muy bien que **los sistemas defensivos sean una capa previa a la pérdida de vida**. Es decir, un impacto puede consumir o dañar primero algo equipado —por ejemplo un escudo, una mejora defensiva o cierto acoplamiento— y recién después comprometer una vida, dependiendo de cómo definamos ese objeto. Eso puede generar decisiones interesantes sin convertir el modo principal en una barra de HP disfrazada.

Para los otros modos podemos reservar comportamientos distintos:
- **Supervivencia:** HP, probablemente con gestión de daño acumulado y recuperación.
- **Infinito:** modelo híbrido, HP + vidas.
- **Principal:** vidas, con énfasis fuerte en evasión.

Y esto implica algo importante que dijiste al final: **la dificultad no debería ser universal**, sino adaptarse al modo. En el principal, la dificultad vendrá mucho de patrones, densidad de proyectiles, posicionamiento y castigo por errores. En supervivencia puede venir más de desgaste, resistencia y administración de recursos. En infinito puede combinar ambas cosas y escalar progresivamente.

Hay una consecuencia de diseño que conviene definir ahora para el modo principal: **qué significa exactamente “perder una vida”**.

Podemos tener varias opciones. Que la nave explote y reaparezca unos segundos después con invulnerabilidad temporal; que reaparezca inmediatamente en una posición segura; o que además perder una vida tenga consecuencias sobre el equipamiento actual, como perder algunos power-ups o acoplamientos.

Esto cambia muchísimo la tensión del juego. Mi siguiente pregunta sería justamente esa:

**Cuando el jugador pierde una vida en el modo principal, qué querés que pierda además de esa vida?**

Nada y simplemente reaparece; parte de sus power-ups; todos los power-ups temporales; algún acoplamiento; puntuación; o una combinación. Esa decisión va a definir bastante el riesgo del combate y el valor de las mejoras.


## [11] user

Yo creo que tener un sistemas de vidas, la idea es que el jugador, al perder una, reaparece en el mismo lugar con un tiempo de invulnerabilidad y que pierda los power ups y acomples


## [12] assistant

Sí, eso deja bastante clara la filosofía del modo principal.

Entonces, para el **modo por niveles**, podemos considerar definido por ahora:

- La nave tiene una cantidad limitada de **vidas**.
- Cuando recibe un impacto que cuenta como daño, **pierde una vida**.
- La nave reaparece aproximadamente en la misma zona donde fue destruida.
- Al reaparecer tiene unos segundos de **invulnerabilidad**, para evitar una cadena de muertes inmediata.
- Al morir, **pierde los power-ups acumulados y los acoplamientos que llevaba durante esa partida**.
- Por lo tanto, sobrevivir no solo conserva vidas: también conserva la potencia que fuiste construyendo durante el nivel.

Esto último me parece especialmente importante para el gameplay. Hace que la muerte tenga un costo mucho mayor que simplemente restar `1 vida`: podés pasar de estar completamente equipado a volver a una nave mucho más básica. Eso genera esa dinámica clásica de shoot 'em up donde **cuanto mejor estás jugando, más fuerte te volvés**, mientras que morir puede hacer que una sección difícil sea todavía más complicada.

Hay un detalle que dejaría marcado como pendiente: **no necesariamente todos los acoplamientos tienen que desaparecer siempre**. Más adelante podríamos tener algunos especialmente raros o permanentes durante el nivel, pero eso lo podemos decidir cuando diseñemos ese sistema.

### Ahora sí: ¿qué hace exactamente la nave básica?

Antes de empezar a hablar de enemigos, power-ups, tienda o progresión, terminaría de definir el moveset mínimo del jugador.

Por ahora tenemos:

**Movimiento:** libre en los dos ejes dentro del área jugable.

**Ataque principal:** disparo sostenido automático.

**Supervivencia:** evitar impactos; vidas limitadas; respawn con invulnerabilidad.

Y nos quedan principalmente **velocidad y acciones adicionales**.

Hay una mecánica muy común en shoot 'em ups que creo que vale la pena discutir para tu juego: tener **dos velocidades de movimiento**.

Normalmente te movés rápido para reposicionarte, pero al mantener una tecla entrás en un movimiento más lento y preciso. Es especialmente útil cuando empiezan a existir muchos proyectiles y necesitás pasar por espacios pequeños. Algunos juegos además muestran el *hitbox* real de la nave mientras mantenés esa tecla.

No estoy diciendo que tengamos que implementarlo, pero sí necesitamos decidir qué tipo de control querés.

Y después tenemos las acciones especiales. Para la **nave inicial del MVP**, ¿querés que sea deliberadamente sencilla —movimiento + disparo y nada más— o querés que desde el primer nivel exista alguna mecánica propia, como un ataque secundario, bomba, habilidad defensiva, dash o similar?

Yo resolvería esas dos cosas antes de pasar a diseñar los enemigos.


## [13] user

Ok. Algo que no hablamos es acerca de los ataques especiales que justo lo dijo. El ataque especial de la nave básica va a ser una bomba que destruye la mayoría de cosas y hace mucho daño. Con el tema de movimiento, podríamos hacer algo, de movimiento lento y movimiento rápido, para yo darle advers. Una tecla que te haga ir más lento, pero que puedas posicionar mejor, y el movimiento normal sea el rápido. Después veremos si tenemos un sistema de dash o movimientos de esquiva, pero por ahora, para el MVP, sería eso.


## [14] assistant

Perfecto. Entonces para la nave básica del MVP ya tenemos un moveset bastante definido:

- **Movimiento libre en 2D** dentro del área jugable.
- **Velocidad normal rápida** para reposicionarse.
- **Modo de movimiento lento/preciso** al mantener una tecla, pensado para esquivar patrones cerrados y posicionarse mejor.
- **Disparo principal sostenido/automático.**
- **Ataque especial: bomba**, que limpia gran parte de las amenazas en pantalla y hace mucho daño a enemigos resistentes.
- **Sin dash ni esquiva especial en el MVP.** Eso queda abierto para otras naves o para una etapa posterior.

La bomba además puede cumplir un rol interesante: no solo ser ofensiva, sino también un **recurso de emergencia**. Si el jugador queda encerrado por proyectiles, puede gastar una bomba para salvar una vida. Eso le da bastante valor estratégico sin añadir demasiada complejidad al control.

También dejaría pendiente una decisión que va a importar mucho después: **cómo se consiguen y cuántas bombas puede almacenar el jugador**. Podrían ser limitadas al inicio del nivel, recuperables mediante drops, comprables en ese sistema de estación que mencionaste, etc. No hace falta resolverlo todavía.

Con esto, creo que el núcleo del jugador para el MVP está suficientemente claro como para pasar a los **enemigos y amenazas del primer nivel**.

Ahí me interesaría definir primero la variedad mínima. Por ejemplo: enemigos básicos de formación, enemigos rápidos, enemigos que disparan desde lejos, enemigos resistentes, meteoritos/obstáculos y ese enemigo fuerte que aparece antes del tramo de descanso.

¿Cómo te imaginás los enemigos más básicos del nivel 1? ¿Querés que sean principalmente naves enemigas, criaturas/entidades espaciales, drones, meteoritos, o una mezcla?


## [15] user

Otra mejor, estos tipos de niveles, todavía no se en el lobby, pero estaría bueno que tenga un tipo de historia. Al progresar los niveles, aparezcan enemigos distintos, por ejemplo, más, o algo especial. Pues, por ejemplo, enemigos al inicio parecen naves. Después esos aliens como que traen un momento pesado, o evolucionan y ya parecen medio naves espaciales, como si fuesen entidades aliens gigantes. Pero eso todavía se falta definir, aunque sean naves gráficas para el modo de. Con respecto a lo demás, el enemigo más débil, la verdad que estaría bueno que aparezcan al principio unos pocos y después ya aparezcan con información o tipo, en forma simétrica, que aparente formación e ir variando. El enemigo más débil es más probable que se arranque información, el enemigo más fuerte menos probable. Hay variedad de enemigos, enemigos rápidos, enemigos que disparan, los cepillos comunes, otros misiles, otros rayos, y enemigos que solo buscan embestir. Ir variando, tener una variedad de muchos. También va a haber obstáculos, como edificios, montañas, cualquier cosa. Meteoritos también, pero eso depende del nivel. De a, el primer nivel sea en la Tierra, como que los aliens lo están atacando, meten meteoritos. En una salida, en algún nivel del espacio, ahí sí. También meter enemigos difíciles, para que tengan ataques especiales, que sean lentos, o en niveles avanzados que sean bastante poderosos, rápidos. Pero eso será para el futuro y requiere un balance bastante preciso.


## [16] assistant

Sí, acá ya aparece algo muy importante: **los niveles no solo cambian dificultad, también deberían contar una progresión del mundo y de la invasión**. Eso le da al modo principal una identidad mucho más fuerte que simplemente encadenar escenarios.

Para el primer nivel, me quedaría con esta dirección provisional: **la Tierra está siendo atacada**. Al principio aparecen pocas naves enemigas simples, casi como exploradores o unidades básicas. Después empiezan a entrar en formaciones simétricas o coordinadas, cambian sus patrones y se mezclan con amenazas distintas. A medida que avanza el nivel, la invasión se vuelve visualmente más evidente: ataques en el fondo, meteoritos u otros elementos cayendo, estructuras terrestres, montañas o edificios como parte del escenario y, eventualmente, enemigos más importantes.

También entendí que querés bastante variedad funcional de enemigos, no simplemente el mismo enemigo con más HP. Por ejemplo: naves rápidas, unidades que disparan proyectiles normales, otras que usan misiles, otras con rayos/láseres, enemigos que buscan embestir al jugador, unidades resistentes y enemigos especiales con ataques propios. Y la **formación también sería una propiedad importante**: los débiles aparecerían muy frecuentemente en grupos y patrones, mientras que cuanto más fuerte sea una unidad, menos habitual sería verla formando grandes grupos.

Más adelante, la propia naturaleza de los enemigos podría evolucionar narrativamente. Al comienzo parecen principalmente **naves alienígenas convencionales**, pero conforme avanza la campaña empezamos a descubrir algo más extraño: organismos, entidades alienígenas enormes, híbridos biomecánicos o criaturas que parecen haber evolucionado hasta funcionar prácticamente como naves. Eso todavía no lo cerraría, pero es una muy buena dirección para ir escalando tanto la estética como la amenaza.

Y los obstáculos también serían **dependientes del nivel**, no un sistema idéntico para todos. En la Tierra pueden ser edificios, relieve, restos, meteoritos del ataque, etc.; en un escenario espacial aparecen otras amenazas completamente distintas.

Hay un punto que me parece especialmente importante de lo que dijiste: **los enemigos avanzados no deberían diseñarse todavía**. Si empezamos a inventar ahora unidades rapidísimas con ataques especiales complejos, estaríamos diseñando dificultad sin haber establecido primero cuánto ocupa la nave, velocidad del jugador, densidad de proyectiles, tamaño de hitbox, etc. Esas cosas van a necesitar bastante balance después.

Para el MVP, entonces, yo reduciría el problema a conseguir **pocos arquetipos que combinen bien entre ellos**, no una cantidad enorme de enemigos.

La siguiente cosa que definiría es el propio **nivel 1 en la Tierra**, porque eso nos va a ayudar muchísimo a concretar tanto enemigos como historia.

No hace falta escribir todavía un guion. Solo me interesa establecer qué está pasando: ¿el jugador empieza ya defendiendo una ciudad/base durante la invasión, está intentando **escapar de la Tierra**, está atravesando territorio atacado para llegar a algún objetivo, o tiene una misión concreta como proteger/destruir/rescatar algo?

Esa decisión puede explicar de forma natural por qué avanzamos continuamente hacia arriba, qué vemos en el fondo y, sobre todo, **por qué aparece el boss al final del nivel**.


## [17] user

Habría que describir bien lo que pasa en el inicio de la animación, pero yo creo que nos encontramos en una etapa donde la Tierra está siendo invadida por alienígenas con naves espaciales, y seguramente nos encontremos en la primera oleada. Por esto, la animación de entrada debe ser un tipo de nave experimental en una base secreta que está saliendo a toda marcha para poder defender la Tierra. En el inicio deben aparecer como si fuesen casas o naves de la actualidad, tratando de defender. Estaría bueno hacer algo especial, pero tampoco tanto para el MVP. Lo podemos dejar para el final, pero tenelo en cuenta para el primer nivel en la etapa final. Teniendo en cuenta eso, la nave irá a defender lo que es la Tierra, seguramente sería en una ciudad o algún lugar importante, y se enfrentará a naves en todo ese nivel. No sé qué más hacer para el inicio del nivel. Tal vez unos aviones tratando de ayudar, que no sirven para nada por el nivel de tecnología de los aliens, pero no sé, no se me ocurre nada más. El objetivo sería tratar de eliminar todas las naves y poco más ya que seria el primer nivel, por ahi una nave grande para el boss.


## [18] assistant

Sí, con eso el **primer nivel ya tiene una premisa narrativa bastante clara** y no hace falta cargarlo de más para el MVP.

Yo lo dejaría conceptualmente así:

La Tierra está sufriendo la **primera gran oleada de una invasión alienígena**. Las fuerzas militares convencionales intentan responder, pero están claramente superadas. En una base secreta se activa de emergencia una **nave experimental**, todavía no pensada como un arma definitiva sino como una respuesta desesperada ante una amenaza que nadie esperaba enfrentar.

La animación inicial puede mostrar esa salida de forma breve: alarma, hangares abriéndose, despegue rápido y transición al gameplay. Después vienen esos 5–10 segundos de calma que ya habíamos definido, donde el jugador ve el escenario terrestre y entiende dónde está.

A partir de ahí, el nivel podría contar la invasión más por **lo que ocurre alrededor del jugador** que por diálogos o cinemáticas largas. Aviones actuales intentando interceptar naves alienígenas, explosiones lejanas, defensas terrestres disparando, naves enemigas atravesando el fondo, meteoritos o restos cayendo. Incluso podés mostrar alguna aeronave humana siendo destruida fácilmente para dejar claro desde el minuto uno que la diferencia tecnológica es enorme.

Lo importante es que esas cosas sean inicialmente **ambientales**, no sistemas que el jugador tenga que gestionar. Así podemos conseguir sensación de guerra sin convertir el MVP en una misión de escolta, defensa de NPCs o protección de edificios.

Y el objetivo del nivel puede ser deliberadamente sencillo: **contener la primera oleada y limpiar la zona de ataque**. El jugador avanza destruyendo las unidades invasoras hasta que aparece la nave más grande que dirige o acompaña esa oleada. Esa nave sería el boss del nivel 1. Al destruirla, no significa que ganamos la guerra; simplemente conseguimos nuestra **primera victoria contra los invasores**.

Eso además nos deja un buen cierre narrativo: victoria local, pero la invasión continúa. Sirve como gancho para que el nivel 2 pueda mostrar que el problema era muchísimo mayor de lo que parecía.

También me gusta que la nave experimental no sea desde el principio “la única esperanza de la humanidad” ni algo excesivamente épico. Puede convertirse en eso con el progreso de la historia. Al principio es simplemente **un prototipo que resulta ser capaz de enfrentarse a tecnología alienígena cuando el resto no puede**.

Para el MVP creo que esto alcanza sobradamente como contexto narrativo. Las escenas adicionales —aviones aliados, combate de fondo más elaborado, destrucción de la ciudad, comunicaciones, etc.— las dejaría anotadas para el **pulido final del nivel**, como dijiste.

Ahora creo que conviene volver al gameplay y concretar **qué enemigos necesita realmente este primer nivel**. Ya tenemos muchos arquetipos posibles, pero para el MVP no necesitamos veinte.

Podríamos empezar definiendo unos **4–6 arquetipos del nivel 1** y luego hacer variedad mediante formaciones y combinaciones. Por ejemplo: básico, rápido, tirador, embestidor, pesado y una amenaza especial previa al boss.

Pero antes quiero que me digas vos cuáles te parecen indispensables para que este primer nivel ya se sienta variado.


## [19] user

Ok. Para el MVP del nivel 1, deberíamos tener como mínimo un enemigo básico, que sería el típico enemigo básico, bastante fácil de destruir, que dispare muy lento y no haga mucho daño. Es básicamente lo peor de los enemigos. Después, un enemigo que dispare igual que el básico, que tenga un disparo un poco diferente, pero que se mueva bastante más rápido. Después tenemos como si fuese una evolución del básico, que tendrá todo lo mismo, con la diferencia de que disparará más rápido. Después, un enemigo súper rápido, que dispara lento, pero es de los más rápidos del nivel. Después, un enemigo más tanque y algo un investigador. Esos serían los básicos del nivel.
despues un enemigo mas pesado, que saque cada bastante tiempo un basico y que no dispare, pero se mueve superlento y tiene bastante vida.
despues, esta el boss que no hace falta decir nada todavia


## [20] assistant

Perfecto. Con esto ya podemos cerrar bastante bien el **roster mínimo de enemigos del nivel 1 para el MVP**.

Yo lo interpretaría así:

- **Básico:** poca vida, lento o velocidad normal, dispara muy lento. Es la unidad más débil y sirve para introducir formaciones y volumen.
- **Rápido ligero:** parecido al básico, pero con mucha más movilidad y un disparo algo distinto. Su peligro viene más de cómo entra y se posiciona que de su potencia.
- **Básico evolucionado / tirador:** comportamiento similar al básico, pero con una cadencia de disparo claramente mayor. Obliga al jugador a priorizarlo antes de que llene demasiado la pantalla.
- **Súper rápido:** de los enemigos más veloces del nivel. Dispara poco, pero su movimiento debería ser la amenaza principal.
- **Tanque:** bastante más resistente y probablemente más lento. Acá entendí “algo un investigador” como una parte que quedó mal transcripta; no asumiría todavía qué característica adicional querías darle.
- **Pesado transportador:** extremadamente lento, mucha vida, no ataca directamente, pero cada cierto tiempo **despliega/genera un enemigo básico**. Mientras permanezca vivo va incrementando la presión de la oleada.
- **Boss:** reservado para diseñarlo después.

Hay algo bueno en esta selección: aunque varios enemigos compartan una base sencilla, **cada uno amenaza al jugador por un motivo distinto**. Eso nos permite obtener mucha más variedad combinándolos en formaciones que creando quince unidades completamente diferentes.

Por ejemplo, un transportador solo no necesariamente es peligroso; pero si aparece mientras dos enemigos rápidos te obligan a reposicionarte, de repente el jugador tiene que decidir si arriesgarse a eliminarlo antes de que genere más unidades. Ese tipo de interacción es donde el nivel puede ganar profundidad.

Y no haría que estos enemigos aparezcan todos desde el minuto uno. El propio nivel puede ir **enseñándolos progresivamente**: primero básicos, luego variantes rápidas, después combinaciones, luego tanque/pesado, etc. Así cada aparición nueva funciona casi como una pequeña presentación de mecánica.

Antes de diseñar las oleadas, me interesa aclarar una cosa porque afecta mucho a todos estos enemigos: **¿cómo querés que se muevan?**

¿La mayoría debería seguir trayectorias/patrones predefinidos —entrar en V, curvas, diagonales, círculos, cruzarse, etc.— o querés que algunos tengan comportamiento más reactivo, por ejemplo perseguir al jugador o intentar colocarse frente a él?

Podemos perfectamente mezclar ambos, pero vale la pena decidir qué filosofía querés para el nivel 1.


## [21] user

para el nivel 1 deben tener trayectoria y patrones mas o menos definidos, pero a la hora de construccion no deben serlo ya que al progresar los niveles estos cambian y permitiria acoplar patrones/trayectorias a otros tipos de enemigos


## [22] assistant

Sí, eso define una regla de diseño bastante importante:

Para el **nivel 1**, los enemigos van a usar trayectorias y patrones relativamente predecibles, porque el objetivo también es enseñar al jugador a leer el combate. Pero conceptualmente esos patrones **no pertenecen al enemigo en sí**.

O sea, un “enemigo básico” no debería significar “entra siempre en diagonal desde arriba”. Ese mismo tipo de enemigo, en niveles posteriores, podría aparecer en V, hacer curvas, cruzar la pantalla, entrar desde los laterales o formar parte de una secuencia mucho más agresiva.

Eso nos permite separar tres cosas desde el diseño del gameplay:

**Tipo de enemigo** → qué tan resistente es, cómo dispara, qué velocidad base tiene, qué amenaza representa.

**Trayectoria** → cómo se desplaza por la pantalla.

**Formación/patrón de aparición** → cuántos aparecen, en qué posiciones, con qué separación y cómo se coordinan.

Todavía no estamos definiendo cómo se implementa esa separación; simplemente estamos estableciendo que **son conceptos independientes del juego**.

Además, para niveles posteriores esto abre posibilidades interesantes. Podés reutilizar un enemigo que el jugador ya conoce pero cambiar completamente la situación: seis básicos en una formación cruzada pueden ser más difíciles que introducir un enemigo nuevo. Y también podrías hacer que ciertos enemigos avanzados rompan esta regla y tengan comportamiento reactivo, persecución o movimientos menos predecibles.

Para el primer nivel mantendría la filosofía de **“legible pero progresivamente exigente”**: primero mostrar un patrón de forma aislada y después empezar a combinarlo con otros.

Creo que con esto ya tenemos suficiente para empezar a hablar de **cómo se construyen las oleadas del nivel 1**: cantidad de fases, cuándo introducimos cada enemigo, dónde ponemos el primer pico de dificultad y qué ocurre antes del boss.


## [23] user

OK. Yo creo que al inicio deben ir apareciendo unos pocos enemigos básicos, por ahí uno que otro rápido, ligero, y después ir metiendo formaciones de básicos, rápidos, ligeros, que aparezca algún tanque. Después en algún momento ir metiendo los súper rápidos, y meter uno o dos pesados transportadores entre el medio o el final del nivel. Más o menos cuando aparezcan esos transportadores o un poco más del final, aparecerían los básicos evolucionados. Y ya después que aparezca el jefe final. Es más o menos una idea, no es que será así, tal cual como dije. Después el tema de pico de dificultad y esas cosas, yo creo que habría que armar un mini sistema para ir metiendo como si fuese un gráfico del nivel de dificultad que va a tener el nivel en cada momento, para ir variando un poco y hacerlo de una forma más fácil. No es para hacerlo ahora, es más para la construcción, pero para que tengas una idea.


## [24] assistant

Sí, esa idea encaja muy bien con lo que venimos definiendo y, además, separa correctamente dos cosas distintas: **qué enemigos se introducen** y **qué nivel de presión tiene el combate en cada momento**.

Para el nivel 1, la progresión provisional podría ser algo así:

- Inicio con pocos enemigos básicos, para que el jugador entre en ritmo.
- Introducción temprana de algún rápido ligero.
- Primeras formaciones combinando básicos y rápidos.
- Aparición ocasional de tanques para empezar a cambiar las prioridades de objetivo.
- Más adelante entran los súper rápidos, aumentando la presión de movimiento.
- En la segunda mitad aparecen uno o dos transportadores pesados, que obligan a reaccionar antes de que generen demasiados básicos.
- Cerca de esa etapa se introducen los básicos evolucionados, aumentando la presión de proyectiles.
- Después se combinan varios de esos arquetipos en encuentros más exigentes.
- Finalmente, transición hacia el boss.

Y lo importante es que esto **no sea una escalera lineal**. Por ejemplo, después de una sección intensa con transportadores podría bajar bastante la presión durante unos segundos, volver con enemigos conocidos en formaciones simples y después empezar la escalada final.

Lo del gráfico de dificultad me parece una muy buena forma de pensar el nivel. No hace falta diseñar la herramienta ahora, pero sí podemos adoptar desde ya el concepto de una **curva de intensidad**: el nivel tendría un valor relativo de presión a lo largo del tiempo, con subidas, bajadas, picos y descansos. Después, durante la construcción, las oleadas se ajustarían para aproximarse a esa curva.

Y esa “dificultad” no tendría que significar solo cantidad de enemigos. Puede salir de varias cosas combinadas: densidad de proyectiles, velocidad de los enemigos, cantidad simultánea, tipos presentes, formaciones, obstáculos, poco espacio disponible, etc.

Por ahora lo dejaría como una **herramienta de diseño del nivel**, no como una mecánica del juego ni como una decisión técnica.

Creo que el siguiente bloque importante ya no son tanto las oleadas, sino los **power-ups y acoplamientos**, porque van a afectar muchísimo cómo evoluciona el jugador dentro de ese mismo nivel. Ahí convendría empezar por aclarar una cosa básica: qué diferencia funcional querés que exista entre un power-up y un acoplamiento, cuánto duran y cómo se consiguen.


## [25] user

Con respecto a los power-ups, la verdad que por ahora no es necesario hacer tantos. Con uno que te suba el daño o la cantidad de proyectiles, otro que sea de un escudo, por ahí de vez en cuando alguna vida extra. Estaría bueno tal vez ser un máximo de vidas en algún momento, o dependiendo del nivel de juego. Y por ahí municiones del ataque especial.
con respecto a los acoplamientos, por ahora, para hacerlo facil, sera dependiendo de el tipo de nave que elija el jugador. una puede ser misiles, armas laser, sistema de contramedidas (que destruyan disparos enemigos), etc.

Con respecto a la mayoría de los power-ups, deberían ser permanentes, entre comillas, o sea, hasta que se gasten, como es el caso de los mayores disparos, el escudo, o las municiones será hasta que el jugador reciba daño o cuando lance la habilidad especial. El único que será distinto será uno que será como invulnerabilidad por algún tiempo determinado. Después, con el tema de los acoplamientos, yo creo que, no sé si hacerlo de un disparo, o sea, que aguante algún tipo de daño, y eso de permitir al jugador no perder una vida y se elimina el acoplamiento al recibir ese daño. Todavía no sé, pero creo que es una buena idea eso.


## [26] assistant

Sí, con eso ya podemos separar bastante bien **power-ups** y **acoplamientos** sin entrar todavía en detalles técnicos.

Para el MVP, los power-ups pueden ser pocos y muy claros:

- **Potencia de disparo:** aumenta daño, cantidad de proyectiles o ambas cosas.
- **Escudo:** absorbe un impacto o cierta cantidad limitada de daño.
- **Vida extra:** aparece de forma poco frecuente.
- **Munición de ataque especial:** recupera bombas o cargas.
- **Invulnerabilidad temporal:** excepción al resto, porque dura por tiempo y no hasta consumirla.

Y me parece buena la idea de que la mayoría sean “permanentes dentro de la vida actual”: permanecen hasta que ocurre la condición que los consume. Si el jugador muere, como ya definimos, pierde los power-ups acumulados.

Para las vidas también podemos dejar previsto un **máximo**, aunque no hace falta fijar todavía si son 3, 5, etc. Incluso podría variar según modo o dificultad.

### Acoplamientos

Acá la diferencia queda mucho más interesante: no son simples aumentos numéricos, sino que **añaden sistemas o armas nuevas a la nave**.

Por ejemplo:

- módulo de misiles;
- módulo láser;
- sistema de contramedidas para destruir proyectiles enemigos;
- más adelante, drones, torretas auxiliares, armas laterales, etc.

Y por ahora su disponibilidad dependería de la nave elegida. Eso permite que las distintas naves no se diferencien únicamente por estadísticas.

Sobre la idea de que **el acoplamiento absorba un impacto**, creo que merece quedar como candidata porque puede generar una mecánica muy buena.

Podría funcionar conceptualmente así:

**Nave + acoplamiento → recibe impacto → se destruye el acoplamiento → la nave sobrevive.**

Eso genera una capa de protección natural sin agregar HP al modo clásico. Además produce una decisión interesante: si llevás un módulo láser muy poderoso, también sabés que cometer un error puede hacerte perderlo.

Pero no cerraría todavía que *todos* los acoplamientos funcionen así. Podríamos terminar teniendo categorías diferentes. Por ejemplo, un módulo físico externo puede romperse al impacto, mientras que otro sistema integrado quizá no tenga ese comportamiento.

También habría que decidir después qué sucede si el jugador tiene simultáneamente **escudo + acoplamiento**. Probablemente queramos un orden claro de protección, por ejemplo:

**invulnerabilidad → escudo → acoplamiento → vida**

pero eso todavía es diseño pendiente, no una decisión.

Con lo que tenemos ahora, creo que ya se empieza a formar un loop interesante:

**destruir enemigos → conseguir mejoras → aumentar poder y capacidades → intentar mantenerlas evitando impactos → morir implica perder ese progreso de combate.**

Eso hace que esquivar tenga valor no solo porque preserva vidas, sino porque conserva la **build temporal** que armaste durante el nivel.

La siguiente cuestión que me parece natural es **cómo aparecen estos power-ups y acoplamientos durante una partida**. Ahí entra lo que mencionaste antes del portaaviones/base: drops de enemigos, puntos específicos del nivel, compra con recursos, o una combinación.


## [27] user

Yo creo con el tema de los power-ups, que aparezcan al destruir enemigos específicos o importantes, pero que no ocurran siempre por el mismo enemigo, sino en la situación que se escoge. Por ejemplo, podemos hacer que un básico evolucionado dropee un power-up cuando estamos llegando al final, pero eso no quiere decir que todos los básicos evolucionados dropeen un power-up, sino está en ese momento. Y por ahí, añadir como si fuesen estructuras o algo que el jugador debe romper para que aparezcan. Con el tema de los acoplamientos debería ser un poco más difícil de obtenermos. Todavía no sé cómo. Por ahí, el destruir un sub-jefe o en los niveles más grandes, cuando destruyes a algún boss, podría dropear algún acoplamiento o alguna base que te las puedas poner.


## [28] assistant

Sí, y ahí aparece una distinción de diseño que me parece muy importante: **los power-ups no tendrían por qué pertenecer al enemigo; pueden pertenecer al momento del nivel**.

O sea, un básico evolucionado no tendría necesariamente una regla del tipo “tiene 20% de probabilidad de soltar mejora”. Podríamos decidir que, en una oleada concreta, **ese enemigo específico está marcado para soltar un power-up**. Así el diseñador del nivel controla cuándo darle recursos al jugador y evita depender demasiado del azar.

Eso encaja muy bien con la curva de intensidad que mencionaste antes. Por ejemplo, después de una sección complicada podemos garantizar una mejora, o justo antes del tramo final podemos darle al jugador una oportunidad de recuperar potencia.

También me gusta mucho la idea de las **estructuras destruibles**. Pueden servir para esconder o contener recursos sin que todo tenga que salir de enemigos: depósitos, contenedores, instalaciones alienígenas, restos, cargueros, etc. Y además podrían cambiar visualmente según el escenario.

### Power-ups

Entonces, por ahora los veo principalmente como recompensas **controladas por el nivel**:

- determinados enemigos pueden soltarlos en momentos concretos;
- ciertas estructuras pueden contenerlos;
- eventualmente podría existir algo de aleatoriedad, pero no necesitamos depender de ella;
- el nivel puede garantizar recursos en puntos donde el balance los necesite.

Eso también permite algo interesante más adelante: si un jugador muy habilidoso destruye una estructura difícil de alcanzar, puede obtener una mejora opcional que otro jugador simplemente ignora.

### Acoplamientos

Estos deberían sentirse bastante más importantes.

No los haría aparecer con la misma frecuencia que un power-up. Para el modo por niveles podrían funcionar como **recompensas especiales o hitos dentro de la partida**.

Las opciones que mencionaste encajan:

- derrotar un sub-jefe;
- destruir una unidad excepcional;
- encontrar una instalación o base especial;
- llegar a un punto determinado del nivel donde se pueda instalar uno;
- en niveles más avanzados, recompensa de determinados bosses.

Y esto conecta con la idea anterior del portaaviones/base. No necesariamente el acoplamiento tiene que aparecer flotando como un power-up. Podrías conseguir, por ejemplo, **el acceso a un módulo**, y después instalarlo en una estación aliada o punto especial del nivel.

No hace falta decidir todavía cuál de estos modelos vamos a usar.

Hay además una consecuencia narrativa interesante: en los primeros niveles los acoplamientos podrían ser tecnología humana experimental, pero conforme avanza la invasión podrías empezar a conseguir tecnología alienígena, piezas híbridas o incluso utilizar sistemas provenientes de esas entidades que mencionaste. Eso puede acompañar muy bien la evolución visual de la campaña.

Creo que ahora hay una decisión bastante importante que deberíamos resolver sobre los acoplamientos:

**¿el jugador puede llevar varios simultáneamente o la nave tiene una cantidad limitada de espacios?**

Por ejemplo, una nave podría tener `2` puntos de acoplamiento y tener que elegir entre misiles + contramedidas, láser + misiles, etc. O podríamos hacer algo mucho más simple inicialmente: **un único acoplamiento activo**, y encontrar otro obliga a reemplazar el actual.

Esto cambia bastante cuánto queremos acercarnos a un sistema de builds, así que conviene definirlo antes de seguir profundizando en ellos.


## [29] user

yo creo que para mvp que solo se pueda tener 1, pero para otros modos de juego o en un futuro que puedan tener varios


## [30] assistant

Sí, para el MVP conviene muchísimo más así.

Entonces dejamos el sistema de acoplamientos con esta regla inicial: **la nave puede tener un solo acoplamiento activo a la vez**. Ese acoplamiento agrega una capacidad nueva —misiles, láser, contramedidas, etc.— y, si el jugador consigue otro, más adelante definiremos si lo reemplaza automáticamente, si puede elegir conservar el actual o si existe algún punto específico donde hacer el cambio.

Eso mantiene el sistema entendible y fácil de balancear en el primer nivel. A la vez, no limita la visión futura: en otros modos, naves especiales o progresión avanzada, podría haber **varios slots de acoplamiento** y ahí sí empezar a aparecer builds mucho más complejas.

Además, esto nos da una separación bastante limpia entre las dos capas de mejora durante una partida:

**Power-ups** → mejoran capacidades que ya tenés o te dan recursos/protección.  
**Acoplamiento** → cambia de forma más profunda lo que la nave puede hacer, y solo podés llevar uno en el MVP.

Creo que ya tenemos bastante definido el núcleo momentáneo de combate y progresión dentro del nivel. El siguiente punto que vale la pena aclarar es **la puntuación y los recursos**, porque antes mencionaste gemas/puntos, una posible tienda durante la partida y otra tienda fuera de ella.

Ahí hay que decidir si querés que la puntuación sea simplemente una medida de rendimiento arcade, o si también funcione como moneda. Yo tendería a separar ambas cosas conceptualmente —score por un lado y recursos gastables por otro—, pero todavía no lo cerraría.

¿Vos cómo te imaginás eso? ¿Querés que matar enemigos dé puntos solamente, o que también pueda dar algún recurso distinto que sirva para comprar/mejorar cosas?


## [31] user

Yo creo que sí, vamos a tener un sistema de puntuación para el mvp, pero para el tema de los recursos, sera mas adelante Ya que para un MVP de un nivel no será posible implementarlo, ya que seguramente hagamos este tipo de en, o cada tres niveles, o cada vez que termine un nivel. O incluso durante un nivel bastante difícil de largo. Como el primer nivel no va a ser difícil ni largo, y como solo va a tener un solo nivel el MVP, no creo que será necesario implementarlo por ahora. Sigue el sistema de puntuación, que es un sistema de puntuación normal. Nada que destacar ahí.


## [32] assistant

Perfecto. Entonces para el MVP queda simple:

- **Sí hay puntuación.**
- Se obtiene de forma arcade tradicional, principalmente destruyendo enemigos y superando el nivel.
- Por ahora **no funciona como moneda** ni alimenta una tienda.
- El sistema de recursos/progresión económica queda para más adelante, cuando existan varios niveles o niveles suficientemente largos como para justificar puntos de compra, hangares o estaciones.
- Tampoco hace falta diseñar ahora una economía persistente.

Esto ayuda bastante a mantener el MVP acotado.

A esta altura ya tenemos bastante avanzado el núcleo del gameplay. Lo próximo que convendría definir es **qué información ve el jugador durante la partida**, porque ya tenemos varios sistemas que necesitan representación: vidas, puntuación, bombas, power-up activo, acoplamiento activo y quizá algún indicador del modo de disparo o estado de invulnerabilidad.

No quiero hablar todavía de diseño visual concreto de la UI, sino solamente de **qué información es indispensable mostrar en pantalla** para que se pueda jugar bien.


## [33] user

Lo que tiene que aparecer es la cantidad de vidas, la cantidad de habilidades especiales, si tiene acople debe aparecer, puntuación, estados de poner ups. Creo que eso es indispensable, no se si se te ocurre algo mas


## [34] assistant

Sí, con eso cubrís prácticamente todo lo indispensable del HUD del MVP.

Yo dejaría como mínimo:

- **Vidas restantes.**
- **Cantidad de bombas / ataques especiales disponibles.**
- **Puntuación actual.**
- **Power-ups activos**, incluyendo su estado cuando corresponda.
- **Acoplamiento equipado**, si existe.
- **Estado de invulnerabilidad** cuando reaparece o toma el power-up temporal; no necesariamente como texto, puede comunicarse visualmente en la nave.
- **Boss HP**, únicamente cuando aparece el jefe.
- Algún **feedback claro de daño/pérdida de mejora**, para que el jugador entienda inmediatamente qué perdió al recibir un impacto.

No agregaría mucho más para el MVP. Evitaría cosas como minimapa, contador de enemigos, barra de progreso permanente del nivel, estadísticas detalladas o multiplicadores si todavía no existe un sistema de combos.

Una cuestión que sí dejaría abierta es **cómo representar el power-up de disparo**. Si puede acumular niveles —por ejemplo, pasar de un disparo a dos, luego tres, luego más daño— necesitamos que el jugador pueda saber claramente en qué nivel de mejora está. Si en cambio cada power-up simplemente reemplaza un estado por otro, el HUD puede ser mucho más sencillo.

Y con esto creo que ya tenemos suficiente del HUD para volver a una parte bastante importante que todavía está abierta: **cómo funcionan exactamente los power-ups de disparo**. Ahí tenemos que decidir si se pueden acumular progresivamente, si existen niveles máximos y qué ocurre al morir.


## [35] user

Ok, con respecto al poder up de disparo, creo que el disparo y su forma es bastante para aclarar al jugador su nivel, la cantidad de disparos o si es solo más daño, hacer los disparos un poco más grande es suficiente por ahora.
Cabe aclarar que estos power up funcionan distinto dependiendo la nave, pero para la básica que añada las disparos es suficiente por ahora. Por ahí añadir un límite de cantidad modificable (para facilidad de escalado en un futuro)


## [36] assistant

Sí, eso alcanza para el MVP y además deja clara una regla útil de diseño: **el power-up no tiene por qué producir el mismo efecto en todas las naves**. Lo que hace es mejorar el sistema de disparo propio de cada nave.

Para la nave básica, entonces, el power-up de disparo sería simple: **aumenta la cantidad de proyectiles** y la propia forma visual del disparo comunica el nivel de mejora, sin necesitar un indicador numérico extra en el HUD. Si en algún caso la mejora fuera más daño en lugar de más proyectiles, bastaría con reforzarlo visualmente —por ejemplo, proyectiles más grandes o más contundentes—.

También dejaría definido que existe un **límite máximo de mejora**, pero no fijamos todavía el número. Ese máximo debería ser fácil de ajustar después según balance, dificultad, nave o modo de juego.

Y como ya habíamos establecido, al perder una vida se pierden esos power-ups acumulados, así que el jugador vuelve al disparo base.

Con esto, el sistema de power-ups del MVP ya está suficientemente claro. El siguiente bloque importante que todavía no definimos bien es **el boss del nivel 1**, pero también podemos dejarlo para más adelante si preferís y pasar primero a otra parte pendiente: menú, flujo del juego, condiciones de victoria/derrota, pausa, audio, etc.


## [37] user

La verdad que no tengo definido como será el boss del lvl1, lo dejaría para más adelante ya que será un boss sencillo al ser de primer nivel.


## [38] assistant

Sí, tiene sentido dejarlo abierto. Para el MVP alcanza con saber que el nivel termina con **un boss sencillo, legible y acorde a un primer nivel**, sin diseñar todavía sus patrones, fases ni estética concreta.

Hasta acá ya tenemos bastante cerrado el **gameplay central del nivel 1**: movimiento, disparo, bomba, vidas, power-ups, acoplamientos, enemigos, progresión de oleadas, puntuación y HUD. El boss puede resolverse después cuando tengamos más claro el ritmo final del nivel.

Yo pasaría ahora al **flujo completo del MVP**, porque ahí todavía faltan decisiones importantes fuera del combate: qué pasa desde que abrís el juego hasta que empezás el nivel, pausa, derrota, victoria, reinicio, selección de nave, ajustes mínimos, etc.

La primera pregunta sería: para este MVP con un solo nivel, ¿querés que ya exista **selección de nave**, aunque haya una sola disponible, o preferís que el jugador simplemente empiece con la nave básica y dejar el selector para cuando haya varias?


## [39] user

Yo creo que podría dejar la pantalla de construcción de naves para el MVP, pero solo dejar elegir una nave y mostrar que en el futuro aparecerán más. Más que eso no añadiría, con solo tener una nave para el MVP alcanzaría.


## [40] assistant

Sí, me parece una buena decisión para el MVP.

Entonces dejamos una **pantalla de selección/construcción de nave**, pero funcionalmente muy acotada:

- Solo habrá **una nave jugable**: la básica.
- Esa nave aparecerá seleccionable y mostrará sus características principales.
- El resto puede aparecer como contenido bloqueado, siluetas o espacios reservados, dejando claro que habrá más naves en el futuro.
- No hace falta implementar todavía un sistema real de desbloqueo, compra ni personalización profunda.
- La pantalla sirve tanto para el flujo del juego como para presentar desde el MVP que **la elección de nave será una parte importante del juego completo**.

Eso además nos permite mostrar desde temprano que distintas naves podrán tener disparos, habilidades y compatibilidad de acoplamientos diferentes, aunque en el MVP solo exista una.

Con esto, el flujo empieza a tomar forma:

**Inicio → menú principal → selección/construcción de nave → nivel 1 → victoria/derrota → volver al menú o reintentar.**

Lo siguiente que convendría definir es el **menú principal y las pantallas mínimas**. Para el MVP, ¿querés algo muy simple tipo *Jugar / Opciones / Salir*, o ya querés dejar visibles secciones futuras como *Campaña, Supervivencia, Infinito, Hangar*, aunque algunas estén bloqueadas o marcadas como “próximamente”?


## [41] user

La verdad que solo jugar opciones y salir, es suficiente para tema VP. Además, como es para un futuro, no lo añadiremos.


## [42] assistant

Sí. Para el MVP conviene mantenerlo limpio:

**Menú principal**
- Jugar
- Opciones
- Salir

Nada de modos futuros visibles, ni botones bloqueados, ni “próximamente”. Si todavía no existe, no hace falta mostrarlo.

El flujo quedaría así:

**Inicio → Menú principal → Jugar → Selección/construcción de nave → Nivel 1 → Victoria o derrota**

Y desde victoria/derrota habría que decidir qué opciones aparecen, pero probablemente algo simple como **Reintentar / Volver al menú** sea suficiente.

Dentro de **Opciones**, para el MVP yo no metería demasiado. Lo mínimo razonable sería:
- volumen general;
- música;
- efectos;
- quizá controles, si después decidimos que sean configurables.

Antes de cerrar eso, hay una decisión que todavía afecta bastante al juego y a la plataforma: **los controles del MVP**.

Hasta ahora sabemos que necesitamos movimiento, disparo, movimiento preciso y bomba. ¿Querés que el MVP sea exclusivamente **teclado**, o querés que también soporte gamepad desde esta primera versión? El soporte táctil para móvil lo dejaría fuera por ahora salvo que después la decisión web vaya en esa dirección.


## [43] user

La verdad que para el mvp estaría bueno que se pueda usar las flechas de movimiento y los botones mininos para ñas demás acciones y que se pueda usar de forma opcional el mover dispara y lanzar habilidad (las 3 mas usadas en estos juegos) con el museo y en configuraciones, vamos a poder configurar botones, pero no habilitarlo para mvp, solo dejar la opción de activar mouse o no


## [44] assistant

Sí, queda bastante claro para el MVP.

Los controles base serían:

- **Flechas:** movimiento.
- **Una tecla para disparar.**
- **Una tecla para movimiento lento/preciso.**
- **Una tecla para la habilidad especial/bomba.**
- **Mouse opcional:** permitiría mover, disparar y lanzar la habilidad especial usando el mouse.
- En **Opciones** habría un toggle para activar o desactivar el control con mouse.
- La **reasignación de teclas** queda pensada para el futuro, pero no se implementa en el MVP.

Yo solo dejaría pendiente una decisión menor: si cuando el mouse está activado **reemplaza** al teclado para esas acciones o si ambos esquemas pueden funcionar al mismo tiempo. Para el MVP, que ambos funcionen simultáneamente suele ser más cómodo, pero no hace falta cerrarlo ahora.

Con esto, creo que el siguiente punto importante sería terminar de definir **qué contiene la pantalla de Opciones del MVP** y después ya revisar si nos falta algún sistema jugable esencial antes de pasar a una especificación más formal.


## [45] user

La verdad es que las opciones que dijiste antes son las ideales. Solo añadiría la opción de activar o desactivar el mod. Después lo que dijiste antes para el MVP están bien.


## [46] assistant

Perfecto. Entonces la pantalla de **Opciones del MVP** queda bastante acotada y suficiente:

- Volumen general.
- Volumen de música.
- Volumen de efectos.
- Activar/desactivar control con mouse.
- Sin reasignación de teclas todavía.

Y asumo que con “activar o desactivar el mod” te referías al **mouse**, por el contexto anterior.

Con esto, el flujo externo al combate también está bastante definido. Nos quedan todavía algunas piezas funcionales importantes antes de poder considerar cerrada la visión del MVP: **pausa**, comportamiento de **victoria/derrota**, audio dentro del nivel y quizá la pantalla/animación inicial que mencionaste al principio.

Yo seguiría con pausa y fin de partida, porque son decisiones pequeñas pero necesarias para que el nivel se sienta como un juego completo y publicable.


## [47] user

Ok. La verdad, como es un juego 2K, y single player, el botón de pausa para el MVP, que solo aparezca el símbolo de pausa, y se pause de todo, es suficiente. Después, ya añadiremos un tipo de menú más formal, pero con eso es suficiente para el tema de pause. El tema de derrota, de elegir la forma de reiniciar el nivel o volver al menú. Para el MVP es suficiente.


## [48] assistant

Sí, con eso alcanza perfectamente para el MVP.

Entonces dejamos:

- **Pausa:** botón/símbolo de pausa simple. Al activarlo, se congela completamente la partida: enemigos, proyectiles, animaciones de gameplay y temporizadores relevantes. Sin menú de pausa completo por ahora.
- **Derrota:** pantalla simple con dos acciones: **Reintentar nivel** o **Volver al menú**.
- **Victoria:** conviene mantener la misma filosofía minimalista: una pantalla/animación corta de victoria y opciones para **volver al menú**; si querés, también puede existir “Reintentar” por comodidad, pero no es indispensable.

Con esto, el flujo funcional del MVP ya está bastante completo.

Lo siguiente que falta cerrar, antes de hacer una especificación revisable, es principalmente **audio y presentación**: música del nivel, efectos de disparos/explosiones, feedback visual, animación inicial y final. No hace falta definir assets concretos todavía, solo qué experiencia mínima querés que tenga para que se sienta publicable.


## [49] user

La verdad que tener mucho que avanzar ahí. Deben tener animaciones, cada cosa. Acá, seguir dejando algo más final, como las animaciones de disparo, las navecitas o enemigos, debe ir ya más o menos versión final para no ir modificándolos tanto. Obviamente el aspecto visual. Meter sonidos, o algún música de nivel sería bueno. Por ahí que cambie cuando llegue el boss para darle un poco de tensión, o momentos difíciles, sería bueno. Pero mucho más que eso, no.


## [50] assistant

Sí, con eso alcanza para cerrar esta parte sin meternos todavía en dirección artística detallada.

Para el MVP, la presentación audiovisual debería llegar ya con un **nivel cercano a final**, justamente para evitar rehacer después enemigos, nave, disparos y feedback básico. Eso incluye animaciones de movimiento/disparo, explosiones, impactos, aparición de enemigos, uso de bomba, pérdida de vida y transiciones simples de victoria/derrota. El pixel-art y la identidad visual concreta los podemos definir más adelante, pero no tendría sentido dejar todo como placeholders hasta el final.

En audio, mantendría un alcance chico pero cuidado: efectos de disparos, impactos, explosiones, pickups, bomba y UI; una música principal para el nivel; y un cambio de música al entrar al boss. Incluso podríamos reservar cambios de intensidad para algunos picos del nivel, pero eso ya sería pulido y no requisito duro del MVP.

Con lo que definimos hasta ahora, creo que ya estamos bastante cerca de poder hacer la **primera especificación revisable del MVP**, pero antes haría una última pasada funcional para detectar huecos. Nos faltaría revisar, sobre todo: condición exacta de victoria/derrota, cantidad inicial de vidas y bombas —aunque puedan quedar como valores de balance—, comportamiento de respawn, selección de dificultad si existe, y si el nivel debe tener algún sistema de checkpoint o siempre reiniciarse completo.

Después de eso sí tendría sentido que te presente una especificación consolidada para que la corrijamos antes de hablar de plataforma o arquitectura.


## [51] user

Ok, para el MVP no habrá sistema de dificultad, aunque sí debería estar implementado un código o de alguna forma que pueda escalarse fácilmente. Respecto a la condición de victoria, la victoria sería el jugador derrote al jefe, si salga con vida. Y la derrota es fácil, con que el jugador pierda sus vidas ya sería derrota. No nos compliquemos para el MVP, ya lo pensaremos en otro momento. La cantidad de vidas iniciales como que sea tres, acercándose sobre. No nos compliquemos, eso lo podemos cambiar fácilmente. Dormimos para las bombas, aunque te recuerdo que esto depende de cada nave. Lo único es que sí implementaremos sistema de checkpoints en algunos niveles difíciles o largos. Pero como para el MVP no lo necesitamos, no lo implementaremos por ahora.


## [52] assistant

Perfecto. Con esto ya podemos considerar **cerrada la definición funcional básica del MVP** sin entrar todavía en plataforma ni arquitectura.

Queda así:

- **Sin selector de dificultad en el MVP.** Más adelante habrá distintos niveles/modos de dificultad, así que cuando llegue la fase técnica habrá que evitar diseñar el juego de forma rígida alrededor de una sola configuración.
- **Victoria:** derrotar al boss y seguir con al menos una vida.
- **Derrota:** quedarse sin vidas.
- **Vidas iniciales:** 3 como valor provisional de balance.
- **Bombas/ataques especiales:** cantidad inicial pendiente de balance y dependiente de cada nave. Para la nave básica definiremos un valor simple cuando toque.
- **Checkpoints:** existirán conceptualmente para niveles largos o difíciles, pero **no forman parte del MVP**, porque el primer nivel será suficientemente corto como para reiniciarlo completo.
- Si perdés el nivel 1: reiniciás desde el principio o volvés al menú.
- Si derrotás al boss: nivel completado y victoria.

Y tomo una precisión importante de lo que dijiste sobre dificultad: no vamos a implementar ahora un “sistema de dificultades” que nadie usa, pero cuando diseñemos técnicamente los sistemas **sí deberemos evitar valores y comportamientos completamente acoplados al nivel 1**, porque sabemos que enemigos, modos y dificultad van a variar en el futuro. Eso lo discutiremos cuando corresponda, no ahora.

A esta altura, creo que ya respondimos prácticamente todas las preguntas necesarias sobre **qué debe hacer el juego del MVP**.

Nos queda una decisión grande que deliberadamente venimos postergando: **desktop vs web**. Y creo que ahora estamos mucho mejor posicionados para discutirla, porque ya sabemos qué tipo de juego queremos construir en vez de decidir la plataforma en abstracto.

Antes de pasar a arquitectura, yo haría justamente eso: comparar desktop y web **contra este shoot 'em up concreto** —pixel-art, teclado + mouse opcional, animaciones, audio, partículas, muchas entidades/proyectiles, Maven + Java, publicación de portfolio— y elegir la plataforma.

Una vez validada esa decisión, recién ahí tendría sentido que te presente la **especificación consolidada del MVP** y después empecemos con las decisiones técnicas.


## [53] user

Ok. Creo que podemos comenzar con esta discusión.


## [54] assistant

Sí. Ahora que ya sabemos **qué juego queremos**, la comparación cambia bastante: ya no es “web vs desktop” en general, sino cuál encaja mejor con un shoot ’em up vertical en Java, publicable y cómodo de mostrar en portfolio.


## [55] tool

The output of this plugin was redacted.


## [56] tool

The output of this plugin was redacted.


## [57] assistant

Bien. Con el juego ya bastante definido, ahora sí la discusión **desktop vs web** tiene criterios concretos.

Para tu caso, hay tres caminos reales:

1. **Desktop Java**
2. **Web manteniendo Java como núcleo**
3. **Web con JS/TS como runtime principal**

El tercero yo lo pondría momentáneamente en segundo plano, porque una de las decisiones ya tomadas es que **Java sea el lenguaje principal**. Cambiar a TS para facilitar navegador iría contra una parte importante de la identidad del proyecto.

### Desktop Java

Es el camino más natural para construir el juego que describimos.

Un shoot 'em up 2D con sprites, partículas, muchos proyectiles, audio, input de teclado/mouse, diferentes escenas, etc. encaja perfectamente con frameworks Java de juegos. Por ejemplo, libGDX sigue siendo multiplataforma y actualmente soporta desktop, navegador y otras plataformas. citeturn962151search10 FXGL también está orientado específicamente a juegos 2D y soporta Maven. citeturn962151search2turn962151search9

Las ventajas serían principalmente **menos fricción técnica alrededor del juego**. Tendríamos acceso directo al runtime Java/JVM, audio, archivos, input y renderizado sin tener que adaptar esas capacidades al sandbox del navegador.

La desventaja para tu objetivo de portfolio es bastante evidente:

**alguien tiene que descargar el juego.**

Eso introduce fricción. Un recruiter o alguien que entre a tu portfolio probablemente tenga mucha más facilidad para hacer:

> Jugar

y que se abra inmediatamente el juego, que descargar un `.exe`, `.zip` o instalador.

Podemos distribuir una aplicación Java incluyendo su runtime para que el usuario no necesite instalar Java por separado; precisamente la documentación de libGDX recomienda contemplar el empaquetado del JRE porque no conviene asumir que el jugador tiene el runtime correcto instalado. citeturn962151search20

---

### Web manteniendo Java

Esta es la alternativa que me parece más interesante para discutir en serio.

TeaVM puede tomar bytecode Java y compilarlo a JavaScript o WebAssembly para ejecutarlo en navegador, y tiene integración con Maven. citeturn138600search0turn138600search1

El resultado podría ser exactamente la experiencia que querías:

> Abrís la página → Jugar → empieza el juego.

Y como nuestro MVP es completamente local y cliente, **no necesitamos backend**.

Por lo tanto, el hosting podría costar literalmente `$0`. GitHub Pages permite sitios estáticos de hasta 1 GB y tiene un límite blando de 100 GB de transferencia mensual, muchísimo para el tráfico esperable de un proyecto de portfolio pequeño. citeturn138600search4 Cloudflare Pages actualmente ofrece requests y transferencia ilimitada para assets estáticos en el plan gratuito. citeturn138600search6turn138600search21

Así que podemos sacar de la discusión una preocupación que tenías:

**el hosting no debería ser el motivo para descartar web.**

El problema de web está en otro lado.

TeaVM vive dentro del entorno del navegador y necesita interoperar con APIs web para Canvas, JavaScript, etc.; su propia documentación proporciona JSO específicamente para esa interacción. citeturn962151search3 Eso significa más restricciones y más superficie de integración que ejecutar directamente sobre desktop.

Y las bibliotecas importan mucho: no podemos asumir que cualquier dependencia Java que agreguemos posteriormente va a funcionar correctamente al transpilarla para navegador.

---

### Hay una cuarta posibilidad bastante interesante

No necesariamente tenemos que hacer:

**desktop O web.**

Podemos elegir tecnologías que hagan plausible publicar **ambos targets**.

libGDX, por ejemplo, explícitamente soporta navegador además de Windows/Linux/macOS. citeturn962151search10 Su backend HTML tradicional utiliza GWT. citeturn138600search2

Pero hay una pequeña fricción con una decisión nuestra: el tooling oficial de libGDX está fuertemente orientado a Gradle. Hay documentación para Maven y soporte desktop con Maven, pero su generador oficial utiliza Gradle. citeturn962151search0turn962151search8

Eso no descarta libGDX, pero **Maven es una restricción que tenemos que poner sobre la mesa cuando comparemos frameworks**.

FXGL encaja más naturalmente con Maven y está orientado a 2D; su documentación incluso declara soporte web, aunque antes de basar el proyecto en ese target yo querría investigar específicamente qué tan maduro y práctico es en 2026. citeturn962151search1turn962151search2

---

## Para *nuestro* juego

Ahora que conozco el gameplay, hay algo que cambia mi percepción.

El juego no necesita casi ninguna ventaja particular de una aplicación desktop:

No hay multiplayer, servidor, archivos gigantes, modding, mundo abierto, sistemas pesados ni integración profunda con el sistema operativo.

Tenemos:

**sprites + movimiento + muchas entidades/proyectiles + colisiones + audio + input + UI + niveles.**

Eso es perfectamente razonable para navegador.

Y el beneficio de portfolio es considerable:

**Portfolio → abrir proyecto → jugar.**

Ese flujo me parece especialmente valioso para este proyecto.

Por eso, sin cerrar todavía la decisión, mi inclinación actual sería:

> **Investigar seriamente web con Java antes de elegir desktop.**

No porque desktop sea peor técnicamente —probablemente sería el camino más sencillo— sino porque **web aporta una ventaja concreta al producto final** que en este caso puede justificar cierta complejidad adicional.

Pero pondría una condición importante:

> No elegiría TeaVM “a mano” + Canvas + construir nosotros mismos toda la capa de juego.

Eso contradice bastante nuestra decisión inicial de no construir infraestructura que ya debería resolver un framework.

Lo que deberíamos discutir ahora es más específico:

**¿cuánta complejidad adicional estás dispuesto a aceptar para conseguir el “abrir un link y jugar”?**

Porque si me decís que esa experiencia es una prioridad fuerte del portfolio, yo investigaría primero un stack Java que pueda producir web. Si es solamente un nice-to-have, desktop probablemente vuelva a tener ventaja.

Y después de responder eso, nuestra siguiente investigación debería ser **framework por framework**, no arquitectura todavía: qué opciones Java 2D actuales funcionan bien con Maven, cuáles permiten web de verdad y qué sacrificios tendría cada una. memcite


## [58] user

OK. Yo creo que podríamos investigar la opción de hacerlo web con Java como base y utilizar el compilado web. Yo antes dije Maven porque es lo que utilizaban antes, pero como es un empaquetador, creo que no será difícil acostumbrarme. Esto, si lo dices que es necesario, lo podemos intercambiar, pero igualmente, preferiría Maven, pero si no hay opción, podemos hacer el intercambio a Grendel. Después, yo creo que podemos investigar y ver si es viable esta opción. Si no, volveremos a Java en desktop.


## [59] assistant

Sí, ese criterio me parece bueno: **primero validar si Java→web es realmente viable para este juego**; si la fricción resulta demasiado alta, desktop queda como fallback natural. Y Maven puede seguir siendo preferencia, no una restricción absoluta.


## [60] tool

The output of this plugin was redacted.


## [61] tool

The output of this plugin was redacted.


## [62] assistant

Sí: después de revisar el estado actual, **la opción web con Java es viable y merece ser nuestra primera candidata**, pero con una condición importante: yo cambiaría la preferencia de Maven a **Gradle si usamos libGDX + TeaVM**.

TeaVM por sí mismo funciona perfectamente con Maven y soporta generación a JavaScript y WebAssembly GC mediante su plugin oficial. citeturn830996view1 El problema aparece cuando lo combinamos con un framework de juego serio. libGDX sí soporta navegador y sigue siendo multiplataforma, pero su soporte Maven oficial está muy limitado: la propia documentación dice que con Maven solo desktop está realmente comprobado y que para cross-platform conviene usar Gradle. citeturn830996view3turn613283search7

Y acá aparece una opción bastante atractiva: **libGDX + gdx-teavm**. Ese backend permite ejecutar aplicaciones libGDX en navegador compilándolas con TeaVM a JavaScript o WebAssembly. Actualmente tiene soporte explícito para web, assets, FreeType y hasta controllers, y su flujo recomendado para aplicaciones es mediante un plugin de Gradle. La versión actual publicada del backend está alineada con libGDX 1.14.2 y TeaVM 0.15.0. citeturn830996view0

Eso cambia bastante mi evaluación anterior.

### Primera candidata

Yo investigaría con esta hipótesis:

**Java + libGDX + Gradle + gdx-teavm → Web**

y manteneríamos también la posibilidad de:

**el mismo core → Desktop**

libGDX ya estructura naturalmente los proyectos con un módulo `core` y launchers/targets separados, incluido desktop y web. citeturn830996view2 Eso encaja muy bien con nuestra idea anterior de que el juego no quede casado innecesariamente con una plataforma.

Además, TeaVM está bastante más avanzado de lo que podía parecer hace unos años. Su línea actual soporta Java moderno y WebAssembly GC; TeaVM 0.13 incluso cerró diferencias importantes entre sus backends JS y Wasm GC, incluyendo soporte de coroutines para emular ciertas operaciones de threads. citeturn830996view4

### ¿Maven o Gradle?

Acá haría una distinción.

**Maven no es técnicamente imposible.** TeaVM tiene soporte Maven oficial. citeturn830996view1

Pero si nuestra elección termina siendo libGDX + gdx-teavm, estaríamos luchando contra el ecosistema si insistimos en Maven. El generador de libGDX, su estructura multiplataforma y el backend gdx-teavm están pensados principalmente alrededor de **Gradle**. citeturn830996view0turn830996view2

Entonces cambiar de Maven a Gradle no sería “porque Gradle sea mejor”, sino porque **para este stack concreto reduce riesgo e integración manual**.

Y sí, creo que te acostumbrarías relativamente rápido. Maven y Gradle cumplen roles parecidos de build/dependency management, aunque Gradle tiene una filosofía distinta y bastante más programable. No cambiaría nada de Java como lenguaje principal.

### Pero todavía no lo declararía ganador

Hay algunas cosas que tenemos que validar específicamente para **nuestro juego** antes.

Quiero comprobar que con ese stack no tengamos problemas relevantes con:

1. rendimiento con muchos enemigos, proyectiles y partículas;
2. audio y cambio de música en runtime;
3. teclado + mouse;
4. pixel-art y escalado/resoluciones;
5. carga de sprites, animaciones y assets;
6. UI de menú/HUD;
7. tamaño y tiempo de carga inicial del build web;
8. compatibilidad razonable Chrome/Firefox/Edge/Safari;
9. debugging desde Java/source maps;
10. dependencias externas: qué cosas podemos y no podemos utilizar cuando TeaVM compila el juego.

Especialmente el último punto. El backend web tradicional de libGDX mediante GWT solo soporta un subconjunto de Java y tiene restricciones en algunas extensiones. citeturn830996view2 gdx-teavm evita parte de ese modelo al trabajar desde bytecode, pero **no significa que cualquier biblioteca JVM vaya a funcionar automáticamente en navegador**. TeaVM implementa su propia capa de class library y existen diferencias respecto de una JVM normal. citeturn613283search32

Así que nuestra estrategia debería ser:

> **Web-first, pero no web-at-all-costs.**

Si las pruebas muestran que libGDX + TeaVM nos deja construir el juego normalmente y el esfuerzo extra es razonable, elegiría web por la ventaja enorme de poder poner un enlace en el portfolio y jugar inmediatamente.

Si descubrimos restricciones que empiezan a dictar cómo tenemos que diseñar el juego, **abandonamos el target web y pasamos a libGDX desktop**, en vez de deformar el proyecto para mantenerlo.

Y sí: si elegimos este camino, **Gradle pasa a ser ahora mismo mi candidato preferido por encima de Maven**, aunque todavía no lo fijaría como decisión hasta terminar esta validación.

El siguiente paso que haría es precisamente esa investigación de viabilidad: revisar esos diez puntos específicamente para **libGDX + gdx-teavm**, y al final darte un veredicto tipo **verde / amarillo / rojo** para usarlo en nuestro MVP. memcite


## [63] user

OK, yo creo que la opción que dices es correcta. Vamos a seguir investigando y veremos que si es viable esta opción.


## [64] assistant

Bien. Voy a validar la opción **Java + libGDX + gdx-teavm** contra las necesidades reales del MVP: rendimiento 2D, input, audio, assets, UI, debugging, compatibilidad web y límites de dependencias. Al final te doy un veredicto claro de viabilidad, sin entrar todavía en arquitectura.


## [65] tool

The output of this plugin was redacted.


## [66] tool

The output of this plugin was redacted.


## [67] assistant

La investigación ya da una señal bastante positiva: el backend no es un experimento abandonado. **gdx-teavm tiene release 1.6.1, está alineado con libGDX 1.14.2 y TeaVM 0.15.0, y su flujo recomendado hoy es Gradle**, con builds web tanto JavaScript como Wasm. 

También confirmé dos puntos importantes para nuestro MVP: libGDX abstrae teclado/mouse también en navegador, y su `AssetManager` maneja texturas, atlas, música y sonidos.


## [68] tool

The output of this plugin was redacted.


## [69] tool

The output of this plugin was redacted.


## [70] assistant

Sí. Con lo revisado hasta ahora, **la opción Java + libGDX + gdx-teavm pasa la primera prueba de viabilidad**. No veo ninguna limitación estructural que nos obligue a volver a desktop para el juego que definimos.

### Evaluación para nuestro MVP

**🟢 Renderizado 2D, sprites, animaciones y partículas.** libGDX está específicamente preparado para este tipo de renderizado mediante `SpriteBatch`, atlas de texturas y sistemas de partículas. Además, la propia documentación recomienda batching, atlas y pooling para manejar grandes cantidades de sprites/partículas eficientemente. citeturn424641search2turn424641search0

Para nuestro shoot 'em up —naves, proyectiles, explosiones y enemigos 2D— esto encaja muy bien. Eso sí: nadie puede garantizar ahora “X miles de proyectiles a 60 FPS” sin medir nuestro juego. Eso habrá que probarlo posteriormente con un pequeño benchmark.

**🟢 Teclado + mouse.** No hay problema conceptual. libGDX expone teclado y mouse también en aplicaciones de navegador y permite tanto consultar continuamente el estado de teclas/botones como trabajar mediante eventos. Eso encaja directamente con flechas + disparo mantenido + movimiento preciso + bomba + mouse opcional que definimos. citeturn483342search2turn483342search3turn483342search6

**🟢 Audio.** libGDX proporciona abstracciones separadas para efectos de sonido y música, y `AssetManager` puede cargar ambos. Por lo tanto, disparos, explosiones, música del nivel y cambio de música al boss entran dentro del stack normal del framework. citeturn760771view2turn483342search8

Hay particularidades web de formatos y algunas funciones avanzadas de audio que no son idénticas en todos los backends, así que cuando elijamos formatos de assets tendremos que verificar browser compatibility. Para nuestro uso básico de volumen, reproducción, efectos y música no lo considero un bloqueo. citeturn483342search8

**🟢 UI.** libGDX ya tiene `scene2d`/`scene2d.ui`, pensado precisamente para menús, HUDs y overlays. No necesitaríamos construir nuestro propio framework de UI para hacer Jugar/Opciones/Salir, selección de nave, HUD y pantallas de victoria/derrota. citeturn483342search9turn424641search6

Eso respeta una de nuestras decisiones iniciales.

**🟢 Assets.** `AssetManager` administra texturas, atlas, fuentes, música y sonidos, incluyendo carga asíncrona. Para una versión web además nos viene muy bien poder mostrar una pantalla de carga real mientras el navegador descarga los recursos. citeturn760771view2

**🟢 Pixel-art y resoluciones.** libGDX dispone de cámaras y viewports independientes del tamaño físico de la ventana, así que podemos establecer una resolución lógica para el juego y adaptarla a distintas pantallas. citeturn252156search6

La estrategia exacta de resolución/escalado la dejaremos para diseño visual.

**🟢 Debugging.** TeaVM actualmente dispone de servidor de desarrollo, recarga y source maps, incluidos los backends JavaScript y WebAssembly GC. También puede desofuscar stack traces para mostrar trazas Java más útiles. citeturn760771view1

Esto era algo que me preocupaba bastante más y resultó estar bastante bien cubierto.

### 🟢/🟡 JavaScript vs WebAssembly

gdx-teavm actualmente puede generar **ambos** desde el mismo proyecto:

**Java → TeaVM → JavaScript**

o

**Java → TeaVM → WebAssembly**

El backend actual de gdx-teavm soporta los dos targets explícitamente. citeturn760771view0turn424641search1

No decidiría todavía cuál usaremos para producción. Podemos incluso desarrollar teniendo disponibles ambos y comparar tamaño, rendimiento y compatibilidad cuando tengamos algo jugable.

Esto es una ventaja interesante: **elegir web no significa elegir ahora JavaScript vs Wasm.**

### 🟡 Dependencias Java

Este es el principal punto que sí tenemos que vigilar.

TeaVM **no ejecuta una JVM completa dentro del navegador**. Tiene su propia implementación de un subconjunto de la biblioteca estándar Java y existen diferencias respecto de ejecutar exactamente el mismo código sobre HotSpot/OpenJDK. citeturn760771view4

Por eso no podremos pensar:

> “Está en Maven Central → puedo instalarlo → funcionará en web.”

Una dependencia que utilice APIs JVM no disponibles, JNI, determinadas capacidades de filesystem, reflexión compleja u otras funciones específicas de desktop podría darnos problemas.

Eso no debería afectar al núcleo del juego si trabajamos principalmente con Java + libGDX, pero **cada dependencia adicional tendrá que evaluarse también por compatibilidad TeaVM**.

### 🟡 gdx-teavm no es el backend oficial de libGDX

También quiero remarcar esto.

gdx-teavm es un proyecto separado del core de libGDX. No significa que esté abandonado —al contrario, actualmente tiene release `1.6.1`, soporte libGDX `1.14.2` + TeaVM `0.15.0`, más de 1500 commits y targets JS/Wasm activos—, pero introduce una dependencia tecnológica más que una aplicación desktop libGDX pura no tendría. citeturn760771view0turn424641search1

Por eso mantendría **desktop como plan B real**, no simplemente teórico.

---

## Gradle: acá sí cambiaría nuestra decisión original

Después de investigar esto, **yo usaría Gradle en lugar de Maven si seguimos por web**.

La documentación oficial de libGDX es muy explícita: Maven es posible, pero su soporte cross-platform está muy limitado y solo desktop está comprobado; la recomendación práctica para multiplataforma es Gradle. citeturn760771view3

Y gdx-teavm recomienda precisamente su **plugin de Gradle**, que ya se ocupa de TeaVM, backend, assets, output web y tareas para ejecutar/buildar JS y Wasm. citeturn760771view0

Así que acá no veo demasiado beneficio en intentar conservar Maven.

Yo cambiaría provisionalmente:

> ~~Java + Maven~~

por:

> **Java + Gradle**

No porque Gradle sea una decisión arquitectónica del juego, sino porque es el camino soportado por las herramientas que estamos evaluando.

---

# Mi semáforo actual

| Área | Estado |
|---|---|
| Java como lenguaje principal | 🟢 |
| Gameplay 2D shoot 'em up | 🟢 |
| Muchos sprites/proyectiles | 🟢* |
| Pixel-art | 🟢 |
| Teclado | 🟢 |
| Mouse | 🟢 |
| Audio | 🟢 |
| Música/boss music | 🟢 |
| Menús/HUD | 🟢 |
| Animaciones/partículas | 🟢 |
| Assets | 🟢 |
| Debugging web | 🟢 |
| JavaScript build | 🟢 |
| WebAssembly build | 🟢 |
| Dependencias Java arbitrarias | 🟡 |
| Madurez adicional de gdx-teavm | 🟡 |
| Maven + web | 🔴/🟡 |
| Gradle + web | 🟢 |

El asterisco de rendimiento significa únicamente **“técnicamente apropiado, pero medir antes de comprometernos”**.

### Conclusión provisional

Yo **seguiría con la opción web**.

Nuestra candidata pasa a ser:

**Java + libGDX + Gradle + gdx-teavm → navegador**

manteniendo un posible target desktop de libGDX como salida si encontramos problemas posteriormente.

Todavía **no la declararía decisión final**. Antes de hacerlo, haría una última validación mucho más práctica: qué tan complicado sería montar un prototipo técnico mínimo que únicamente pruebe **renderizado masivo + input + audio + assets + build web**, sin implementar nada del juego real.

Eso nos permitiría establecer un criterio concreto de “si pasa estas pruebas, elegimos web” antes de empezar la implementación del MVP. memcite


## [71] user

OK. ¿Podrías hacer eso tú?


## [72] assistant

Sí. Puedo hacer una **validación técnica aislada**, sin tocar todavía el proyecto real ni convertir esto en implementación del MVP. La trataría como una prueba de viabilidad: verificar qué exige el setup, qué tan limpio es el build web y dónde están los riesgos reales antes de comprometernos con la plataforma.


## [73] tool

The output of this plugin was redacted.


## [74] tool

The output of this plugin was redacted.


## [75] assistant

Sí. Y creo que conviene que **esa prueba la haga yo como un spike técnico separado**, no como parte del juego. Así no contaminamos el proyecto con decisiones provisionales.

Por ahora, sin escribir código todavía, ya puedo definir exactamente qué tendría que demostrar esa prueba. gdx-teavm ofrece actualmente tareas Gradle separadas para ejecutar/buildar los targets JavaScript y WebAssembly, y el plugin se ocupa del backend web, assets y servidor local, así que el escenario que queremos comprobar está soportado explícitamente por la herramienta. citeturn187842view0

### La prueba que haría

No tendría historia, sprites definitivos ni arquitectura del juego. Sería deliberadamente fea y descartable.

**1. Renderizado / estrés**

Simularíamos una situación bastante peor que el nivel 1:

- cientos de enemigos/sprites;
- cientos o miles de proyectiles;
- partículas/explosiones;
- movimiento constante;
- colisiones simples;
- HUD básico.

La pregunta sería simplemente: **¿podemos mantener un framerate razonablemente estable en navegador?**

No necesitamos demostrar que soporta una barbaridad absurda. Necesitamos suficiente margen para que nuestro shoot 'em up no esté funcionando al límite desde el primer nivel.

**2. Input**

Probaríamos exactamente lo que definimos para el MVP:

- flechas;
- disparo sostenido;
- tecla de movimiento lento;
- bomba;
- mouse opcional;
- combinar teclado y mouse.

Hay un detalle web real que tendremos que contemplar: teclas como las flechas pueden activar comportamientos del navegador, como desplazamiento de la página, pero libGDX permite capturarlas e impedir esas acciones. citeturn187842view2

**3. Audio**

Probaríamos simultáneamente:

- música;
- varios efectos de disparo;
- explosiones;
- cambio de música;
- control de volumen.

Acá ya encontré una restricción que tendremos que aceptar independientemente de TeaVM: los navegadores generalmente **requieren una interacción del usuario antes de permitir audio**. citeturn187842view2

Para nosotros no supone casi ningún problema porque tenemos:

**Página carga → menú → usuario pulsa Jugar**

Ese click ya nos da naturalmente una interacción antes de empezar música/gameplay.

**4. Assets**

Probaría carga de:

- sprites;
- texture atlas;
- animaciones;
- fuente;
- música;
- efectos.

Y comprobaríamos el peso inicial y cuánto tarda en estar listo el juego.

Esto es particularmente importante para portfolio: no quiero que consigamos “jugar desde un enlace” pero el visitante vea una pantalla negra durante 15 segundos.

La carga web de assets puede organizarse para no precargar obligatoriamente todo antes de empezar; libGDX documenta precisamente el uso de `AssetManager` para diferir recursos que no sean necesarios inicialmente. citeturn187842view2

**5. Pixel-art**

Probaríamos:

- resolución lógica baja;
- diferentes tamaños de ventana;
- fullscreen;
- escalado;
- sprites sin blur;
- distintos ratios de pantalla.

No necesitamos definir todavía cuál será la resolución final.

**6. JavaScript contra WebAssembly**

Este test es especialmente interesante.

Haríamos exactamente el mismo escenario en:

**Java → JavaScript**

y

**Java → Wasm**

porque el backend actual permite declarar ambos targets desde el mismo proyecto. citeturn187842view0

Compararíamos:

- FPS;
- estabilidad;
- tiempo de compilación;
- tamaño del build;
- tiempo de carga;
- debugging;
- comportamiento en navegadores.

No asumiría que Wasm necesariamente gana. Elegiríamos basándonos en mediciones.

### 7. Navegadores

Como mínimo probaría:

**Chrome / Edge / Firefox**

y verificaría Safari a nivel de compatibilidad aunque probablemente no podamos hacer todas las pruebas locales desde Windows.

No buscaríamos “funciona absolutamente idéntico en cualquier navegador existente”; buscaríamos una matriz de soporte razonable que podamos documentar.

### 8. Restricciones Java

Esta sería probablemente la prueba más importante desde el punto de vista técnico.

TeaVM compila bytecode Java hacia JavaScript/Wasm y mantiene su propia implementación de las APIs Java disponibles; no tenemos una JVM completa viviendo dentro del navegador. citeturn187842view1turn493373search5

Por eso probaría temprano cualquier cosa que sepamos que probablemente vaya a necesitar el juego y que pueda rozar:

- reflexión;
- filesystem;
- serialización;
- librerías externas;
- threading;
- APIs específicas de JVM.

El juego que diseñamos hasta ahora no depende demasiado de ninguna de esas cosas, lo cual juega bastante a nuestro favor.

---

## Criterio de aprobación

También pondría condiciones **antes** de hacer el spike, para no terminar justificando web porque nos gusta la idea.

### 🟢 WEB APROBADA

Si:

- rendimiento tiene margen;
- input funciona perfectamente;
- audio no genera problemas graves;
- assets cargan razonablemente;
- JS o Wasm funciona de manera consistente;
- desarrollar/debuggear sigue siendo cómodo;
- las restricciones de TeaVM no empiezan a invadir el diseño del juego.

Entonces:

> **Java + libGDX + Gradle + gdx-teavm + Web queda como plataforma oficial.**

### 🟡 WEB CON RESERVAS

Si funciona, pero encontramos una o dos molestias manejables —por ejemplo determinado formato de audio o alguna librería incompatible— decidimos si el beneficio de portfolio compensa esas restricciones.

### 🔴 VOLVEMOS A DESKTOP

Si necesitamos empezar a hacer cosas como:

> “No podemos diseñar este sistema así porque TeaVM…”

> “Esta dependencia esencial no funciona…”

> “Tenemos que mantener dos implementaciones de demasiadas cosas…”

> “El rendimiento está demasiado justo…”

entonces no insistimos.

Pasamos a:

**Java + libGDX + Gradle → Desktop**

y seguimos construyendo el juego.

---

Hay además algo que me deja más tranquilo con esa estrategia: **el core de libGDX no desaparece si falla TeaVM**. gdx-teavm justamente funciona como backend de libGDX; el propio proyecto separa backend web, GLFW y otros targets. citeturn187842view0

Así que nuestro experimento no sería “apostar todo a una tecnología web rara”. Estaríamos comprobando si podemos agregar **web como plataforma de ejecución de un juego libGDX en Java**.

Y mantengo la restricción que definimos al principio: **todavía no voy a crear ese spike ni escribir código**. Primero terminamos descubrimiento/especificación. Cuando lleguemos a la validación técnica, esta sería una de las primeras cosas que construiría, antes de implementar el juego real. memcite


## [76] user

Ok, entonces ya más o menos teníamos cerrado lo que sería la primera etapa de planificación, ¿no es cierto? Lo siguiente qué sería? ¿Sería planificar lo que sería el proyecto en general, además del MVP o otras cosas?


## [77] assistant

Sí. **La primera etapa de planificación ya está prácticamente cerrada**: visión del juego, género, loop principal, alcance del MVP, nivel 1, nave básica, enemigos, power-ups, acoplamientos, HUD, flujo de menús y dirección provisional de plataforma.

Lo siguiente no sería saltar directo a arquitectura. Yo haría una **segunda etapa de diseño del producto**, más amplia que el MVP, para entender hacia dónde puede crecer el juego sin obligarnos todavía a implementarlo.

Ahí definiríamos, a nivel funcional y conceptual:

- estructura general de la campaña;
- progresión entre niveles;
- tipos de naves y cómo se diferencian;
- evolución de acoplamientos y power-ups;
- modos futuros: infinito, supervivencia, etc.;
- progresión/meta-progresión, tienda o recursos;
- narrativa general e invasión alienígena;
- tipos de escenarios y cómo cambian los niveles;
- filosofía de bosses y sub-bosses;
- qué sistemas son del **MVP**, cuáles son **post-MVP temprano** y cuáles pertenecen a una **visión final**.

Pero hay una distinción importante: **no hace falta diseñar ahora todos los niveles, todas las naves ni todos los enemigos**. Lo que necesitamos es definir las reglas y la dirección del juego completo. Por ejemplo, saber que habrá una campaña de múltiples niveles, que las naves tendrán identidades distintas y que los acoplamientos crecerán en complejidad. No necesitamos inventar hoy la nave número 12.

Después de esa segunda etapa, yo seguiría este orden:

**1. Visión general del juego completo**  
Qué queremos que pueda llegar a ser.

**2. Delimitar releases.**  
MVP → primera versión posterior al MVP → objetivos de largo plazo. Esto evita que sistemas futuros se filtren continuamente al MVP.

**3. Especificación consolidada del MVP.**  
Ahí sí te presentaría todo lo que definimos en un documento lógico y revisable: qué entra, qué no entra, reglas de gameplay y criterios de “terminado”. Vos lo corregís y aprobás.

**4. Validación técnica de plataforma.**  
El spike de libGDX + gdx-teavm que acabamos de discutir. Si pasa, web. Si no, desktop.

**5. Diseño técnico/arquitectura.**  
Recién acá hablamos en serio de composición, eventos, DI, separación de sistemas, escenas, assets, persistencia, testing, etc.

**6. Plan de implementación y tareas.**

**7. Construcción.**

En otras palabras, ahora estamos justo entre **“ya sé qué MVP quiero”** y **“necesito definir qué juego quiero que exista alrededor de ese MVP”**.

Yo empezaría la segunda etapa por la **estructura general de la campaña y progresión**, porque muchas cosas que ya mencionaste —nuevas naves, evolución alienígena, recursos, estaciones, acoplamientos, bosses— dependen de eso. memcite


## [78] user

ok, empecemos con eso


## [79] assistant

Perfecto. Entonces arrancamos con la **visión general de campaña y progresión**, todavía sin bajar a arquitectura ni a una lista cerrada de contenido.

La primera decisión grande es cómo querés que se sienta la campaña como conjunto. Hasta ahora tenemos que el nivel 1 ocurre durante la primera oleada de invasión en la Tierra, y que más adelante los enemigos podrían volverse más extraños, biomecánicos o directamente entidades alienígenas enormes.

Yo empezaría por definir tres cosas:

- **Escala de la campaña:** si querés que vaya de “defender la Tierra” a “salir al espacio y llevar la guerra al enemigo”, o algo más contenido.
- **Estructura de niveles:** si cada nivel es una misión lineal independiente, o si querés que haya bifurcaciones, elecciones de ruta, zonas opcionales, etc.
- **Progresión del jugador:** qué cosas se conservan entre niveles: naves desbloqueadas, acoplamientos, mejoras permanentes, recursos, puntuación, etc.

Mi intuición, por lo que venís describiendo, es una campaña con escalada bastante clara: empezar en la Tierra, sobrevivir a la invasión, luego pasar a órbita/espacio, descubrir más sobre los alienígenas y terminar enfrentando amenazas cada vez menos “convencionales”. Pero eso todavía es solo una dirección posible.

Así que la primera pregunta sería: **¿cómo imaginás el arco general de la campaña desde el nivel 1 hasta el final?** No hace falta definir cantidad de niveles todavía; solo el viaje general que querés que viva el jugador.


## [80] user

Ok, la verdad que para la historia estaría bueno hacer como si fuesen etapas. La primera etapa sería la llegada de los aliens a la Tierra y todo el combate sería en ella, tratando de defender ciudades o lugares importantes. Esto podría terminar con la destrucción de un boss bastante grande, como una nave nodriza, y esto nos llevaría a la segunda etapa, que sería todavía en la Tierra, pero en la parte de la atmósfera, o sea, en el espacio, pero en la órbita terrestre. Esto podría llevar a la defensa de la Luna como tercera etapa. Y acá donde más o menos termina la tercera etapa, en la Luna, después me gustaría hacer una animación de, no sé, una batalla o una animación, pero estaría bueno hacer una batalla a un nivel, que sea volviendo a la Tierra, que se encuentren con una supernave, que esta al ser destruida, tiene una animación de que, como que sale un alien gigante dentro de esa nave, y ahí empezaría lo que es la cuarta etapa, donde ya empezamos a ver más alienígenas que naves, como que hace esa transformación. Y esa cuarta etapa va a ser en el espacio. Después la quinta etapa ya sería de vuelta en la Tierra, haciendo creer que los aliens estos evolucionados son más fuertes, y nos hicieron retroceder hasta la Tierra, siendo ya como sería la última etapa, por lo menos de la primera parte. Me gustaría hacer una campaña más amplia, pero yo creo que podríamos dejarlo terminado si concluimos en la Tierra como la última defensa. Y si ganamos, esto más o menos sería como el final de El Día de la Independencia 2, que van a ir contra los aliens en su planeta en vez de defendernos.


## [81] assistant

Sí, esto ya nos da un **arco de campaña bastante sólido** y, sobre todo, una escalada narrativa clara. Yo lo ordenaría así:

### Etapa 1 — Invasión de la Tierra
La campaña empieza con la primera oleada alienígena. Los combates ocurren sobre ciudades, bases, zonas estratégicas y otros puntos importantes. La humanidad todavía está reaccionando y las amenazas son principalmente naves alienígenas “convencionales”.

El cierre de esta etapa sería la destrucción de una **gran nave nodriza**, que marca una primera victoria importante.

### Etapa 2 — Órbita terrestre
La guerra se desplaza hacia la alta atmósfera y la órbita. Acá el jugador ya sale del entorno terrestre y empieza a combatir en condiciones más espaciales, con estaciones, satélites, restos orbitales, flotas, etc.

La sensación debería ser que la humanidad está intentando recuperar el control del espacio alrededor de la Tierra.

### Etapa 3 — Defensa de la Luna
La campaña se expande hasta la Luna. Puede haber defensa de instalaciones, bases lunares o posiciones estratégicas.

Esta etapa sería todavía parte de la guerra contra las **naves alienígenas**, pero podría empezar a introducir indicios de que hay algo más extraño detrás de ellas.

Y al final viene el gran punto de inflexión.

### Transición — La revelación
Durante el regreso hacia la Tierra —o en una batalla importante cerca de ella— aparece una **supernave alienígena**.

El jugador consigue destruirla, pero en lugar de terminar simplemente con una explosión, la nave se abre o se desintegra y de su interior emerge una **entidad alienígena gigantesca**.

Ese sería el momento donde tanto el jugador como la humanidad entienden que quizá las “naves” no eran exactamente lo que parecían.

Esto funciona muy bien como cambio de acto.

### Etapa 4 — Guerra contra las entidades
A partir de acá cambia bastante la estética y el tipo de enemigo.

Seguimos en el espacio, pero empezamos a encontrar:

- criaturas espaciales;
- organismos biomecánicos;
- seres que funcionan como naves;
- estructuras orgánicas;
- enemigos que mezclan tecnología y biología;
- eventualmente entidades enormes.

No hace falta que desaparezcan por completo las naves tradicionales. Incluso podría ser más inquietante que convivan ambas cosas.

La sensación general sería que **la verdadera fuerza invasora finalmente se está mostrando**.

### Etapa 5 — Última defensa de la Tierra
Los nuevos enemigos son considerablemente más peligrosos y la humanidad empieza a perder terreno.

Después de haber avanzado desde la superficie hasta la Luna y el espacio profundo, el jugador termina siendo empujado de vuelta a la Tierra.

Eso crea una estructura bastante buena porque regresamos visualmente al punto de partida, pero todo cambió.

La Tierra de la etapa 5 no debería sentirse como la de la etapa 1.

En la primera:

> “Nos están invadiendo.”

En la quinta:

> “Esta es la última línea de defensa.”

Y el final de esta primera gran campaña sería conseguir detener esa ofensiva y salvar la Tierra.

### Y deja preparado un segundo arco

Acá también me gusta mucho la idea tipo *Independence Day: Resurgence* que mencionás.

La historia puede terminar satisfactoriamente:

**la Tierra sobrevivió.**

Pero la última escena puede dejar planteado:

> Hasta ahora estuvimos defendiéndonos. La próxima vez vamos nosotros.

Eso permite que el juego completo tenga una campaña cerrada aunque jamás hagamos una continuación, pero también deja naturalmente abierta una **segunda campaña ofensiva**:

**Sistema Solar → territorio alienígena → planeta/origen enemigo.**

No necesitamos diseñar eso ahora.

---

Hay algo especialmente bueno en esta estructura: **la progresión narrativa también justifica la progresión mecánica**.

Al principio podemos enseñar al jugador con enemigos relativamente reconocibles. Conforme avanza:

**naves → naves avanzadas → híbridos → entidades → criaturas gigantes.**

Por lo tanto podemos ir aumentando la rareza de patrones, tipos de ataques, acoplamientos, armas y bosses sin que parezca simplemente que “el nivel 20 es más difícil porque sí”.

Creo que la siguiente decisión ya debería ser más estructural:

**¿cuántos niveles aproximadamente querés que tenga cada etapa?**

No necesito un número definitivo. Quiero saber si imaginás algo como:

> 3–5 niveles por etapa, con un boss importante al final

o algo más grande:

> 8–10 niveles por etapa, con sub-bosses, misiones especiales y varios bosses.

Eso nos va a permitir estimar qué tan grande querés que sea realmente esta primera campaña.


## [82] user

La verdad es, para la primera parte, yo creo que entre cinco y tres niveles por etapa. Esta bien, si vemos que el trabajo lo hicimos bien y rapido, podriamos agregar mas niveles en el camino.


## [83] assistant

Sí, **3 a 5 niveles por etapa** me parece una escala razonable para esta primera campaña. Con 5 etapas, eso nos deja una campaña base de aproximadamente **15 a 25 niveles**, sin obligarnos a fijar el número exacto desde ahora.

Lo importante sería tratar ese rango como una guía, no como una cuota. Si una etapa ya cuenta bien lo que tiene que contar con 3 niveles, no conviene rellenarla artificialmente. Y si durante el desarrollo vemos que el ritmo es bueno y crear contenido nuevo no cuesta tanto, podemos extenderla.

Yo propondría una regla simple: **cada etapa debe tener una identidad propia y cerrar con un acontecimiento importante**, normalmente un boss o una transición narrativa fuerte. Dentro de ella, los niveles deberían introducir gradualmente escenarios, combinaciones de enemigos y alguna mecánica nueva, sin exigir que cada nivel invente sistemas completamente distintos.

También dejaría una distinción útil para más adelante:

**Campaña objetivo:** 3–5 niveles por etapa.  
**MVP:** solo el primer nivel de la etapa 1.  
**Expansión:** agregar niveles cuando el sistema base esté suficientemente maduro y producir contenido sea más barato.

Eso evita que diseñemos ahora veinte niveles en detalle.

El siguiente punto de la campaña que definiría es **cómo progresa el jugador entre esos niveles**. Ya sabemos que habrá nuevas naves, acoplamientos y posiblemente recursos/tiendas más adelante, pero todavía no sabemos qué se conserva de una misión a otra.

Por ejemplo: ¿querés que al completar niveles el jugador vaya **desbloqueando naves y acoplamientos permanentemente**, y antes de cada misión arme su configuración desde el hangar? ¿O imaginás una progresión más lineal donde ciertas cosas se entregan automáticamente conforme avanza la historia?


## [84] user

Ok. La verdad que, como primera parte, yo creo que los power-ups, o sea, los escudos, los aumentos de disparo, etcétera, deberían poder mantenerse por nivel mientras el jugador no haya perdido una vida. En realidad todavía no estoy seguro si mantener un sistema en que si el jugador pierde una vida, continúa en los power-ups, y si el jugador pierde sus vidas, ahí sí ya pierde todo, sus power-ups, y tiene que reiniciar el nivel desde cero. O hacerlo más difícil, que al perder una vida ya pierda directamente todo. Por ahí hacerlo en base a la dificultad o un modo hardcore, o no sé. Los acoplamientos sí me parece que deben desaparecer al recibir daño o perder una vida. Y como los power-ups, se mantienen si el jugador pasa de nivel. Bueno, el tema del hangar, yo creo que podríamos añadir un hangar cada vez que se termina una etapa, sería una buena opción, y entre medio de algún nivel intermedio. Todavía no sé esta última parte, pero más o menos yo creo que esa idea va estar bien.


## [85] assistant

Sí, acá apareció una decisión de diseño importante que vale la pena revisar porque modifica bastante la sensación de progresión entre niveles.

Hasta ahora habíamos dado por hecho que **perder una vida hacía perder power-ups y acoplamientos**, pero ahora estás planteando algo más flexible. Yo lo dejaría abierto y separaría ambos sistemas:

- **Power-ups:** pueden persistir entre niveles mientras el jugador siga “vivo” dentro de la misma run/campaña.
- **Acoplamientos:** son más frágiles y deberían perderse al recibir cierto daño o, como mínimo, al perder una vida.
- **Game over:** si se terminan todas las vidas, se reinicia el nivel y se pierde la progresión temporal acumulada.

Para los power-ups veo tres modelos válidos:

**Modelo permisivo:** perder una vida no afecta los power-ups. Solo se pierden al quedarse sin vidas. Esto favorece mucho la progresión y evita que una muerte te deje demasiado debilitado.

**Modelo arcade:** perder una vida elimina los power-ups. Es más castigador y hace que cada impacto importe muchísimo.

**Modelo dependiente de dificultad:** en normal conservás parte o todos los power-ups; en dificultades altas los perdés al morir. Me parece especialmente interesante porque permite conservar el espíritu arcade sin hacer demasiado hostil la campaña base.

No cerraría esto todavía, sobre todo porque ya dijimos que el MVP no tendrá selector de dificultad. Para el MVP podemos usar una regla provisional y después balancearla.

### El hangar

La idea de que aparezca **entre etapas** me parece bastante natural.

Terminás una etapa → llegás al hangar/base → preparás la siguiente parte de la campaña.

Ahí podrían ocurrir cosas como selección de nave, acoplamientos disponibles, mejoras permanentes, compra con recursos, revisión de stats, etc. Todavía no necesitamos decidir exactamente todo lo que hace.

Y también me gusta que en etapas largas pueda existir **algún hangar o punto de reabastecimiento intermedio**. Eso permitiría que una etapa de cinco niveles no se convierta necesariamente en una cadena larguísima sin posibilidad de ajustar la nave.

Yo distinguiría dos conceptos:

**Hangar principal:** aparece al terminar una etapa y representa una pausa importante de campaña.

**Punto de reabastecimiento:** puede aparecer ocasionalmente entre niveles o incluso dentro de uno muy largo. Es más limitado y no necesariamente ofrece todas las opciones del hangar.

Eso además conecta perfectamente con aquella idea anterior del portaaviones/base durante algunas misiones.

La siguiente decisión que haría es una bastante central para la progresión: **qué cosas son permanentes y qué cosas pertenecen solamente a una run o tramo de campaña**.

Por ejemplo, una nave desbloqueada seguramente debería ser permanente. Pero todavía tenemos que decidir si un acoplamiento desbloqueado queda disponible para siempre en el hangar, aunque después el módulo equipado pueda destruirse durante una misión. Esa diferencia entre **“desbloquear algo”** y **“llevarlo equipado”** puede ser clave para todo el sistema.


## [86] user

Yo creo que podemos definir que las naves y acoplamientos son permanentes en términos de desbloqueo. O sea, al desbloquear una nave o un acoplamiento, debe poder aparecer en el siguiente run que juegue el jugador. No vamos a hacer que si lo desbloquea, lo pueda utilizar en la misma run, porque podría hacer esto un poco más difícil de mantener. pero al desbloquearlo lo puede jugar en las otras runs. Aunque hay que hablarlo porque esto puede hacer que el usuario solo tenga una nave para toda la campaña. Así que no sé, por ahí hacerlo que se actualice cada vez que el jugador aterrice en el hangar. Hay que charlarlo bien. Después lo demás son cosas que se equipan en el momento.


## [87] assistant

Sí, acá conviene separar **desbloqueo permanente** de **disponibilidad dentro de la run**, porque si mezclamos ambas cosas podemos terminar con el problema que señalás: desbloqueás una nave al principio de la campaña, pero no podés usarla hasta terminarla entera, y entonces gran parte del desbloqueo pierde gracia.

Yo propondría esta regla conceptual:

- **Naves y acoplamientos desbloqueados:** quedan permanentemente en el perfil del jugador.
- **Durante una run/campaña:** lo nuevo que desbloqueás no aparece mágicamente en mitad de un nivel.
- **Al llegar a un hangar**, el inventario se sincroniza con todo lo que ya hayas desbloqueado y podés cambiar de nave/acoplamiento.
- Si perdés la run, esos desbloqueos **no se pierden**.
- Power-ups, bombas, mejoras temporales y demás siguen perteneciendo al estado de la partida, no al desbloqueo permanente.

Esto creo que resuelve bastante bien el problema.

Por ejemplo:

> Nivel 2 → conseguís/desbloqueás una nueva nave → seguís usando la actual → terminás la etapa → llegás al hangar → la nueva nave ya está disponible.

Y si ponemos un hangar intermedio:

> Nivel 7 → desbloqueás un nuevo acoplamiento → nivel 8 → llegás a una base de reabastecimiento/hangar → ya podés equiparlo.

Así el **hangar se convierte en un punto real de transición de la campaña**, no solamente en una pantalla de menú.

También permite algo interesante con la dificultad: cambiar de nave no sería algo que hacés cada treinta segundos porque un enemigo te resulta incómodo. Tenés que comprometerte con una configuración durante cierto tramo y esperar al siguiente hangar para modificarla.

### Hay una segunda cuestión importante

Tenemos que distinguir **desbloquear un acoplamiento** de **tener físicamente ese acoplamiento durante un nivel**.

Podría funcionar así:

**Desbloqueo permanente:**  
“Ya descubriste/desarrollaste el módulo de misiles.”

**Equipamiento:**  
En el hangar decidís comenzar el siguiente tramo con ese módulo.

**Acoplamientos encontrados durante niveles:**  
Podrían ser versiones temporales que encontrás durante esa run, pero eventualmente desbloquean permanentemente el tipo de módulo.

Eso nos permitiría hacer algo bastante satisfactorio. Imaginá que derrotás por primera vez un sub-boss y suelta un **módulo láser experimental**. Lo podés utilizar durante esa run, y además queda registrado como desbloqueado para futuros hangares/runs.

No digo que tenga que funcionar exactamente así, pero evitaría una situación rara donde encontrás una nueva arma y el juego te dice “genial, ahora terminá toda la campaña para poder probarla”.

Por eso, mi inclinación sería:

> **Los desbloqueos son permanentes inmediatamente, pero solo se pueden gestionar/equipar libremente al llegar a un hangar.**

Y algunos objetos obtenidos durante una misión podrían permitirse usar en ese mismo momento si forman parte de la recompensa del gameplay.

Creo que la siguiente cosa que necesitamos definir es precisamente **qué entendemos por “run” en el modo campaña**, porque la venimos usando pero todavía no la formalizamos. Puede significar desde “empezar un nivel” hasta “intentar completar toda la campaña desde el principio”, y eso cambia muchísimo cómo funcionan vidas, power-ups, hangares y game over.


## [88] user

OK, la verdad que lo entendiste bastante bien. Y sí, es de la forma que yo pensaba, con el tema de los acoplamientos. Sí, si el jugador encuentra un acoplamiento en medio de un nivel, lo puede utilizar y es la manera de desbloquearlo para utilizarlo en las siguientes runs o veces que dan gara esté disponible. Con run me refiero a iteración de partida. O sea, si el jugador empieza, completa varios niveles y pierde todas sus vidas, ahí termina la run. Aunque pueda reiniciar el nivel, estaría empezando desde un punto de guardado, que sería una segunda run. Mientras el jugador no pierda todas sus vidas, se considera la misma run.


## [89] assistant

Sí, perfecto. Entonces podemos formalizar **run** de una forma bastante clara:

Una **run** empieza cuando el jugador arranca desde un punto de guardado/hangar/checkpoint de campaña y continúa mientras conserve al menos una vida. Puede atravesar varios niveles seguidos. Si pierde todas las vidas, esa run termina.

Al reiniciar desde el último punto de guardado disponible, comienza **una nueva run**. Eso significa que algunos estados temporales pueden resetearse, mientras que los desbloqueos permanentes no.

Con eso, la progresión queda mucho más ordenada:

- **Permanente entre runs:** naves desbloqueadas, tipos de acoplamientos desbloqueados y, más adelante, cualquier progreso meta que definamos.
- **Persistente dentro de una run:** power-ups que decidamos conservar entre niveles, vidas restantes, bombas/recursos temporales y acoplamiento actualmente equipado.
- **Acoplamiento encontrado durante un nivel:** se puede utilizar inmediatamente y, además, queda desbloqueado permanentemente para futuras runs.
- **Hangar:** punto donde podés cambiar nave y equipar libremente los acoplamientos que ya tengas desbloqueados.
- **Game over:** termina la run y volver al último punto de guardado inicia otra.

Esto también nos resuelve un problema narrativo y jugable: una run no tiene por qué significar “jugar las cinco etapas completas desde cero”. Podemos poner puntos de guardado importantes, seguramente ligados a hangares o finales de etapa, y así cada tramo tiene su propia tensión sin hacer que perder al final de la campaña te mande necesariamente al nivel 1.

Hay una decisión que ahora pasa a ser bastante importante: **qué conserva exactamente el jugador al empezar una nueva run desde un punto de guardado**.

Por ejemplo, imaginemos que termina la etapa 1 con 2 vidas, disparo mejorado y un escudo, llega al hangar y se guarda. Luego pierde todas las vidas en la etapa 2.

Cuando empieza la nueva run desde ese hangar, ¿querés que vuelva con una configuración base —por ejemplo 3 vidas, sin power-ups y con el acoplamiento que elija— o que el checkpoint recuerde parte del estado con el que llegó originalmente?

Yo tendería a que el punto de guardado sea un **nuevo comienzo limpio del tramo**, porque hace mucho más sencillo balancear cada etapa y evita guardar estados malos, pero esta sí es una decisión de gameplay que vale la pena discutir.


## [90] user

Yo creo que acá iría dependiendo del nivel. Si inicia en la etapa 1, debería iniciar con todo en base. Pero si inicia en etapas tardías como la etapa 4, acá dependiendo del nivel, si es más fácil, le vamos a dar algunos power-ups de disparos para que no sea tan difícil, ya que van a haber enemigos más difíciles en estas etapas más tardías. Pero si es el nivel súper difícil o hardcore, que empiece en estado base. O algo así.


## [91] assistant

Sí, eso tiene bastante sentido. Entonces el **estado inicial de una nueva run desde un checkpoint no sería global**, sino definido por el propio tramo o por la dificultad/modo.

La regla conceptual podría ser:

- **Etapas iniciales:** empezar prácticamente en estado base.
- **Etapas avanzadas:** el checkpoint puede otorgar una carga inicial mínima para que el jugador no entre subpotenciado frente a enemigos pensados para una progresión más avanzada. Por ejemplo, uno o dos niveles de power-up de disparo, cierta cantidad de bombas o algún recurso equivalente.
- **Dificultades altas / hardcore:** reducir o eliminar esas ayudas y comenzar mucho más cerca del estado base.
- Los desbloqueos permanentes de naves y acoplamientos siguen estando disponibles; lo que cambia es el **estado temporal con el que comienza esa run**.

Esto también nos ayuda a no caer en un problema clásico de balance: que una etapa 4 esté diseñada suponiendo que el jugador llega “cargadísimo” desde la etapa 1. Si alguien empieza directamente desde un checkpoint de etapa 4, el juego puede darle una configuración inicial razonable para ese tramo.

Y al mismo tiempo, una run larga bien jugada puede seguir teniendo una ventaja real porque quizá llegás al checkpoint con mejores condiciones que el mínimo estándar.

Yo dejaría esto como un concepto de **loadout inicial por checkpoint**, ajustable según etapa y dificultad.

Con esto ya tenemos bastante definida la progresión entre niveles y runs. El siguiente bloque que me parece natural es **cómo se desbloquean las naves**: si aparecen como recompensas de historia, por derrotar ciertos bosses, cumplir objetivos especiales, encontrar prototipos, etc. Ahí podemos definir la filosofía sin diseñar todavía todas las naves.


## [92] user

Yo creo que la forma fácil de desbloquear naves sería matando bosses o cambiando etapas, que también puede ser buena idea. Por ahí algunas naves se desbloquean haciendo requisitos específicos, pero esas son como naves más especiales o acoplamientos más especiales.


## [93] assistant

Sí, esa filosofía de desbloqueo encaja bien y además permite separar progreso normal de contenido especial.

Yo lo dejaría así:

- **Naves principales:** se desbloquean de forma natural al avanzar la campaña, normalmente al derrotar ciertos bosses o al completar/cambiar de etapa.
- **Acoplamientos comunes:** se descubren durante niveles, al derrotar enemigos especiales, sub-bosses o mediante eventos concretos, y desde ese momento quedan desbloqueados permanentemente.
- **Naves y acoplamientos especiales:** requieren condiciones específicas, por ejemplo completar un nivel sin morir, alcanzar cierta puntuación, encontrar una ruta/objeto oculto o derrotar un enemigo opcional.

Esto tiene una ventaja importante: el jugador **no necesita hacer desafíos extra para experimentar la variedad básica del juego**. Si simplemente juega la campaña, va recibiendo nuevas naves y herramientas. Los desafíos quedan para contenido más raro o prestigioso.

También evitaría que los requisitos especiales sean puramente de grind. Me parece mejor que representen habilidad, exploración o dominio del juego, porque encaja más con un shoot 'em up.

Con esto, la progresión general ya está tomando forma bastante clara. El siguiente tema que yo tocaría es **cómo se diferencian las naves entre sí**, pero a nivel de filosofía, no diseñando todavía diez modelos. Por ejemplo, si cada nave cambia solo estadísticas o si realmente queremos que cambie el estilo de juego mediante velocidad, disparo, bomba, habilidad, compatibilidad de acoplamientos, etc.


## [94] user

Yo creo que por lo menos para la primera parte que estamos haciendo, cada nave va a tener habilidades y cosas distintas. Algunas que se muevan más rápido, que tengan habilidades especiales, que disparen más, que tengan más daño, otras que se muevan más lento, siempre balanceándolos, pero que sean de formas distintas. No es necesario decir cómo va a ser cada una actualmente, pero que se pueda editar durante el camino, o sea, durante el desarrollo del juego, para no tener que acoplarnos a un estilo y mantenerlo durante todo el desarrollo.


## [95] assistant

Sí, y eso define una regla bastante buena para el diseño de naves: **cada nave debe tener identidad jugable propia**, no ser simplemente la misma con números distintos.

Entonces, para esta primera parte de la campaña:

- algunas serán más rápidas y frágiles;
- otras más lentas pero con más potencia;
- algunas tendrán mayor cadencia;
- otras menos disparos pero más daño;
- podrán variar las habilidades especiales;
- también podrá cambiar cómo responden a los power-ups y qué acoplamientos aprovechan mejor.

Lo importante es que todo eso quede **abierto a iteración durante el desarrollo**. No vamos a diseñar ahora una tabla cerrada de 8 naves y obligarnos después a respetarla. Primero definimos la filosofía general y, cuando el gameplay real exista, vamos creando y balanceando cada nave según lo que funcione mejor.

Eso también implica que no conviene que la campaña dependa narrativamente de que “la nave X siempre tenga exactamente estas estadísticas”. Las naves deberían poder ajustarse bastante sin romper el resto del juego.

Con esto, yo diría que ya tenemos bastante bien definida la **progresión de campaña, runs, hangares, desbloqueos y filosofía de naves**.

El próximo bloque natural sería definir **la progresión de acoplamientos y power-ups a lo largo de la campaña**: no cada uno en detalle, sino cómo aumentan en complejidad y variedad entre etapa 1 y etapa 5. Ahí podemos decidir, por ejemplo, cuándo empiezan a aparecer módulos más raros, tecnología alienígena, combinaciones más avanzadas, etc.


## [96] user

Ok. La verdad es que los power-ups no hay nada que hablar, con que, si aparece uno en etapa uno o en etapa cinco, la verdad que es indiferente, ya que el power-up es el mismo. Por ahí, ir variando en cómo y cuándo aparecen, pero eso no hay que definirlo ahora. Por ahí los acoplamientos ya lo dijimos, más o menos cuándo aparecen. Yo creo que deberían salir dependiendo de la etapa o nivel que sea. Por ejemplo, un acoplamiento que necesite misiles en ese nivel, sería bueno introducirlo en ese nivel. O en una etapa donde hay muchísimos proyectiles, el acoplamiento de contramedidas, pueda aparecer ahí siempre con la idea de ayudar al jugador dependiendo del nivel o etapa.


## [97] assistant

Sí, eso deja una regla bastante clara: **los power-ups son herramientas universales del combate**, mientras que los acoplamientos sí pueden introducirse de forma contextual según lo que el nivel quiere enseñar o exigir.

Entonces, para los acoplamientos, la lógica de progresión sería algo así:

- no aparecen por una progresión fija tipo “etapa 2 = misiles, etapa 3 = láser”;
- se introducen cuando **el diseño del nivel justifica su utilidad**;
- idealmente, el jugador recibe una oportunidad razonable de entender para qué sirve el acoplamiento poco después de obtenerlo;
- algunos niveles pueden estar pensados para que cierto acoplamiento sea especialmente útil, pero sin volverlo obligatorio salvo casos muy concretos;
- una vez descubierto, queda desbloqueado permanentemente para futuras runs.

Tu ejemplo de contramedidas encaja perfecto: si una sección empieza a introducir mucha densidad de proyectiles enemigos, ese es un buen momento para presentar un módulo que pueda destruirlos. Lo mismo con misiles si aparecen objetivos resistentes, múltiples blancos o enemigos difíciles de alcanzar.

También evitaría que el juego diga implícitamente “tenés que usar exactamente este módulo para pasar este nivel”. Es mejor que el nivel diga **“este módulo te da una nueva forma de resolver este problema”**, dejando espacio para que otras naves o configuraciones también funcionen.

Con esto, creo que **la progresión de power-ups/acoplamientos ya está suficientemente definida** para esta etapa de planificación.

El siguiente bloque que yo abordaría es el de **modos de juego fuera de la campaña**: infinito, supervivencia y cualquier otro que quieras contemplar. No para diseñarlos completos ahora, sino para definir qué lugar ocupan en el juego final y cómo se diferencian realmente del modo campaña.


## [98] user

Ok. Tanto el modo infinito como el modo supervivencia va a ser de escala infinita hasta que el jugador pierda todas sus vidas. La diferencia va a estar más en la forma. El modo infinito, por ahora todavía no sé si implementar el sistema de hangares para modo infinito, ya que la idea sería mantener un progreso en base a los power-ups o módulos que vaya adquiriendo el jugador durante este modo infinito, ya que sería solamente un nivel que aparecerían enemigos y bosses durante todo ese nivel hasta que el jugador pierda. En el modo supervivencia sí van a aparecer hangares, es más parecido al modo historia, con la única particularidad que el escalado de nivel también va a ser infinito y va a repetir los ciclos de etapas hasta que el jugador pierda. Por ejemplo, al inicio del nivel supervivencia, las primeras cinco etapas van a ser las mismas que en el modo historia, por ahí cambiando como es la dificultad de cada nivel, haciendo que enemigos aparezcan de otras formas, cambiando bosses, pero los escenarios, por lo menos visualmente, van a ser los mismos. Pero cuando el jugador complete el último nivel de la etapa 5, volverá a empezar en la etapa 1. Pero no quiere decir que se reinicie todo completamente, solo volverá al escenario de la etapa 1, pero con la dificultad como si fuese una etapa 6. Si vuelve a completar las cinco etapas, volverá a lo que sería una etapa 11, y así hasta que el jugador pierda, porque cada vez más niveles gana en el modo supervivencia, más difícil va a ser. No sé si se entendió la diferencia entre supervivencia e infinita.


## [99] assistant

Sí, se entendió bien, y la diferencia es bastante clara.

**Modo infinito:** sería una sola sesión continua, prácticamente un único nivel sin final. Van apareciendo enemigos, formaciones, amenazas y bosses de manera indefinida, con dificultad creciente hasta que el jugador pierde todas sus vidas. La progresión ocurre dentro de esa misma partida mediante power-ups y módulos/acoplamientos obtenidos durante la run. El tema de incluir hangares acá queda abierto porque podría cortar demasiado el ritmo continuo.

**Modo supervivencia:** también es infinito, pero estructurado como una campaña cíclica. Reutiliza las cinco etapas visuales/narrativas del modo historia y conserva una estructura más parecida a niveles, transiciones y hangares. Cuando el jugador completa la etapa 5, vuelve visualmente a la etapa 1, pero **no reinicia la dificultad**: ese nuevo ciclo equivaldría a continuar con una etapa 6. Después del segundo ciclo sería como entrar en etapa 11, y así sucesivamente.

O sea, el ciclo sería algo conceptualmente como:

**Etapas 1–5 → dificultad base**  
**Etapas 1–5 otra vez → dificultad equivalente a 6–10**  
**Etapas 1–5 otra vez → dificultad equivalente a 11–15**  
**...hasta morir.**

Y esa dificultad creciente no tiene por qué ser solo “más HP y más daño”. Puede evolucionar mediante enemigos más avanzados, patrones distintos, más combinaciones simultáneas, bosses diferentes o modificados, mayor densidad de proyectiles, etc.

Eso hace que ambos modos tengan objetivos distintos aunque compartan la condición final de “sobrevivir hasta perder”:

**Infinito = resistencia arcade continua.**  
**Supervivencia = campaña infinita por ciclos, con progresión y pausas entre tramos.**

También veo una diferencia potencial importante para más adelante: el modo infinito parece ideal para priorizar **score y duración de la run**, mientras que supervivencia puede priorizar **hasta qué ciclo/etapa llegó el jugador**, además de la puntuación.

Yo dejaría abierto el sistema de hangares del infinito, tal como dijiste. Primero habría que ver cuánto rompe el ritmo y si realmente hace falta. En supervivencia, en cambio, sí parece una parte natural del modo.

Con esto, los dos modos futuros ya tienen una identidad suficientemente distinta. El próximo punto general que nos falta bastante es probablemente **la progresión/meta-progresión fuera de las runs**: recursos, tienda, qué se compra, qué se desbloquea jugando y qué cosas nunca deberían comprarse sino conseguirse por logros o campaña.


## [100] user

Ok, no sé si lo había dicho antes, pero el hangar tiene una moneda particular que solo sirve durante la run. O sea, se pierde si el jugador pierde la run. Por ahí, si el jugador quiere iniciar una nueva run en niveles avanzados, por ahí darles algunos puntos base o moneda base, todavía no sé cómo llamarlo. Pero más que eso, no. Después, habría una tienda donde se pueden comprar cosas especiales. Pero no vamos a enfocarnos tanto en eso. Por ahí hacer skins y alguna nave o acoplamiento especial. Aunque todavía no sé cómo hacer la moneda de esta tienda. Por ahí hacerlo con puntuación general. O sea, hacerlo puntuación acumulada y ya está. Pero todavía no sé. Lo único que es, yo desbloquearía el nivel infinito cuando el jugador complete toda la campaña. Y el modo supervivencia cuando complete la primera etapa. Algo así como para darle un premio al jugar la campaña. No sé qué opinas tú acerca de esto. Por ahí darle la opción de poner códigos para desbloquear cosas más fácilmente.


## [101] assistant

Sí, me parece una buena dirección, y además ya empieza a separar bien **progresión de run** de **meta-progresión permanente**.

Para el hangar, la moneda debería ser claramente **temporal de la run**. La ganás jugando, la gastás en hangares durante esa misma run y se pierde cuando termina. Eso hace que funcione como recurso táctico, no como economía permanente. Si el jugador empieza una run desde una etapa avanzada, tiene sentido darle una cantidad base para que no llegue completamente “vacío”, igual que con los power-ups iniciales. El nombre lo podemos dejar para más adelante.

Para la tienda permanente, yo no la complicaría ahora. La idea de usar **puntuación acumulada** como moneda meta es bastante elegante porque evita introducir otra divisa sin necesidad. Podría funcionar como “score total histórico” o una parte gastable derivada del score, pero eso sí habría que pensarlo bien para no crear una situación rara donde gastar puntos haga bajar una estadística que el jugador percibe como récord. Una solución futura podría ser separar “score histórico” de “créditos obtenidos por score”, aunque no hace falta cerrarlo hoy.

Respecto a los desbloqueos de modos, me gustan bastante:

- **Supervivencia** al completar la primera etapa: premio temprano, le da al jugador otro modo sin exigir terminar toda la campaña.
- **Infinito** al completar la campaña: se siente como una recompensa importante y además tiene sentido que sea el modo más “arcade puro” para alguien que ya conoce todos los sistemas.

Eso también ayuda a que la campaña siga siendo el recorrido principal del juego en la primera experiencia.

Sobre los **códigos**, sí pueden servir, pero yo los plantearía como una función secundaria tipo “cheat codes / códigos de desbloqueo”, no como parte normal de la progresión. Pueden ser útiles para testing, contenido especial, easter eggs o incluso para permitir que alguien desbloquee modos rápidamente si ya jugó en otra plataforma. Pero no los usaría como sustituto del sistema normal de desbloqueos.

Con esto, la progresión general queda bastante ordenada en tres capas:

**Run:** moneda temporal, power-ups, acoplamientos equipados, vidas, bombas.  
**Campaña/perfil:** naves y acoplamientos desbloqueados, etapas alcanzadas, modos desbloqueados.  
**Meta-progresión:** tienda permanente, skins y contenido especial, posiblemente usando score acumulado o una moneda derivada.

Yo creo que ya estamos muy cerca de cerrar también esta segunda etapa de planificación. Nos quedarían por definir a nivel general **la filosofía de bosses/sub-bosses, narrativa/presentación entre etapas y quizá cómo se guarda el progreso del perfil**; no el formato técnico del guardado, sino qué progreso conceptual queremos conservar. Después de eso ya tendría sentido consolidar la visión completa del juego y separar claramente **MVP / post-MVP / visión final**.


## [102] user

Ok. Con el tema de los bosses, normalmente van a haber bosses al final de cada nivel. Puede que no haya boss en algún nivel especial donde haya animaciones o sea simplemente una arandada de enemigos. Pero normalmente habrá bosses a cada final de nivel. Los sub-bosses aparecerán en niveles puntuales. Y algo que todavía no sé si hacer niveles que tengan múltiples bosses. O sea, un nivel normal haciendo pelea contra enemigos, sale un boss, después volvemos a otras peleas con enemigos y sale otro boss, y así. Todavía no sé, pero estaría bueno contemplarlo. No sé a qué te referís con narrativa presentación entre etapas, pero todavía no sé cómo se guardaría el progreso del jugador en un perfil. Hay que plantear esto. Aunque estaría bueno guardarlo. El cómo, no sé, pero sí estaría bueno guardar el progreso en algún lado.


## [103] assistant

Sí, con eso la filosofía de bosses queda bastante bien delimitada.

Para la campaña, tomaría como regla general que **cada nivel termina con un boss**, salvo niveles especiales donde el cierre sea otra cosa: una secuencia narrativa, una gran oleada, una persecución, una defensa prolongada o algún evento distinto. Los **sub-bosses** quedarían reservados para niveles concretos, como picos de dificultad o hitos intermedios.

Y dejaría explícitamente contemplados los **niveles multi-boss**. No como norma, pero sí como formato válido: tramo normal → boss → descanso/oleadas → segundo boss → posible cierre. Eso puede servir mucho más adelante para niveles largos, finales de etapa o momentos especialmente importantes.

Cuando hablaba de “narrativa/presentación entre etapas”, me refería a cómo se comunica la historia fuera del combate. Por ejemplo: cinemáticas cortas, imágenes pixel-art con texto, comunicaciones por radio, una pantalla de briefing antes de la misión, escenas dentro del hangar, etc. No hace falta definirlo ahora si todavía no tenés una preferencia clara.

Sobre el **perfil y guardado de progreso**, sí creo que conviene definir primero **qué debe recordar**, aunque no sepamos todavía cómo se persiste técnicamente. Para el juego completo, yo guardaría como mínimo:

- progreso de campaña: etapas/niveles alcanzados o completados;
- naves desbloqueadas;
- acoplamientos desbloqueados;
- modos desbloqueados;
- contenido permanente de tienda, como skins;
- puntuaciones/récords relevantes;
- configuraciones del jugador;
- posiblemente desafíos o secretos completados.

En cambio, cosas como power-ups actuales, moneda temporal del hangar, vidas de una run o acoplamientos temporales pertenecen al **estado de run/checkpoint**, no al perfil permanente.

Y acá aparece una decisión importante: ¿querés que el juego permita **varios perfiles/slots de guardado**, tipo `Partida 1 / Partida 2 / Partida 3`, o pensás en un único progreso global del jugador? Para un juego arcade como este, un solo perfil puede ser suficiente, pero varios slots permiten volver a empezar la campaña sin borrar tus desbloqueos principales.


## [104] user

yo creo que un sistema de 3 slots esta bien para los perfiles


## [105] assistant

Sí, **3 slots de perfil** me parece una buena escala: alcanza para tener campañas separadas sin meter complejidad innecesaria.

Conceptualmente, cada slot debería guardar su propio progreso permanente:

- niveles/etapas completados;
- naves desbloqueadas;
- acoplamientos desbloqueados;
- modos desbloqueados;
- contenido comprado/desbloqueado en tienda;
- puntuaciones y récords;
- configuraciones específicas del perfil, si decidimos que no sean globales.

Y además puede guardar el **último punto de progreso de campaña** para continuar una run o reiniciar desde el último checkpoint/hangar según las reglas que definamos.

Lo importante es que los tres perfiles sean completamente independientes. Así podés tener, por ejemplo, una campaña avanzada en un slot y empezar desde cero en otro sin tocar el progreso anterior.

Con esto, yo diría que ya tenemos casi cerrada esta **segunda etapa de planificación general**. Nos falta muy poco antes de consolidar todo: principalmente decidir, a nivel conceptual, cómo queremos manejar **continuar una run / guardar en checkpoints** y si la configuración general —audio, mouse, etc.— pertenece al perfil o al juego completo. Después de eso ya podemos separar formalmente **MVP, post-MVP y visión completa**.


## [106] user

Yo creo que vamos a hacer un guardado automático cada vez que el jugador haga clic en el botón guardar y salir, o cuando termina un nivel o etapa, para que el usuario no pierda su guardado. También implementar un botón de continuar. Y después la configuración general, las configuraciones de audio, mouse, etcétera. Yo creo que deberían pertenecer al perfil, pero no sé si al juego completo. O sea, si el usuario hace una configuración de botones en el slot 1, para mí esa configuración debe permanecer en el slot 2 o 3. Pero no sé bien cómo hacer esto.


## [107] assistant

Yo separaría **progreso de perfil** y **preferencias globales del juego**. En tu ejemplo, las configuraciones de audio, mouse y controles deberían ser globales, no pertenecer a cada slot. Si el usuario cambia una tecla o baja el volumen, esperaría que eso siga igual aunque cambie de perfil.

Entonces quedaría así:

**Perfil/slot**
- progreso de campaña;
- niveles y etapas completados;
- naves y acoplamientos desbloqueados;
- modos desbloqueados;
- tienda/contenido permanente;
- récords y puntuaciones;
- estado de continuación de la run.

**Configuración global**
- volumen general;
- música;
- efectos;
- mouse activado/desactivado;
- keybindings cuando los implementemos;
- otras preferencias futuras como fullscreen, resolución, accesibilidad, etc.

Sobre el guardado, también haría una distinción: **“Guardar y salir”** debería guardar el estado actual permitido y volver al menú; además habría **autosave al terminar un nivel o llegar a un punto seguro/hangar**. El botón **Continuar** cargaría el último estado válido de ese slot.

Eso sí: más adelante tendremos que definir con precisión *qué puede guardar “Guardar y salir” si se usa en medio de un nivel*. Hay dos caminos: permitir continuar exactamente desde ese punto, o hacer que guardar y salir te devuelva al último checkpoint seguro para evitar abusos tipo save-scumming. Yo no cerraría eso todavía.

Con esta decisión, diría que la segunda etapa de planificación general ya está **prácticamente cerrada**. El siguiente paso lógico es hacer una **consolidación formal** de todo lo definido, separando claramente:

**MVP**, **post-MVP cercano** y **visión completa**.

Esa sería la especificación funcional revisable antes de volver a la validación técnica web y, recién después, arquitectura.
