using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// Draws a line from a selected station to its rally point, ending in a small ring. Only shown
    /// while the station is selected, so the map isn't permanently criss-crossed with them.
    /// </summary>
    public class RallyPointRenderer(Texture2D pixel) : ISystem, IDrawSystem
    {
        private const float MarkerRadius = 10f;

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(),
            ComponentRef.Of<Selectable>(), ComponentRef.Of<Station>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();
                var stationSpan = archetypeChunk.GetSpan<Station>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (!selectableSpan[i].IsSelected || stationSpan[i].RallyPoint is not Vector2 rallyPoint)
                    {
                        continue;
                    }

                    var colour = SpriteSet.FactionColour(factionSpan[i].Id);
                    Primitives.DrawLine(spriteBatch, pixel, positionSpan[i].Location, rallyPoint, colour);
                    Primitives.DrawCircleOutline(spriteBatch, pixel, rallyPoint, MarkerRadius, colour, thickness: 1.5f, segments: 12);
                }
            }
        }
    }
}
