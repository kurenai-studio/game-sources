"""Estados del juego, sub-actos y máquina de estados."""
from enum import Enum, auto


class GameState(Enum):
    MENU = auto()
    SUB_ACT_1_1 = auto()         # La Frecuencia Fantasma
    SUB_ACT_1_2 = auto()         # Infiltración en el Almacén 4
    SUB_ACT_1_3 = auto()         # El Tránsito de la Plaza
    SUB_ACT_1_4 = auto()         # El Búnker Olvidado y VULCANO
    BASE_MANAGEMENT = auto()     # fase estratégica de VULCANO entre sub-actos (mundo detenido)
    ACT_2_BASE = auto()          # terminal táctico de la base (expediciones)
    CAMPAIGN_MENU = auto()       # selección de mapa de campaña (antes del Acto 2)
    INCURSION = auto()           # expedición jugable: exploración, combate y saqueo
    ACT_2_SETUP = auto()         # preparación (construcción con descuento)
    ACT_2_PLAY = auto()          # oleadas de asedio (y asalto si VULCANO no está en línea)
    ACT_2_ASSAULT = auto()       # sub-acto 2.2: asalto a la Fundición Renegada
    RETRY_SUB_ACT = auto()       # derrota: reintentar solo el sub-acto actual
    SIEGE = auto()               # Guerra de Asedio: mapa grande, Fortaleza enemiga evolutiva y drones (modo Comandante)
    CAMPAIGN_VICTORY = auto()    # cierre de campaña: estadísticas del asedio y guardado de la victoria
    VICTORY = auto()


class SubAct(Enum):
    S1_1 = "1.1 · La Frecuencia Fantasma"
    S1_2 = "1.2 · Infiltración en el Almacén 4"
    S1_3 = "1.3 · El Tránsito de la Plaza"
    S1_4 = "1.4 · El Búnker Olvidado y VULCANO"
    S2_0 = "2.0 · Base Central"
    S2_X = "2.x · Incursión"
    S2_1 = "2.1 · Asedio Inicial"
    S2_2 = "2.2 · Asalto a la Fundición"
    S3_0 = "3 · Guerra de Asedio"


SUB_ACT_OF = {
    GameState.SUB_ACT_1_1: SubAct.S1_1,
    GameState.SUB_ACT_1_2: SubAct.S1_2,
    GameState.SUB_ACT_1_3: SubAct.S1_3,
    GameState.SUB_ACT_1_4: SubAct.S1_4,
    GameState.ACT_2_BASE: SubAct.S2_0,
    GameState.INCURSION: SubAct.S2_X,
    GameState.ACT_2_SETUP: SubAct.S2_1,
    GameState.ACT_2_PLAY: SubAct.S2_1,
    GameState.ACT_2_ASSAULT: SubAct.S2_2,
    GameState.SIEGE: SubAct.S3_0,
}
FIRST_STATE_OF = {
    SubAct.S1_1: GameState.SUB_ACT_1_1,
    SubAct.S1_2: GameState.SUB_ACT_1_2,
    SubAct.S1_3: GameState.SUB_ACT_1_3,
    SubAct.S1_4: GameState.SUB_ACT_1_4,
    SubAct.S2_0: GameState.ACT_2_BASE,
    SubAct.S2_X: GameState.INCURSION,
    SubAct.S2_1: GameState.ACT_2_SETUP,
    SubAct.S2_2: GameState.ACT_2_ASSAULT,
    SubAct.S3_0: GameState.SIEGE,
}
# Secuencia de la campaña
NEXT_STATE = {
    GameState.SUB_ACT_1_1: GameState.SUB_ACT_1_2,
    GameState.SUB_ACT_1_2: GameState.SUB_ACT_1_3,
    GameState.SUB_ACT_1_3: GameState.SUB_ACT_1_4,
    GameState.SUB_ACT_1_4: GameState.ACT_2_BASE,
}


class State:
    """Pantalla del juego. Varios GameState pueden compartir la misma pantalla."""

    def __init__(self, game):
        self.game = game

    def enter(self, **kwargs):
        pass

    def exit(self):
        pass

    def handle_event(self, event):
        pass

    def update(self, dt):
        pass

    def draw(self, screen):
        pass


class StateMachine:
    def __init__(self):
        self.current_state = GameState.MENU
        self.previous_state = None
        self.sub_act = None               # sub-acto en curso (se conserva durante RETRY_SUB_ACT)
        self.screens = {}
        self.active = None

    def register(self, game_state, screen):
        self.screens[game_state] = screen

    def start(self):
        self.active = self.screens[self.current_state]
        self.active.enter()

    def transition(self, new_state, **kwargs):
        self.previous_state = self.current_state
        self.current_state = new_state
        self.sub_act = SUB_ACT_OF.get(new_state, self.sub_act)
        screen = self.screens[new_state]
        if screen is not self.active:     # SETUP -> PLAY comparten pantalla: no se reinicia
            if self.active is not None:
                self.active.exit()
            self.active = screen
            screen.enter(**kwargs)

    def handle_event(self, event):
        self.active.handle_event(event)

    def update(self, dt):
        self.active.update(dt)

    def draw(self, screen):
        self.active.draw(screen)
