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
    /// Stations slowly repair themselves, so they have to be genuinely defeated rather than
    /// whittled down by whatever happens to wander past.
    /// </summary>
    /// <remarks>
    /// Runs before <c>CombatSystem</c> so healing is applied to last frame's damage rather than
    /// undoing this frame's. That ordering also means a station reduced to zero stays at zero -
    /// <c>DeathSystem</c> sees it in the same frame it dies, with no chance of being healed back
    /// above the threshold first.
    ///
    /// Constant regeneration rather than out-of-combat regeneration, deliberately: it's less state
    /// and it makes the arithmetic legible - effective incoming damage is simply attacker dps minus
    /// the repair rate. The trade-off is that a siege is slower than raw damage numbers suggest,
    /// which is the intended feel. If stations ever become too hard to remove, the fix is a
    /// damage-recency check (no repair for N seconds after being hit) rather than a lower rate,
    /// since a lower rate would let chip damage work again.
    /// </remarks>
    public class StationRepairSystem : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Health>(), ComponentRef.Of<Station>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var elapsedSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;

            foreach (var archetypeChunk in archetypeChunks)
            {
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var health = ref healthSpan[i];

                    // A station already at zero is dead this frame; repairing it would resurrect it.
                    if (health.Current <= 0f || health.Current >= health.Maximum)
                    {
                        continue;
                    }

                    health.Current = MathHelper.Min(
                        health.Current + stationSpan[i].RepairPerSecond * elapsedSeconds,
                        health.Maximum);
                }
            }
        }
    }
}
