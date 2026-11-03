using Microsoft.Xna.Framework;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Input;
using MonoGameLibrary.Systems.Infrastructure;
using MonoGameLibrary.UI;
using Proto4X.Sandbox.Components;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Systems
{
    /// <summary>
    /// Right clicking with a station selected sets its rally point: everything it builds from then
    /// on flies there instead of idling at the shipyard.
    /// </summary>
    /// <remarks>
    /// A station has no <c>Motion</c>, so <c>MoveOrderSystem</c>'s query skips it entirely and the
    /// same right click means "go here" for ships and "send new ships here" for stations without
    /// either system needing to know the other exists. That separation falls out of the component
    /// masks rather than being coded.
    ///
    /// Rallying a miner onto an asteroid field is the useful case: it arrives, finds its move order
    /// spent, and starts mining the nearest free rock - which is exactly what you wanted.
    /// </remarks>
    public class RallyPointSystem(Camera camera) : ISystem, IUpdateSystem
    {
        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(),
            ComponentRef.Of<Selectable>(), ComponentRef.Of<Station>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public void Update(GameTime gameTime, List<ArchetypeChunk> archetypeChunks)
        {
            var mouse = InputManager.Instance.MouseInfo;
            if (!mouse.WasButtonJustPressed(MouseButton.Right))
            {
                return;
            }

            var rallyPoint = Vector2.Transform(mouse.Position.ToVector2(), Matrix.Invert(camera.GetCameraTransform()));

            foreach (var archetypeChunk in archetypeChunks)
            {
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (selectableSpan[i].IsSelected && factionSpan[i].Id == FactionId.Player)
                    {
                        stationSpan[i].RallyPoint = rallyPoint;
                    }
                }
            }
        }
    }
}
