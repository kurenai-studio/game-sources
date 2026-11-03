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
    /// Publishes where each faction's stations are, for miners to deliver to and for the enemy AI to
    /// attack. Doubles as the win condition: a faction with no entries left has lost.
    /// </summary>
    public class StationIndexSystem : ISystem, IUpdateSystem
    {
        public readonly record struct StationRecord(Vector2 Location, FactionId Faction);

        private readonly List<StationRecord> stations = [];

        public IReadOnlyList<StationRecord> Stations => stations;

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Station>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            stations.Clear();

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    stations.Add(new StationRecord(positionSpan[i].Location, factionSpan[i].Id));
                }
            }
        }

        public Vector2? FindNearest(Vector2 from, FactionId faction)
        {
            Vector2? nearest = null;
            var nearestDistanceSquared = float.MaxValue;

            foreach (var station in stations)
            {
                if (station.Faction != faction)
                {
                    continue;
                }

                var distanceSquared = Vector2.DistanceSquared(from, station.Location);
                if (distanceSquared < nearestDistanceSquared)
                {
                    nearestDistanceSquared = distanceSquared;
                    nearest = station.Location;
                }
            }

            return nearest;
        }

        /// <summary>The nearest station belonging to anyone else - what an attack wave aims at.</summary>
        public Vector2? FindNearestHostile(Vector2 from, FactionId ownFaction)
        {
            Vector2? nearest = null;
            var nearestDistanceSquared = float.MaxValue;

            foreach (var station in stations)
            {
                if (station.Faction == ownFaction || station.Faction == FactionId.Neutral)
                {
                    continue;
                }

                var distanceSquared = Vector2.DistanceSquared(from, station.Location);
                if (distanceSquared < nearestDistanceSquared)
                {
                    nearestDistanceSquared = distanceSquared;
                    nearest = station.Location;
                }
            }

            return nearest;
        }

        public int CountFor(FactionId faction)
        {
            var count = 0;
            foreach (var station in stations)
            {
                if (station.Faction == faction)
                {
                    count++;
                }
            }
            return count;
        }
    }
}
