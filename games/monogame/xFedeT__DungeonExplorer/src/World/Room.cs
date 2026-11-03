// ============================================
// Room.cs - Represents a room in the dungeon
// ============================================
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace DungeonExplorer.World
{
    /// <summary>
    /// Represents a rectangular room in the dungeon
    /// </summary>
    public class Room
    {
        public int Id { get; set; }
        public int X { get; set; }
        public int Y { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public RoomType Type { get; set; }
        public List<Vector2> Connections { get; private set; }
        public bool IsExplored { get; set; }
        
        public Rectangle Bounds => new Rectangle(X, Y, Width, Height);
        public Vector2 Center => new Vector2(X + Width / 2f, Y + Height / 2f);
        public Vector2 TopLeft => new Vector2(X, Y);
        public Vector2 TopRight => new Vector2(X + Width - 1, Y);
        public Vector2 BottomLeft => new Vector2(X, Y + Height - 1);
        public Vector2 BottomRight => new Vector2(X + Width - 1, Y + Height - 1);

        public Room(int x, int y, int width, int height, int id = 0, RoomType type = RoomType.Normal)
        {
            X = x;
            Y = y;
            Width = width;
            Height = height;
            Id = id;
            Type = type;
            Connections = new List<Vector2>();
            IsExplored = false;
        }

        /// <summary>
        /// Checks if this room overlaps with another room
        /// </summary>
        public bool Overlaps(Room other)
        {
            if (other == null) return false;
            
            return X < other.X + other.Width && 
                   X + Width > other.X && 
                   Y < other.Y + other.Height && 
                   Y + Height > other.Y;
        }

        /// <summary>
        /// Checks if this room overlaps with another room with a buffer
        /// </summary>
        public bool OverlapsWithBuffer(Room other, int buffer = 1)
        {
            if (other == null) return false;
            
            return X - buffer < other.X + other.Width && 
                   X + Width + buffer > other.X && 
                   Y - buffer < other.Y + other.Height && 
                   Y + Height + buffer > other.Y;
        }

        /// <summary>
        /// Checks if a point is inside this room
        /// </summary>
        public bool Contains(int x, int y)
        {
            return x >= X && x < X + Width && y >= Y && y < Y + Height;
        }

        /// <summary>
        /// Checks if a point is inside this room
        /// </summary>
        public bool Contains(Vector2 point)
        {
            return Contains((int)point.X, (int)point.Y);
        }

        /// <summary>
        /// Gets a random position inside the room
        /// </summary>
        public Vector2 GetRandomPosition()
        {
            var random = new Random();
            return new Vector2(
                random.Next(X + 1, X + Width - 1),
                random.Next(Y + 1, Y + Height - 1)
            );
        }
        
        

        /// <summary>
        /// Gets a random position on the edge of the room
        /// </summary>
        public Vector2 GetRandomEdgePosition()
        {
            var random = new Random();
            var side = random.Next(4); // 0=top, 1=right, 2=bottom, 3=left
            
            switch (side)
            {
                case 0: // Top
                    return new Vector2(random.Next(X, X + Width), Y);
                case 1: // Right
                    return new Vector2(X + Width - 1, random.Next(Y, Y + Height));
                case 2: // Bottom
                    return new Vector2(random.Next(X, X + Width), Y + Height - 1);
                case 3: // Left
                    return new Vector2(X, random.Next(Y, Y + Height));
                default:
                    return Center;
            }
        }

        /// <summary>
        /// Calculates the distance to another room (center to center)
        /// </summary>
        public float DistanceTo(Room other)
        {
            if (other == null) return float.MaxValue;
            return Vector2.Distance(Center, other.Center);
        }

        /// <summary>
        /// Gets the closest point on this room to another room
        /// </summary>
        public Vector2 GetClosestPointTo(Room other)
        {
            if (other == null) return Center;
            
            var otherCenter = other.Center;
            var thisCenter = Center;
            
            // Find closest point on edge
            float x = Math.Max(X, Math.Min(otherCenter.X, X + Width - 1));
            float y = Math.Max(Y, Math.Min(otherCenter.Y, Y + Height - 1));
            
            return new Vector2(x, y);
        }

        /// <summary>
        /// Adds a connection point to another room
        /// </summary>
        public void AddConnection(Vector2 connectionPoint)
        {
            if (!Connections.Contains(connectionPoint))
            {
                Connections.Add(connectionPoint);
            }
        }

        /// <summary>
        /// Gets all floor positions in this room
        /// </summary>
        public List<Vector2> GetAllFloorPositions()
        {
            var positions = new List<Vector2>();
            
            for (int x = X; x < X + Width; x++)
            {
                for (int y = Y; y < Y + Height; y++)
                {
                    positions.Add(new Vector2(x, y));
                }
            }
            
            return positions;
        }

        /// <summary>
        /// Gets the perimeter positions of the room
        /// </summary>
        public List<Vector2> GetPerimeterPositions()
        {
            var positions = new List<Vector2>();
            
            // Top and bottom edges
            for (int x = X; x < X + Width; x++)
            {
                positions.Add(new Vector2(x, Y)); // Top
                positions.Add(new Vector2(x, Y + Height - 1)); // Bottom
            }
            
            // Left and right edges (excluding corners already added)
            for (int y = Y + 1; y < Y + Height - 1; y++)
            {
                positions.Add(new Vector2(X, y)); // Left
                positions.Add(new Vector2(X + Width - 1, y)); // Right
            }
            
            return positions;
        }

        /// <summary>
        /// Checks if this room is adjacent to another room
        /// </summary>
        public bool IsAdjacentTo(Room other)
        {
            if (other == null) return false;
            
            // Check if rooms are touching but not overlapping
            bool horizontallyAdjacent = (X + Width == other.X || other.X + other.Width == X) &&
                                       (Y < other.Y + other.Height && Y + Height > other.Y);
            
            bool verticallyAdjacent = (Y + Height == other.Y || other.Y + other.Height == Y) &&
                                     (X < other.X + other.Width && X + Width > other.X);
            
            return horizontallyAdjacent || verticallyAdjacent;
        }

        /// <summary>
        /// Gets the area of the room
        /// </summary>
        public int GetArea()
        {
            return Width * Height;
        }

        /// <summary>
        /// Checks if the room is valid (positive dimensions)
        /// </summary>
        public bool IsValid()
        {
            return Width > 0 && Height > 0;
        }

        public override string ToString()
        {
            return $"Room {Id}: ({X}, {Y}) [{Width}x{Height}] - {Type}";
        }

        public override bool Equals(object obj)
        {
            if (obj is Room other)
            {
                return X == other.X && Y == other.Y && Width == other.Width && Height == other.Height;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(X, Y, Width, Height);
        }
    }

    /// <summary>
    /// Types of rooms that can exist in the dungeon
    /// </summary>
    public enum RoomType
    {
        Normal,
        StartRoom,
        EndRoom,
        TreasureRoom,
        BossRoom,
        SecretRoom
    }
}