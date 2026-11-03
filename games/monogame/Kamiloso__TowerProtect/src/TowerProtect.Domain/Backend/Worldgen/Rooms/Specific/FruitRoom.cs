using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell.Gate;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Specific;

internal class FruitRoom(Random rng) : GateRoom(rng,
    pattern: """
        S . . . S
        # . . . #
        S . . . S
        # . . . #
        S . . . S
        """);
