// ============================================
// Enemy.cs - Enemy entity with AI behavior
// ============================================
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Entities;
using DungeonExplorer.Components;
using System;

namespace DungeonExplorer.Entities
{
    /// <summary>
    /// Enemy entity with AI behavior and pathfinding
    /// </summary>
    public class Enemy : Entity
    {
        public int Damage { get; set; }
        public float AttackCooldown { get; set; }
        private float _attackTimer;

        public Enemy(Vector2 position, Texture2D texture)
        {
            // Add required components
            AddComponent(new TransformComponent(position));
            AddComponent(new RenderComponent(texture));
            AddComponent(new MovementComponent(80f, 0.9f)); // Slightly slower than player
            AddComponent(new HealthComponent(50));
            AddComponent(new AIComponent(100f, 35f, 60f)); // Detection range, attack range, move speed

            Damage = 20;
            AttackCooldown = 1.5f; // Attack every 1.5 seconds
            _attackTimer = 0f;

            // Set up render component
            var render = GetComponent<RenderComponent>();
            render.LayerDepth = 0.4f;

            // Set up some patrol points around starting position
            SetupPatrolBehavior(position);
        }

        private void SetupPatrolBehavior(Vector2 startPos)
        {
            var ai = GetComponent<AIComponent>();
            if (ai != null)
            {
                // Add some patrol points in a small area around spawn
                ai.AddPatrolPoint(startPos + new Vector2(-64, 0));
                ai.AddPatrolPoint(startPos + new Vector2(64, 0));
                ai.AddPatrolPoint(startPos + new Vector2(0, -64));
                ai.AddPatrolPoint(startPos + new Vector2(0, 64));
                ai.SetState(AIState.Patrolling);
            }
        }

        public override void Update(GameTime gameTime)
        {
            base.Update(gameTime);

            _attackTimer -= (float)gameTime.ElapsedGameTime.TotalSeconds;

            // Apply movement to transform
            if (Movement != null && Transform != null)
            {
                float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
                Transform.Position += Movement.Velocity * deltaTime;
            }

            // Visual feedback based on AI state
            UpdateVisualFeedback();
        }

        private void UpdateVisualFeedback()
        {
            if (AI == null || Render == null) return;

            switch (AI.CurrentState)
            {
                case AIState.Idle:
                case AIState.Patrolling:
                    Render.Tint = Color.White;
                    break;
                case AIState.Chasing:
                    Render.Tint = Color.Orange;
                    break;
                case AIState.Attacking:
                    Render.Tint = Color.Red;
                    break;
                case AIState.Searching:
                    Render.Tint = Color.Yellow;
                    break;
            }
        }

        public bool CanAttack()
        {
            return _attackTimer <= 0f;
        }

        public void Attack()
        {
            _attackTimer = AttackCooldown;
            // Attack logic would be handled by combat system
        }

        public Vector2 GetGridPosition()
        {
            return new Vector2(
                MathF.Floor(Transform.Position.X / 32f),
                MathF.Floor(Transform.Position.Y / 32f)
            );
        }

        public float GetDistanceToPlayer(Player player)
        {
            return Vector2.Distance(Transform.Position, player.Transform.Position);
        }
    }
}