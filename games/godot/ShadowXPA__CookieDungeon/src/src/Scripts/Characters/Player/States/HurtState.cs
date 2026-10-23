using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Player.States;

public partial class HurtState : State
{
    public override void Enter()
    {
        var subject = GetSubject<Player>();
        if (subject is null) return;

        subject.Velocity = Vector2.Zero;
        subject.Animations?.ResetAndPlay("hurt");
    }

    public override string? ProcessFrame(double delta)
    {
        var subject = GetSubject<Player>();
        if (subject is null) return null;

        if (subject.Animations is null || !subject.Animations.IsPlaying())
        {
            return "idle";
        }

        return null;
    }
}
