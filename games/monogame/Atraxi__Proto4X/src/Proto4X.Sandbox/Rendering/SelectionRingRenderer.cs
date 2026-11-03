using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// Draws a ring around every selected unit. World space, so rings sit on their units and scale
    /// with the camera. The drag rectangle used to be drawn here too and now lives in
    /// <see cref="SelectionBoxRenderer"/>, since a system declares exactly one <c>DrawSpace</c> and
    /// that rectangle was never really a world-space thing.
    /// </summary>
    public class SelectionRingRenderer(Texture2D pixel) : ISystem, IDrawSystem
    {
        public static readonly Color SelectionColour = new(140, 255, 160);

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Selectable>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var selectableSpan = archetypeChunk.GetSpan<Selectable>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (!selectableSpan[i].IsSelected)
                    {
                        continue;
                    }

                    Primitives.DrawCircleOutline(
                        spriteBatch,
                        pixel,
                        positionSpan[i].Location,
                        selectableSpan[i].PickRadius + 4f,
                        SelectionColour,
                        thickness: 1.5f);
                }
            }
        }
    }
}
