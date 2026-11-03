using System;
using TowerProtect.Domain.Backend.Entities.Interactions.Output;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Abstract;

internal abstract class Entity(Vec2 position, double rotation, byte health)
{
    public Guid Guid { get; } = Guid.NewGuid();

    public abstract EntityType Type { get; }
    public abstract bool IsDamageable { get; }
    public virtual bool IsRendered => true;

    public Vec2 Position { get; protected set; } = position;
    public double Rotation { get; protected set; } = rotation;

    public byte MaxHealth { get; } = health;
    public byte Health { get; private set; } = health;
    public bool IsAlive { get; private set; } = true;

    // protected IEntityPanel Panel { get; } = panel;
    public EntityData EntityData => new(Guid, Type, Position, Rotation);

    public event Action? OnDeathEvent;

    public virtual bool ApplyDamage()
    {
        if (IsDamageable && IsAlive && --Health <= 0)
        {
            BeforeDeath();

            OnDeathEvent?.Invoke();
            IsAlive = false;

            return true;
        }

        return false;
    }

    protected virtual void BeforeDeath() { }
}
