// ============================================
// AIComponent.cs - AI behavior and pathfinding
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Components;
using DungeonExplorer.AI;
using DungeonExplorer.World;
using System.Collections.Generic;

namespace DungeonExplorer.Components
{
    public enum AIState
    {
        Idle,
        Patrolling,
        Chasing,
        Attacking,
        Searching
    }

    /// <summary>
    /// Component that handles AI behavior and decision making
    /// </summary>
    public class AIComponent : IComponent
    {
        public AIState CurrentState { get; set; }
        public float DetectionRange { get; set; }
        public float AttackRange { get; set; }
        public float MoveSpeed { get; set; }
        public Vector2 Target { get; set; }
        public List<Vector2> CurrentPath { get; private set; }
        public int CurrentPathIndex { get; set; }
        
        // Patrol behavior
        public List<Vector2> PatrolPoints { get; set; }
        public int PatrolIndex { get; set; }
        public float PatrolWaitTime { get; set; }
        private float _patrolTimer;

        // State timers
        public float StateTimer { get; set; }
        public float LastPlayerSeenTime { get; set; }
        public Vector2 LastPlayerPosition { get; set; }

        private AStar _pathfinder;

        public AIComponent(float detectionRange = 128f, float attackRange = 40f, float moveSpeed = 50f)
        {
            CurrentState = AIState.Idle;
            DetectionRange = detectionRange;
            AttackRange = attackRange;
            MoveSpeed = moveSpeed;
            CurrentPath = new List<Vector2>();
            PatrolPoints = new List<Vector2>();
            PatrolWaitTime = 2f;
            _pathfinder = new AStar();
        }

        public void Update(GameTime gameTime)
        {
            float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
            StateTimer += deltaTime;

            if (CurrentState == AIState.Patrolling)
            {
                _patrolTimer += deltaTime;
            }
        }

        public bool FindPath(Vector2 start, Vector2 end, Dungeon dungeon)
        {
            var path = _pathfinder.FindPath(start, end, dungeon);
            if (path != null && path.Count > 0)
            {
                CurrentPath = path;
                CurrentPathIndex = 0;
                return true;
            }

            CurrentPath.Clear();
            return false;
        }

        public Vector2? GetNextPathPoint()
        {
            if (CurrentPath.Count == 0 || CurrentPathIndex >= CurrentPath.Count)
                return null;

            return CurrentPath[CurrentPathIndex];
        }

        public void AdvanceToNextPathPoint()
        {
            CurrentPathIndex++;
        }

        public bool HasReachedEndOfPath()
        {
            return CurrentPathIndex >= CurrentPath.Count;
        }

        public void SetState(AIState newState)
        {
            if (CurrentState != newState)
            {
                CurrentState = newState;
                StateTimer = 0f;
                
                // State-specific initialization
                switch (newState)
                {
                    case AIState.Patrolling:
                        _patrolTimer = 0f;
                        break;
                }
            }
        }

        public bool CanPatrol()
        {
            return _patrolTimer >= PatrolWaitTime;
        }

        public void ResetPatrolTimer()
        {
            _patrolTimer = 0f;
        }

        public void AddPatrolPoint(Vector2 point)
        {
            PatrolPoints.Add(point);
        }

        public Vector2? GetNextPatrolPoint()
        {
            if (PatrolPoints.Count == 0) return null;

            PatrolIndex = (PatrolIndex + 1) % PatrolPoints.Count;
            return PatrolPoints[PatrolIndex];
        }
    }
}