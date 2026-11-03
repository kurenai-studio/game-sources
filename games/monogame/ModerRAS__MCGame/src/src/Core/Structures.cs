using Microsoft.Xna.Framework;
using System;

namespace MCGame.Core
{
    /// <summary>
    /// 区块坐标结构
    /// 用于唯一标识世界中的区块位置
    /// </summary>
    public struct ChunkPosition : IEquatable<ChunkPosition>
    {
        public int X { get; set; }
        public int Y { get; set; }
        public int Z { get; set; }

        public ChunkPosition(int x, int y, int z)
        {
            X = x;
            Y = y;
            Z = z;
        }

        public static ChunkPosition FromWorldPosition(Vector3 worldPosition, int chunkSize)
        {
            return new ChunkPosition(
                (int)Math.Floor(worldPosition.X / chunkSize),
                (int)Math.Floor(worldPosition.Y / chunkSize),
                (int)Math.Floor(worldPosition.Z / chunkSize)
            );
        }

        public Vector3 ToWorldPosition(int chunkSize)
        {
            return new Vector3(X * chunkSize, Y * chunkSize, Z * chunkSize);
        }

        public override bool Equals(object? obj)
        {
            return obj is ChunkPosition other && Equals(other);
        }

        public bool Equals(ChunkPosition other)
        {
            return X == other.X && Y == other.Y && Z == other.Z;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(X, Y, Z);
        }

        public static bool operator ==(ChunkPosition left, ChunkPosition right)
        {
            return left.Equals(right);
        }

        public static bool operator !=(ChunkPosition left, ChunkPosition right)
        {
            return !(left == right);
        }

        public override string ToString()
        {
            return $"Chunk({X}, {Y}, {Z})";
        }
    }

    /// <summary>
    /// 方块数据结构（16位紧凑存储）
    /// 性能优化：使用16位而非32位减少50%内存占用
    /// 12位方块类型 + 4位元数据
    /// </summary>
    public struct BlockData : IEquatable<BlockData>
    {
        public ushort Value;

        public BlockType Type => (BlockType)(Value & 0x0FFF);
        public byte Metadata => (byte)(Value >> 12);

        public BlockData(BlockType type, byte metadata = 0)
        {
            // 确保类型在12位范围内
            if ((ushort)type > 0x0FFF)
                throw new ArgumentException($"BlockType {type} exceeds 12-bit limit");

            // 确保元数据在4位范围内
            if (metadata > 0x0F)
                throw new ArgumentException($"Metadata {metadata} exceeds 4-bit limit");

            Value = (ushort)((ushort)type | (metadata << 12));
        }

        public static BlockData Empty => new BlockData(BlockType.Air, 0);

        public override bool Equals(object? obj)
        {
            return obj is BlockData other && Equals(other);
        }

        public bool Equals(BlockData other)
        {
            return Value == other.Value;
        }

        public override int GetHashCode()
        {
            return Value.GetHashCode();
        }

        public static bool operator ==(BlockData left, BlockData right)
        {
            return left.Equals(right);
        }

        public static bool operator !=(BlockData left, BlockData right)
        {
            return !(left == right);
        }

        public override string ToString()
        {
            return $"Block({Type}, Meta:{Metadata})";
        }
    }

    /// <summary>
    /// 方块类型枚举
    /// 支持最多4096种不同类型的方块
    /// </summary>
    public enum BlockType : ushort
    {
        Air = 0,
        Stone = 1,
        Grass = 2,
        Dirt = 3,
        Wood = 4,
        Leaves = 5,
        Water = 6,
        Sand = 7,
        Glass = 8,
        Brick = 9,
        Cobblestone = 10,
        Iron = 11,
        Gold = 12,
        Diamond = 13,
        Coal = 14,
        Bedrock = 15,
        // 可以继续添加更多方块类型...
    }

    /// <summary>
    /// 方向枚举，用于面剔除计算
    /// </summary>
    public enum Direction
    {
        Up,
        Down,
        North,
        South,
        East,
        West
    }

    /// <summary>
    /// 区块状态枚举
    /// 用于追踪区块的生命周期状态
    /// </summary>
    public enum ChunkState
    {
        Unloaded,
        Loading,
        Generating,
        Meshing,
        Ready,
        Unloading
    }

    /// <summary>
    /// 渲染统计信息
    /// 用于性能监控和调试
    /// </summary>
    public struct RenderStatistics
    {
        public int DrawCalls { get; set; }
        public int Triangles { get; set; }
        public int VisibleChunks { get; set; }
        public int TotalChunks { get; set; }
        public float FrameTime { get; set; }
        public int FPS { get; set; }

        public void Reset()
        {
            DrawCalls = 0;
            Triangles = 0;
            VisibleChunks = 0;
            FrameTime = 0;
            FPS = 0;
        }
    }

    /// <summary>
    /// 世界设置结构
    /// 定义世界的基本参数
    /// </summary>
    public struct WorldSettings
    {
        public long Seed { get; set; }
        public int ChunkSize { get; set; }
        public int ChunkHeight { get; set; }
        public int RenderDistance { get; set; }
        public string WorldName { get; set; }
        public bool IsMultiplayer { get; set; }

        public static WorldSettings Default => new WorldSettings
        {
            Seed = DateTime.Now.Ticks,
            ChunkSize = 16,
            ChunkHeight = 256,
            RenderDistance = 10,
            WorldName = "New World",
            IsMultiplayer = false
        };
    }
}