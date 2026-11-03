using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Input;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Build hotkeys for whichever of the player's stations are currently selected.
    /// </summary>
    /// <remarks>
    /// Previously these keys were global and always charged the first station found, which stopped
    /// making sense the moment a second station could exist. Orders now go to the selection, as in
    /// any RTS: click the station you want producing, then press the key. Select several and they
    /// all queue - each charged separately, so a shortfall simply stops partway down the list
    /// rather than overdrawing.
    ///
    /// <b>Shift + the same key</b> sets a standing order instead of queueing one ship: the station
    /// re-queues that kind for itself whenever its queue runs dry (see <c>StationAutoQueueSystem</c>
    /// and <c>Station.AutoQueue</c>). Pressing it again clears the standing order. It's the same
    /// modifier an RTS conventionally uses for an infinite queue, and it costs nothing at the moment
    /// it's pressed - the charge happens per ship, later, as each top-up is queued.
    /// </remarks>
    public class StationCommandSystem(Economy economy) : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Faction>(), ComponentRef.Of<Health>(),
            ComponentRef.Of<Selectable>(), ComponentRef.Of<Station>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var keyboard = InputManager.Instance.KeyboardInfo;
            var commands = ShipBlueprints.CommandsFor(UnitKind.Station);
            var wantsStandingOrder = keyboard.IsKeyDown(Keys.LeftShift) || keyboard.IsKeyDown(Keys.RightShift);

            foreach (var command in commands)
            {
                if (!keyboard.WasKeyJustPressed(command.Hotkey))
                {
                    continue;
                }

                if (wantsStandingOrder)
                {
                    ToggleStandingOrderOnSelectedStations(archetypeChunks, command.Produces);
                }
                else
                {
                    QueueOnSelectedStations(archetypeChunks, command.Produces);
                }
            }
        }

        /// <summary>
        /// Turns a standing order on, or off again if it was already set to this kind - one key for
        /// both, because "press it again to stop" is the only rule worth having to remember.
        /// </summary>
        private static void ToggleStandingOrderOnSelectedStations(List<ArchetypeChunk> archetypeChunks, UnitKind produces)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (!selectableSpan[i].IsSelected || factionSpan[i].Id != FactionId.Player || healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    ref var station = ref stationSpan[i];
                    station.AutoQueue = station.AutoQueue == produces ? UnitKind.None : produces;
                }
            }
        }

        private void QueueOnSelectedStations(List<ArchetypeChunk> archetypeChunks, UnitKind produces)
        {
            var cost = ShipBlueprints.For(produces).MineralCost;

            foreach (var archetypeChunk in archetypeChunks)
            {
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (!selectableSpan[i].IsSelected || factionSpan[i].Id != FactionId.Player || healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    if (!economy.TrySpend(FactionId.Player, cost))
                    {
                        return;
                    }

                    ref var station = ref stationSpan[i];
                    if (produces == UnitKind.Miner)
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
