using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Player.States;

public partial class DashState : State
{
    private float _dashDistance = 300.0f;
    private float _dashDuration;
    private Vector2? _direction;

    public override void Enter()
    {
        var subject = GetSubject<Player>();
        if (subject is null) return;

        subject.Velocity = Vector2.Zero;
        subject.Stats.Mana -= subject.Skills.Dash.Cost + subject.Stats.Level;
        subject.Skills.Dash.CurrentCooldown = subject.Skills.Dash.Cooldown;
        SignalBus.BroadcastManaUpdated(subject.Stats.Mana, subject.Stats.MaxMana);
        SignalBus.BroadcastDashCooldownUpdated(subject.Skills.Dash.CurrentCooldown, subject.Skills.Dash.Cooldown);

        _dashDuration = _dashDistance / subject.Stats.Dash;
        var target = subject.InputController.GetTargetPosition(subject);
        _direction = (target - subject.GlobalPosition).Normalized();
        subject.LookAtTarget(target);
        subject.Animations?.ResetAndPlay(subject.Skills.Dash.Animation);
    }

    public override string? ProcessPhysics(double delta)
    {
        var subject = GetSubject<Player>();
        if (subject is null) return null;

        if (_direction is null) return "idle";

        var direction = (Vector2)_direction;

        subject.Velocity = direction * subject.Stats.Dash;
        subject.MoveAndSlide();

        _dashDuration -= (float)delta;

        if (_dashDuration <= 0)
        {
            return "idle";
        }

        return null;
    }
}
