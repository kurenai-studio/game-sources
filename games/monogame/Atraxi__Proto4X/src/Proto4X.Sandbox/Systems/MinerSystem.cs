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
    /// The gather loop: claim an asteroid, fly to it, mine until full, fly home, deposit, repeat.
    /// </summary>
    /// <remarks>
    /// One miner per asteroid. Claims are gathered in a first pass over every miner before any new
    /// ones are handed out, so a rock already spoken for is invisible to the next miner looking for
    /// work. The claim is a <em>position</em>, not an entity reference - asteroids never move, so
    /// their location is a perfectly stable name, and this keeps the no-entity-ids rule intact.
    ///
    /// A pending <c>MoveOrder.Destination</c> means "someone is already driving this ship", which is
    /// what lets a player order override the loop for free: the miner won't pick a new destination
    /// until it has arrived where the player sent it, then resumes on its own - after the grace
    /// period on that order runs out, so a miner flown to a field the player intends to build on
    /// waits there instead of immediately claiming the nearest rock and leaving.
    /// </remarks>
    public class MinerSystem(AsteroidIndexSystem asteroidIndex, StationIndexSystem stationIndex, Economy economy) : ISystem, IUpdateSystem
    {
        private const float AsteroidArrivalRadius = 38f;
        private const float StationArrivalRadius = 64f;

        private readonly HashSet<Vector2> claimedAsteroids = [];

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Motion>(), ComponentRef.Of<MoveOrder>(),
            ComponentRef.Of<Faction>(), ComponentRef.Of<Miner>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var elapsedSeconds = (float)gameTime.ElapsedGameTime.TotalSeconds;

            CollectClaims(archetypeChunks);

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var moveOrderSpan = archetypeChunk.GetSpan<MoveOrder>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var minerSpan = archetypeChunk.GetSpan<Miner>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var miner = ref minerSpan[i];
                    ref var moveOrder = ref moveOrderSpan[i];
                    var location = positionSpan[i].Location;

                    // Mining and building are deliberate stops, not idleness - say so, or the
                    // separation nudge will drift a miner off the rock it's working. A miner
                    // sitting out the grace on a player's order is a third kind of deliberate
                    // stop: it should still be where they put it when they press the next key.
                    // A builder that has reached its site but can't be paid for yet counts too, or
                    // the separation nudge walks it off the spot it was sent to.
                    var isWaitingOnPlayer = moveOrder.Destination is null && moveOrder.CommandGraceRemaining > 0f;
                    moveOrder.IsHoldingPosition = isWaitingOnPlayer
                        || miner.Task is MinerTask.Mining or MinerTask.Constructing or MinerTask.FlyingToBuildSite;

                    switch (miner.Task)
                    {
                        case MinerTask.FlyingToAsteroid:
                            if (moveOrder.Destination is not null || isWaitingOnPlayer)
                            {
                                break;
                            }

                            if (miner.ClaimedAsteroid is not Vector2 claim)
                            {
                                if (!TryClaimAsteroid(location, ref miner))
                                {
                                    break;
                                }

                                claim = miner.ClaimedAsteroid!.Value;
                            }

                            if (Vector2.DistanceSquared(location, claim) <= AsteroidArrivalRadius * AsteroidArrivalRadius)
                            {
                                miner.Task = MinerTask.Mining;
                            }
                            else
                            {
                                moveOrder.Destination = claim;
                            }
                            break;

                        case MinerTask.Mining:
                            // A move order issued while mining wins - the player told it to go somewhere.
                            if (moveOrder.Destination is not null)
                            {
                                ReleaseClaim(ref miner);
                                miner.Task = MinerTask.FlyingToAsteroid;
                                break;
                            }

                            miner.Carried += miner.MiningRatePerSecond * elapsedSeconds;
                            if (miner.Carried >= miner.Capacity)
                            {
                                miner.Carried = miner.Capacity;
                                // The rock is freed while hauling, so it isn't held idle across the round trip.
                                ReleaseClaim(ref miner);
                                miner.Task = MinerTask.FlyingToStation;
                            }
                            break;

                        case MinerTask.FlyingToStation:
                            if (moveOrder.Destination is not null || isWaitingOnPlayer)
                            {
                                break;
                            }

                            if (stationIndex.FindNearest(location, factionSpan[i].Id) is not Vector2 station)
                            {
                                // Nowhere left to deliver to - the faction's last station is gone.
                                break;
                            }

                            if (Vector2.DistanceSquared(location, station) <= StationArrivalRadius * StationArrivalRadius)
                            {
                                economy.Deposit(factionSpan[i].Id, miner.Carried);
                                miner.Carried = 0f;
                                miner.Task = MinerTask.FlyingToAsteroid;
                            }
                            else
                            {
                                moveOrder.Destination = station;
                            }
                            break;

                        case MinerTask.FlyingToBuildSite:
                        case MinerTask.Constructing:
                            // Founding a station is somebody else's state machine - see
                            // ExpansionAiSystem and MinerConstructionSystem. Listed rather than
                            // left to fall through, because "the gather loop deliberately does not
                            // touch a builder" is a rule, not an omission.
                            break;
                    }
                }
            }
        }

        /// <summary>
        /// Every claim currently held, gathered before any are handed out. Miners all share one
        /// archetype, so a single pass sees the whole fleet.
        /// </summary>
        private void CollectClaims(List<ArchetypeChunk> archetypeChunks)
        {
            claimedAsteroids.Clear();

            foreach (var archetypeChunk in archetypeChunks)
            {
                var minerSpan = archetypeChunk.GetSpan<Miner>();
                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (minerSpan[i].ClaimedAsteroid is Vector2 claimed)
                    {
                        claimedAsteroids.Add(claimed);
                    }
                }
            }
        }

        private bool TryClaimAsteroid(Vector2 from, ref Miner miner)
        {
            if (asteroidIndex.FindNearestUnclaimed(from, claimedAsteroids) is not Vector2 asteroid)
            {
                return false;
            }

            miner.ClaimedAsteroid = asteroid;
            claimedAsteroids.Add(asteroid);
            return true;
        }

        private void ReleaseClaim(ref Miner miner)
        {
            if (miner.ClaimedAsteroid is Vector2 claimed)
            {
                claimedAsteroids.Remove(claimed);
                miner.ClaimedAsteroid = null;
            }
        }
    }
}
