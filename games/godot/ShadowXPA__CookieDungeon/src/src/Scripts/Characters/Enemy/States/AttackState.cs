using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;

namespace CookieDungeon.Scripts.Characters.Enemy.States;

public partial class AttackState : State
{
    public override void Enter()
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return;

        subject.Animations?.ResetAndPlay("attack");
    }

    public override string? ProcessFrame(double delta)
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return null;

        if (subject.Animations is null || !subject.Animations.IsPlaying())
        {
            var isInRange = subject.Target is not null && (subject.AttackRange?.OverlapsBody(subject.Target) ?? false);

            if (isInRange) return "attack";

            if (subject.Target is not null)
            {
                return "chase";
            }

            return "idle";
        }

        return null;
    }
}
