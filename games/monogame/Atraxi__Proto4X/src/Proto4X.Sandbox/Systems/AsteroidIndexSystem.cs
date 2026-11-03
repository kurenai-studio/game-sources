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
    /// Publishes a flat snapshot of every asteroid's location once per frame, so that systems which
    /// query a different archetype (miners) can still ask "where is the nearest free rock".
    /// </summary>
    /// <remarks>
    /// This is the standing workaround for the engine having no cross-archetype join: a system only
    /// ever receives chunks matching its own single AND-mask, so relating two unrelated archetypes
    /// means one of them publishing a copy for the other to read. It only works because asteroids
    /// are read-only to miners here - a snapshot gives you no way to write back. That's the direct
    /// reason asteroids are infinite in this build. See ENGINE_REQUESTS.md.
    ///
    /// The nearest-search is a linear scan. It's called only when a miner actually needs new work -
    /// roughly once per round trip, not once per frame - so it stays cheap even with a few hundred
    /// asteroids. If that stops being true, this is the obvious first place for a spatial grid.
    /// </remarks>
    public class AsteroidIndexSystem : ISystem, IUpdateSystem
    {
        private readonly List<Vector2> locations = [];

        public IReadOnlyList<Vector2> Locations => locations;

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Gatherable>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            locations.Clear();

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    locations.Add(positionSpan[i].Location);
                }
            }
        }

        /// <summary>
        /// The closest asteroid nobody has claimed, or null if every rock is taken. Claims are
        /// compared by exact position because the caller stores the exact value it was handed here.
        /// </summary>
        public Vector2? FindNearestUnclaimed(Vector2 from, IReadOnlySet<Vector2> claimed)
        {
            Vector2? nearest = null;
            var nearestDistanceSquared = float.MaxValue;

            foreach (var location in locations)
            {
                if (claimed.Contains(location))
                {
                    continue;
                }

                var distanceSquared = Vector2.DistanceSquared(from, location);
                if (distanceSquared < nearestDistanceSquared)
                {
                    nearestDistanceSquared = distanceSquared;
                    nearest = location;
                }
            }

            return nearest;
        }
    }
}
