using CookieDungeon.Scripts.Objects;
using Godot;

namespace CookieDungeon.Scripts.Characters.Enemy;

public partial class RangedEnemy : Enemy
{
    [Export]
    public PackedScene? Projectile { get; private set; }
    [Export]
    public Marker2D? ProjectileSpawner { get; private set; }
    [Export]
    public Node? ProjectileContainer { get; private set; }
    [Export]
    public float ProjectileRange { get; private set; } = 300.0f;

    public void SpawnProjectile()
    {
        if (Target is null || Projectile is null || ProjectileContainer is null || ProjectileSpawner is null) return;

        var projectile = Projectile.Instantiate<Projectile>();
        var projectileStats = new Stats(Stats);
        projectileStats.Speed *= 2;
        projectile.ProjectileDistance = ProjectileRange * Scale.X;
        projectile.SetStats(projectileStats);
        ProjectileContainer.AddChild(projectile);
        projectile.Scale = Scale;
        projectile.GlobalPosition = ProjectileSpawner.GlobalPosition;
        projectile.MoveTowardTarget(Target.GlobalPosition, (Target.GlobalPosition - ProjectileSpawner.GlobalPosition).Normalized());
    }
}
