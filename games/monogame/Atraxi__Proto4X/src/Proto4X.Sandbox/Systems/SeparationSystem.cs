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
    /// Nudges idle ships apart when they end up stacked on the same spot, so a group that has
    /// finished moving settles into a cluster instead of a single overlapping blob.
    /// </summary>
    /// <remarks>
    /// Only idle ships push - anything with a live <c>MoveOrder.Destination</c> is left alone, so
    /// this can never fight the steering system for control of a ship that's trying to go
    /// somewhere. It also runs <em>after</em> <c>MoveToTargetSystem</c>, which zeroes acceleration
    /// for ships with no destination; writing after that is what makes the nudge survive to
    /// <c>MovementSystem</c>.
    ///
    /// This is an O(n^2) sweep over every mobile ship, and unlike <c>CombatSystem</c>'s it can't be
    /// range-limited early, so it's the most likely first casualty of a large fleet. A uniform grid
    /// over ship positions is the obvious fix when that day comes.
    /// </remarks>
    public class SeparationSystem : ISystem, IUpdateSystem
    {
        private const float PersonalSpace = 26f;
        private const float PushAcceleration = 140f;

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Motion>(), ComponentRef.Of<MoveOrder>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var personalSpaceSquared = PersonalSpace * PersonalSpace;

            for (var chunkIndex = 0; chunkIndex < archetypeChunks.Count; chunkIndex++)
            {
                var chunk = archetypeChunks[chunkIndex];
                var positionSpan = chunk.GetSpan<Position>();
                var motionSpan = chunk.GetSpan<Motion>();
                var moveOrderSpan = chunk.GetSpan<MoveOrder>();

                for (var i = 0; i < chunk.EntityCount; i++)
                {
                    // Travelling ships are the steering system's business; ships holding position
                    // (mining, building) are parked on purpose. Only genuinely idle ships get nudged.
                    if (moveOrderSpan[i].Destination is not null || moveOrderSpan[i].IsHoldingPosition)
                    {
                        continue;
                    }

                    var location = positionSpan[i].Location;
                    var push = Vector2.Zero;

                    for (var otherChunkIndex = 0; otherChunkIndex < archetypeChunks.Count; otherChunkIndex++)
                    {
                        var otherChunk = archetypeChunks[otherChunkIndex];
                        var otherPositions = otherChunk.GetSpan<Position>();

                        for (var j = 0; j < otherChunk.EntityCount; j++)
                        {
                            if (otherChunkIndex == chunkIndex && j == i)
                            {
                                continue;
                            }

                            var offset = location - otherPositions[j].Location;
                            var distanceSquared = offset.LengthSquared();
                            if (distanceSquared >= personalSpaceSquared)
                            {
                                continue;
                            }

                            // Exactly coincident ships have no direction to separate along, so give
                            // them a deterministic one derived from their index rather than a random
                            // number - reproducible frames matter more than variety here.
                            push += distanceSquared > 0.0001f
                                ? offset / MathF.Sqrt(distanceSquared)
                                : new Vector2(MathF.Cos(i * 2.4f), MathF.Sin(i * 2.4f));
                        }
                    }

                    if (push != Vector2.Zero)
                    {
                        push.Normalize();
                        motionSpan[i].Acceleration += push * PushAcceleration;
                    }
                }
            }
        }
    }
}
