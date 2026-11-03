using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Specific;

internal class SpawnRoom(Random rng) : GiantRoom(rng,
    pattern: """
        . . . . . . . . . . . . . . . . .
        . B . B . . . . . . . . . B . B .
        . . ~ . . . . . . . . . . . ~ . .
        . B . B . . . . . . . . . B . B .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . . . . . . . . . . . . . . . . .
        . B . B . . . . . . . . . B . B .
        . . ~ . . . . . . . . . . . ~ . .
        . B . B . . . . . . . . . B . B .
        . . . . . . . . . . . . . . . . .
        """);
