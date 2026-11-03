using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using MonoGameLibrary.UI;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using System;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// A corner minimap: one faction-coloured dot per unit and station, plus an outline showing
    /// where the camera currently is. The first piece of real UI in the game, and the thing that
    /// makes the map bigger than one screen actually playable.
    /// </summary>
    /// <remarks>
    /// Screen space, so it stays put and stays the same size while the world pans and zooms
    /// underneath it - the entire point of the pass, and not something the world-space workaround
    /// could have faked.
    ///
    /// Dot size comes from <c>Health.Maximum</c> rather than a component that says "I am a station",
    /// because the query has to match ships and stations at once and only one AND-mask is available.
    /// It reads as "bigger things draw bigger", which is true enough to be worth the trick.
    /// </remarks>
    public class MinimapRenderer(Texture2D pixel, GraphicsDevice graphicsDevice, Camera camera, Rectangle worldBounds) : ISystem, IDrawSystem
    {
        private const float PanelWidth = 220f;
        private const float Margin = 12f;
        private const float StationHealthThreshold = 500f;

        private static readonly Color PanelColour = new(6, 10, 20, 200);
        private static readonly Color BorderColour = new(70, 90, 120);
        private static readonly Color CameraOutlineColour = new(200, 220, 255, 160);

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Health>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.Screen;

        public void Draw(SpriteBatch spriteBatch, Rectangle viewport, List<ArchetypeChunk> archetypeChunks)
        {
            var scale = PanelWidth / worldBounds.Width;
            var panelSize = new Vector2(PanelWidth, worldBounds.Height * scale);
            var screen = graphicsDevice.Viewport.Bounds;
            var panelTopLeft = new Vector2(Margin, screen.Height - panelSize.Y - Margin);

            Primitives.FillRectangle(spriteBatch, pixel, panelTopLeft, panelSize, PanelColour);

            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var healthSpan = archetypeChunk.GetSpan<Health>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    var dotSize = healthSpan[i].Maximum >= StationHealthThreshold ? 5f : 2f;
                    var dotCentre = panelTopLeft + ToMinimap(positionSpan[i].Location, scale);

                    Primitives.FillRectangle(
                        spriteBatch,
                        pixel,
                        dotCentre - new Vector2(dotSize / 2f),
                        new Vector2(dotSize),
                        SpriteSet.FactionColour(factionSpan[i].Id));
                }
            }

            DrawCameraOutline(spriteBatch, panelTopLeft, panelSize, scale, screen);
            Primitives.DrawRectangleOutline(spriteBatch, pixel, panelTopLeft, panelSize, BorderColour);
        }

        private Vector2 ToMinimap(Vector2 worldLocation, float scale)
            => (worldLocation - new Vector2(worldBounds.X, worldBounds.Y)) * scale;

        /// <summary>
        /// Outlines the visible region by projecting the screen's corners back into the world. Under
        /// a rotated camera the true region is a rotated quad, and this draws its bounding box -
        /// slightly generous, which is the right way round for a "you are here" indicator.
        /// </summary>
        private void DrawCameraOutline(SpriteBatch spriteBatch, Vector2 panelTopLeft, Vector2 panelSize, float scale, Rectangle screen)
        {
            var screenToWorld = Matrix.Invert(camera.GetCameraTransform());

            ReadOnlySpan<Vector2> screenCorners =
            [
                new(screen.Left, screen.Top),
                new(screen.Right, screen.Top),
                new(screen.Right, screen.Bottom),
                new(screen.Left, screen.Bottom),
            ];

            var minimum = new Vector2(float.MaxValue);
            var maximum = new Vector2(float.MinValue);

            foreach (var corner in screenCorners)
            {
                var world = Vector2.Transform(corner, screenToWorld);
                minimum = Vector2.Min(minimum, world);
                maximum = Vector2.Max(maximum, world);
            }

            var outlineTopLeft = panelTopLeft + ToMinimap(minimum, scale);
            var outlineSize = (maximum - minimum) * scale;

            // Keep the indicator inside the panel when the camera is looking past the world edge.
            var clampedTopLeft = Vector2.Clamp(outlineTopLeft, panelTopLeft, panelTopLeft + panelSize);
            var clampedBottomRight = Vector2.Clamp(outlineTopLeft + outlineSize, panelTopLeft, panelTopLeft + panelSize);

            Primitives.DrawRectangleOutline(spriteBatch, pixel, clampedTopLeft, clampedBottomRight - clampedTopLeft, CameraOutlineColour);
        }
    }
}
