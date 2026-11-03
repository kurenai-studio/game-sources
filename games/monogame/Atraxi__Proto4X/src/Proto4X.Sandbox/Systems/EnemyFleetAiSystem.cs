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
    /// Decides where each AI faction's fighters go: home to defend if their territory is under
    /// attack, out on a wave if they've massed enough, loitering near a station otherwise.
    /// </summary>
    /// <remarks>
    /// Every threshold here lives in <see cref="AiDoctrine"/>, alongside the rest of the AI's rules.
    ///
    /// Defence takes priority over everything, and that ordering is the whole fix for factions
    /// collapsing early. Previously a faction committed its entire fleet the moment it hit the wave
    /// threshold and never looked back, so the first faction to attack was also the first to lose
    /// its undefended base - and once a base fell, production stopped and that faction was finished.
    /// Now an attacked faction recalls, which means trading fleets no longer decides the game in the
    /// first minute.
    ///
    /// Threat detection is free here: this system's query already returns every mobile armed ship of
    /// every faction, so pairing them against the station index needs no extra pass elsewhere.
    ///
    /// Waves target the nearest <em>hostile</em> station rather than the player specifically, so AI
    /// factions fight each other.
    ///
    /// <para>The wave threshold scales with <em>station count</em>, not miner count. Stations are
    /// the better input because the threshold is really asking "do I have enough surplus that
    /// leaving won't cost me a base", and both halves of that scale with stations: more stations
    /// means more places to defend, and also more production to reach a bigger number. Scaling on
    /// miners would instead mean a richer faction waits longer before attacking, which is backwards
    /// - a strong economy should make a faction more aggressive, not less. Miner count is already
    /// represented indirectly anyway, since stations are what miners get spent on.</para>
    /// </remarks>
    public class EnemyFleetAiSystem(StationIndexSystem stationIndex, FleetCensusSystem fleetCensus) : ISystem, IUpdateSystem
    {
        private readonly bool[] waveCommitted = new bool[Enum.GetValues<FactionId>().Length];
        private readonly Vector2?[] threatenedStation = new Vector2?[Enum.GetValues<FactionId>().Length];
        private int loiterSlot;

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Motion>(), ComponentRef.Of<MoveOrder>(),
            ComponentRef.Of<Faction>(), ComponentRef.Of<Weapon>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            DetectThreats(archetypeChunks);
            UpdateWaveCommitment();
            AssignDestinations(archetypeChunks);
        }

        /// <summary>
        /// Finds, for each faction, the station of theirs with a hostile ship nearest to it. Runs
        /// over every armed ship against every station - both small sets, so a plain sweep is fine.
        /// </summary>
        private void DetectThreats(List<ArchetypeChunk> archetypeChunks)
        {
            Array.Clear(threatenedStation);
            var closestThreatSquared = new float[threatenedStation.Length];
            Array.Fill(closestThreatSquared, AiDoctrine.ThreatRadius * AiDoctrine.ThreatRadius);

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var weaponSpan = archetypeChunk.GetSpan<Weapon>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (weaponSpan[i].Range <= 0f)
                    {
                        continue;
                    }

                    var attackerFaction = factionSpan[i].Id;
                    var attackerLocation = positionSpan[i].Location;

                    foreach (var station in stationIndex.Stations)
                    {
                        if (station.Faction == attackerFaction || station.Faction == FactionId.Neutral)
                        {
                            continue;
                        }

                        var distanceSquared = Vector2.DistanceSquared(attackerLocation, station.Location);
                        var defender = (int)station.Faction;
                        if (distanceSquared < closestThreatSquared[defender])
                        {
                            closestThreatSquared[defender] = distanceSquared;
                            threatenedStation[defender] = station.Location;
                        }
                    }
                }
            }
        }

        private void UpdateWaveCommitment()
        {
            foreach (var faction in Faction.AiControlled)
            {
                var fighters = fleetCensus.FightersFor(faction);
                var launchStrength = WaveLaunchStrengthFor(faction);

                if (fighters >= launchStrength)
                {
                    waveCommitted[(int)faction] = true;
                }
                else if (fighters <= launchStrength / AiDoctrine.WaveBreakOffDivisor)
                {
                    // Breaking off scales with the same figure, so a big empire retreats a big wave
                    // rather than grinding it down to the last three ships.
                    waveCommitted[(int)faction] = false;
                }
            }
        }

        /// <summary>
        /// How many fighters a faction masses before attacking, scaled by how many stations it has
        /// to leave behind.
        /// </summary>
        private int WaveLaunchStrengthFor(FactionId faction)
        {
            var extraStations = Math.Max(0, stationIndex.CountFor(faction) - 1);
            return Math.Min(
                AiDoctrine.BaseWaveStrength + AiDoctrine.WaveStrengthPerExtraStation * extraStations,
                AiDoctrine.MaximumWaveStrength);
        }

        private void AssignDestinations(List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var moveOrderSpan = archetypeChunk.GetSpan<MoveOrder>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var weaponSpan = archetypeChunk.GetSpan<Weapon>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    var faction = factionSpan[i].Id;
                    if (!AiDoctrine.Governs(faction) || weaponSpan[i].Range <= 0f)
                    {
                        continue;
                    }

                    ref var moveOrder = ref moveOrderSpan[i];
                    var location = positionSpan[i].Location;

                    // Under attack at home overrides an in-flight wave: fighters turn around.
                    if (threatenedStation[(int)faction] is Vector2 underAttack)
                    {
                        moveOrder.Destination = underAttack;
                        continue;
                    }

                    if (moveOrder.Destination is not null)
                    {
                        continue;
                    }

                    var target = waveCommitted[(int)faction]
                        ? stationIndex.FindNearestHostile(location, faction)
                        : Loiter(stationIndex.FindNearest(location, faction));

                    if (target is Vector2 destination)
                    {
                        moveOrder.Destination = destination;
                    }
                }
            }
        }

        private Vector2? Loiter(Vector2? homeStation)
        {
            if (homeStation is not Vector2 home)
            {
                return null;
            }

            var angle = loiterSlot++ * 1.1f;
            return home + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * AiDoctrine.LoiterRadius;
        }
    }
}
