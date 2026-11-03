using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Input;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Miners double as builders: with one selected, the build hotkey founds a new station where
    /// that miner is standing. Expansion is therefore a movement decision - fly a miner to the
    /// asteroid field you want to work, then build there.
    /// </summary>
    /// <remarks>
    /// Construction runs on the miner's own <c>Timer</c>, the same clock stations use to produce
    /// ships, so it gets the same radial progress ring for free.
    ///
    /// Charging per miner is deliberately self-limiting: select ten miners with 200 minerals and
    /// exactly one starts building, because the other nine fail <c>TrySpend</c>. No queueing rules
    /// or "who goes first" logic needed.
    ///
    /// <para><b>The builder is consumed by the station.</b> A miner that finishes a station is
    /// removed, so expanding costs minerals <em>and</em> a worker - the base you found is the miner
    /// you no longer have mining. That's what makes expansion a decision rather than something you
    /// do automatically whenever the mineral count crosses 200: it dips your income at the moment
    /// you commit, and pays it back only once the new base is staffed. It also gives the equivalent
    /// AI rule something to be measured against, since the AI plays the same mechanic (see
    /// <c>AiDoctrine.MinersKeptWorking</c>).</para>
    ///
    /// This system finishes construction for <em>both</em> sides - the player's hotkey and
    /// <c>ExpansionAiSystem</c>'s dispatch both end in a miner with <c>Task = Constructing</c> and a
    /// running timer, and one completion path serves both.
    /// </remarks>
    public class MinerConstructionSystem(Economy economy, SpawnQueue spawnQueue) : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<MoveOrder>(), ComponentRef.Of<Faction>(),
            ComponentRef.Of<Timer>(), ComponentRef.Of<Selectable>(), ComponentRef.Of<Miner>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var keyboard = InputManager.Instance.KeyboardInfo;
            var wantsToBuild = false;
            foreach (var command in ShipBlueprints.CommandsFor(UnitKind.Miner))
            {
                if (command.Produces == UnitKind.Station && keyboard.WasKeyJustPressed(command.Hotkey))
                {
                    wantsToBuild = true;
                }
            }

            var cost = ShipBlueprints.For(UnitKind.Station).MineralCost;
            var buildDuration = TimeSpan.FromSeconds(ShipBlueprints.For(UnitKind.Station).BuildSeconds);

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var moveOrderSpan = archetypeChunk.GetSpan<MoveOrder>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var timerSpan = archetypeChunk.GetSpan<Timer>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var minerSpan = archetypeChunk.GetSpan<Miner>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var miner = ref minerSpan[i];
                    ref var timer = ref timerSpan[i];
                    ref var moveOrder = ref moveOrderSpan[i];
                    var faction = factionSpan[i].Id;

                    if (miner.Task == MinerTask.Constructing)
                    {
                        if (timer.HasElapsed)
                        {
                            CompleteStation(archetypeChunk, i, positionSpan[i].Location, faction);
                        }
                        continue;
                    }

                    if (!wantsToBuild || !selectableSpan[i].IsSelected || faction != FactionId.Player)
                    {
                        continue;
                    }

                    // continue, not return: later entities in this sweep still need their
                    // completion checks, and TrySpend deducts nothing when it fails.
                    if (!economy.TrySpend(FactionId.Player, cost))
                    {
                        continue;
                    }

                    miner.Task = MinerTask.Constructing;
                    miner.ClaimedAsteroid = null;
                    // The player builds where the miner stands, so the site is simply here. Recorded
                    // anyway because the AI's spacing rule reads every faction's pending sites.
                    miner.BuildSite = positionSpan[i].Location;
                    moveOrder.Destination = null;
                    timer.Restart(buildDuration);
                }
            }
        }

        /// <summary>
        /// The station appears and the miner that built it does not survive the process.
        /// </summary>
        /// <remarks>
        /// Removal is queued and applied by <c>Archetype.ProcessDeferredUpdates</c> after every
        /// system has run, so the miner is still there for the rest of this frame - which is fine,
        /// because its task is <c>Constructing</c> and every system that cares leaves a builder
        /// alone. The station itself can't be created here either: systems describe what they built
        /// and <c>Sandbox.OnUpdate</c> drains the queue. So the two halves of "miner becomes
        /// station" are a queued add and a queued remove that land in the same gap between frames.
        /// </remarks>
        private void CompleteStation(ArchetypeChunk archetypeChunk, int entityIndex, Vector2 location, FactionId faction)
        {
            spawnQueue.Enqueue(new SpawnRequest(UnitKind.Station, faction, location));
            archetypeChunk.QueueEntityForRemovalByIndex(entityIndex);
        }
    }
}
