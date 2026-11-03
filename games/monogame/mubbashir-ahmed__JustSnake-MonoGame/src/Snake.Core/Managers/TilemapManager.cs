using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Graphics;
using System;
using System.IO;

namespace Snake.Core.Managers
{
    /// <summary>
    /// Manages the game's tilemap, including loading and drawing.
    /// </summary>
    public class TilemapManager
    {
        /// <summary>
        /// The tilemap.
        /// </summary>
        private Tilemap tilemap;

        /// <summary>
        /// The tilemap definition path.
        /// </summary>
        private readonly string TilemapDefinitionPath = Path.Combine("Textures", "tilemap-definition.xml");

        /// <summary>
        /// Loads the tilemap from the content manager.
        /// </summary>
        /// <param name="contentManager">The content manager to load the tilemap from.</param>
        public void LoadContent(ContentManager contentManager)
        {
            ArgumentNullException.ThrowIfNull(contentManager);

            // Load the tilemap from the content manager
            tilemap = Tilemap.FromFile(contentManager, TilemapDefinitionPath);
        }

        /// <summary>
        /// Draws the tilemap.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw with.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            ArgumentNullException.ThrowIfNull(spriteBatch);

            // Draw the tilemap
            tilemap?.Draw(spriteBatch);
        }

        /// <summary>
        /// Gets the current tilemap instance.
        /// </summary>
        /// <returns>The tilemap, or null if not loaded.</returns>
        public Tilemap GetTilemap()
        {
            // Return the tilemap
            return tilemap;
        }
    }
}
