using System;
using Microsoft.Xna.Framework;
using Monogame.Enchanted;
using MonoGame.Extended;
using MonoGame.Extended.Collisions;

namespace PortalMercenary.Game;

public abstract class Entity : IFloatUpdatable, ICollisionActor
{
    public Vector2 Position { get; protected set; }
    public int Id { get; }
    public abstract CollisionShape2D Shape { get; }

    public Entity(Vector2 position = default)
    {
        Position = position;
        Id = GetHashCode();
    }
    
    public abstract void Update(float dt);

    public bool IsAlive { get; private set; } = true;

    public event Action<Entity> Died;

    protected void Die()
    {
        IsAlive = false;
        Died?.Invoke(this);
    }
}