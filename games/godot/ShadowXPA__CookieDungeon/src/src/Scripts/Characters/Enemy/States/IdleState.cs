using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Enemy.States;

public partial class IdleState : State
{
    private double _idleTime;

    public override void Enter()
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return;

        subject.Velocity = Vector2.Zero;
        subject.Animations?.ResetAndPlay("idle");
        RandomizeIdle();
    }

    public override string? ProcessFrame(double delta)
    {
        _idleTime -= delta;

        if (_idleTime <= 0)
        {
            return "wander";
        }

        return null;
    }


    private void RandomizeIdle()
    {
        _idleTime = GD.RandRange(1.0, 3.0);
    }
}
