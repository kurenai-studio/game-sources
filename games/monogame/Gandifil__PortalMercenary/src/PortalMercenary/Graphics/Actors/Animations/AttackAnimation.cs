using System;
using Microsoft.Xna.Framework;
using MonoGame.Extended;

namespace PortalMercenary.Graphics.Actors.Animations;

public class AttackAnimation: ActorAnimation
{
    private ActorBody _actorBody;
    private ActorPart _weapon;
    private Vector2 _backupPosition;
    private float _backupRotation;

    private const float Range = MathF.PI / 3;
    private const float Radius = 50f;

    private bool _hasReachedHalf;
    public event EventHandler ReachedHalf;
    public event EventHandler Finished;
    
    public override void Start(ActorBody actorBody)
    {
        _actorBody = actorBody;
        _weapon = actorBody.Weapon;
        _backupPosition = _weapon.Position;
        _backupRotation = _weapon.Rotation;
    }

    public override void Update(float dt)
    {
        base.Update(dt);
        

        var progress = _dt / Duration;
        if (!_hasReachedHalf && progress > 0.5f)
        {
            _hasReachedHalf = true;
            ReachedHalf?.Invoke(this, EventArgs.Empty);
        }
        
        var currentAngle = MathHelper.Lerp(-Range, Range, progress);
        var pos = Radius * new Vector2(0, -1);
        pos.Rotate(_actorBody.Actor.Shift.ToAngle() + currentAngle);
        _weapon.Position = pos;
        _weapon.Rotation = pos.ToAngle() - MathF.PI / 2;
    }

    public override void Finish()
    {
        _weapon.Position = _backupPosition;
        _weapon.Rotation = _backupRotation;
        Finished?.Invoke(this, EventArgs.Empty);
    }
}