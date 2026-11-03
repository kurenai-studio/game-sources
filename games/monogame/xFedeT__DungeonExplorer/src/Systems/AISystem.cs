// ============================================
// Systems/AISystem.cs
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Entities;
using DungeonExplorer.Components;
using DungeonExplorer.World;
using System;

namespace DungeonExplorer.Systems
{
    public class AISystem
    {
        public void Update(GameTime gameTime, Enemy enemy, Player player, Dungeon dungeon)
        {
            if (enemy?.AI == null || enemy.Transform == null || enemy.Movement == null) return;
            if (player?.Transform == null) return;

            var ai = enemy.AI;
            var transform = enemy.Transform;
            var movement = enemy.Movement;

            float distanceToPlayer = Vector2.Distance(transform.Position, player.Transform.Position);

            // State transitions
            switch (ai.CurrentState)
            {
                case AIState.Idle:
                case AIState.Patrolling:
                    if (distanceToPlayer <= ai.DetectionRange)
                    {
                        ai.SetState(AIState.Chasing);
                        ai.Target = player.Transform.Position;
                    }
                    else if (ai.CurrentState == AIState.Idle)
                    {
                        ai.SetState(AIState.Patrolling);
                    }
                    break;

                case AIState.Chasing:
                    if (distanceToPlayer > ai.DetectionRange * 1.5f)
                    {
                        ai.SetState(AIState.Searching);
                        ai.LastPlayerPosition = player.Transform.Position;
                        ai.LastPlayerSeenTime = (float)gameTime.TotalGameTime.TotalSeconds;
                    }
                    else if (distanceToPlayer <= ai.AttackRange)
                    {
                        ai.SetState(AIState.Attacking);
                    }
                    else
                    {
                        ai.Target = player.Transform.Position;
                    }
                    break;

                case AIState.Attacking:
                    if (distanceToPlayer > ai.AttackRange)
                    {
                        ai.SetState(AIState.Chasing);
                    }
                    break;

                case AIState.Searching:
                    if (distanceToPlayer <= ai.DetectionRange)
                    {
                        ai.SetState(AIState.Chasing);
                    }
                    else if (ai.StateTimer > 3f) // Search for 3 seconds
                    {
                        ai.SetState(AIState.Patrolling);
                    }
                    break;
            }

            // State behaviors
            switch (ai.CurrentState)
            {
                case AIState.Patrolling:
                    HandlePatrolling(ai, transform, movement, gameTime);
                    break;

                case AIState.Chasing:
                    HandleChasing(ai, transform, movement, dungeon);
                    break;

                case AIState.Attacking:
                    HandleAttacking(enemy, player);
                    break;

                case AIState.Searching:
                    HandleSearching(ai, transform, movement, dungeon);
                    break;
            }
        }

        private void HandlePatrolling(AIComponent ai, TransformComponent transform, MovementComponent movement, GameTime gameTime)
        {
            if (!ai.CanPatrol()) return;

            if (ai.CurrentPath.Count == 0 || ai.HasReachedEndOfPath())
            {
                var nextPatrolPoint = ai.GetNextPatrolPoint();
                if (nextPatrolPoint.HasValue)
                {
                    ai.Target = nextPatrolPoint.Value * 32; // Convert to world coordinates
                    // For simplicity, just move directly (in a full implementation, use pathfinding)
                }
                ai.ResetPatrolTimer();
            }

            MoveTowardsTarget(ai, transform, movement);
        }

        private void HandleChasing(AIComponent ai, TransformComponent transform, MovementComponent movement, Dungeon dungeon)
        {
            // Find path to player
            if (ai.FindPath(transform.Position, ai.Target, dungeon))
            {
                MoveAlongPath(ai, transform, movement);
            }
            else
            {
                // Direct movement if pathfinding fails
                MoveTowardsTarget(ai, transform, movement);
            }
        }

        private void HandleAttacking(Enemy enemy, Player player)
        {
            if (enemy.CanAttack())
            {
                enemy.Attack();
                // Damage would be handled by combat system
            }
        }

        private void HandleSearching(AIComponent ai, TransformComponent transform, MovementComponent movement, Dungeon dungeon)
        {
            // Move towards last known player position
            ai.Target = ai.LastPlayerPosition;
            MoveTowardsTarget(ai, transform, movement);
        }

        private void MoveTowardsTarget(AIComponent ai, TransformComponent transform, MovementComponent movement)
        {
            var direction = ai.Target - transform.Position;
            if (direction.Length() > 5f) // Close enough threshold
            {
                direction.Normalize();
                movement.AddForce(direction * ai.MoveSpeed * 10f);
            }
        }

        private void MoveAlongPath(AIComponent ai, TransformComponent transform, MovementComponent movement)
        {
            var nextPoint = ai.GetNextPathPoint();
            if (nextPoint.HasValue)
            {
                var direction = nextPoint.Value - transform.Position;
                if (direction.Length() < 16f) // Close enough to waypoint
                {
                    ai.AdvanceToNextPathPoint();
                }
                else
                {
                    direction.Normalize();
                    movement.AddForce(direction * ai.MoveSpeed * 10f);
                }
            }
        }
    }
}
