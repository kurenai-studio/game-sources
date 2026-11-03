using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Removes anything whose health has run out. Removal is queued and applied by
    /// <c>Archetype.ProcessDeferredUpdates</c> after every system has run, so the entity survives
    /// the rest of this frame - which is why every other system still checks <c>Current &gt; 0</c>
    /// rather than assuming a live entity is a healthy one.
    /// </summary>
    public class DeathSystem : ISystem, IUpdateSystem
    {
        public int PlayerLosses { get; private set; }
        public int EnemyLosses { get; private set; }

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Health>(), ComponentRef.Of<Faction>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (healthSpan[i].Current > 0f)
                    {
                        continue;
                    }

                    if (factionSpan[i].Id == FactionId.Player)
                    {
                        PlayerLosses++;
                    }
                    else if (factionSpan[i].Id == FactionId.Enemy)
                    {
                        EnemyLosses++;
                    }

                    archetypeChunk.QueueEntityForRemovalByIndex(i);
                }
            }
        }
    }
}
