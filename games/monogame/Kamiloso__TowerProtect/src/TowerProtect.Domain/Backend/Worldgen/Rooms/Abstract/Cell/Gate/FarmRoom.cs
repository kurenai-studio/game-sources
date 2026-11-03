using System;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell.Gate;

internal abstract class FarmRoom(Random rng, char enemy) : GateRoom(rng,
    entrance: 'R',
    pattern: """
        ? . . . ?
        . . . . .
        . . ? . .
        . . . . .
        ? . . . ?
        """)
{
    protected override TileType ParseTile(char c)
    {
        if (c == '?')
            c = enemy;

        return base.ParseTile(c);
    }
}
