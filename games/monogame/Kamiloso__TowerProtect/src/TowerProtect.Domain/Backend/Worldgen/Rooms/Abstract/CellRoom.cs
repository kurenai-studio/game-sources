using System;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract;

internal abstract class GiantRoom(Random rng, string pattern)
    : Room(rng, range: 8, pattern);
