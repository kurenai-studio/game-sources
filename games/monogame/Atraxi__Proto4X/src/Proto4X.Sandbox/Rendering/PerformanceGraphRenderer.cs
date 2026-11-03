using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// A rolling frame-time graph in the top-right corner, for watching the engine buckle under
    /// load. One column per recent frame, height proportional to how long that frame took.
    /// </summary>
    /// <remarks>
    /// No text, in keeping with the rest of the UI, and it turns out a graph is the better tool
    /// anyway: an average FPS number hides exactly the thing you want to catch, which is the
    /// occasional long frame. Two reference lines mark the 60fps and 30fps budgets, so "are we
    /// still fine" is a shape comparison rather than a number to read.
    ///
    /// Columns are coloured by which budget they blow, so a screen full of green is healthy, amber
    /// is missing 60fps, and red is missing 30fps.
    /// </remarks>
    public class PerformanceGraphRenderer(Texture2D pixel, GraphicsDevice graphicsDevice) : ISystem, IDrawSystem
    {
        private const int SampleCount = 180;
        private const float GraphHeight = 60f;
        private const float ColumnWidth = 2f;
        private const float Margin = 12f;

        private const float SixtyFpsMilliseconds = 1000f / 60f;
        private const float ThirtyFpsMilliseconds = 1000f / 30f;

        /// <summary>Top of the graph. Frames slower than this clip rather than rescaling the whole chart.</summary>
        private const float CeilingMilliseconds = 50f;

        private static readonly Color PanelColour = new(6, 10, 20, 190);
        private static readonly Color BorderColour = new(70, 90, 120);
        private static readonly Color GoodColour = new(120, 220, 150);
        private static readonly Color WarnColour = new(240, 200, 110);
        private static readonly Color BadColour = new(255, 120, 110);
        private static readonly Color GuideColour = new(90, 110, 140, 180);

        private readonly float[] samples = new float[SampleCount];
        private int nextSample;

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [];

        public DrawSpace DrawSpace => DrawSpace.Screen;

        /// <summary>Called from the game loop, since a draw system isn't handed a GameTime.</summary>
        public void Record(GameTime gameTime)
        {
            samples[nextSample] = (float)gameTime.ElapsedGameTime.TotalMilliseconds;
            nextSample = (nextSample + 1) % SampleCount;
        }

        public void Draw(SpriteBatch spriteBatch, Rectangle viewport, List<ArchetypeChunk> archetypeChunks)
        {
            var screen = graphicsDevice.Viewport.Bounds;
            var graphWidth = SampleCount * ColumnWidth;
            var topLeft = new Vector2(screen.Width - graphWidth - Margin, Margin);

            Primitives.FillRectangle(spriteBatch, pixel, topLeft, new Vector2(graphWidth, GraphHeight), PanelColour);

            DrawGuide(spriteBatch, topLeft, graphWidth, SixtyFpsMilliseconds);
            DrawGuide(spriteBatch, topLeft, graphWidth, ThirtyFpsMilliseconds);

            for (var column = 0; column < SampleCount; column++)
            {
                // Oldest sample on the left, so the graph scrolls the way people expect.
                var milliseconds = samples[(nextSample + column) % SampleCount];
                if (milliseconds <= 0f)
                {
                    continue;
                }

                var height = MathHelper.Clamp(milliseconds / CeilingMilliseconds, 0f, 1f) * GraphHeight;
                var columnTopLeft = new Vector2(topLeft.X + column * ColumnWidth, topLeft.Y + GraphHeight - height);

                var colour = milliseconds > ThirtyFpsMilliseconds ? BadColour
                    : milliseconds > SixtyFpsMilliseconds ? WarnColour
                    : GoodColour;

                Primitives.FillRectangle(spriteBatch, pixel, columnTopLeft, new Vector2(ColumnWidth, height), colour);
            }

            Primitives.DrawRectangleOutline(spriteBatch, pixel, topLeft, new Vector2(graphWidth, GraphHeight), BorderColour);
        }

        private void DrawGuide(SpriteBatch spriteBatch, Vector2 topLeft, float graphWidth, float budgetMilliseconds)
        {
            var y = topLeft.Y + GraphHeight - MathF.Min(budgetMilliseconds / CeilingMilliseconds, 1f) * GraphHeight;
            Primitives.DrawLine(spriteBatch, pixel, new Vector2(topLeft.X, y), new Vector2(topLeft.X + graphWidth, y), GuideColour);
        }
    }
}
