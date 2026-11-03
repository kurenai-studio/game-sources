// ============================================
// Tile.cs - Represents a single tile in the world
// ============================================
using Microsoft.Xna.Framework;

namespace DungeonExplorer.World
{
    public enum TileType
    {
        Wall,
        Floor,
        Door,
        Corridor
    }

    /// <summary>
    /// Represents a single tile in the dungeon
    /// </summary>
    public class Tile
    {
        public TileType Type { get; set; }
        public bool IsWalkable { get; set; }
        public bool IsTransparent { get; set; }
        public Vector2 Position { get; set; }
        public Color Tint { get; set; }
        public bool IsExplored { get; set; }
        public bool IsVisible { get; set; }
        public bool IsStartPosition { get; set; }
        public bool IsEndPosition { get; set; }
        public int RoomId { get; set; } = -1;

        public Tile(TileType type, int x, int y) : this(type, new Vector2(x, y))
        {
        }

        public Tile(TileType type, Vector2 position)
        {
            Type = type;
            Position = position;
            Tint = Color.White;
            IsExplored = false;
            IsVisible = false;
            IsStartPosition = false;
            IsEndPosition = false;

            // Set base properties based on type
            switch (type)
            {
                case TileType.Wall:
                    IsWalkable = false;
                    IsTransparent = false;
                    break;
                case TileType.Floor:
                case TileType.Corridor:
                case TileType.Door:
                    IsWalkable = true;
                    IsTransparent = true;
                    break;
            }
        }

        public void SetExplored()
        {
            IsExplored = true;
        }

        public void SetVisible(bool visible)
        {
            IsVisible = visible;
            if (visible) IsExplored = true;
        }

        public override string ToString()
        {
            return $"Tile at ({Position.X}, {Position.Y}) - Type: {Type}, Walkable: {IsWalkable}";
        }
    }
}