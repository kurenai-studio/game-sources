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
    /// Shows what a station is building and how far along it is, without writing anything down: a
    /// radial progress ring around the station, a shrunken sprite of the ship itself in the middle
    /// of that ring, and one pip per item still queued behind it.
    /// </summary>
    /// <remarks>
    /// The sprite is the label. A player who has seen a freighter mine and a fighter shoot already
    /// knows what those two silhouettes mean, so the icon carries the same information the word
    /// "Miner" would, in less space and in every language.
    ///
    /// A station with a standing order (<c>Station.AutoQueue</c>) also gets a badge below it: the
    /// ship it keeps making, inside a broken ring. The gaps are the whole point - a solid ring is
    /// already spoken for as "progress", and a dashed one reads as a cycle rather than a measurement.
    /// </remarks>
    public class BuildProgressRenderer(Texture2D pixel, SpriteSet sprites) : ISystem, IDrawSystem
    {
        private const float RingRadius = 46f;
        private const float IconScreenSize = 18f;
        private const float IconOffsetY = -62f;
        private const float PipSize = 4f;
        private const float PipSpacing = 7f;
        private const float PipOffsetY = 52f;

        private const float StandingOrderOffsetY = 80f;
        private const float StandingOrderRadius = 13f;
        private const float StandingOrderIconSize = 15f;
        private const int StandingOrderTicks = 6;

        /// <summary>Progress starts at 12 o'clock; sprite rotation is measured from +X.</summary>
        private const float RingStartAngle = -MathHelper.PiOver2;

        private static readonly Color TrackColour = new(40, 55, 75, 160);

        private static readonly ComponentRef[] requiredComponentProviders =
        [
            ComponentRef.Of<Position>(), ComponentRef.Of<Faction>(), ComponentRef.Of<Health>(),
            ComponentRef.Of<Timer>(), ComponentRef.Of<Station>(),
        ];

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => requiredComponentProviders;

        public DrawSpace DrawSpace => DrawSpace.World;

        public void Draw(SpriteBatch spriteBatch, Rectangle cullingBounds, List<ArchetypeChunk> archetypeChunks)
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
                    var station = stationSpan[i];
                    if (healthSpan[i].Current <= 0f)
                    {
                        continue;
                    }

                    var faction = factionSpan[i].Id;
                    var location = positionSpan[i].Location;
                    var colour = SpriteSet.FactionColour(faction);

                    // The standing-order badge is drawn for an idle station too - "this one keeps
                    // making fighters" is exactly the thing you want to see while it is waiting for
                    // the minerals to do so.
                    if (station.AutoQueue != UnitKind.None)
                    {
                        DrawStandingOrderBadge(spriteBatch, station.AutoQueue, faction, colour, location + new Vector2(0f, StandingOrderOffsetY));
                    }

                    if (station.InProgress == UnitKind.None)
                    {
                        continue;
                    }

                    Primitives.DrawCircleOutline(spriteBatch, pixel, location, RingRadius, TrackColour, thickness: 3f);
                    Primitives.DrawArc(
                        spriteBatch,
                        pixel,
                        location,
                        RingRadius,
                        RingStartAngle,
                        MathHelper.TwoPi * ProgressOf(timerSpan[i]),
                        colour,
                        thickness: 3f);

                    DrawShipIcon(spriteBatch, station.InProgress, faction, location + new Vector2(0f, IconOffsetY), IconScreenSize);
                    DrawQueuePips(spriteBatch, station, colour, location + new Vector2(0f, PipOffsetY));
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

        /// <summary>
        /// The ship a station keeps re-ordering, ringed by evenly spaced ticks. Deliberately not a
        /// solid circle: that shape already means "progress" a few pixels further up.
        /// </summary>
        private void DrawStandingOrderBadge(SpriteBatch spriteBatch, UnitKind kind, FactionId faction, Color colour, Vector2 centre)
        {
            var tickSweep = MathHelper.TwoPi / (StandingOrderTicks * 2f);
            for (var tick = 0; tick < StandingOrderTicks; tick++)
            {
                Primitives.DrawArc(
                    spriteBatch,
                    pixel,
                    centre,
                    StandingOrderRadius,
                    RingStartAngle + tick * tickSweep * 2f,
                    tickSweep,
                    colour,
                    thickness: 2f,
                    segments: 3);
            }

            DrawShipIcon(spriteBatch, kind, faction, centre, StandingOrderIconSize);
        }

        private void DrawShipIcon(SpriteBatch spriteBatch, UnitKind kind, FactionId faction, Vector2 centre, float screenSize)
        {
            var texture = SpriteLibrary.GetTexture(ShipBlueprints.SpriteIdFor(kind, faction, sprites));
            var scale = screenSize / texture.Width;

            spriteBatch.Draw(
                texture,
                centre,
                null,
                Color.White,
                0f,
                new Vector2(texture.Width / 2f, texture.Height / 2f),
                scale,
                SpriteEffects.None,
                0f);
        }

        /// <summary>One pip per item still waiting, so a deep queue reads as a longer row.</summary>
        private void DrawQueuePips(SpriteBatch spriteBatch, Station station, Color colour, Vector2 centre)
        {
            var queued = station.QueuedMiners + station.QueuedFighters;
            if (queued <= 0)
            {
                return;
            }

            var rowWidth = (queued - 1) * PipSpacing;
            for (var pip = 0; pip < queued; pip++)
            {
                var topLeft = centre + new Vector2(pip * PipSpacing - rowWidth / 2f - PipSize / 2f, 0f);
                Primitives.FillRectangle(spriteBatch, pixel, topLeft, new Vector2(PipSize), colour);
            }
        }
    }
}
