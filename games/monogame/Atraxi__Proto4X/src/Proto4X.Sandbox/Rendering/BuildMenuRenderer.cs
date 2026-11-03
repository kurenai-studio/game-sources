using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary;
using MonoGameLibrary.Archetypes;
using MonoGameLibrary.Components.Infrastructure;
using MonoGameLibrary.Systems.Infrastructure;
using Proto4X.Sandbox.Components;
using Proto4X.Sandbox.Game;
using Proto4X.Sandbox.Systems;
using System.Collections.Generic;

namespace Proto4X.Sandbox.Rendering
{
    /// <summary>
    /// The build menu for whatever is currently selected, with no numbers and no words: one slot per
    /// available command, showing what it produces, whether you can afford it, how close you are,
    /// and which key issues it.
    /// </summary>
    /// <remarks>
    /// The slots come from <c>ShipBlueprints.CommandsFor</c> - the same table the command systems
    /// read - so what's drawn and what the keys actually do cannot drift apart. Select a station and
    /// the menu offers ships; select a miner and it offers a station. Select nothing and there is no
    /// menu, which is itself the correct feedback.
    ///
    /// The affordability ring does the work a price tag would. It fills as minerals accumulate and
    /// closes exactly when the command becomes affordable, so "a complete circle means yes" is the
    /// only thing to learn - and unlike a number it answers "how much longer" without arithmetic.
    /// The hotkey is a row of pips rather than a digit.
    /// </remarks>
    public class BuildMenuRenderer(
        Texture2D pixel,
        GraphicsDevice graphicsDevice,
        SpriteSet sprites,
        Economy economy,
        SelectionSummarySystem selectionSummary) : ISystem, IDrawSystem
    {
        private const float SlotSize = 56f;
        private const float SlotSpacing = 12f;
        private const float IconSize = 34f;
        private const float MarginBottom = 18f;
        private const float RingRadius = 25f;
        private const float PipSize = 3f;
        private const float PipSpacing = 6f;
        private const float PipOffsetY = 22f;

        private const float RingStartAngle = -MathHelper.PiOver2;

        private static readonly Color SlotColour = new(6, 10, 20, 200);
        private static readonly Color TrackColour = new(40, 55, 75, 200);
        private static readonly Color UnaffordableTint = new(90, 95, 110);

        public IReadOnlyList<ComponentRef> RequiredComponentProviders => [];

        public DrawSpace DrawSpace => DrawSpace.Screen;

        public void Draw(SpriteBatch spriteBatch, Rectangle viewport, List<ArchetypeChunk> archetypeChunks)
        {
            var commands = ShipBlueprints.CommandsFor(selectionSummary.PrimaryKind);
            if (commands.Length == 0)
            {
                return;
            }

            var screen = graphicsDevice.Viewport.Bounds;
            var minerals = economy.GetMinerals(FactionId.Player);

            var totalWidth = commands.Length * SlotSize + (commands.Length - 1) * SlotSpacing;
            var firstCentreX = screen.Width / 2f - totalWidth / 2f + SlotSize / 2f;
            var centreY = screen.Height - MarginBottom - SlotSize / 2f;

            for (var slot = 0; slot < commands.Length; slot++)
            {
                var centre = new Vector2(firstCentreX + slot * (SlotSize + SlotSpacing), centreY);
                DrawSlot(spriteBatch, centre, commands[slot], minerals);
            }
        }

        private void DrawSlot(SpriteBatch spriteBatch, Vector2 centre, UnitCommand command, int minerals)
        {
            var cost = ShipBlueprints.For(command.Produces).MineralCost;
            var affordability = MathHelper.Clamp(minerals / (float)cost, 0f, 1f);
            var isAffordable = minerals >= cost;
            var accent = SpriteSet.FactionColour(FactionId.Player);

            Primitives.FillRectangle(spriteBatch, pixel, centre - new Vector2(SlotSize / 2f), new Vector2(SlotSize), SlotColour);

            var texture = SpriteLibrary.GetTexture(ShipBlueprints.SpriteIdFor(command.Produces, FactionId.Player, sprites));
            spriteBatch.Draw(
                texture,
                centre,
                null,
                isAffordable ? Color.White : UnaffordableTint,
                0f,
                new Vector2(texture.Width / 2f, texture.Height / 2f),
                IconSize / texture.Width,
                SpriteEffects.None,
                0f);

            Primitives.DrawCircleOutline(spriteBatch, pixel, centre, RingRadius, TrackColour, thickness: 2.5f);
            Primitives.DrawArc(
                spriteBatch,
                pixel,
                centre,
                RingRadius,
                RingStartAngle,
                MathHelper.TwoPi * affordability,
                isAffordable ? accent : Color.Lerp(TrackColour, accent, 0.55f),
                thickness: 2.5f);

            var rowWidth = (command.HotkeyPips - 1) * PipSpacing;
            for (var pip = 0; pip < command.HotkeyPips; pip++)
            {
                var topLeft = centre + new Vector2(pip * PipSpacing - rowWidth / 2f - PipSize / 2f, PipOffsetY);
                Primitives.FillRectangle(spriteBatch, pixel, topLeft, new Vector2(PipSize), accent);
            }
        }
    }
}
