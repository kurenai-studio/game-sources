using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Makes AI factions expand: as soon as one can afford a station on top of its reserve, it
    /// sends its nearest spare miner to the frontier and spends that miner founding a base there.
    /// </summary>
    /// <remarks>
    /// Every threshold this reads lives in <see cref="AiDoctrine"/>, including the rules in prose.
    /// Three things about the behaviour are worth stating where the code is:
    ///
    /// <para><b>There is no station cap.</b> A faction expands whenever it can pay and has a legal
    /// site, and while it is saving toward one, <c>EnemyProductionAiSystem</c> leaves the earmarked
    /// minerals alone (see <see cref="SavingsFor"/>). Before that reservation existed the AI only
    /// ever expanded on income it happened to accumulate while every build queue was full, which
    /// made expansion a side effect of queue depth rather than a decision - a faction with a wide
    /// economy would sink everything into fighters and never found a second base.</para>
    ///
    /// <para><b>Expansion costs a miner.</b> The builder is consumed by the station it founds, so
    /// the AI refuses to expand at or below <see cref="AiDoctrine.MinersKeptWorking"/> miners.
    /// Without that floor a poor faction with two miners could spend one on a base it then had no
    /// economy to staff.</para>
    ///
    /// <para><b>Site choice is the whole strategy, and the obvious version of it is wrong.</b>
    /// Picking the asteroid <em>furthest</em> from your own stations sounds like "claim the most new
    /// ground" but actually means "walk to the opposite corner of the map", frequently into the
    /// middle of someone else's base. Expanding outward from your own frontier is the real
    /// behaviour: take the <em>nearest</em> field that isn't already yours, and refuse sites too
    /// close to a rival or to a base one of your own miners is already flying out to build.</para>
    /// </remarks>
    public class ExpansionAiSystem(
        Economy economy,
        AsteroidIndexSystem asteroidIndex,
        StationIndexSystem stationIndex) : ISystem, IUpdateSystem
    {
        /// <summary>A station that doesn't exist yet, but soon will - a miner is on its way to build it.</summary>
        private readonly record struct PendingSite(Vector2 Location, FactionId Faction);

        private static readonly int FactionCount = Enum.GetValues<FactionId>().Length;

        /// <summary>
        /// The frontier site each faction intends to use next, refreshed on a cadence and held
        /// between refreshes. Kept even while the faction can't afford it - that's the whole point,
        /// since "there is somewhere to go" is what justifies saving up for the trip.
        /// </summary>
        private readonly Vector2?[] cachedSites = new Vector2?[FactionCount];

        /// <summary>This frame's actual orders: a site here means "send someone now", i.e. paid for and legal.</summary>
        private readonly Vector2?[] dispatchSites = new Vector2?[FactionCount];

        private readonly bool[] isExpanding = new bool[FactionCount];

        /// <summary>Has a builder that hasn't been charged yet - i.e. still travelling, so the price must stay held.</summary>
        private readonly bool[] hasUnpaidBuilder = new bool[FactionCount];
        private readonly int[] minerCounts = new int[FactionCount];
        private readonly int[] savings = new int[FactionCount];
        private readonly List<PendingSite> pendingSites = [];

        /// <summary>Where the nearest free miner to each faction's chosen site sits, as (chunk, index).</summary>
        private readonly int[] builderChunk = new int[FactionCount];
        private readonly int[] builderIndex = new int[FactionCount];
        private readonly float[] builderDistanceSquared = new float[FactionCount];

        private float secondsUntilSiteSearch;

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<MoveOrder>(), ComponentRef.Of<Faction>(),
            ComponentRef.Of<Timer>(), ComponentRef.Of<Miner>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        /// <summary>
        /// Minerals this faction is holding back for its next station, which production must not
        /// spend. Zero for a faction that isn't currently able to expand at all - there's no point
        /// starving the fleet to save for a base there's nowhere to put.
        /// </summary>
        public int SavingsFor(FactionId faction) => savings[(int)faction];

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var stationCost = ShipBlueprints.Station.MineralCost;
            var buildDuration = TimeSpan.FromSeconds(ShipBlueprints.Station.BuildSeconds);

            SurveyMiners(archetypeChunks);
            ChooseExpansionSites(gameTime, stationCost);
            DriveBuilders(archetypeChunks, stationCost, buildDuration);
            DispatchNewBuilders(archetypeChunks);
        }

        /// <summary>
        /// One pass to learn everything about miners the decisions below need: how many each faction
        /// has, which factions already have an expansion in flight, and where every station that is
        /// about to exist is going to be. Gathering pending sites from <em>every</em> faction,
        /// including the player's, is what makes the spacing rule work against buildings that
        /// haven't been built yet.
        /// </summary>
        private void SurveyMiners(List<ArchetypeChunk> archetypeChunks)
        {
            Array.Clear(minerCounts);
            Array.Clear(isExpanding);
            Array.Clear(hasUnpaidBuilder);
            pendingSites.Clear();

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var minerSpan = archetypeChunk.GetSpan<Miner>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    var faction = factionSpan[i].Id;
                    minerCounts[(int)faction]++;

                    if (minerSpan[i].Task is not (MinerTask.FlyingToBuildSite or MinerTask.Constructing))
                    {
                        continue;
                    }

                    isExpanding[(int)faction] = true;
                    hasUnpaidBuilder[(int)faction] |= minerSpan[i].Task == MinerTask.FlyingToBuildSite;
                    pendingSites.Add(new PendingSite(minerSpan[i].BuildSite ?? positionSpan[i].Location, faction));
                }
            }
        }

        /// <summary>
        /// Picks at most one site per faction - one expansion at a time, which is what keeps the
        /// spacing rule simple and stops a rich faction dispatching four miners to the same corner
        /// on four consecutive frames.
        /// </summary>
        private void ChooseExpansionSites(GameTime gameTime, int stationCost)
        {
            var isSearchDue = secondsUntilSiteSearch <= 0f;
            secondsUntilSiteSearch = isSearchDue
                ? AiDoctrine.SiteSearchIntervalSeconds
                : secondsUntilSiteSearch - (float)gameTime.ElapsedGameTime.TotalSeconds;

            Array.Clear(savings);
            Array.Clear(dispatchSites);
            Array.Fill(builderChunk, -1);
            Array.Fill(builderDistanceSquared, float.MaxValue);

            var priceOfExpanding = stationCost + AiDoctrine.ExpansionReserve;

            foreach (var faction in Faction.AiControlled)
            {
                var index = (int)faction;

                // Already expanding: don't go looking for a second site. Keep holding the price only
                // while the builder is still travelling - once it has arrived and paid, the money is
                // gone and continuing to reserve it would idle the fleet for the whole build.
                if (isExpanding[index])
                {
                    cachedSites[index] = null;
                    savings[index] = hasUnpaidBuilder[index] ? stationCost : 0;
                    continue;
                }

                if (minerCounts[index] <= AiDoctrine.MinersKeptWorking)
                {
                    cachedSites[index] = null;
                    continue;
                }

                if (isSearchDue)
                {
                    cachedSites[index] = FindFrontierSite(faction);
                }
                else if (cachedSites[index] is Vector2 cached && !IsLegalSite(cached, faction))
                {
                    // A cached answer can go stale between searches - somebody else's station may
                    // have appeared next to it. Re-checking is cheap; acting on it isn't.
                    cachedSites[index] = null;
                }

                if (cachedSites[index] is not Vector2 site)
                {
                    // Nowhere legal to put one, so there's nothing to save for and the fleet gets
                    // the money. A faction boxed in by rivals builds fighters, which is correct.
                    continue;
                }

                // Saving is declared on having a site, not on being able to afford one - the site is
                // exactly what makes the saving worth doing. Tying it to affordability instead would
                // be self-defeating: production would spend the money every frame the faction was
                // short, which is every frame until it isn't, so it never would be.
                savings[index] = priceOfExpanding;

                if (economy.GetMinerals(faction) >= priceOfExpanding)
                {
                    dispatchSites[index] = site;
                }
            }
        }

        /// <summary>
        /// Moves miners that are already committed along: keep them pointed at their site, and turn
        /// the charge into a build the moment one arrives.
        /// </summary>
        private void DriveBuilders(List<ArchetypeChunk> archetypeChunks, int stationCost, TimeSpan buildDuration)
        {
            var arrivalRadiusSquared = AiDoctrine.BuildSiteArrivalRadius * AiDoctrine.BuildSiteArrivalRadius;

            for (var chunkIndex = 0; chunkIndex < archetypeChunks.Count; chunkIndex++)
            {
                var archetypeChunk = archetypeChunks[chunkIndex];
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var moveOrderSpan = archetypeChunk.GetSpan<MoveOrder>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var timerSpan = archetypeChunk.GetSpan<Timer>();
                var minerSpan = archetypeChunk.GetSpan<Miner>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    var faction = factionSpan[i].Id;
                    if (!AiDoctrine.Governs(faction))
                    {
                        continue;
                    }

                    ref var miner = ref minerSpan[i];
                    var location = positionSpan[i].Location;

                    // Assembling already - MinerConstructionSystem finishes what this started.
                    if (miner.Task == MinerTask.Constructing)
                    {
                        continue;
                    }

                    if (miner.Task == MinerTask.FlyingToBuildSite)
                    {
                        FlyToBuildSite(ref miner, ref moveOrderSpan[i], ref timerSpan[i], location, faction, stationCost, buildDuration, arrivalRadiusSquared);
                        continue;
                    }

                    // A free miner. Whoever is nearest the site gets the job, so expanding costs
                    // the least mining time - taking whichever miner came first in the chunk
                    // regularly picked one on the far side of the empire.
                    if (dispatchSites[(int)faction] is not Vector2 site)
                    {
                        continue;
                    }

                    var distanceSquared = Vector2.DistanceSquared(location, site);
                    if (distanceSquared >= builderDistanceSquared[(int)faction])
                    {
                        continue;
                    }

                    builderDistanceSquared[(int)faction] = distanceSquared;
                    builderChunk[(int)faction] = chunkIndex;
                    builderIndex[(int)faction] = i;
                }
            }
        }

        private void FlyToBuildSite(
            ref Miner miner,
            ref MoveOrder moveOrder,
            ref Timer timer,
            Vector2 location,
            FactionId faction,
            int stationCost,
            TimeSpan buildDuration,
            float arrivalRadiusSquared)
        {
            if (miner.BuildSite is not Vector2 site)
            {
                // Shouldn't happen - defensive, and the cheapest recovery is back to mining.
                miner.Task = MinerTask.FlyingToAsteroid;
                miner.BuildSite = null;
                return;
            }

            if (Vector2.DistanceSquared(location, site) > arrivalRadiusSquared)
            {
                moveOrder.Destination = site;
                return;
            }

            // Charged on arrival rather than on dispatch, so minerals spent by the fleet during the
            // trip simply delay the base instead of overdrawing. The miner waits on site.
            if (!economy.TrySpend(faction, stationCost))
            {
                moveOrder.Destination = null;
                return;
            }

            miner.Task = MinerTask.Constructing;
            miner.ClaimedAsteroid = null;
            moveOrder.Destination = null;
            timer.Restart(buildDuration);
        }

        /// <summary>
        /// Commits the miner picked in <see cref="DriveBuilders"/>. Separate pass because "nearest"
        /// isn't known until every miner has been looked at.
        /// </summary>
        private void DispatchNewBuilders(List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var faction in Faction.AiControlled)
            {
                var index = (int)faction;
                if (dispatchSites[index] is not Vector2 site || builderChunk[index] < 0)
                {
                    continue;
                }

                var archetypeChunk = archetypeChunks[builderChunk[index]];
                ref var miner = ref archetypeChunk.Get<Miner>(builderIndex[index]);
                ref var moveOrder = ref archetypeChunk.Get<MoveOrder>(builderIndex[index]);

                miner.Task = MinerTask.FlyingToBuildSite;
                miner.BuildSite = site;
                miner.ClaimedAsteroid = null;
                moveOrder.Destination = site;
                moveOrder.IsHoldingPosition = false;

                // Claimed for this trip, so the next frame's survey sees the faction as expanding
                // rather than picking a second site next to this one.
                dispatchSites[index] = null;
                cachedSites[index] = null;
                isExpanding[index] = true;
            }
        }

        /// <summary>
        /// The closest asteroid that's outside our own territory and outside anyone else's - the
        /// frontier. Nearest-qualifying rather than furthest, so bases grow outward in a ring
        /// instead of teleporting across the map.
        /// </summary>
        private Vector2? FindFrontierSite(FactionId faction)
        {
            Vector2? best = null;
            var bestDistanceSquared = float.MaxValue;

            foreach (var asteroid in asteroidIndex.Locations)
            {
                if (stationIndex.FindNearest(asteroid, faction) is not Vector2 nearestOwn)
                {
                    continue;
                }

                var ownDistanceSquared = Vector2.DistanceSquared(asteroid, nearestOwn);
                if (ownDistanceSquared >= bestDistanceSquared || !IsLegalSite(asteroid, faction))
                {
                    continue;
                }

                bestDistanceSquared = ownDistanceSquared;
                best = asteroid;
            }

            return best;
        }

        /// <summary>
        /// The spacing rule, and the only place it is enforced: far enough from our own stations and
        /// our own in-flight sites to be expansion rather than infill, and far enough from everyone
        /// else's to not be a declaration of war we can't back up.
        /// </summary>
        private bool IsLegalSite(Vector2 site, FactionId faction)
        {
            var minimumOwnSquared = AiDoctrine.MinimumStationSpacing * AiDoctrine.MinimumStationSpacing;
            var minimumRivalSquared = AiDoctrine.MinimumDistanceFromRivalStations * AiDoctrine.MinimumDistanceFromRivalStations;

            if (stationIndex.FindNearest(site, faction) is Vector2 nearestOwn
                && Vector2.DistanceSquared(site, nearestOwn) < minimumOwnSquared)
            {
                return false;
            }

            if (stationIndex.FindNearestHostile(site, faction) is Vector2 nearestRival
                && Vector2.DistanceSquared(site, nearestRival) < minimumRivalSquared)
            {
                return false;
            }

            foreach (var pending in pendingSites)
            {
                var limitSquared = pending.Faction == faction ? minimumOwnSquared : minimumRivalSquared;
                if (Vector2.DistanceSquared(site, pending.Location) < limitSquared)
                {
                    return false;
                }
            }

            return true;
        }
    }
}
