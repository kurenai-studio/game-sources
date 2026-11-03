using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.IO;
using System.Xml;
using System.Xml.Linq;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a tilemap containing a grid of tiles.
    /// </summary>
    public class Tilemap
    {
        /// <summary>
        /// The base tile size.
        /// </summary>
        private const int BaseTileSize = 8;

        /// <summary>
        /// The default scale X.
        /// </summary>
        private const float DefaultScaleX = 4.0f;

        /// <summary>
        /// The default scale Y.
        /// </summary>
        private const float DefaultScaleY = 4.0f;

        /// <summary>
        /// The wall tile ID 1.
        /// </summary>
        private const int WallTileId1 = 29;

        /// <summary>
        /// The wall tile ID 2.
        /// </summary>
        private const int WallTileId2 = 30;

        /// <summary>
        /// The wall tile ID 3.
        /// </summary>
        private const int WallTileId3 = 31;

        /// <summary>
        /// The wall tile ID 4.
        /// </summary>
        private const int WallTileId4 = 32;

        /// <summary>
        /// The tileset.
        /// </summary>
        private readonly Tileset tileset;

        /// <summary>
        /// The tiles.
        /// </summary>
        private readonly int[] tiles;

        /// <summary>
        /// Gets the number of rows in the tilemap.
        /// </summary>
        public int Rows { get; }

        /// <summary>
        /// Gets the number of columns in the tilemap.
        /// </summary>
        public int Columns { get; }

        /// <summary>
        /// Gets the total number of tiles in the tilemap.
        /// </summary>
        public int Count { get; }

        /// <summary>
        /// Gets or sets the scale factor for rendering tiles.
        /// </summary>
        public Vector2 Scale { get; set; }

        /// <summary>
        /// Gets the scaled width of each tile.
        /// </summary>
        public float TileWidth => tileset.TileWidth * Scale.X;

        /// <summary>
        /// Gets the scaled height of each tile.
        /// </summary>
        public float TileHeight => tileset.TileHeight * Scale.Y;

        /// <summary>
        /// Gets the scaled size of each tile.
        /// </summary>
        public float TileSize => BaseTileSize * Scale.X;

        /// <summary>
        /// Initializes a new instance of the Tilemap class.
        /// </summary>
        /// <param name="tileset">The tileset to use.</param>
        /// <param name="columns">The number of columns.</param>
        /// <param name="rows">The number of rows.</param>
        public Tilemap(Tileset tileset, int columns, int rows)
        {
            ArgumentNullException.ThrowIfNull(tileset);

            // Check if the columns is less than or equal to zero and throw an exception
            if (columns <= 0)
                throw new ArgumentOutOfRangeException(nameof(columns));

            // Check if the rows is less than or equal to zero and throw an exception
            if (rows <= 0)
                throw new ArgumentOutOfRangeException(nameof(rows));

            // Set the tileset
            this.tileset = tileset;

            // Set the rows and columns
            Rows = rows;
            Columns = columns;

            // Set the count
            Count = columns * rows;

            // Set the scale
            Scale = new Vector2(DefaultScaleX, DefaultScaleY);

            // Set the tiles
            tiles = new int[Count];
        }

        /// <summary>
        /// Sets a tile at the specified index.
        /// </summary>
        /// <param name="index">The tile index.</param>
        /// <param name="tilesetId">The tileset ID to set.</param>
        public void SetTile(int index, int tilesetId)
        {
            // Check if the index is less than zero or greater than or equal to the count and throw an exception
            if (index < 0 || index >= Count)
                throw new ArgumentOutOfRangeException(nameof(index));

            // Set the tile at the index
            tiles[index] = tilesetId;
        }

        /// <summary>
        /// Sets a tile at the specified column and row.
        /// </summary>
        /// <param name="column">The column index.</param>
        /// <param name="row">The row index.</param>
        /// <param name="tilesetId">The tileset ID to set.</param>
        public void SetTile(int column, int row, int tilesetId)
        {
            // Calculate the index
            int index = row * Columns + column;

            // Set the tile at the index
            SetTile(index, tilesetId);
        }

        /// <summary>
        /// Gets the texture region for a tile at the specified index.
        /// </summary>
        /// <param name="index">The tile index.</param>
        /// <returns>The texture region for the tile.</returns>
        public TextureRegion GetTile(int index)
        {
            // Check if the index is less than zero or greater than or equal to the count and throw an exception
            if (index < 0 || index >= Count)
                throw new ArgumentOutOfRangeException(nameof(index));

            // Get the tile at the index
            return tileset.GetTile(tiles[index]);
        }

        /// <summary>
        /// Gets the texture region for a tile at the specified column and row.
        /// </summary>
        /// <param name="column">The column index.</param>
        /// <param name="row">The row index.</param>
        /// <returns>The texture region for the tile.</returns>
        public TextureRegion GetTile(int column, int row)
        {
            // Calculate the index
            int index = row * Columns + column;

            // Get the tile at the index
            return GetTile(index);
        }

        /// <summary>
        /// Draws the tilemap to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            // Loop through the tiles
            for (int i = 0; i < Count; i++)
            {
                // Get the tileset index
                int tilesetIndex = tiles[i];

                // Get the tile at the tileset index
                TextureRegion tile = tileset.GetTile(tilesetIndex);

                // Calculate the x and y positions
                int x = i % Columns;
                int y = i / Columns;

                // Create a new position
                Vector2 position = new Vector2(x * TileWidth, y * TileHeight);
                tile.Draw(spriteBatch, position, Color.White, 0.0f, Vector2.Zero, Scale, SpriteEffects.None, 0.0f);
            }
        }

        /// <summary>
        /// Checks if a tile at the specified position is a wall.
        /// </summary>
        /// <param name="column">The column index.</param>
        /// <param name="row">The row index.</param>
        /// <returns>True if the tile is a wall or out of bounds, false otherwise.</returns>
        public bool IsWall(int column, int row)
        {
            // Check if the column is less than zero or greater than or equal to the columns and throw an exception
            if (column < 0 || column >= Columns || row < 0 || row >= Rows)
            {
                return true;
            }

            // Calculate the index
            int index = row * Columns + column;
            int tileId = tiles[index];

            // Return true if the tile is a wall or out of bounds, false otherwise
            return tileId == WallTileId1 || tileId == WallTileId2 || 
                   tileId == WallTileId3 || tileId == WallTileId4;
        }

        public static Tilemap FromFile(ContentManager content, string filename)
        {
            // Get the file path
            string filePath = Path.Combine(content.RootDirectory, filename);

            // Open the stream

            using (Stream stream = TitleContainer.OpenStream(filePath))
            {
                using (XmlReader reader = XmlReader.Create(stream))
                {
                    // Load the document
                    XDocument document = XDocument.Load(reader);
                    XElement rootElement = document.Root;

                    // Get the tileset element
                    XElement tilesetElement = rootElement.Element("Tileset");

                    // Get the region attribute
                    string regionAttribute = tilesetElement.Attribute("region").Value;
                    string[] split = regionAttribute.Split(" ", StringSplitOptions.RemoveEmptyEntries);

                    // Parse the x, y, width, and height
                    int x = int.Parse(split[0]);
                    int y = int.Parse(split[1]);
                    int width = int.Parse(split[2]);
                    int height = int.Parse(split[3]);

                    // Parse the tile width and height
                    int tileWidth = int.Parse(tilesetElement.Attribute("tileWidth").Value);
                    int tileHeight = int.Parse(tilesetElement.Attribute("tileHeight").Value);

                    // Get the content path
                    string contentPath = tilesetElement.Value;

                    // Load the texture

                    Texture2D texture = content.Load<Texture2D>(contentPath);

                    // Create a new texture region
                    TextureRegion textureRegion = new TextureRegion(texture, x, y, width, height);

                    // Create a new tileset
                    Tileset tileset = new Tileset(textureRegion, tileWidth, tileHeight);

                    // Get the tiles element
                    XElement tilesElement = rootElement.Element("Tiles");

                    // Get the rows
                    string[] rows = tilesElement.Value.Trim().Split('\n', StringSplitOptions.RemoveEmptyEntries);

                    // Get the column count
                    int columnCount = rows[0].Split(" ", StringSplitOptions.RemoveEmptyEntries).Length;

                    // Create a new tilemap
                    Tilemap tilemap = new Tilemap(tileset, columnCount, rows.Length);

                    // Loop through the rows
                    for (int row = 0; row < rows.Length; row++)
                    {
                        string[] columns = rows[row].Trim().Split(" ", StringSplitOptions.RemoveEmptyEntries);

                        for (int column = 0; column < columnCount; column++)
                        {
                            // Parse the tileset index
                            int tilesetIndex = int.Parse(columns[column]);

                            // Set the tile at the column and row
                            tilemap.SetTile(column, row, tilesetIndex);
                        }
                    }

                    // Return the tilemap
                    return tilemap;
                }
            }
        }
    }
}
