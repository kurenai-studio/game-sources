using System;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Worldgen.Rooms.Abstract.Cell;

internal abstract class BlobRoom(Random rng, char tile) : CellRoom(rng,
    pattern: GetRandomPattern(rng))
{
    private readonly Random _rng = rng;

    protected sealed override bool RotateFreely => true;

    private static string GetRandomPattern(Random rng)
    {
        int rand = rng.Next(3);

        if (rand == 0)
            return """
                . . . . .
                . * ? . .
                . ? ? ? .
                . * ? * .
                . . . . .
                """;

        if (rand == 1)
            return """
                . . . . .
                . ^ ? ^ .
                . ? ? ? .
                . ^ ^ ^ .
                . . . . .
                """;

        if (rand == 2)
            return """
                . . . . .
                . . ? ^ .
                . ^ ? ? .
                . . ^ . .
                . . . . .
                """;

        throw new NotSupportedException();
    }

    protected override TileType ParseTile(char c) => base.ParseTile(c switch
    {
        '^' => _rng.Next(3) == 0 ? tile : '.',
        '*' => _rng.Next(2) == 0 ? tile : '.',
        '?' => tile,
        _ => c
    });
}
