using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Specific;

internal class TrapRoom(Random rng) : CellRoom(rng,
    pattern: """
        B . . . B
        . . . . .
        . . $ . .
        . . . . .
        B . . . B
        """);
