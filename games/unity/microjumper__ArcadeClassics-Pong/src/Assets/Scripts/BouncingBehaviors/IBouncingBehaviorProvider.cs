using Playfield;

namespace BouncingBehaviors
{
    public interface IBouncingBehaviorProvider
    {
        public IBounceBehavior BounceBehavior { get; }
        public SurfaceType SurfaceType { get; }
    }
}