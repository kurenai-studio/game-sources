import pytest
from simulation import Simulation

@pytest.fixture
def simulation():
    return Simulation((20,30))

def test_matrix_initialization(simulation):
    assert simulation.matrix.shape == (20, 30)
    assert simulation.SHAPE == (20,30)
    assert simulation.WIDTH == 20
    assert simulation.HEIGHT == 30

def test_ask_pre_info(monkeypatch, simulation):
    info = iter([90, 40, 30, 20, 10, 5]) 
    monkeypatch.setattr("builtins.input", lambda inp: str(next(info)))
    simulation.ask_pre_info()

    assert simulation.diseaseConstants["density"] == 0.9
    assert simulation.diseaseConstants["susceptible"] == 0.4
    assert simulation.diseaseConstants["immune"] == 0.3
    assert simulation.diseaseConstants["carrier"] == 0.2
    assert simulation.diseaseConstants["infected"] == 0.1
    assert simulation.diseaseConstants["mortality"] == 0.05

@pytest.mark.parametrize("density, expected_population", [
    (0, 0),
    (50, 300),
    (100, 600),
])
def test_init_grid(monkeypatch, simulation, density, expected_population):
    info = iter([density, 40, 30, 20, 10, 5]) 
    monkeypatch.setattr("builtins.input", lambda inp: str(next(info)))
    simulation.ask_pre_info()
    simulation.init__grid()

    counter = 0
    for i in range(simulation.SHAPE[0]):
        for j in range(simulation.SHAPE[1]):
            if simulation.matrix[i,j] is not None:
                counter += 1

    assert counter == expected_population

def test_no_deaths_without_infected(monkeypatch, simulation):
    info = iter([90, 100, 0, 0, 0, 100])
    monkeypatch.setattr("builtins.input", lambda _: str(next(info)))

    simulation.ask_pre_info()
    simulation.init__grid()
    monkeypatch.setattr(simulation, "info", lambda: None)
    for _ in range(10):
        simulation.update()

    dead_count = sum(
        1
        for person in simulation.matrix.flat
        if person is not None and person.status == "dead"
    )

    assert dead_count == 0