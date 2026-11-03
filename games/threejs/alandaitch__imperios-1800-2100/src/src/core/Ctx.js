/**
 * CONTRATO DE INTEGRACIÓN — leélo antes de tocar cualquier módulo.
 *
 * `ctx` es el único objeto que se pasa a todos los sistemas. Cada módulo se
 * engancha acá y NUNCA importa a otro módulo hermano por su ruta salvo que sea
 * una fábrica pura (art/, data/). Así los módulos se pueden reescribir en
 * paralelo sin romper a los vecinos.
 *
 * ctx = {
 *   motor:     Engine
 *   mundo:     World
 *   bus:       EventBus
 *   rng:       RNG
 *   ruido:     Ruido
 *   escena:    THREE.Scene
 *   camara:    THREE.PerspectiveCamera
 *   renderer:  THREE.WebGLRenderer
 *   render:    Renderer      (composer, postfx, calidad)
 *   camCtrl:   CamaraRTS     (.enfocar(x,z), .posicionSuelo(), .rayo(nx,ny))
 *   cielo:     Cielo         (.horaDelDia 0..24, .setEdad(n))
 *   terreno:   Terreno       (.altura(x,z), .pendiente(x,z), .tam, .transitable(x,z))
 *   agua:      Agua
 *   mapa:      MapaGenerado  ({ semilla, tam, inicios[], recursos[] })
 *   texturas:  BibliotecaTexturas
 *   vista:     VistaEntidades (instancias/mallas por entidad; .sincronizar())
 *   nav:       Navegacion    (.camino(x0,z0,x1,z1) -> [{x,z}])
 *   niebla:    Niebla
 *   eco:       Economia      (.recursos[jugador] = {alimento, materiales, capital, energia})
 *   edades:    SistemaEdades (.edad[jugador] 0..4)
 *   ia:        IA
 *   ui:        HUD
 *   audio:     MotorAudio
 *   seleccion: Seleccion     (.ids Set<number>)
 *   ordenes:   Ordenes       (.mover(ids,x,z) .atacar(ids,id) .recolectar(...) ...)
 *   jugadorLocal: number
 *   calidad:   'baja'|'media'|'alta'|'ultra'
 * }
 *
 * Cada sistema expone: { nombre, orden, fijo?(dt, ctx), cada?(dtReal, alfa, ctx) }
 * Órdenes de ejecución convenidos:
 *   10 entrada/órdenes · 20 IA · 30 navegación · 40 movimiento · 50 combate
 *   60 economía/producción · 70 niebla · 80 vista/animación · 90 UI · 100 render
 */
export const ORDEN = {
  ENTRADA: 10, IA: 20, NAV: 30, MOVIMIENTO: 40, COMBATE: 50,
  ECONOMIA: 60, NIEBLA: 70, VISTA: 80, UI: 90, RENDER: 100,
};

export const RECURSO = { ALIMENTO: 0, MATERIALES: 1, CAPITAL: 2, ENERGIA: 3 };
export const NOMBRE_RECURSO = ['Alimento', 'Materiales', 'Capital', 'Energía'];
