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
    /// A faction-coloured health bar above anything that has taken damage. Undamaged entities draw
    /// nothing, so a healthy base doesn't look like a UI mockup.
    /// </summary>
    public class HealthBarRenderer(Texture2D pixel) : ISystem, IDrawSystem
    {
        private const float BarWidth = 30f;
        private const float BarHeight = 3f;
        private const float BarOffsetY = -26f;

        private static readonly ComponentRef[] requiredComponentProviders =
            [ComponentRef.Of<Position>(), ComponentRef.Of<Health>(), ComponentRef.Of<Faction>()];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        // Bars are positioned per entity, so they belong in the world and scale with the camera.
        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var healthSpan = archetypeChunk.GetSpan<Health>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    var health = healthSpan[i];
                    if (health.Current >= health.Maximum || health.Current <= 0f)
                    {
                        continue;
                    }

                    var fraction = MathHelper.Clamp(health.Current / health.Maximum, 0f, 1f);
                    var topLeft = positionSpan[i].Location + new Vector2(-BarWidth / 2f, BarOffsetY);

                    Primitives.FillRectangle(spriteBatch, pixel, topLeft, new Vector2(BarWidth, BarHeight), new Color(30, 30, 30));
                    Primitives.FillRectangle(spriteBatch, pixel, topLeft, new Vector2(BarWidth * fraction, BarHeight), SpriteSet.FactionColour(factionSpan[i].Id));
                }
            }
        }
    }
}
