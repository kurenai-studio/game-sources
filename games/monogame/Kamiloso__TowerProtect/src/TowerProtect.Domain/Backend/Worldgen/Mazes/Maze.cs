using System;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Worldgen.Mazes;

internal class Maze
{
    public int MRange { get; }

    private readonly Area<byte> _area;

    public Maze(int mRange)
    {
        MRange = mRange;

        var mPos = mRange * Vec2Int.Right;
        var dir = Vec2Int.Right;

        int areaRange = Ptr(mPos, dir).x;

        _area = new Area<byte>(areaRange)
            .Populate(ptr => (byte)(IsCellPtr(ptr, checkArea: false) ? 0 : 1));
    }

    public void IterateCells(Action<Vec2Int> action)
        => Area.Iterate(MRange, mPos => action(mPos));

    public void IterateEdges(Action<Vec2Int, Vec2Int> action)
        => Area.Iterate(MRange, mPos =>
        {
            action(mPos, Vec2Int.Left);
            action(mPos, Vec2Int.Up);

            if (mPos.x == MRange)
                action(mPos, Vec2Int.Right);

            if (mPos.y == MRange)
                action(mPos, Vec2Int.Down);
        });

    public void IterateCorners(Action<Vec2Int, Vec2Int> action)
        => Area.Iterate(MRange, mPos =>
        {
            action(mPos, Vec2Int.Up + Vec2Int.Left);

            if (mPos.x == MRange)
                action(mPos, Vec2Int.Right + Vec2Int.Up);

            if (mPos.y == MRange)
                action(mPos, Vec2Int.Left + Vec2Int.Down);

            if (mPos.x == MRange && mPos.y == MRange)
                action(mPos, Vec2Int.Right + Vec2Int.Down);
        });

    public bool ExistsAt(Vec2Int mPos, Vec2Int dir)
        => ReadAtPtr(Ptr(mPos, dir)) == 1;

    public bool EmptyAt(Vec2Int mPos, Vec2Int dir)
        => ReadAtPtr(Ptr(mPos, dir)) == 0;

    public bool OutlineAt(Vec2Int mPos, Vec2Int dir)
        => IsOutlineAtPtr(Ptr(mPos, dir));

    public void PlaceAt(Vec2Int mPos, Vec2Int dir)
        => ModifyAtPtr(Ptr(mPos, dir), 1);

    public void RemoveAt(Vec2Int mPos, Vec2Int dir)
        => ModifyAtPtr(Ptr(mPos, dir), 0);

    private byte ReadAtPtr(Vec2Int ptr)
    {
        if (!IsAccessablePtr(ptr))
            throw new ArgumentException($"Element at ptr = {ptr} cannot be read");

        return _area[ptr];
    }

    private bool IsOutlineAtPtr(Vec2Int ptr)
    {
        if (!IsEdgePtr(ptr))
            throw new ArgumentException($"Element at ptr {ptr} is not an edge");

        return ptr.MaxAbs == _area.Range;
    }

    private void ModifyAtPtr(Vec2Int ptr, byte value)
    {
        if (!IsEdgePtr(ptr))
            throw new ArgumentException($"Element at ptr {ptr} cannot be modified");

        if (_area[ptr] == value)
            return;

        _area[ptr] = value;

        foreach (Vec2Int dir in Vec2Int.MainDirections)
        {
            Vec2Int ptr1 = ptr + dir;

            if (!IsCornerPtr(ptr1))
                continue;

            bool isAttached = IsCornerAttachedAtPtr(ptr1);

            _area[ptr1] = (byte)(isAttached ? 1 : 0);
        }
    }

    private bool IsCornerAttachedAtPtr(Vec2Int ptr)
    {
        foreach (Vec2Int dir in Vec2Int.MainDirections)
        {
            Vec2Int ptr2 = ptr + dir;

            if (!IsAccessablePtr(ptr2) || _area[ptr2] == 1)
                return true;
        }

        return false;
    }

    private bool IsCellPtr(Vec2Int ptr, bool checkArea = true)
        => (!checkArea || IsAccessablePtr(ptr)) && ptr.x % 2 == 0 && ptr.y % 2 == 0;

    private bool IsEdgePtr(Vec2Int ptr, bool checkArea = true)
        => (!checkArea || IsAccessablePtr(ptr)) && ptr.x % 2 != 0 ^ ptr.y % 2 != 0;

    private bool IsCornerPtr(Vec2Int ptr, bool checkArea = true)
        => (!checkArea || IsAccessablePtr(ptr)) && ptr.x % 2 != 0 && ptr.y % 2 != 0;

    private bool IsAccessablePtr(Vec2Int ptr)
        => _area.ContainsKey(ptr);

    private static Vec2Int Ptr(Vec2Int mPos, Vec2Int dir)
        => 2 * mPos + dir;
}
