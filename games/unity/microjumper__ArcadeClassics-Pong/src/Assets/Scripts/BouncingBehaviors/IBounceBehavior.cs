using UnityEngine;

namespace BouncingBehaviors
{
    public interface IBounceBehavior
    {
        void Bounce(Ball ball, Collision2D collision);
    }
}