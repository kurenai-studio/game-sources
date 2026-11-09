namespace PortalMercenary.Graphics.Actors.Animations;

public abstract class ActorAnimation
{
    public required float Duration { get; init; }

    public bool IsFinished { get; private set; }

    protected float _dt;

    public abstract void Start(ActorBody actor);
    
    public virtual void Update(float dt)
    {
        _dt += dt;

        if (_dt >= Duration)
        {
            IsFinished = true;
            Finish();
        }
    }
    
    public abstract void Finish();
}