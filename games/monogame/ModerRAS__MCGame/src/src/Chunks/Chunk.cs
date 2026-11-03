using Microsoft.Xna.Framework;
using MCGame.Core;
using MCGame.Rendering;
using MCGame.Blocks;
using MCGame.WorldGeneration;
using MCGame.Utils;
using System;
using System.Collections.Generic;

namespace MCGame.Chunks
{
    /// <summary>
    /// 区块类
    /// 管理单个区块的方块数据和网格
    /// 简化实现：使用3D数组存储方块数据，支持基本的网格生成
    /// </summary>
    public class Chunk
    {
        // 区块常量
        public const int SIZE = 16;
        public const int HEIGHT = 256;
        public const int VOLUME = SIZE * SIZE * HEIGHT;

        // 区块属性
        public ChunkPosition Position { get; set; }
        public ChunkState State { get; set; }
        public bool IsDirty { get; set; }
        public bool IsLoaded { get; set; }
        public bool IsMeshGenerated { get; set; }

        // 方块数据（16位紧凑存储，节省50%内存）
        private readonly BlockData[,,] _blocks;

        // 网格数据
        public ChunkMesh Mesh { get; set; }
        public BoundingBox Bounds { get; private set; }

        // 邻近区块引用
        public Chunk[,,] Neighbors { get; private set; }

        // 性能优化：可见面缓存
        private readonly bool[,,] _visibleFaces;
        private bool _visibilityCacheValid;

        /// <summary>
        /// 构造函数
        /// </summary>
        public Chunk(ChunkPosition position)
        {
            Position = position;
            State = ChunkState.Unloaded;
            IsDirty = false;
            IsLoaded = false;
            IsMeshGenerated = false;
            _visibilityCacheValid = false;

            // 初始化方块数据数组
            _blocks = new BlockData[SIZE, HEIGHT, SIZE];
            
            // 初始化可见面缓存
            _visibleFaces = new bool[SIZE, HEIGHT, SIZE];
            
            // 初始化邻近区块数组
            Neighbors = new Chunk[3, 3, 3];

            // 计算区块边界框
            CalculateBounds();

            // 填充空气方块
            FillWithAir();
        }

        /// <summary>
        /// 计算区块边界框
        /// </summary>
        private void CalculateBounds()
        {
            var worldPos = Position.ToWorldPosition(SIZE);
            var min = worldPos;
            var max = worldPos + new Vector3(SIZE, HEIGHT, SIZE);
            Bounds = new BoundingBox(min, max);
        }

        /// <summary>
        /// 填充空气方块
        /// </summary>
        private void FillWithAir()
        {
            for (int x = 0; x < SIZE; x++)
            {
                for (int y = 0; y < HEIGHT; y++)
                {
                    for (int z = 0; z < SIZE; z++)
                    {
                        _blocks[x, y, z] = BlockData.Empty;
                    }
                }
            }
        }

        /// <summary>
        /// 获取方块数据
        /// </summary>
        public BlockData GetBlock(int x, int y, int z)
        {
            if (IsOutOfBounds(x, y, z))
            {
                return BlockData.Empty;
            }

            return _blocks[x, y, z];
        }

        /// <summary>
        /// 设置方块数据
        /// </summary>
        public void SetBlock(int x, int y, int z, BlockData block)
        {
            if (IsOutOfBounds(x, y, z))
            {
                return;
            }

            var oldBlock = _blocks[x, y, z];
            if (oldBlock != block)
            {
                _blocks[x, y, z] = block;
                IsDirty = true;
                _visibilityCacheValid = false;

                // 标记邻近区块也需要更新
                MarkNeighborsForUpdate(x, y, z);
            }
        }

        /// <summary>
        /// 检查坐标是否越界
        /// </summary>
        private bool IsOutOfBounds(int x, int y, int z)
        {
            return x < 0 || x >= SIZE || y < 0 || y >= HEIGHT || z < 0 || z >= SIZE;
        }

        /// <summary>
        /// 标记邻近区块需要更新
        /// </summary>
        private void MarkNeighborsForUpdate(int x, int y, int z)
        {
            // 检查是否在边界上
            if (x == 0 && Neighbors[0, 1, 1] != null)
                Neighbors[0, 1, 1].IsDirty = true;
            if (x == SIZE - 1 && Neighbors[2, 1, 1] != null)
                Neighbors[2, 1, 1].IsDirty = true;
            if (z == 0 && Neighbors[1, 1, 0] != null)
                Neighbors[1, 1, 0].IsDirty = true;
            if (z == SIZE - 1 && Neighbors[1, 1, 2] != null)
                Neighbors[1, 1, 2].IsDirty = true;
        }

        /// <summary>
        /// 获取世界坐标中的方块
        /// </summary>
        public BlockData GetBlockWorld(Vector3 worldPosition)
        {
            var localPos = WorldToLocal(worldPosition);
            return GetBlock(localPos.X, localPos.Y, localPos.Z);
        }

        /// <summary>
        /// 设置世界坐标中的方块
        /// </summary>
        public void SetBlockWorld(Vector3 worldPosition, BlockData block)
        {
            var localPos = WorldToLocal(worldPosition);
            SetBlock(localPos.X, localPos.Y, localPos.Z, block);
        }

        /// <summary>
        /// 世界坐标转换为本地坐标
        /// </summary>
        private Vector3Int WorldToLocal(Vector3 worldPosition)
        {
            var chunkWorldPos = Position.ToWorldPosition(SIZE);
            var localPos = worldPosition - chunkWorldPos;
            
            return new Vector3Int(
                (int)Math.Floor(localPos.X),
                (int)Math.Floor(localPos.Y),
                (int)Math.Floor(localPos.Z)
            );
        }

        /// <summary>
        /// 生成分形地形
        /// 简化实现：使用柏林噪声生成器生成地形
        /// </summary>
        public void GenerateTerrain(long seed)
        {
            // 使用柏林噪声生成器
            var worldGenerator = new WorldGenerator((int)seed);
            var chunkData = worldGenerator.GenerateChunk(Position.X, Position.Z, SIZE);
            
            // 将生成的数据转换为方块数据
            int nonAirBlocks = 0;
            for (int x = 0; x < SIZE; x++)
            {
                for (int y = 0; y < HEIGHT; y++)
                {
                    for (int z = 0; z < SIZE; z++)
                    {
                        var blockType = (BlockType)chunkData[x, y, z];
                        _blocks[x, y, z] = new BlockData(blockType, 0);
                        
                        if (blockType != BlockType.Air)
                        {
                            nonAirBlocks++;
                        }
                    }
                }
            }
            
            IsDirty = true;
            
            // 添加调试信息
            Logger.Debug($"Chunk {Position}: Generated {nonAirBlocks} non-air blocks out of {VOLUME} total blocks");
        }

        
        /// <summary>
        /// 更新邻近区块引用
        /// </summary>
        public void UpdateNeighbors(Chunk[,,] neighbors)
        {
            Neighbors = neighbors;
            _visibilityCacheValid = false;
        }

        /// <summary>
        /// 获取邻近方块
        /// </summary>
        public BlockData GetNeighborBlock(int x, int y, int z, Direction direction)
        {
            var neighborX = x;
            var neighborY = y;
            var neighborZ = z;

            // 计算邻近坐标
            switch (direction)
            {
                case Direction.Up:
                    neighborY++;
                    break;
                case Direction.Down:
                    neighborY--;
                    break;
                case Direction.North:
                    neighborZ--;
                    break;
                case Direction.South:
                    neighborZ++;
                    break;
                case Direction.East:
                    neighborX++;
                    break;
                case Direction.West:
                    neighborX--;
                    break;
            }

            // 检查是否在当前区块内
            if (neighborX >= 0 && neighborX < SIZE && 
                neighborY >= 0 && neighborY < HEIGHT && 
                neighborZ >= 0 && neighborZ < SIZE)
            {
                return GetBlock(neighborX, neighborY, neighborZ);
            }

            // 检查邻近区块
            var neighborChunk = GetNeighborChunk(direction);
            if (neighborChunk != null)
            {
                // 转换为邻近区块的本地坐标
                switch (direction)
                {
                    case Direction.Up:
                        if (neighborY < HEIGHT)
                            return neighborChunk.GetBlock(neighborX, neighborY, neighborZ);
                        else
                            return BlockData.Empty;
                    case Direction.Down:
                        if (neighborY >= 0)
                            return neighborChunk.GetBlock(neighborX, neighborY, neighborZ);
                        else
                            return BlockData.Empty;
                    case Direction.North:
                        return neighborChunk.GetBlock(neighborX, neighborY, SIZE - 1);
                    case Direction.South:
                        return neighborChunk.GetBlock(neighborX, neighborY, 0);
                    case Direction.East:
                        return neighborChunk.GetBlock(0, neighborY, neighborZ);
                    case Direction.West:
                        return neighborChunk.GetBlock(SIZE - 1, neighborY, neighborZ);
                }
            }

            return BlockData.Empty;
        }

        /// <summary>
        /// 获取邻近区块
        /// </summary>
        private Chunk GetNeighborChunk(Direction direction)
        {
            return direction switch
            {
                Direction.Up => Neighbors[1, 2, 1],
                Direction.Down => Neighbors[1, 0, 1],
                Direction.North => Neighbors[1, 1, 0],
                Direction.South => Neighbors[1, 1, 2],
                Direction.East => Neighbors[2, 1, 1],
                Direction.West => Neighbors[0, 1, 1],
                _ => null
            };
        }

        /// <summary>
        /// 检查方块面是否可见
        /// </summary>
        public bool IsFaceVisible(int x, int y, int z, Direction direction)
        {
            var currentBlock = GetBlock(x, y, z);
            var neighborBlock = GetNeighborBlock(x, y, z, direction);
            
            return BlockHelper.IsFaceVisible(currentBlock.Type, neighborBlock.Type, direction);
        }

        /// <summary>
        /// 获取所有需要更新的方块
        /// </summary>
        public List<Vector3Int> GetDirtyBlocks()
        {
            var dirtyBlocks = new List<Vector3Int>();
            
            for (int x = 0; x < SIZE; x++)
            {
                for (int y = 0; y < HEIGHT; y++)
                {
                    for (int z = 0; z < SIZE; z++)
                    {
                        if (_blocks[x, y, z].Type != BlockType.Air)
                        {
                            dirtyBlocks.Add(new Vector3Int(x, y, z));
                        }
                    }
                }
            }
            
            return dirtyBlocks;
        }

        /// <summary>
        /// 重置区块状态
        /// </summary>
        public void Reset()
        {
            FillWithAir();
            IsDirty = false;
            IsMeshGenerated = false;
            _visibilityCacheValid = false;
            Mesh = null;
        }

        /// <summary>
        /// 卸载区块
        /// </summary>
        public void Unload()
        {
            State = ChunkState.Unloaded;
            IsLoaded = false;
            Mesh?.Dispose();
            Mesh = null;
        }
    }

    /// <summary>
    /// 3D整数向量结构
    /// 用于表示方块坐标
    /// </summary>
    public struct Vector3Int
    {
        public int X { get; set; }
        public int Y { get; set; }
        public int Z { get; set; }

        public Vector3Int(int x, int y, int z)
        {
            X = x;
            Y = y;
            Z = z;
        }

        public static Vector3Int operator +(Vector3Int a, Vector3Int b)
        {
            return new Vector3Int(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
        }

        public static Vector3Int operator -(Vector3Int a, Vector3Int b)
        {
            return new Vector3Int(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
        }

        public static implicit operator Vector3(Vector3Int v)
        {
            return new Vector3(v.X, v.Y, v.Z);
        }

        public override string ToString()
        {
            return $"({X}, {Y}, {Z})";
        }
    }
}