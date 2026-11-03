using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary;
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
    /// The same radial progress language as <see cref="BuildProgressRenderer"/>, for a miner part
    /// way through founding a station: a ring that fills, with the station's own sprite ghosted
    /// inside it so you can see what is about to appear and where.
    /// </summary>
    /// <remarks>
    /// A separate system rather than a branch inside the station renderer, because a system gets one
    /// AND-mask and miners and stations are different archetypes. The visual language is shared even
    /// though the query can't be.
    /// </remarks>
    public class ConstructionProgressRenderer(Texture2D pixel, SpriteSet sprites) : ISystem, IDrawSystem
    {
        private const float RingRadius = 40f;
        private const float GhostSize = 52f;
        private const float RingStartAngle = -MathHelper.PiOver2;

        private static readonly Color TrackColour = new(40, 55, 75, 160);
        private static readonly Color GhostTint = new(255, 255, 255, 70);

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(),
            ComponentRef.Of<Timer>(), ComponentRef.Of<Miner>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
        {
            foreach (var archetypeChunk in archetypeChunks)
            {
                var positionSpan = archetypeChunk.GetSpan<Position>();
                var factionSpan = archetypeChunk.GetSpan<Faction>();
                var timerSpan = archetypeChunk.GetSpan<Timer>();
                var minerSpan = archetypeChunk.GetSpan<Miner>();

                for (var i = 0; i < archetypeChunk.EntityCount; i++)
                {
                    if (minerSpan[i].Task != MinerTask.Constructing)
                    {
                        continue;
                    }

                    var faction = factionSpan[i].Id;
                    var location = positionSpan[i].Location;
                    var texture = SpriteLibrary.GetTexture(ShipBlueprints.SpriteIdFor(UnitKind.Station, faction, sprites));

                    spriteBatch.Draw(
                        texture,
                        location,
                        null,
                        GhostTint,
                        0f,
                        new Vector2(texture.Width / 2f, texture.Height / 2f),
                        GhostSize / texture.Width,
                        SpriteEffects.None,
                        0f);

                    Primitives.DrawCircleOutline(spriteBatch, pixel, location, RingRadius, TrackColour, thickness: 3f);
                    Primitives.DrawArc(
                        spriteBatch,
                        pixel,
                        location,
                        RingRadius,
                        RingStartAngle,
                        MathHelper.TwoPi * ProgressOf(timerSpan[i]),
                        SpriteSet.FactionColour(faction),
                        thickness: 3f);
                }
            }
        }

        private static float ProgressOf(Timer timer)
        {
            if (timer.DurationTicks <= 0)
            {
                return 1f;
            }

            var elapsedTicks = timer.DurationTicks - timer.RemainingTicks;
            return MathHelper.Clamp((float)elapsedTicks / timer.DurationTicks, 0f, 1f);
        }
    }
}
