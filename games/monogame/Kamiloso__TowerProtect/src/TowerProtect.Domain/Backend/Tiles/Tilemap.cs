using System;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Backend.Tiles.Specific;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Backend.Worldgen;
using AutoInterfaceAttributes;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Backend.Tiles.Abstract;

namespace TowerProtect.Domain.Backend.Tiles;

partial interface ITilemap;

[AutoInterface]
public class Tilemap : ITilemap
{
    private readonly Area<Tile> _area;

    public event Action<Vec2Int, TileData>? TileUpdateEvent;

    public Tilemap(IMap map, ITileFactory tileFactory)
    {
        _area = new Area<Tile>(map.Range);
        _area.Populate(pos =>
        {
            var tileType = map[pos];
            var tile = tileFactory.CreateTile(tileType);

            tile.OnBreakEvent += () =>
            {
                _area[pos] = AirTile.Instance;
                TileUpdateEvent?.Invoke(pos, _area[pos].TileData);
            };

            return tile;
        });
    }

    public TilemapData CollectTilemapData()
        => TilemapData.FromArea(_area, t => t.TileData);

    public bool TryBreak(Vec2Int pos) => _area[pos].TryBreak();
}
