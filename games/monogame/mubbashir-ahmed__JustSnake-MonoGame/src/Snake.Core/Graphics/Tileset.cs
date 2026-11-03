using System;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a tileset containing multiple tile regions from a texture.
    /// </summary>
    public class Tileset
    {
        private readonly TextureRegion[] tiles;

        /// <summary>
        /// Gets the width of each tile in pixels.
        /// </summary>
        public int TileWidth { get; }

        /// <summary>
        /// Gets the height of each tile in pixels.
        /// </summary>
        public int TileHeight { get; }

        /// <summary>
        /// Gets the number of columns in the tileset.
        /// </summary>
        public int Columns { get; }

        /// <summary>
        /// Gets the number of rows in the tileset.
        /// </summary>
        public int Rows { get; }

        /// <summary>
        /// Gets the total number of tiles in the tileset.
        /// </summary>
        public int Count { get; }

        /// <summary>
        /// Initializes a new instance of the Tileset class.
        /// </summary>
        /// <param name="textureRegion">The texture region containing all tiles.</param>
        /// <param name="tileWidth">The width of each tile.</param>
        /// <param name="tileHeight">The height of each tile.</param>
        public Tileset(TextureRegion textureRegion, int tileWidth, int tileHeight)
        {
            ArgumentNullException.ThrowIfNull(textureRegion);

            // Check if the tile width is less than or equal to zero and throw an exception
            if (tileWidth <= 0)
                throw new ArgumentOutOfRangeException(nameof(tileWidth));

            // Check if the tile height is less than or equal to zero and throw an exception
            if (tileHeight <= 0)
                throw new ArgumentOutOfRangeException(nameof(tileHeight));

            // Set the tile width and height
            TileWidth = tileWidth;
            TileHeight = tileHeight;

            // Set the columns and rows
            Columns = textureRegion.Width / tileWidth;
            Rows = textureRegion.Height / tileHeight;

            // Set the count
            Count = Columns * Rows;

            // Set the tiles
            tiles = new TextureRegion[Count];

            // Loop through the tiles
            for (int i = 0; i < Count; i++)
            {
                // Calculate the x and y positions
                int x = (i % Columns) * tileWidth;
                int y = (i / Columns) * tileHeight;

                // Create a new texture region
                tiles[i] = new TextureRegion(
                    textureRegion.Texture, 
                    textureRegion.SourceRectangle.X + x,
                    textureRegion.SourceRectangle.Y + y, 
                    tileWidth, 
                    tileHeight
                );
            }
        }

        /// <summary>
        /// Gets a tile by its index.
        /// </summary>
        /// <param name="index">The index of the tile.</param>
        /// <returns>The texture region for the tile.</returns>
        public TextureRegion GetTile(int index)
        {
            // Check if the index is less than zero or greater than or equal to the count and throw an exception
            if (index < 0 || index >= Count)
                throw new ArgumentOutOfRangeException(nameof(index));

            // Return the tile at the index
            return tiles[index];
        }

        /// <summary>
        /// Gets a tile by its column and row.
        /// </summary>
        /// <param name="column">The column index.</param>
        /// <param name="row">The row index.</param>
        /// <returns>The texture region for the tile.</returns>
        public TextureRegion GetTile(int column, int row)
        {
            // Calculate the index
            int index = row * Columns + column;

            // Return the tile at the index
            return GetTile(index);
        }
    }
}
