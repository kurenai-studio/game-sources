using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Enemy.States;

public partial class ChaseState : State
{
    public override void Enter()
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return;

        subject.Animations?.ResetAndPlay("move");
    }

    public override string? ProcessPhysics(double delta)
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return null;

        var target = subject.Target;

        if (target is null) return null;

        var direction = (target.GlobalPosition - subject.GlobalPosition).Normalized();

        subject.Velocity = subject.Velocity.MoveToward(direction * subject.Stats.Speed,
            (direction == Vector2.Zero ? subject.Stats.Deceleration : subject.Stats.Acceleration) * (float)delta);
        subject.MoveAndSlide();

        return null;
    }
}
