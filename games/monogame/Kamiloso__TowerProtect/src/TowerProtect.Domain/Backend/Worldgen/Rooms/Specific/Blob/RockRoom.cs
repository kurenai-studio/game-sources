using System;
using TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Specific.Blob;

internal class RockRoom(Random rng)
    : BlobRoom(rng, tile: 'B');
