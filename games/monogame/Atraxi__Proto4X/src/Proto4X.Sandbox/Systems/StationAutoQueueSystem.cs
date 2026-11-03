using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Keeps a station with a standing order building: whenever its queue runs dry, it charges for
    /// and re-queues the ship kind marked on <c>Station.AutoQueue</c>.
    /// </summary>
    /// <remarks>
    /// Set with shift + the ship's hotkey - see <c>StationCommandSystem</c>. It's the RTS
    /// infinite-queue idea, and the reason to want it here is that a base's interesting decision is
    /// <em>which</em> ship it makes, not remembering to press the key again every eight seconds.
    ///
    /// <para>A separate system rather than a branch inside <c>ProductionSystem</c>, for one concrete
    /// reason: this is the only part of the loop that <em>spends</em>. <c>ProductionSystem</c> turns
    /// an already-paid-for queue into ships and touches no economy at all, and keeping the charge
    /// out of it means there is still exactly one answer to "where do minerals leave the player's
    /// account" per kind of order.</para>
    ///
    /// <para>Refilling only an <em>empty</em> queue - nothing queued and nothing in progress - is
    /// what stops a standing order competing with the player's own orders. Queue three fighters by
    /// hand and the station builds those three first; the standing order picks up after them.
    /// A faction that can't afford the top-up simply doesn't get one this frame and tries again on
    /// the next, so a standing order waits out a poor patch instead of blocking anything.</para>
    /// </remarks>
    public class StationAutoQueueSystem(Economy economy) : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Faction>(), ComponentRef.Of<Health>(), ComponentRef.Of<Station>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var station = ref stationSpan[i];

                    if (healthSpan[i].Current <= 0f || station.AutoQueue == UnitKind.None)
                    {
                        continue;
                    }

                    var isQueueEmpty = station.InProgress == UnitKind.None
                        && station.QueuedMiners + station.QueuedFighters == 0;

                    if (!isQueueEmpty)
                    {
                        continue;
                    }

                    if (!economy.TrySpend(factionSpan[i].Id, ShipBlueprints.For(station.AutoQueue).MineralCost))
                    {
                        continue;
                    }

                    if (station.AutoQueue == UnitKind.Miner)
                    {
                        station.QueuedMiners++;
                    }
                    else
                    {
                        station.QueuedFighters++;
                    }
                }
            }
        }
    }
}
