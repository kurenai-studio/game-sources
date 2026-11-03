# InfectionSim

**InfectionSim** is a Python application with a graphical user interface (GUI) and command-line inputs for simulating the spread of an airborne infectious disease through a population. It models transmission dynamics and individual health outcomes over time.

Individuals can be **healthy (susceptible), carriers, infected, immune (including vaccinated individuals), recovered, or dead**.

The model is conceptually inspired by respiratory infectious diseases such as **COVID-19, influenza, and measles**.

> **Disclaimer:** InfectionSim is an educational and visualization tool, not a scientifically validated epidemiological model. Its simplified probabilistic approach provides a visual representation of how an infectious disease can spread through a population. The simulation does not use differential equations and should not be used to make real-world epidemiological predictions.

## Features

### Health statuses and color coding

The simulation represents individuals as colored cells in a population grid.

| Status | Description | Color |
|---|---|---|
| Susceptible | Healthy individuals who can become infected | Blue |
| Immune | Vaccinated or otherwise immune individuals | Green |
| Carrier | Individuals carrying the infectious agent | Yellow |
| Infected | Individuals with or without symptoms | Red |
| Recovered | Individuals who have recovered from the infection | Magenta |
| Dead | Individuals who have died | Brown |
| Empty cell | No individual present | Black |

### Initial parameters

At startup, the application requests the following parameters:

- **Population density:** Percentage of cells occupied by individuals, calculated as the number of individuals divided by the total number of cells.
- **Healthy individuals:** Percentage of the population that is healthy and susceptible.
- **Carriers:** Percentage of the population classified as carriers.
- **Infected individuals:** Percentage of the population that is infected.
- **Vaccinated individuals:** Percentage of the population that is vaccinated.

The initial percentages of healthy, carrier, infected, and vaccinated individuals must add up to **100% of the population**.

### Simulation results

When the simulation is terminated using `ESC`, a graph displaying the trends of the different population categories is generated using **Matplotlib**.

The graph supports interactive inspection, including **zooming in and out**, and can be **saved as an image file** using Matplotlib's toolbar.

## Requirements

- Python 3.9 or newer
- The dependencies listed in `requirements.txt`

The application uses the following libraries:

- `numpy` — Matrix handling and numerical operations.
- `pygame-ce` — GUI rendering, simulation visualization, and keyboard/mouse input.
- `matplotlib` — Plotting and visualizing simulation results.
- `pytest` — Automated testing of the application (used for the test suite).

Any additional dependencies are listed in `requirements.txt`. Other functionality relies on Python's standard library.

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/zj4ck3/infectionSim.git
cd infectionSim
```

### 2. Create and activate a virtual environment

On Linux and macOS:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

On Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### 3. Install the dependencies

```bash
python -m pip install -r requirements.txt
```

### 4. Install the package in editable mode

```bash
python -m pip install -e .
```

Editable mode allows you to modify the source code without reinstalling the package after every change. It is also useful when working on the project and running its tests.

## Usage

### Start the application

Run the following command from the project's root directory:

```bash
python src/main.py
```

### 1. Initialization

At startup, the application requests command-line parameters, including population density and the initial distribution of individuals among the different health statuses.

### 2. Simulation controls

| Key / Input | Action |
|---|---|
| `SPACE` | Pause the simulation |
| `+` / `-` | Increase or decrease the simulation speed (tick rate) |
| `R` | Convert all infected individuals and carriers into recovered individuals |
| Left mouse button | Change the selected cell's status when the simulation is paused |

To modify an individual's status, pause the simulation, select the desired status using the corresponding key, and then click the target cell with the left mouse button.

#### Cell status editing

| Key | New status |
|---|---|
| `S` | Susceptible |
| `V` | Immune / vaccinated |
| `C` | Carrier |
| `I` | Infected |
| `D` | Dead |
| `H` | Recovered |
| `N` | Empty cell |

### 3. Exiting the simulation

- **`ESC`** — End the simulation and display a graph of the population trends. The graph can be zoomed and saved using Matplotlib's toolbar.
- **Window close button (`X`)** — Exit the application.

## Project Structure

```text
infectionSim/
├── src/
│   ├── main.py             # Application entry point
│   ├── simulation.py       # Simulation logic and Pygame rendering
│   └── person.py           # Person class and health status transitions
├── tests/
│   ├── test_person.py      # Tests for person.py
│   └── test_simulation.py  # Tests for simulation.py
├── requirements.txt        # Python dependencies
├── LICENSE                 # MIT License
├── README.md               # Project documentation
└── pyproject.toml          # Project metadata and test configuration
```

## Contributing

Bug reports, suggestions, and pull requests are welcome.

Before submitting a change, please verify that:

- The application starts and runs correctly.
- All automated tests pass.

Run the test suite with:

```bash
python -m pytest
```

## License

This project is licensed under the [MIT License](LICENSE).