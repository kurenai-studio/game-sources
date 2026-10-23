using UnityEngine;

namespace BouncingBehaviors
{
    public class PaddleBounce : IBounceBehavior
    {
        public void Bounce(Ball ball, Collision2D collision)
        {
            var paddleCenter = collision.collider.bounds.center;
            var paddleExtentsY = collision.collider.bounds.extents.y;
            var contactPoint = collision.GetContact(0).point;
            
            // Calculate the hit factor (a value from -1 to 1 based on where the ball hit)
            var hitFactor = Mathf.Clamp((contactPoint.y - paddleCenter.y) / paddleExtentsY, -1, 1);
            
            var angle = hitFactor * ball.RuntimeBallData.maxBounceAngleInDegrees * Mathf.Deg2Rad;
            
            ball.Direction = new Vector2(-Mathf.Sign(ball.Direction.x) * Mathf.Cos(angle), Mathf.Sin(angle));
            
            ball.RuntimeBallData.speed = Mathf.Min(ball.RuntimeBallData.speed * ball.RuntimeBallData.speedIncrease, ball.RuntimeBallData.maxSpeed); 
        }
    }
}