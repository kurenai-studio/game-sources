using System;
using TowerProtect.Domain.Model.Tiles;

namespace TowerProtect.Domain.Backend.Tiles.Abstract;

public abstract class Tile(byte durability = 0)
{
    public abstract TileType Type { get; }
    public virtual bool IsBreakable => false;
    public virtual bool IsPassable => false;

    public byte Durability { get; private set; } = durability;
    public bool Exists { get; private set; } = true;
    public TileData TileData => new(Type, Durability);

    public event Action? OnBreakEvent;

    public bool TryBreak()
    {
        if (IsBreakable && Exists && --Durability <= 0)
        {
            BeforeBreak();

            OnBreakEvent?.Invoke();
            Exists = false;

            return true;
        }

        return false;
    }

    protected virtual void BeforeBreak() { }
}
