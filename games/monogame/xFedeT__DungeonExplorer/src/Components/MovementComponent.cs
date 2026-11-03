// ============================================
// MovementComponent.cs - Handles movement and physics
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Components;

namespace DungeonExplorer.Components
{
    /// <summary>
    /// Component that handles entity movement and basic physics
    /// </summary>
    public class MovementComponent : IComponent
    {
        public Vector2 Velocity { get; set; }
        public Vector2 Acceleration { get; set; }
        public float MaxSpeed { get; set; }
        public float Friction { get; set; }
        public bool CanMove { get; set; }

        public MovementComponent(float maxSpeed = 100f, float friction = 0.8f)
        {
            Velocity = Vector2.Zero;
            Acceleration = Vector2.Zero;
            MaxSpeed = maxSpeed;
            Friction = friction;
            CanMove = true;
        }

        public void Update(GameTime gameTime)
        {
            if (!CanMove) return;

            float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;

            // Apply acceleration to velocity
            Velocity += Acceleration * deltaTime;

            // Apply friction
            Velocity *= Friction;

            // Clamp to max speed
            if (Velocity.Length() > MaxSpeed)
            {
                Velocity.Normalize();
                Velocity *= MaxSpeed;
            }

            // Reset acceleration for next frame
            Acceleration = Vector2.Zero;
        }

        public void AddForce(Vector2 force)
        {
            Acceleration += force;
        }

        public void SetVelocity(Vector2 velocity)
        {
            Velocity = velocity;
        }
    }
}