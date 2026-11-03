// ============================================
// DungeonGenerator.cs - Generates random dungeons
// ============================================
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;

namespace DungeonExplorer.World
{
    /// <summary>
    /// Generates random dungeons using various algorithms
    /// </summary>
    public class DungeonGenerator
    {
        public int LastSeed { get; private set; }
        private Random _random;
        
        // Generation parameters
        public int MinRoomSize { get; set; } = 4;
        public int MaxRoomSize { get; set; } = 12;
        public int MaxAttempts { get; set; } = 100;
        public float RoomDensity { get; set; } = 0.3f; // Percentage of dungeon that should be rooms

        public DungeonGenerator()
        {
            LastSeed = Environment.TickCount;
            _random = new Random(LastSeed);
        }

        /// <summary>
        /// Generates a new dungeon with the specified parameters
        /// </summary>
        public Dungeon Generate(int width, int height, int minRooms, int maxRooms, int? seed = null)
        {
            if (seed.HasValue)
            {
                LastSeed = seed.Value;
                _random = new Random(LastSeed);
            }
            else
            {
                LastSeed = Environment.TickCount;
                _random = new Random(LastSeed);
            }

            var dungeon = new Dungeon(width, height);
            
            // Generate rooms
            var rooms = GenerateRooms(width, height, minRooms, maxRooms);
            
            // Add rooms to dungeon
            foreach (var room in rooms)
            {
                dungeon.AddRoom(room);
            }
            
            // Connect rooms with corridors
            ConnectRooms(dungeon, rooms);
            
            // Set start and end positions
            SetStartAndEndPositions(dungeon, rooms);
            
            // Add doors
            dungeon.AddDoors();
            
            return dungeon;
        }

        /// <summary>
        /// Generates a list of non-overlapping rooms
        /// </summary>
        private List<Room> GenerateRooms(int dungeonWidth, int dungeonHeight, int minRooms, int maxRooms)
        {
            var rooms = new List<Room>();
            int roomCount = _random.Next(minRooms, maxRooms + 1);
            int attempts = 0;
            int maxTotalAttempts = MaxAttempts * roomCount;

            while (rooms.Count < roomCount && attempts < maxTotalAttempts)
            {
                attempts++;
                
                // Generate random room dimensions
                int width = _random.Next(MinRoomSize, MaxRoomSize + 1);
                int height = _random.Next(MinRoomSize, MaxRoomSize + 1);
                
                // Generate random position
                int x = _random.Next(1, dungeonWidth - width - 1);
                int y = _random.Next(1, dungeonHeight - height - 1);
                
                var newRoom = new Room(x, y, width, height, rooms.Count);
                
                // Check if room overlaps with existing rooms
                bool overlaps = false;
                foreach (var existingRoom in rooms)
                {
                    if (newRoom.OverlapsWithBuffer(existingRoom, 2)) // 2 tile buffer between rooms
                    {
                        overlaps = true;
                        break;
                    }
                }
                
                if (!overlaps)
                {
                    rooms.Add(newRoom);
                }
            }
            
            // Ensure we have at least one room
            if (rooms.Count == 0)
            {
                // Create a fallback room in the center
                int centerX = dungeonWidth / 2 - 3;
                int centerY = dungeonHeight / 2 - 3;
                rooms.Add(new Room(centerX, centerY, 6, 6, 0));
            }
            
            return rooms;
        }

        /// <summary>
        /// Connects all rooms with corridors using a minimum spanning tree approach
        /// </summary>
        private void ConnectRooms(Dungeon dungeon, List<Room> rooms)
        {
            if (rooms.Count <= 1) return;
            
            var connectedRooms = new HashSet<Room> { rooms[0] };
            var unconnectedRooms = new HashSet<Room>(rooms.Skip(1));
            
            while (unconnectedRooms.Count > 0)
            {
                Room closestConnected = null;
                Room closestUnconnected = null;
                float shortestDistance = float.MaxValue;
                
                // Find the shortest connection between connected and unconnected rooms
                foreach (var connected in connectedRooms)
                {
                    foreach (var unconnected in unconnectedRooms)
                    {
                        float distance = connected.DistanceTo(unconnected);
                        if (distance < shortestDistance)
                        {
                            shortestDistance = distance;
                            closestConnected = connected;
                            closestUnconnected = unconnected;
                        }
                    }
                }
                
                // Create corridor between the closest rooms
                if (closestConnected != null && closestUnconnected != null)
                {
                    CreateCorridor(dungeon, closestConnected, closestUnconnected);
                    connectedRooms.Add(closestUnconnected);
                    unconnectedRooms.Remove(closestUnconnected);
                }
            }
            
            // Add some extra connections for more interesting layouts
            AddExtraConnections(dungeon, rooms);
        }

        /// <summary>
        /// Adds additional corridors to create loops and alternative paths
        /// </summary>
        private void AddExtraConnections(Dungeon dungeon, List<Room> rooms)
        {
            int extraConnections = Math.Max(1, rooms.Count / 4); // 25% more connections
            
            for (int i = 0; i < extraConnections; i++)
            {
                var room1 = rooms[_random.Next(rooms.Count)];
                var room2 = rooms[_random.Next(rooms.Count)];
                
                if (room1 != room2 && room1.DistanceTo(room2) < 20) // Only connect nearby rooms
                {
                    CreateCorridor(dungeon, room1, room2);
                }
            }
        }

        /// <summary>
        /// Creates an L-shaped corridor between two rooms
        /// </summary>
        private void CreateCorridor(Dungeon dungeon, Room room1, Room room2)
        {
            var start = room1.GetClosestPointTo(room2);
            var end = room2.GetClosestPointTo(room1);
            
            // Choose random direction for the L-shape (horizontal first or vertical first)
            if (_random.Next(2) == 0)
            {
                // Horizontal first, then vertical
                dungeon.CreateCorridorBetweenPoints((int)start.X, (int)start.Y, (int)end.X, (int)start.Y);
                dungeon.CreateCorridorBetweenPoints((int)end.X, (int)start.Y, (int)end.X, (int)end.Y);
            }
            else
            {
                // Vertical first, then horizontal
                dungeon.CreateCorridorBetweenPoints((int)start.X, (int)start.Y, (int)start.X, (int)end.Y);
                dungeon.CreateCorridorBetweenPoints((int)start.X, (int)end.Y, (int)end.X, (int)end.Y);
            }
            
            // Mark connection points
            room1.AddConnection(start);
            room2.AddConnection(end);
        }

        /// <summary>
        /// Sets the start position in the first room and end position in the last room
        /// </summary>
        private void SetStartAndEndPositions(Dungeon dungeon, List<Room> rooms)
        {
            if (rooms.Count == 0) return;
            
            // Start position in the first room
            var startRoom = rooms[0];
            startRoom.Type = RoomType.StartRoom;
            dungeon.SetStartPosition(startRoom.GetRandomPosition());
            
            // End position in the room farthest from start
            if (rooms.Count > 1)
            {
                Room endRoom = rooms[1];
                float maxDistance = 0;
                
                foreach (var room in rooms.Skip(1))
                {
                    float distance = startRoom.DistanceTo(room);
                    if (distance > maxDistance)
                    {
                        maxDistance = distance;
                        endRoom = room;
                    }
                }
                
                endRoom.Type = RoomType.EndRoom;
                dungeon.SetEndPosition(endRoom.GetRandomPosition());
            }
        }

        /// <summary>
        /// Generates a dungeon using cellular automata (for more organic caves)
        /// </summary>
        public Dungeon GenerateCavelike(int width, int height, float wallProbability = 0.45f, int iterations = 5)
        {
            var dungeon = new Dungeon(width, height);
            
            // Initialize with random walls
            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    if (x == 0 || x == width - 1 || y == 0 || y == height - 1)
                    {
                        // Keep borders as walls
                        dungeon.Tiles[x, y] = new Tile(TileType.Wall, x, y);
                    }
                    else if (_random.NextDouble() < wallProbability)
                    {
                        dungeon.Tiles[x, y] = new Tile(TileType.Wall, x, y);
                    }
                    else
                    {
                        dungeon.Tiles[x, y] = new Tile(TileType.Floor, x, y);
                    }
                }
            }
            
            // Apply cellular automata rules
            for (int iteration = 0; iteration < iterations; iteration++)
            {
                ApplyCellularAutomataRules(dungeon);
            }
            
            // Find and connect the largest open areas
            var openAreas = FindOpenAreas(dungeon);
            if (openAreas.Count > 0)
            {
                ConnectOpenAreas(dungeon, openAreas);
                
                // Set start and end positions
                var startArea = openAreas[0];
                var endArea = openAreas[openAreas.Count - 1];
                
                dungeon.SetStartPosition(GetRandomPositionInArea(startArea));
                dungeon.SetEndPosition(GetRandomPositionInArea(endArea));
            }
            
            return dungeon;
        }

        private void ApplyCellularAutomataRules(Dungeon dungeon)
        {
            var newTiles = new Tile[dungeon.Width, dungeon.Height];
            
            for (int x = 0; x < dungeon.Width; x++)
            {
                for (int y = 0; y < dungeon.Height; y++)
                {
                    int neighborWalls = CountNeighborWalls(dungeon, x, y);
                    
                    if (neighborWalls > 4)
                    {
                        newTiles[x, y] = new Tile(TileType.Wall, x, y);
                    }
                    else
                    {
                        newTiles[x, y] = new Tile(TileType.Floor, x, y);
                    }
                }
            }
            
            for (var x = 0; x < dungeon.Width; x++)
            {
                for (var y = 0; y < dungeon.Height; y++)
                {
                    dungeon.Tiles[x, y] = newTiles[x, y];
                }
            }
        }

        private int CountNeighborWalls(Dungeon dungeon, int x, int y)
        {
            int wallCount = 0;
            
            for (int nx = x - 1; nx <= x + 1; nx++)
            {
                for (int ny = y - 1; ny <= y + 1; ny++)
                {
                    if (nx == x && ny == y) continue;
                    
                    if (!dungeon.IsValidPosition(nx, ny) || dungeon.Tiles[nx, ny].Type == TileType.Wall)
                    {
                        wallCount++;
                    }
                }
            }
            
            return wallCount;
        }

        private List<List<Vector2>> FindOpenAreas(Dungeon dungeon)
        {
            var visited = new bool[dungeon.Width, dungeon.Height];
            var areas = new List<List<Vector2>>();
            
            for (int x = 0; x < dungeon.Width; x++)
            {
                for (int y = 0; y < dungeon.Height; y++)
                {
                    if (!visited[x, y] && dungeon.IsWalkable(x, y))
                    {
                        var area = FloodFill(dungeon, x, y, visited);
                        if (area.Count > 10) // Only keep areas with at least 10 tiles
                        {
                            areas.Add(area);
                        }
                    }
                }
            }
            
            // Sort areas by size (largest first)
            areas.Sort((a, b) => b.Count.CompareTo(a.Count));
            
            return areas;
        }

        private List<Vector2> FloodFill(Dungeon dungeon, int startX, int startY, bool[,] visited)
        {
            var area = new List<Vector2>();
            var stack = new Stack<Vector2>();
            stack.Push(new Vector2(startX, startY));
            
            while (stack.Count > 0)
            {
                var current = stack.Pop();
                int x = (int)current.X;
                int y = (int)current.Y;
                
                if (visited[x, y] || !dungeon.IsWalkable(x, y))
                    continue;
                
                visited[x, y] = true;
                area.Add(current);
                
                // Add neighbors
                for (int dx = -1; dx <= 1; dx++)
                {
                    for (int dy = -1; dy <= 1; dy++)
                    {
                        if (dx == 0 && dy == 0) continue;
                        
                        int nx = x + dx;
                        int ny = y + dy;
                        
                        if (dungeon.IsValidPosition(nx, ny) && !visited[nx, ny] && dungeon.IsWalkable(nx, ny))
                        {
                            stack.Push(new Vector2(nx, ny));
                        }
                    }
                }
            }
            
            return area;
        }

        private void ConnectOpenAreas(Dungeon dungeon, List<List<Vector2>> areas)
        {
            for (int i = 0; i < areas.Count - 1; i++)
            {
                var area1 = areas[i];
                var area2 = areas[i + 1];
                
                // Find closest points between areas
                Vector2 closestPoint1 = area1[0];
                Vector2 closestPoint2 = area2[0];
                float shortestDistance = Vector2.Distance(closestPoint1, closestPoint2);
                
                foreach (var point1 in area1)
                {
                    foreach (var point2 in area2)
                    {
                        float distance = Vector2.Distance(point1, point2);
                        if (distance < shortestDistance)
                        {
                            shortestDistance = distance;
                            closestPoint1 = point1;
                            closestPoint2 = point2;
                        }
                    }
                }
                
                // Create corridor between closest points
                dungeon.CreateCorridorBetweenPoints(
                    (int)closestPoint1.X, (int)closestPoint1.Y,
                    (int)closestPoint2.X, (int)closestPoint2.Y
                );
            }
        }

        private Vector2 GetRandomPositionInArea(List<Vector2> area)
        {
            return area[_random.Next(area.Count)];
        }

        /// <summary>
        /// Validates that a generated dungeon meets basic requirements
        /// </summary>
        public bool ValidateDungeon(Dungeon dungeon)
        {
            // Check that there's a path from start to end
            if (dungeon.StartPosition == Vector2.Zero || dungeon.EndPosition == Vector2.Zero)
                return false;
            
            // Check that there are walkable tiles
            bool hasWalkableTiles = false;
            for (int x = 0; x < dungeon.Width; x++)
            {
                for (int y = 0; y < dungeon.Height; y++)
                {
                    if (dungeon.IsWalkable(x, y))
                    {
                        hasWalkableTiles = true;
                        break;
                    }
                }
                if (hasWalkableTiles) break;
            }
            
            return hasWalkableTiles;
        }
    }
}