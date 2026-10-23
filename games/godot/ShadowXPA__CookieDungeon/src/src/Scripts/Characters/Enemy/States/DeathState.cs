using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;

namespace CookieDungeon.Scripts.Characters.Enemy.States;

public partial class DeathState : State
{
    public override void Enter()
    {
        var subject = GetSubject<Enemy>();
        if (subject is null) return;

        subject.Animations?.ResetAndPlay("death");
    }
}
