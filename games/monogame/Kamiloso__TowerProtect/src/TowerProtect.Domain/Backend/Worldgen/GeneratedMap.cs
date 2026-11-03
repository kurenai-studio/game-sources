using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Backend.Worldgen.Extended;
using TowerProtect.Domain.Backend.Worldgen.Mazes;
using TowerProtect.Domain.Backend.Worldgen.Rooms;
using static TowerProtect.Domain.Config.WorldgenConfig;

namespace TowerProtect.Domain.Backend.Worldgen;

internal class GeneratedMap(
    IMazeGenerator mazeGenerator,
    IRoomPlacer roomPlacer) : Map
{
    public override int Range => TilemapRange;

    protected override Area<TileType> GenerateArea()
    {
        var rng = new Random();
        var area = new MapArea(Range);

        BuildMaze(area, rng);

        area.SpreadTile(TileType.Rock, 0.02, rng);
        area.PlaceRooms(roomPlacer, rng);

        return area;
    }

    private void BuildMaze(MapArea area, Random rng)
    {
        var maze = new MapMaze(MazeRange);

        maze.Generate(mazeGenerator, rng);
        maze.Decay(0.05, rng);
        maze.Evaporate3x3(Vec2Int.Zero);

        maze.CopyIntoArea(area, TileType.Wall);
    }
}
