from person import Person
from simulation import Simulation

if __name__ == "__main__":
    sim = Simulation((40, 60), window_size=(1500, 800))
    sim.ask_pre_info()
    sim.init__grid()
    sim.run()