using System;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Inventions.Tools;

public class Area<T>
{
    public int Range { get; }
    public int Size => Area.Size(Range);
    public int Capacity => Area.Capacity(Range);

    private readonly T[] _data;

    public Area(int range)
    {
        Range = range;
        _data = new T[Capacity];
    }

    public Area(int range, Func<Vec2Int, T> factory) : this(range)
        => Populate(factory);

    public Area(int range, out int size) : this(range)
        => size = Size;

    public T this[Vec2Int pos]
    {
        get => _data[Size * (pos.x + Range) + pos.y + Range];
        set => _data[Size * (pos.x + Range) + pos.y + Range] = value;
    }

    public bool ContainsKey(Vec2Int pos) => Area.ContainsKey(Range, pos);

    public Area<T> Iterate(Action<Vec2Int> action)
    {
        Area.Iterate(Range, action);
        return this;
    }

    public Area<T> Populate(Func<Vec2Int, T> factory)
    {
        Iterate(pos => this[pos] = factory(pos));
        return this;
    }
}

public static class Area
{
    public static int Size(int range) => 2 * range + 1;
    public static int Capacity(int range) => Size(range) * Size(range);

    public static bool ContainsKey(int range, Vec2Int pos)
        => Math.Abs(pos.x) <= range && Math.Abs(pos.y) <= range;

    public static void Iterate(int range, Action<Vec2Int> action)
    {
        for (int x = -range; x <= range; x++)
            for (int y = -range; y <= range; y++)
            {
                action(new Vec2Int(x, y));
            }
    }
}
