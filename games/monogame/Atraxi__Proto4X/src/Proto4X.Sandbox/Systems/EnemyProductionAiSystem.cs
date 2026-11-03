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
    /// The build order for every AI faction: grow the mining fleet to a target size, then spend
    /// everything on fighters - except the minerals earmarked for the next station. Deliberately
    /// about as clever as an Age of Empires "Standard" AI on a bad day; it exists to give the player
    /// something to lose to, not to be a good opponent.
    /// </summary>
    /// <remarks>
    /// Every number here lives in <see cref="AiDoctrine"/>, which also states the rules in the order
    /// they are applied.
    ///
    /// <para><b>The expansion fund is honoured, and that's the whole reason the AI expands at
    /// all.</b> <c>ExpansionAiSystem</c> publishes what a faction is saving for a station and this
    /// system won't spend into it, so "expand as soon as it can afford one" is a rule rather than an
    /// accident. Previously nothing was reserved: production spent every mineral the moment it
    /// landed, and a station only ever got founded on income that happened to arrive while all the
    /// build queues were full. The one exception is the economy floor - a faction under
    /// <see cref="AiDoctrine.MinersKeptWorking"/> miners rebuilds miners out of the expansion fund,
    /// because a faction that mines nothing never gets to spend it anyway.</para>
    ///
    /// <para>Faction-agnostic: it drives whichever factions are listed in <c>Faction.AiControlled</c>,
    /// so adding a third player to the map cost nothing here. Each AI faction has its own economy, so
    /// they compete for asteroids without competing for money.</para>
    /// </remarks>
    public class EnemyProductionAiSystem(
        Economy economy,
        FleetCensusSystem fleetCensus,
        StationIndexSystem stationIndex,
        ExpansionAiSystem expansionAi) : ISystem, IUpdateSystem
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
                    var faction = factionSpan[i].Id;
                    if (!AiDoctrine.Governs(faction) || healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    ref var station = ref stationSpan[i];
                    if (station.QueuedMiners + station.QueuedFighters >= AiDoctrine.MaximumQueueDepth)
                    {
                        continue;
                    }

                    var miners = fleetCensus.MinersFor(faction) + station.QueuedMiners;

                    // Rule 1: below the floor, the economy comes before everything, expansion fund
                    // included. Above it, the fund is untouchable.
                    var reserve = miners < AiDoctrine.MinersKeptWorking ? 0 : expansionAi.SavingsFor(faction);

                    // Miner target scales with station count, so an expanding AI keeps staffing the
                    // bases it founds rather than stalling at a fixed fleet size.
                    var minerTarget = AiDoctrine.TargetMinersPerStation * stationIndex.CountFor(faction);
                    if (miners < minerTarget)
                    {
                        if (TrySpendAbove(faction, ShipBlueprints.Miner.MineralCost, reserve))
                        {
                            station.QueuedMiners++;
                        }
                    }
                    else if (TrySpendAbove(faction, ShipBlueprints.Fighter.MineralCost, reserve))
                    {
                        station.QueuedFighters++;
                    }
                }
            }
        }

        /// <summary>Spends only what sits above the faction's expansion fund.</summary>
        private bool TrySpendAbove(FactionId faction, int cost, int reserve)
        {
            return economy.GetMinerals(faction) - reserve >= cost && economy.TrySpend(faction, cost);
        }
    }
}
