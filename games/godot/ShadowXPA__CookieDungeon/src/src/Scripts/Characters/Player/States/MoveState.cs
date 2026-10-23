using CookieDungeon.Scripts.States;
using CookieDungeon.Scripts.Utils;
using Godot;

namespace CookieDungeon.Scripts.Characters.Player.States;

public partial class MoveState : State
{
    private float _regenCooldown = 2.5f;

    public override void Enter()
    {
        var subject = GetSubject<Player>();
        if (subject is null) return;

        _regenCooldown = 2.5f;
        subject.Animations?.ResetAndPlay("move");
    }

    public override string? ProcessInput(InputEvent @event)
    {
        var subject = GetSubject<Player>();
        if (subject is null) return null;

        if (@event is InputEventMouseMotion mouseMotion)
        {
            var target = subject.InputController.GetTargetPosition(subject);
            subject.LookAtTarget(target);
        }

        if (subject.InputController.IsDashing() && subject.Skills.Dash.CanCast(subject.Stats.Mana + subject.Stats.Level))
        {
            return "dash";
        }

        if (subject.InputController.IsNormalAttacking() && subject.Skills.NormalAttack.CanCast())
        {
            return "attack";
        }

        return null;
    }

    public override string? ProcessFrame(double delta)
    {
        var subject = GetSubject<Player>();
        if (subject is null) return null;

        _regenCooldown -= (float)delta;

        if (_regenCooldown <= 0)
        {
            var stats = subject.Stats;
            _regenCooldown = 2.5f;
            stats.RegenHealth();
            stats.RegenMana();
            SignalBus.BroadcastHealthUpdated(stats.Health, stats.MaxHealth);
            SignalBus.BroadcastManaUpdated(stats.Mana, stats.MaxMana);
        }

        return null;
    }

    public override string? ProcessPhysics(double delta)
    {
        var subject = GetSubject<Player>();
        if (subject is null) return null;

        var direction = subject.InputController.GetDirection();

        subject.Velocity = subject.Velocity.MoveToward(direction * subject.Stats.Speed,
            (direction == Vector2.Zero ? subject.Stats.Deceleration : subject.Stats.Acceleration) * (float)delta);
        subject.MoveAndSlide();

        if (subject.Velocity == Vector2.Zero)
        {
            return "idle";
        }

        return null;
    }
}
