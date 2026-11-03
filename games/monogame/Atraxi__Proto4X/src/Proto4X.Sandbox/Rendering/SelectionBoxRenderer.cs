using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Systems;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// Draws the box-select rectangle while a drag is in progress.
    /// </summary>
    /// <remarks>
    /// Belongs to no entity at all: the rectangle lives on <see cref="SelectionSystem"/>, not in
    /// the world, so <c>RequiredComponentProviders</c> is empty and the scheduler runs this once a
    /// frame with no chunks.
    ///
    /// Being screen space, the rectangle is now drawn from the raw mouse coordinates with a
    /// constant one-pixel border. The previous version transformed all four corners back into world
    /// space to survive the camera transform, which was correct but meant the border thickness
    /// scaled with zoom - a hairline when zoomed out, a fat band when zoomed in.
    /// </remarks>
    public class SelectionBoxRenderer(Texture2D pixel, SelectionSystem selectionSystem) : ISystem, IDrawSystem
    {
        private static readonly Color FillColour = new(140, 255, 160, 40);

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [];

        public DrawSpace DrawSpace => DrawSpace.Screen;

        public void Draw(SpriteBatch spriteBatch, Rectangle viewport, List<ArchetypeChunk> archetypeChunks)
        {
            if (selectionSystem.DragScreenRectangle is not { } dragRectangle)
            {
                return;
            }

            var (start, current) = dragRectangle;
            var topLeft = Vector2.Min(start, current);
            var size = Vector2.Max(start, current) - topLeft;

            Primitives.FillRectangle(spriteBatch, pixel, topLeft, size, FillColour);
            Primitives.DrawRectangleOutline(spriteBatch, pixel, topLeft, size, SelectionRingRenderer.SelectionColour);
        }
    }
}
