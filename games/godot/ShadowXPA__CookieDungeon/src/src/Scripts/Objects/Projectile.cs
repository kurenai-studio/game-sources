using CookieDungeon.Scripts.Characters;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Objects;

public partial class Projectile : Area2D
{
    [Export]
    public Stats Stats { get; private set; } = new();
    [Export]
    public float ProjectileDistance { get; set; } = 300.0f;

    private AnimatedSprite2D? _animations;
    private CollisionShape2D? _hitbox;
    private Vector2? _direction;
    private float _projectileDuration;

    public override void _Ready()
    {
        _animations = GetNode<AnimatedSprite2D>("%Animations");
        _hitbox = GetNode<CollisionShape2D>("%HitBox");
        _animations.AnimationFinished += QueueFree;
        BodyEntered += OnHit;
    }

    public override void _ExitTree()
    {
        if (_animations is not null)
            _animations.AnimationFinished -= QueueFree;
        BodyEntered -= OnHit;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_direction is null) return;

        var direction = (Vector2)_direction;
        GlobalPosition += direction * Stats.Speed * (float)delta;

        _projectileDuration -= (float)delta;

        if (_projectileDuration <= 0)
        {
            Break();
        }
    }

    public void MoveTowardTarget(Vector2 target, Vector2 direction)
    {
        _direction = direction;
        this.LookAtPoint(target);
        _animations?.Play("thrown");
    }

    public void OnHit(Node2D body)
    {
        Break();

        if (body is Character character)
        {
            var crit = GD.Randf();
            var isCrit = crit <= Stats.CriticalRate;
            character.ApplyDamage(Stats.Attack, Stats.CriticalDamage, isCrit);
        }
    }

    public void SetStats(Stats stats)
    {
        Stats = stats;
        _projectileDuration = ProjectileDistance / Stats.Speed;
    }

    private void Break()
    {
        _direction = null;
        _animations?.Play("broken");
        _hitbox?.SetDeferred(CollisionShape2D.PropertyName.Disabled, true);
    }
}
