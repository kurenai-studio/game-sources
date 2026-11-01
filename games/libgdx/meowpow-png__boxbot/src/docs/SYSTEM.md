# System

## Hot Path

The game enters the runtime path through `SimulationScreen.render(float delta)`.
Simulation advances at fixed intervals while rendering runs on every frame.

```mermaid
flowchart TD
    Frame["SimulationScreen.render(delta)"]
    Failed{"World has failed?"}
    End["Mark run ended"]
    Running{"Run still active?"}
    Movement["Movement TickAccumulator"]
    Action["Action TickAccumulator"]
    Render["Render every frame"]

    Frame --> Failed
    Failed -->|yes| End
    Failed -->|no| Running
    End --> Running
    Running -->|yes| Movement
    Movement --> Action
    Running -->|no| Render
    Action --> Render

    Render --> Map["WorldRenderer"]
    Render --> Entities["EntityRenderer"]
    Render --> Lighting["LightingRenderer"]
    Render --> Hud["HudRenderer"]
```

`TickAccumulator` converts frame delta into zero or more fixed ticks. Its movement alpha is then shared by entity and lighting rendering for interpolation.

```mermaid
sequenceDiagram
    participant Screen as SimulationScreen
    participant Movement as movement TickAccumulator<br/>0.3 seconds
    participant Director as RobotDirector
    participant Action as action TickAccumulator<br/>0.75 seconds
    participant World as World and demand processes
    participant Renderers

    Screen->>Movement: update(delta)
    loop zero or more elapsed movement ticks
        Movement->>Director: tickMovement()
    end
    Screen->>Action: update(delta)
    loop zero or more elapsed action ticks
        Action->>Director: tickAction()
        Action->>World: world.tick()
        Action->>World: retrievalDemandProcess.tick(world)
        Action->>World: truck.tick(world)
    end
    Screen->>Renderers: render(movement alpha)
```

## Robot Director

The director advances the robot's lifecycle. When the robot is neither moving nor busy, it either begins the next phase or asks the controller for an action.

```mermaid
stateDiagram-v2
    [*] --> DecisionReady
    DecisionReady --> ToSource: TakeJob or Retrieve
    DecisionReady --> ToChargingStation: Charge
    ToSource --> PickingUp: route complete
    PickingUp --> DecisionReady: pickup complete
    DecisionReady --> ToDestination: StoreAt or ReserveBay
    ToDestination --> DroppingOff: route complete
    DroppingOff --> DecisionReady: drop-off complete
    ToChargingStation --> Charging: route complete
    Charging --> DecisionReady: battery full
    DecisionReady --> DecisionReady: Idle
```

Travel begins only when the director commits to an action that requires a destination. A route is consumed one turn or one cell at a time on movement ticks.

```mermaid
flowchart TD
    Route["RobotDirector.routeTo(goals)"] --> Find["Pathfinder.findPath"]
    Find --> AtGoal{"Start is a goal?"}
    AtGoal -->|yes| NoTravel["Single-cell path; no route to follow"]
    AtGoal -->|no| Search["Breadth-first search of walkable neighbors"]
    Search --> Reachable{"Goal reached?"}
    Reachable -->|no| NoPath["Empty path"]
    Reachable -->|yes| Reconstruct["Reconstruct shortest path"]
    Reconstruct --> Follow["Robot.followRoute"]
    Follow --> Movement["Robot.tickMovement"]
    Movement --> Available{"Route present and battery available?"}
    Available -->|no| Ready["Director may advance state"]
    Available -->|yes| Facing{"Facing next cell?"}
    Facing -->|no| Turn["Turn only"]
    Facing -->|yes| Step["Move one cell and drain battery"]
```

## Robot Controller

`AiRobotController` provides policy; `RobotDirector` validates and carries out the resulting action.

```mermaid
flowchart TD
    Decide["RobotController.decide"] --> Carrying{"Carrying a package?"}
    Carrying -->|yes| Retrieval{"Retrieval package and bay capacity?"}
    Retrieval -->|yes| Reserve["ReserveBay"]
    Retrieval -->|no| Empty{"An empty shelf exists?"}
    Empty -->|yes| Store["StoreAt"]
    Empty -->|no| Idle["Idle"]

    Carrying -->|no| Low{"Battery low?"}
    Low -->|yes| Charge["Charge"]
    Low -->|no| Wanted{"Wanted occupied shelf exists?"}
    Wanted -->|yes| Retrieve["Retrieve nearest shelf"]
    Wanted -->|no| Job{"Pending putaway job exists?"}
    Job -->|yes| Take["TakeJob"]
    Job -->|no| Idle
```

## Simulation

Action ticks also advance the world and its periodic processes, in a fixed order.

```mermaid
flowchart TD
    Tick["Action tick"] --> RobotAction["RobotDirector.tickAction"]
    RobotAction --> WorldTick["World.tick"]
    WorldTick --> Clock["Advance simulation clock"]
    Clock --> Expired{"Orders past deadline?"}
    Expired -->|yes| Revert["Revert each expired order"]
    Expired -->|no| Demand
    Revert --> Demand["RetrievalDemandProcess.tick"]
    Demand --> Arrival{"Demand interval elapsed?"}
    Arrival -->|yes| Order["Sample color and start outbound order"]
    Arrival -->|no| Truck
    Order --> Truck["Truck.tick"]
    Truck --> Visit{"Truck interval elapsed?"}
    Visit -->|yes| Work["Ship outbound packages; add inbound packages and putaway jobs"]
    Visit -->|no| Done["Tick complete"]
    Work --> Done
```

## Rendering

Rendering remains active after the run ends. It reads world state but does not advance simulation state.

```mermaid
flowchart LR
    Frame["Frame render"] --> Map["WorldRenderer<br/>viewport, camera, tile map"]
    Map --> Entities["EntityRenderer"]
    Entities --> Bay["Loading-bay label and packages"]
    Entities --> Station["Charging station"]
    Entities --> Shelves["Each shelf: package or label"]
    Entities --> Robot["Interpolated robot and carried package"]
    Robot --> Lighting["LightingRenderer"]
    Lighting --> Mask["Render darkness and headlight mask"]
    Mask --> Composite["Composite mask over world"]
    Composite --> Hud["HudRenderer<br/>HUD panel"]
```
