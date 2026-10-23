using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Enemy.States;

public partial class WanderState : State
{
    private Vector2 _direction;
    private double _wanderTime;

    public override void Enter()
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return;

        RandomizeWander();
        subject.Animations?.ResetAndPlay("move");
    }

    public override string? ProcessFrame(double delta)
    {
        _wanderTime -= delta;

        if (_wanderTime <= 0)
        {
            return "idle";
        }

        return null;
    }

    public override string? ProcessPhysics(double delta)
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return null;

        subject.Velocity = subject.Velocity.MoveToward(_direction * (subject.Stats.Speed / 2),
            (_direction == Vector2.Zero ? subject.Stats.Deceleration : subject.Stats.Acceleration) * (float)delta);
        subject.MoveAndSlide();

        return null;
    }

    private void RandomizeWander()
    {
        _direction = new Vector2((float)GD.RandRange(-1.0, 1.0), (float)GD.RandRange(-1.0, 1.0)).Normalized();
        _wanderTime = GD.RandRange(1.0f, 3.0f);
    }
}
