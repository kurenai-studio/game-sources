using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell.Gate;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Specific.Farm;

internal class AnimalRoom(Random rng)
    : FarmRoom(rng, 'n');
