using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Every armed entity beams the nearest hostile inside its range, continuously. No projectiles,
    /// no stored target - the target is re-picked every frame, which is both simpler and the only
    /// option available while entities have no ids to remember each other by.
    /// </summary>
    /// <remarks>
    /// Attackers and victims come from the same query, which is why unarmed ships still carry a
    /// zero-range Weapon: one AND-mask has to cover both sides of the interaction. The cost is an
    /// O(n^2) sweep over everything that can be shot. Fine at this scale, and a concrete data point
    /// for why the engine wants a real cross-archetype join (see ENGINE_REQUESTS.md).
    /// </remarks>
    public class CombatSystem : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Health>(), ComponentRef.Of<Weapon>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var elapsedSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;

            foreach (var archetypeChunk in archetypeChunks)
            {
                var weaponSpan = archetypeChunk.GetSpan<Weapon>();
                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    weaponSpan[i].FiringAt = null;
                }
            }

            for (var attackerChunkIndex = 0; attackerChunkIndex < archetypeChunks.Count; attackerChunkIndex++)
            {
                var attackerChunk = archetypeChunks[attackerChunkIndex];
                var attackerPositions = attackerChunk.GetSpan<Position>();
                var attackerFactions = attackerChunk.GetSpan<Faction>();
                var attackerHealths = attackerChunk.GetSpan<Health>();
                var attackerWeapons = attackerChunk.GetSpan<Weapon>();

                for (var attackerIndex = 0; attackerIndex < attackerChunk.EntityCount; attackerIndex++)
                {
                    ref var weapon = ref attackerWeapons[attackerIndex];
                    if (weapon.Range <= 0f || weapon.DamagePerSecond <= 0f || attackerHealths[attackerIndex].Current <= 0f)
                    {
                        continue;
                    }

                    var attackerLocation = attackerPositions[attackerIndex].Location;
                    var attackerFaction = attackerFactions[attackerIndex].Id;

                    var closestDistanceSquared = weapon.Range * weapon.Range;
                    var targetChunk = -1;
                    var targetIndex = -1;

                    for (var candidateChunkIndex = 0; candidateChunkIndex < archetypeChunks.Count; candidateChunkIndex++)
                    {
                        var candidateChunk = archetypeChunks[candidateChunkIndex];
                        var candidatePositions = candidateChunk.GetSpan<Position>();
                        var candidateFactions = candidateChunk.GetSpan<Faction>();
                        var candidateHealths = candidateChunk.GetSpan<Health>();

                        for (var candidateIndex = 0; candidateIndex < candidateChunk.EntityCount; candidateIndex++)
                        {
                            if (candidateFactions[candidateIndex].Id == attackerFaction || candidateHealths[candidateIndex].Current <= 0f)
                            {
                                continue;
                            }

                            var distanceSquared = Vector2.DistanceSquared(attackerLocation, candidatePositions[candidateIndex].Location);
                            if (distanceSquared < closestDistanceSquared)
                            {
                                closestDistanceSquared = distanceSquared;
                                targetChunk = candidateChunkIndex;
                                targetIndex = candidateIndex;
                            }
                        }
                    }

                    if (targetChunk < 0)
                    {
                        continue;
                    }

                    var victimChunk = archetypeChunks[targetChunk];
                    victimChunk.GetSpan<Health>()[targetIndex].Current -= weapon.DamagePerSecond * elapsedSeconds;
                    weapon.FiringAt = victimChunk.GetSpan<Position>()[targetIndex].Location;
                }
            }
        }
    }
}
