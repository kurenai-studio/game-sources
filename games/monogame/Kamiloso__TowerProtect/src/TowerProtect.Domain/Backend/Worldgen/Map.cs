using AutoInterfaceAttributes;
using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Worldgen;

[AutoInterface]
internal abstract class Map : IMap
{
    public abstract int Range { get; }
    public int Size => 2 * Range + 1;
    public int Capacity => Size * Size;

    private readonly Area<TileType> _area;
    public TileType this[Vec2Int pos] => _area[pos];

    protected Map()
    {
        _area = GenerateArea();

        if (_area.Range != Range)
            throw new InvalidOperationException("Invalid table range");
    }

    protected abstract Area<TileType> GenerateArea();
}
