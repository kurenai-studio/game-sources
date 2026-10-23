using UnityEngine;

namespace BouncingBehaviors
{
    public class WallBounce : IBounceBehavior
    {
        public void Bounce(Ball ball, Collision2D collision)
        {
            var currentDirection = ball.Direction; 
            
            var normal = collision.GetContact(0).normal;

            var reflectedDirection = Vector2.Reflect(currentDirection, normal);
            
            ball.Direction = reflectedDirection;
        }
    }
}