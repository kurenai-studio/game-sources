using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Player.States;

public partial class DeathState : State
{
    public override void Enter()
    {
        var subject = GetSubject<Player>();
        if (subject is null) return;

        subject.Velocity = Vector2.Zero;
        subject.Animations?.ResetAndPlay("death");
        SignalBus.BroadcastPlayerDied();
    }
}
