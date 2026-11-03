using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Blocks;
using MCGame.Core;
using MCGame.Chunks;
using MCGame.Utils;
using System;
using System.Collections.Generic;

namespace MCGame.Rendering
{
    /// <summary>
    /// 区块网格生成器
    /// 简化实现：合并区块内所有可见面的顶点数据，大幅减少DrawCall
    /// 原本实现：每个方块面单独渲染
    /// 简化实现：合并整个区块的可见面，大幅减少DrawCall
    /// </summary>
    public class ChunkMesher
    {
        private readonly BlockRegistry _blockRegistry;
        private readonly GraphicsDevice _graphicsDevice;
        
        // 顶点数据缓存
        private readonly List<VertexPositionNormalTexture> _vertices;
        private readonly List<ushort> _indices;
        
        // 性能优化：预分配数组避免频繁GC
        private readonly Vector3[] _faceVertices;
        private readonly Vector3[] _faceNormals;
        private readonly Vector2[] _faceUVs;
        
        // 面剔除优化：缓存可见性数据
        private readonly bool[,,] _visibilityCache;
        private bool _visibilityCacheValid;

        public ChunkMesher(BlockRegistry blockRegistry, GraphicsDevice graphicsDevice)
        {
            _blockRegistry = blockRegistry;
            _graphicsDevice = graphicsDevice;
            
            // 初始化顶点数据列表
            _vertices = new List<VertexPositionNormalTexture>(8192);
            _indices = new List<ushort>(12288);
            
            // 预分配面数据数组
            _faceVertices = new Vector3[4];
            _faceNormals = new Vector3[6];
            _faceUVs = new Vector2[4];
            
            // 初始化面法线
            InitializeFaceNormals();
            
            // 初始化可见性缓存
            _visibilityCache = new bool[Chunk.SIZE, Chunk.HEIGHT, Chunk.SIZE];
            _visibilityCacheValid = false;
        }

        /// <summary>
        /// 初始化面法线
        /// </summary>
        private void InitializeFaceNormals()
        {
            _faceNormals[(int)Direction.Up] = Vector3.Up;
            _faceNormals[(int)Direction.Down] = Vector3.Down;
            _faceNormals[(int)Direction.North] = Vector3.Forward;
            _faceNormals[(int)Direction.South] = Vector3.Backward;
            _faceNormals[(int)Direction.East] = Vector3.Right;
            _faceNormals[(int)Direction.West] = Vector3.Left;
        }

        /// <summary>
        /// 生成区块网格
        /// </summary>
        public ChunkMesh GenerateMesh(Chunk chunk)
        {
            // 清空之前的数据
            _vertices.Clear();
            _indices.Clear();
            
            // 验证可见性缓存
            if (!_visibilityCacheValid)
            {
                UpdateVisibilityCache(chunk);
            }

            int visibleBlocks = 0;
            int visibleFaces = 0;

            // 遍历所有方块，生成可见面
            for (int x = 0; x < Chunk.SIZE; x++)
            {
                for (int y = 0; y < Chunk.HEIGHT; y++)
                {
                    for (int z = 0; z < Chunk.SIZE; z++)
                    {
                        var block = chunk.GetBlock(x, y, z);
                        if (block.Type != BlockType.Air && _blockRegistry.ShouldRenderFace(block.Type))
                        {
                            visibleBlocks++;
                            // 检查六个方向的可见性
                            if (chunk.IsFaceVisible(x, y, z, Direction.Up)) visibleFaces++;
                            if (chunk.IsFaceVisible(x, y, z, Direction.Down)) visibleFaces++;
                            if (chunk.IsFaceVisible(x, y, z, Direction.North)) visibleFaces++;
                            if (chunk.IsFaceVisible(x, y, z, Direction.South)) visibleFaces++;
                            if (chunk.IsFaceVisible(x, y, z, Direction.East)) visibleFaces++;
                            if (chunk.IsFaceVisible(x, y, z, Direction.West)) visibleFaces++;
                            
                            AddVisibleFaces(chunk, x, y, z, block);
                        }
                    }
                }
            }
            
            // 添加详细的调试信息
            Logger.Debug($"Chunk {chunk.Position}: Processing {visibleBlocks} visible blocks with {visibleFaces} visible faces");
            Logger.Debug($"Chunk {chunk.Position}: ShouldRenderFace for Stone = {_blockRegistry.ShouldRenderFace(BlockType.Stone)}");
            Logger.Debug($"Chunk {chunk.Position}: ShouldRenderFace for Grass = {_blockRegistry.ShouldRenderFace(BlockType.Grass)}");
            Logger.Debug($"Chunk {chunk.Position}: ShouldRenderFace for Dirt = {_blockRegistry.ShouldRenderFace(BlockType.Dirt)}");
            Logger.Debug($"Chunk {chunk.Position}: ShouldRenderFace for Air = {_blockRegistry.ShouldRenderFace(BlockType.Air)}");
            
            // 添加调试信息
            if (visibleBlocks == 0)
            {
                Logger.Debug($"Chunk {chunk.Position} has no visible blocks!");
            }
            Logger.Debug($"Chunk {chunk.Position}: {visibleBlocks} visible blocks, {visibleFaces} visible faces, {_vertices.Count} vertices, {_indices.Count} indices");

            // 创建网格对象
            var mesh = new ChunkMesh(_graphicsDevice);
            
            // 添加顶点和索引
            for (int i = 0; i < _vertices.Count; i++)
            {
                mesh.AddVertex(_vertices[i].Position, _vertices[i].Normal, _vertices[i].TextureCoordinate);
            }
            
            for (int i = 0; i < _indices.Count; i += 3)
            {
                if (i + 2 < _indices.Count)
                {
                    mesh.AddTriangle(_indices[i], _indices[i + 1], _indices[i + 2]);
                }
            }
            
            // 构建GPU缓冲区
            mesh.BuildBuffer(_graphicsDevice);
            
            return mesh;
        }

        /// <summary>
        /// 更新可见性缓存
        /// </summary>
        private void UpdateVisibilityCache(Chunk chunk)
        {
            for (int x = 0; x < Chunk.SIZE; x++)
            {
                for (int y = 0; y < Chunk.HEIGHT; y++)
                {
                    for (int z = 0; z < Chunk.SIZE; z++)
                    {
                        var block = chunk.GetBlock(x, y, z);
                        _visibilityCache[x, y, z] = block.Type != BlockType.Air;
                    }
                }
            }
            
            _visibilityCacheValid = true;
        }

        /// <summary>
        /// 添加可见面
        /// </summary>
        private void AddVisibleFaces(Chunk chunk, int x, int y, int z, BlockData block)
        {
            // 检查六个方向的可见性
            if (chunk.IsFaceVisible(x, y, z, Direction.Up))
            {
                AddFace(chunk, x, y, z, Direction.Up, block);
            }
            
            if (chunk.IsFaceVisible(x, y, z, Direction.Down))
            {
                AddFace(chunk, x, y, z, Direction.Down, block);
            }
            
            if (chunk.IsFaceVisible(x, y, z, Direction.North))
            {
                AddFace(chunk, x, y, z, Direction.North, block);
            }
            
            if (chunk.IsFaceVisible(x, y, z, Direction.South))
            {
                AddFace(chunk, x, y, z, Direction.South, block);
            }
            
            if (chunk.IsFaceVisible(x, y, z, Direction.East))
            {
                AddFace(chunk, x, y, z, Direction.East, block);
            }
            
            if (chunk.IsFaceVisible(x, y, z, Direction.West))
            {
                AddFace(chunk, x, y, z, Direction.West, block);
            }
        }

        /// <summary>
        /// 添加单个面
        /// </summary>
        private void AddFace(Chunk chunk, int x, int y, int z, Direction direction, BlockData block)
        {
            // 计算世界坐标
            var worldPos = chunk.Position.ToWorldPosition(Chunk.SIZE);
            var blockWorldPos = worldPos + new Vector3(x, y, z);
            
            // 获取面顶点
            var faceVertices = BlockHelper.GetFaceVertices(direction, blockWorldPos);
            
            // 获取方块颜色
            var blockColor = _blockRegistry.GetBaseColor(block.Type);
            
            // 计算UV坐标
            CalculateFaceUVs(direction);
            
            // 添加面到网格
            AddQuadToMesh(faceVertices, _faceNormals[(int)direction], _faceUVs, blockColor);
            
            // 调试信息：每添加100个面输出一次
            if (_vertices.Count % 400 == 0) // 每个面4个顶点
            {
                Logger.Debug($"Chunk {chunk.Position}: Added face for {block.Type} at ({x},{y},{z}) direction {direction}, total vertices: {_vertices.Count}");
            }
        }

        /// <summary>
        /// 计算面的UV坐标
        /// </summary>
        private void CalculateFaceUVs(Direction direction)
        {
            // 简化实现：所有面使用相同的UV坐标
            _faceUVs[0] = new Vector2(0, 0);
            _faceUVs[1] = new Vector2(1, 0);
            _faceUVs[2] = new Vector2(1, 1);
            _faceUVs[3] = new Vector2(0, 1);
        }

        /// <summary>
        /// 添加四边形到网格
        /// </summary>
        private void AddQuadToMesh(Vector3[] vertices, Vector3 normal, Vector2[] uvs, Color color)
        {
            var startIndex = (ushort)_vertices.Count;
            
            // 添加四个顶点
            for (int i = 0; i < 4; i++)
            {
                var vertexColor = color.ToVector3(); // 简化实现：使用基础颜色
                _vertices.Add(new VertexPositionNormalTexture(
                    vertices[i],
                    normal,
                    uvs[i]
                ));
            }
            
            // 添加两个三角形（逆时针顺序）
            _indices.Add(startIndex);
            _indices.Add((ushort)(startIndex + 1));
            _indices.Add((ushort)(startIndex + 2));
            
            _indices.Add(startIndex);
            _indices.Add((ushort)(startIndex + 2));
            _indices.Add((ushort)(startIndex + 3));
        }

        /// <summary>
        /// 优化网格：合并相邻的相同面
        /// 简化实现：跳过此优化步骤以保持代码简洁
        /// </summary>
        private void OptimizeMesh()
        {
            // 原本实现：复杂的面合并算法
            // 简化实现：直接使用生成的网格，不进行额外优化
            // 这会稍微降低性能但大大简化代码复杂度
        }

        /// <summary>
        /// 检查网格是否有效
        /// </summary>
        private bool ValidateMesh()
        {
            // 检查顶点数量是否在合理范围内
            if (_vertices.Count > 65536)
            {
                Console.WriteLine("Warning: Vertex count exceeds 16-bit limit");
                return false;
            }
            
            // 检查索引数量是否匹配
            if (_indices.Count != _vertices.Count * 3 / 2) // 每个四边形6个索引
            {
                Console.WriteLine("Warning: Index count doesn't match vertex count");
                return false;
            }
            
            return true;
        }

        /// <summary>
        /// 生成网格统计信息
        /// </summary>
        public MeshStats GetMeshStats()
        {
            return new MeshStats
            {
                VertexCount = _vertices.Count,
                IndexCount = _indices.Count,
                TriangleCount = _indices.Count / 3,
                EstimatedMemoryUsage = (_vertices.Count * 32 + _indices.Count * 2) / 1024f // KB
            };
        }

        /// <summary>
        /// 重置网格生成器状态
        /// </summary>
        public void Reset()
        {
            _vertices.Clear();
            _indices.Clear();
            _visibilityCacheValid = false;
        }
    }

    /// <summary>
    /// 网格统计信息
    /// </summary>
    public struct MeshStats
    {
        public int VertexCount { get; set; }
        public int IndexCount { get; set; }
        public int TriangleCount { get; set; }
        public float EstimatedMemoryUsage { get; set; } // KB

        public override string ToString()
        {
            return $"Mesh: {VertexCount} vertices, {TriangleCount} triangles, {EstimatedMemoryUsage:F1}KB";
        }
    }

    /// <summary>
    /// 高级网格生成器（预留）
    /// 支持更复杂的网格优化算法
    /// </summary>
    public class AdvancedChunkMesher : ChunkMesher
    {
        public AdvancedChunkMesher(BlockRegistry blockRegistry, GraphicsDevice graphicsDevice) 
            : base(blockRegistry, graphicsDevice)
        {
        }

        /// <summary>
        /// 生成带有贪婪网格合并优化的区块网格
        /// 原本实现：复杂的贪婪网格合并算法
        /// 简化实现：继承基础实现，暂时不添加复杂优化
        /// </summary>
        public new ChunkMesh GenerateMesh(Chunk chunk)
        {
            // 简化实现：直接使用基础网格生成
            // 在实际项目中，这里可以实现贪婪网格合并算法
            return base.GenerateMesh(chunk);
        }

        /// <summary>
        /// 贪婪网格合并算法
        /// 原本实现：复杂的面合并逻辑
        /// 简化实现：预留接口，暂不实现
        /// </summary>
        private void GreedyMeshMerge(Chunk chunk)
        {
            // 原本实现：遍历所有面，寻找可合并的相邻面
            // 简化实现：跳过此步骤，保持代码简洁
        }
    }

    /// <summary>
    /// 网格优化器
    /// 提供各种网格优化功能
    /// </summary>
    public static class MeshOptimizer
    {
        /// <summary>
        /// 简化网格：移除不可见面
        /// </summary>
        public static void SimplifyMesh(List<VertexPositionNormalTexture> vertices, List<ushort> indices)
        {
            // 简化实现：直接返回，不进行优化
            // 原本实现：复杂的网格简化算法
        }

        /// <summary>
        /// 优化顶点顺序以提高缓存命中率
        /// </summary>
        public static void OptimizeVertexOrder(List<VertexPositionNormalTexture> vertices, List<ushort> indices)
        {
            // 简化实现：直接返回，不进行优化
            // 原本实现：顶点缓存优化算法
        }

        /// <summary>
        /// 合并相同材质的网格
        /// </summary>
        public static void MergeByMaterial(List<RenderBatch> batches)
        {
            // 简化实现：直接返回，不进行优化
            // 原本实现：材质合并算法
        }
    }
}