using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary;
using Proto4X.Sandbox.Components;
using System;

namespace Proto4X.Sandbox.Game
{
    /// <summary>
    /// Loads the game's art and registers it with <see cref="SpriteLibrary"/>, including a
    /// per-faction tinted copy of every ship and station.
    /// </summary>
    /// <remarks>
    /// The tinting happens here, at load, by baking recoloured copies of the texture, because
    /// <c>Drawable</c> carries no colour and <c>Renderer</c> always draws <c>Color.White</c>.
    /// Baking copies costs a little VRAM but needs no engine change - see "Drawable has no tint,
    /// scale or layer" in ENGINE_REQUESTS.md. Cost scales with faction count, which is the one
    /// thing that made adding a third faction non-free.
    /// </remarks>
    public class SpriteSet
    {
        private static readonly Color[] FactionTints = BuildFactionTints();

        private readonly int[] minerSprites;
        private readonly int[] fighterSprites;
        private readonly int[] stationSprites;

        public int[] AsteroidSpriteIds { get; }

        /// <summary>A 1x1 white texture, the drawing primitive every overlay renderer stretches into lines and bars.</summary>
        public Texture2D Pixel { get; }

        public SpriteSet(ContentManager content, GraphicsDevice graphicsDevice)
        {
            Pixel = new Texture2D(graphicsDevice, 1, 1);
            Pixel.SetData([Color.White]);

            var miner = content.Load<Texture2D>("Ships/ship_freighter_32x32");
            var fighter = content.Load<Texture2D>("Ships/ship_fighter_32x32");
            var station = content.Load<Texture2D>("Stations/station_core_64x64");

            var factionCount = Enum.GetValues<FactionId>().Length;
            minerSprites = new int[factionCount];
            fighterSprites = new int[factionCount];
            stationSprites = new int[factionCount];

            foreach (var faction in Faction.Playing)
            {
                var tint = FactionTints[(int)faction];
                minerSprites[(int)faction] = SpriteLibrary.Add(Tint(graphicsDevice, miner, tint));
                fighterSprites[(int)faction] = SpriteLibrary.Add(Tint(graphicsDevice, fighter, tint));
                stationSprites[(int)faction] = SpriteLibrary.Add(Tint(graphicsDevice, station, tint));
            }

            AsteroidSpriteIds =
            [
                SpriteLibrary.Add(content.Load<Texture2D>("Resources/rock1_24x24")),
                SpriteLibrary.Add(content.Load<Texture2D>("Resources/rock2_32x32")),
                SpriteLibrary.Add(content.Load<Texture2D>("Resources/rock3_28x28")),
            ];
        }

        public int MinerSpriteFor(FactionId faction) => minerSprites[(int)faction];

        public int FighterSpriteFor(FactionId faction) => fighterSprites[(int)faction];

        public int StationSpriteFor(FactionId faction) => stationSprites[(int)faction];

        public static Color FactionColour(FactionId faction) => FactionTints[(int)faction];

        private static Color[] BuildFactionTints()
        {
            var tints = new Color[Enum.GetValues<FactionId>().Length];
            for (var i = 0; i < tints.Length; i++)
            {
                tints[i] = Color.Gray;
            }

            tints[(int)FactionId.Player] = new Color(120, 190, 255);
            tints[(int)FactionId.Enemy] = new Color(255, 120, 110);
            tints[(int)FactionId.Rival] = new Color(240, 200, 110);
            return tints;
        }

        private static Texture2D Tint(GraphicsDevice graphicsDevice, Texture2D source, Color tint)
        {
            var pixels = new Color[source.Width * source.Height];
            source.GetData(pixels);

            for (var i = 0; i < pixels.Length; i++)
            {
                var pixel = pixels[i];
                pixels[i] = new Color(
                    (byte)(pixel.R * tint.R / 255),
                    (byte)(pixel.G * tint.G / 255),
                    (byte)(pixel.B * tint.B / 255),
                    pixel.A);
            }

            var tinted = new Texture2D(graphicsDevice, source.Width, source.Height);
            tinted.SetData(pixels);
            return tinted;
        }
    }
}
