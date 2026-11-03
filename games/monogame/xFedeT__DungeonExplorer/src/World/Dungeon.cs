using Microsoft.Xna.Framework;
using System.Collections.Generic;
using System.Linq;

namespace DungeonExplorer.World
{
    /// <summary>
    /// Rappresenta un dungeon completo con stanze, corridoi e tile
    /// </summary>
    public class Dungeon
    {
        public int Width { get; private set; }
        public int Height { get; private set; }
        public Tile[,] Tiles { get; private set; }
        public List<Room> Rooms { get; private set; }
        public Vector2 StartPosition { get; private set; }
        public Vector2 EndPosition { get; private set; }
        public bool ShowDebugInfo { get; set; } = false;

        public Dungeon(int width, int height)
        {
            Width = width;
            Height = height;
            Tiles = new Tile[width, height];
            Rooms = new List<Room>();
            
            // Inizializza tutte le tile come muri
            InitializeTiles();
        }

        /// <summary>
        /// Inizializza tutte le tile come muri
        /// </summary>
        private void InitializeTiles()
        {
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    Tiles[x, y] = new Tile(TileType.Wall, x, y);
                }
            }
        }

        /// <summary>
        /// Aggiunge una stanza al dungeon
        /// </summary>
        public void AddRoom(Room room)
        {
            if (room == null) return;

            Rooms.Add(room);

            // Crea le tile del pavimento per la stanza
            for (int x = room.X; x < room.X + room.Width; x++)
            {
                for (int y = room.Y; y < room.Y + room.Height; y++)
                {
                    if (IsValidPosition(x, y))
                    {
                        Tiles[x, y] = new Tile(TileType.Floor, x, y);
                        Tiles[x, y].RoomId = room.Id;
                    }
                }
            }
        }

        /// <summary>
        /// Crea un corridoio tra due punti
        /// </summary>
        public void CreateCorridor(Vector2 start, Vector2 end)
        {
            CreateCorridorBetweenPoints((int)start.X, (int)start.Y, (int)end.X, (int)end.Y);
        }

        /// <summary>
        /// Crea un corridoio a forma di L tra due punti
        /// </summary>
        public void CreateCorridorBetweenPoints(int x1, int y1, int x2, int y2)
        {
            // Corridoio orizzontale
            int startX = System.Math.Min(x1, x2);
            int endX = System.Math.Max(x1, x2);
            
            for (int x = startX; x <= endX; x++)
            {
                if (IsValidPosition(x, y1))
                {
                    Tiles[x, y1] = new Tile(TileType.Floor, x, y1);
                }
            }

            // Corridoio verticale
            int startY = System.Math.Min(y1, y2);
            int endY = System.Math.Max(y1, y2);
            
            for (int y = startY; y <= endY; y++)
            {
                if (IsValidPosition(x2, y))
                {
                    Tiles[x2, y] = new Tile(TileType.Floor, x2, y);
                }
            }
        }

        /// <summary>
        /// Imposta la posizione di inizio del dungeon
        /// </summary>
        public void SetStartPosition(Vector2 position)
        {
            StartPosition = position;
            
            if (IsValidPosition((int)position.X, (int)position.Y))
            {
                Tiles[(int)position.X, (int)position.Y].IsStartPosition = true;
            }
        }

        /// <summary>
        /// Imposta la posizione finale del dungeon
        /// </summary>
        public void SetEndPosition(Vector2 position)
        {
            EndPosition = position;
            
            if (IsValidPosition((int)position.X, (int)position.Y))
            {
                Tiles[(int)position.X, (int)position.Y].IsEndPosition = true;
            }
        }

        /// <summary>
        /// Ottiene la posizione di inizio in coordinate mondo
        /// </summary>
        public Vector2 GetStartPosition()
        {
            return StartPosition;
        }

        /// <summary>
        /// Ottiene tutte le stanze del dungeon
        /// </summary>
        public List<Room> GetRooms()
        {
            return new List<Room>(Rooms);
        }

        /// <summary>
        /// Ottiene la stanza che contiene una specifica posizione
        /// </summary>
        public Room GetRoomAt(Vector2 worldPosition)
        {
            int tileX = (int)(worldPosition.X / 32); // TILE_SIZE
            int tileY = (int)(worldPosition.Y / 32);

            return GetRoomAt(tileX, tileY);
        }

        /// <summary>
        /// Ottiene la stanza che contiene una specifica posizione in coordinate tile
        /// </summary>
        public Room GetRoomAt(int tileX, int tileY)
        {
            foreach (var room in Rooms)
            {
                if (room.Contains(tileX, tileY))
                {
                    return room;
                }
            }
            return null;
        }

        /// <summary>
        /// Controlla se una posizione è valida nel dungeon
        /// </summary>
        public bool IsValidPosition(int x, int y)
        {
            return x >= 0 && x < Width && y >= 0 && y < Height;
        }

        /// <summary>
        /// Controlla se una tile è camminabile
        /// </summary>
        public bool IsWalkable(int x, int y)
        {
            if (!IsValidPosition(x, y)) return false;
            
            var tile = Tiles[x, y];
            return tile != null && (tile.Type == TileType.Floor || tile.Type == TileType.Door);
        }

        /// <summary>
        /// Ottiene la tile in una specifica posizione
        /// </summary>
        public Tile GetTile(int x, int y)
        {
            if (!IsValidPosition(x, y)) return null;
            return Tiles[x, y];
        }

        /// <summary>
        /// Ottiene la tile in una posizione mondiale
        /// </summary>
        public Tile GetTileAtWorldPosition(Vector2 worldPosition)
        {
            int tileX = (int)(worldPosition.X / 32);
            int tileY = (int)(worldPosition.Y / 32);
            return GetTile(tileX, tileY);
        }

        /// <summary>
        /// Ottiene tutti i vicini camminabili di una tile
        /// </summary>
        public List<Tile> GetWalkableNeighbors(int x, int y)
        {
            var neighbors = new List<Tile>();
            
            // Controlla le 4 direzioni principali
            int[] dx = { 0, 1, 0, -1 };
            int[] dy = { -1, 0, 1, 0 };
            
            for (int i = 0; i < 4; i++)
            {
                int nx = x + dx[i];
                int ny = y + dy[i];
                
                if (IsWalkable(nx, ny))
                {
                    neighbors.Add(Tiles[nx, ny]);
                }
            }
            
            return neighbors;
        }

        /// <summary>
        /// Ottiene tutti i vicini di una tile (inclusi i muri)
        /// </summary>
        public List<Tile> GetAllNeighbors(int x, int y)
        {
            var neighbors = new List<Tile>();
            
            for (int dx = -1; dx <= 1; dx++)
            {
                for (int dy = -1; dy <= 1; dy++)
                {
                    if (dx == 0 && dy == 0) continue; // Skip la tile centrale
                    
                    int nx = x + dx;
                    int ny = y + dy;
                    
                    if (IsValidPosition(nx, ny))
                    {
                        neighbors.Add(Tiles[nx, ny]);
                    }
                }
            }
            
            return neighbors;
        }

        /// <summary>
        /// Trova il percorso più breve tra due stanze
        /// </summary>
        public List<Vector2> FindPathBetweenRooms(Room roomA, Room roomB)
        {
            if (roomA == null || roomB == null) return new List<Vector2>();

            // Usa i centri delle stanze come punti di partenza e arrivo
            Vector2 startPoint = roomA.Center;
            Vector2 endPoint = roomB.Center;

            // Implementazione semplificata - in una versione completa useresti A*
            var path = new List<Vector2> { startPoint, endPoint };
            return path;
        }

        /// <summary>
        /// Ottiene una posizione casuale camminabile nel dungeon
        /// </summary>
        public Vector2? GetRandomWalkablePosition()
        {
            var walkablePositions = new List<Vector2>();
            
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    if (IsWalkable(x, y))
                    {
                        walkablePositions.Add(new Vector2(x, y));
                    }
                }
            }
            
            if (walkablePositions.Count > 0)
            {
                var random = new System.Random();
                return walkablePositions[random.Next(walkablePositions.Count)];
            }
            
            return null;
        }

        /// <summary>
        /// Ottiene tutte le posizioni camminabili in una stanza specifica
        /// </summary>
        public List<Vector2> GetWalkablePositionsInRoom(Room room)
        {
            var positions = new List<Vector2>();
            
            if (room == null) return positions;
            
            for (int x = room.X; x < room.X + room.Width; x++)
            {
                for (int y = room.Y; y < room.Y + room.Height; y++)
                {
                    if (IsWalkable(x, y))
                    {
                        positions.Add(new Vector2(x, y));
                    }
                }
            }
            
            return positions;
        }

        /// <summary>
        /// Controlla se due stanze sono connesse da corridoi
        /// </summary>
        public bool AreRoomsConnected(Room roomA, Room roomB)
        {
            // Implementazione semplificata
            // In una versione completa, potresti usare un algoritmo di flood-fill
            // o controllare se esiste un percorso tra le stanze
            
            var pathA = FindPathBetweenRooms(roomA, roomB);
            return pathA.Count > 0;
        }

        /// <summary>
        /// Aggiunge porte tra stanze e corridoi
        /// </summary>
        public void AddDoors()
        {
            foreach (var room in Rooms)
            {
                // Trova i punti dove la stanza si connette ai corridoi
                var doorPositions = FindPotentialDoorPositions(room);
                
                foreach (var doorPos in doorPositions)
                {
                    if (IsValidPosition(doorPos.X, doorPos.Y))
                    {
                        Tiles[doorPos.X, doorPos.Y].Type = TileType.Door;
                    }
                }
            }
        }

        /// <summary>
        /// Trova le posizioni potenziali per le porte di una stanza
        /// </summary>
        private List<Point> FindPotentialDoorPositions(Room room)
        {
            var doorPositions = new List<Point>();
            
            // Controlla i bordi della stanza
            for (int x = room.X; x < room.X + room.Width; x++)
            {
                // Bordo superiore
                if (room.Y > 0 && IsWalkable(x, room.Y - 1))
                {
                    doorPositions.Add(new Point(x, room.Y));
                }
                
                // Bordo inferiore
                if (room.Y + room.Height < Height && IsWalkable(x, room.Y + room.Height))
                {
                    doorPositions.Add(new Point(x, room.Y + room.Height - 1));
                }
            }
            
            for (int y = room.Y; y < room.Y + room.Height; y++)
            {
                // Bordo sinistro
                if (room.X > 0 && IsWalkable(room.X - 1, y))
                {
                    doorPositions.Add(new Point(room.X, y));
                }
                
                // Bordo destro
                if (room.X + room.Width < Width && IsWalkable(room.X + room.Width, y))
                {
                    doorPositions.Add(new Point(room.X + room.Width - 1, y));
                }
            }
            
            return doorPositions;
        }

        /// <summary>
        /// Ottiene statistiche del dungeon per debug
        /// </summary>
        public DungeonStats GetStats()
        {
            int floorTiles = 0;
            int wallTiles = 0;
            int doorTiles = 0;
            
            for (int x = 0; x < Width; x++)
            {
                for (int y = 0; y < Height; y++)
                {
                    switch (Tiles[x, y].Type)
                    {
                        case TileType.Floor:
                            floorTiles++;
                            break;
                        case TileType.Wall:
                            wallTiles++;
                            break;
                        case TileType.Door:
                            doorTiles++;
                            break;
                    }
                }
            }
            
            return new DungeonStats
            {
                TotalRooms = Rooms.Count,
                FloorTiles = floorTiles,
                WallTiles = wallTiles,
                DoorTiles = doorTiles,
                TotalTiles = Width * Height,
                FloorPercentage = (float)floorTiles / (Width * Height) * 100f
            };
        }
    }

    /// <summary>
    /// Struttura per le statistiche del dungeon
    /// </summary>
    public struct DungeonStats
    {
        public int TotalRooms;
        public int FloorTiles;
        public int WallTiles;
        public int DoorTiles;
        public int TotalTiles;
        public float FloorPercentage;
    }
}