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
    /// Turns a station's build queue into finished ships, one at a time, on the engine's
    /// <c>Timer</c> component.
    /// </summary>
    /// <remarks>
    /// Two things to know about driving <c>Timer</c> from a system:
    /// <list type="bullet">
    /// <item><c>Timer.HasElapsed</c> is a level, not an event - it stays true until someone restarts
    /// the timer. Completion state therefore lives here, in <c>InProgress</c>: that field is what
    /// distinguishes "a build just finished" from "no build is running and the clock is at zero".</item>
    /// <item>Finished ships are described, not created - see <see cref="SpawnRequest"/>.</item>
    /// </list>
    /// </remarks>
    public class ProductionSystem(SpawnQueue spawnQueue) : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Health>(), ComponentRef.Of<Timer>(), ComponentRef.Of<Station>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var timerSpan = archetypeChunk.GetSpan<Timer>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    ref var station = ref stationSpan[i];
                    ref var timer = ref timerSpan[i];

                    if (healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    if (station.InProgress == UnitKind.None)
                    {
                        StartNextInQueue(ref station, ref timer);
                        continue;
                    }

                    if (!timer.HasElapsed)
                    {
                        continue;
                    }

                    spawnQueue.Enqueue(new SpawnRequest(
                        station.InProgress,
                        factionSpan[i].Id,
                        RallyPointFor(positionSpan[i].Location, station.RallyDistance, station.ShipsBuilt),
                        station.RallyPoint));

                    station.ShipsBuilt++;
                    station.InProgress = UnitKind.None;
                    StartNextInQueue(ref station, ref timer);
                }
            }
        }

        private static void StartNextInQueue(ref Station station, ref Timer timer)
        {
            UnitKind next;
            if (station.QueuedMiners > 0)
            {
                station.QueuedMiners--;
                next = UnitKind.Miner;
            }
            else if (station.QueuedFighters > 0)
            {
                station.QueuedFighters--;
                next = UnitKind.Fighter;
            }
            else
            {
                return;
            }

            station.InProgress = next;
            timer.Restart(TimeSpan.FromSeconds(ShipBlueprints.For(next).BuildSeconds));
        }

        private static Vector2 RallyPointFor(Vector2 stationLocation, float rallyDistance, int shipsBuilt)
        {
            var angle = shipsBuilt * 0.9f;
            return stationLocation + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * rallyDistance;
        }
    }
}
