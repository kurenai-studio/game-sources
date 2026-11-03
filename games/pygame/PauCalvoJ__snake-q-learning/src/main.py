import argparse

from Agent import QAgent
from SnakeGame import SnakeGame

RUTA_MODELO = "modelo_snake.pkl"


def ejecutar(entrenar, rapido, max_partidas):
    agente = QAgent()
    hay_modelo = agente.cargar(RUTA_MODELO)
    if not entrenar:
        if not hay_modelo:
            print("Entrena primero con: python main.py --rapido --partidas 2000")
            return
        agente.epsilon = 0  # Solo jugar: sin decisiones al azar

    juego = SnakeGame(mostrar=not rapido)
    puntuaciones = []

    try:
        while max_partidas == 0 or len(puntuaciones) < max_partidas:
            juego.reset()
            estado = juego.get_state()

            while not juego.done:
                accion = agente.choose_action(estado)
                proximo_estado, recompensa, done = juego.step(accion)
                if entrenar:
                    agente.learn(estado, accion, recompensa, proximo_estado, done)
                estado = proximo_estado

            puntuaciones.append(juego.puntuacion)
            if entrenar:
                agente.fin_de_partida()

            if juego.puntuacion == max(puntuaciones):
                print(f"Partida {len(puntuaciones)} | ¡Récord de la sesión!: {juego.puntuacion}")

            if len(puntuaciones) % 50 == 0:
                ultimas = puntuaciones[-50:]
                print(f"Partida: {len(puntuaciones)} | Media últimas 50: {sum(ultimas) / 50:.1f} | "
                      f"Récord: {max(puntuaciones)} | Epsilon: {agente.epsilon:.2f}")
                if entrenar:
                    agente.guardar(RUTA_MODELO)

    except (KeyboardInterrupt, SystemExit):
        print("\nInterrumpido.")

    if entrenar:
        agente.guardar(RUTA_MODELO)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Snake con Q-Learning tabular")
    parser.add_argument("--jugar", action="store_true",
                        help="ver jugar al modelo guardado, sin entrenar")
    parser.add_argument("--rapido", action="store_true",
                        help="sin ventana: entrena o evalúa mucho más rápido")
    parser.add_argument("--partidas", type=int, default=0,
                        help="número de partidas (0 = hasta cerrar la ventana o Ctrl+C)")
    args = parser.parse_args()

    ejecutar(entrenar=not args.jugar, rapido=args.rapido, max_partidas=args.partidas)
