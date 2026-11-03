using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Steering: turns a <c>MoveOrder.Destination</c> into acceleration, brakes on approach, and
    /// clears the order on arrival. Clearing it is the signal every other system watches for -
    /// "no destination" is how a miner knows it's free to pick its own next job.
    /// </summary>
    /// <remarks>
    /// It also runs down <c>MoveOrder.CommandGraceRemaining</c>, and only while the unit has no
    /// destination, which is what makes that field a pause <em>at the destination</em> rather than
    /// a delay on the journey. Steering owns it because steering owns the transition the grace is
    /// measured from: this system is the only place an order is spent.
    /// </remarks>
    public class MoveToTargetSystem : ISystem, IUpdateSystem
    {
        private const float Acceleration = 250f;
        private const float ArriveRadius = 8f;
        private const float SlowRadius = 80f;

        /// <summary>Ship art points up the screen; sprite rotation is measured from +X.</summary>
        private const float SpriteFacingOffset = MathHelper.PiOver2;

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Motion>(), ComponentRef.Of<MoveOrder>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var elapsedSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var motionSpan = archetypeChunk.GetSpan<Motion>();
                var moveOrderSpan = archetypeChunk.GetSpan<MoveOrder>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var moveOrder = ref moveOrderSpan[i];
                    ref var motion = ref motionSpan[i];
                    ref var position = ref positionSpan[i];

                    if (moveOrder.Destination is not Vector2 destination)
                    {
                        motion.Acceleration = Vector2.Zero;

                        // The order is spent, so the player's grace period starts running here.
                        if (moveOrder.CommandGraceRemaining > 0f)
                        {
                            moveOrder.CommandGraceRemaining = MathF.Max(0f, moveOrder.CommandGraceRemaining - elapsedSeconds);
                        }

                        // Holding position means actually stopping, not coasting to a halt on
                        // friction - a miner parked on a rock should stay on the rock.
                        if (moveOrder.IsHoldingPosition)
                        {
                            motion.Velocity = Vector2.Zero;
                        }
                        continue;
                    }

                    var toTarget = destination - position.Location;
                    var distance = toTarget.Length();

                    if (distance <= ArriveRadius)
                    {
                        moveOrder.Destination = null;
                        motion.Acceleration = Vector2.Zero;
                        motion.Velocity = Vector2.Zero;
                        continue;
                    }

                    var heading = toTarget / distance;
                    var speedScale = distance < SlowRadius ? distance / SlowRadius : 1f;
                    motion.Acceleration = heading * Acceleration * speedScale;
                    position.Rotation = MathF.Atan2(heading.Y, heading.X) + SpriteFacingOffset;
                }
            }
        }
    }
}
