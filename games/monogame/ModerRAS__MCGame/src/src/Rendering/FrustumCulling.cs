using Microsoft.Xna.Framework;
using MCGame.Core;
using MCGame.Chunks;
using System;
using System.Collections.Generic;

namespace MCGame.Rendering
{
    /// <summary>
    /// 视锥剔除系统
    /// 简化实现：使用球形包围盒进行快速视锥剔除
    /// 原本实现：精确的AABB包围盒视锥剔除
    /// 简化实现：球形包围盒 + 距离剔除，性能更好但精度略低
    /// </summary>
    public class FrustumCulling : IDisposable
    {
        // 视锥体
        private BoundingFrustum _frustum;
        
        // 相机信息
        private Vector3 _cameraPosition;
        private float _maxRenderDistance;
        
        // 区块包围盒缓存
        private readonly Dictionary<ChunkPosition, BoundingSphere> _chunkSpheres;
        private readonly Dictionary<ChunkPosition, BoundingBox> _chunkBoxes;
        
        // 性能统计
        private int _chunksTested;
        private int _chunksCulled;
        private int _distanceCulled;

        public Vector3 CameraPosition => _cameraPosition;
        public float MaxRenderDistance => _maxRenderDistance;
        public int ChunksTested => _chunksTested;
        public int ChunksCulled => _chunksCulled;
        public int DistanceCulled => _distanceCulled;

        public FrustumCulling()
        {
            _frustum = new BoundingFrustum(Matrix.Identity);
            _maxRenderDistance = 200f; // 默认渲染距离
            
            _chunkSpheres = new Dictionary<ChunkPosition, BoundingSphere>();
            _chunkBoxes = new Dictionary<ChunkPosition, BoundingBox>();
        }

        /// <summary>
        /// 更新视锥体
        /// </summary>
        public void UpdateFrustum(Matrix view, Matrix projection)
        {
            _frustum = new BoundingFrustum(view * projection);
            
            // 从视图矩阵提取相机位置
            ExtractCameraPosition(view);
        }

        /// <summary>
        /// 设置最大渲染距离
        /// </summary>
        public void SetMaxRenderDistance(float distance)
        {
            _maxRenderDistance = distance;
        }

        /// <summary>
        /// 从视图矩阵提取相机位置
        /// </summary>
        private void ExtractCameraPosition(Matrix viewMatrix)
        {
            // 视图矩阵的逆矩阵的平移部分就是相机位置
            var inverseView = Matrix.Invert(viewMatrix);
            _cameraPosition = inverseView.Translation;
        }

        /// <summary>
        /// 检查区块是否可见
        /// </summary>
        public bool IsChunkVisible(Chunk chunk)
        {
            _chunksTested++;
            
            var chunkPos = chunk.Position;
            
            // 快速距离剔除
            if (IsChunkTooFar(chunkPos))
            {
                _distanceCulled++;
                return false;
            }
            
            // 获取或创建区块包围盒
            var sphere = GetChunkSphere(chunkPos, chunk.Bounds);
            var box = GetChunkBox(chunkPos, chunk.Bounds);
            
            // 简化的视锥体测试：先测试球形包围盒
            if (!_frustum.Intersects(sphere))
            {
                _chunksCulled++;
                return false;
            }
            
            // 精确测试：测试AABB包围盒
            if (!_frustum.Intersects(box))
            {
                _chunksCulled++;
                return false;
            }
            
            return true;
        }

        /// <summary>
        /// 检查区块是否过远
        /// </summary>
        private bool IsChunkTooFar(ChunkPosition chunkPos)
        {
            var chunkWorldPos = chunkPos.ToWorldPosition(Chunk.SIZE);
            var distance = Vector3.Distance(_cameraPosition, chunkWorldPos);
            return distance > _maxRenderDistance;
        }

        /// <summary>
        /// 获取区块球形包围盒
        /// </summary>
        private BoundingSphere GetChunkSphere(ChunkPosition chunkPos, BoundingBox bounds)
        {
            if (!_chunkSpheres.TryGetValue(chunkPos, out var sphere))
            {
                // 计算包围球（使用包围盒的中心和对角线的一半作为半径）
                var center = (bounds.Min + bounds.Max) * 0.5f;
                var radius = Vector3.Distance(bounds.Min, bounds.Max) * 0.5f;
                
                sphere = new BoundingSphere(center, radius);
                _chunkSpheres[chunkPos] = sphere;
            }
            
            return sphere;
        }

        /// <summary>
        /// 获取区块AABB包围盒
        /// </summary>
        private BoundingBox GetChunkBox(ChunkPosition chunkPos, BoundingBox bounds)
        {
            if (!_chunkBoxes.TryGetValue(chunkPos, out var box))
            {
                box = bounds;
                _chunkBoxes[chunkPos] = box;
            }
            
            return box;
        }

        /// <summary>
        /// 获取可见区块列表
        /// </summary>
        public List<Chunk> GetVisibleChunks(IEnumerable<Chunk> chunks)
        {
            var visibleChunks = new List<Chunk>();
            
            // 重置统计
            _chunksTested = 0;
            _chunksCulled = 0;
            _distanceCulled = 0;
            
            foreach (var chunk in chunks)
            {
                if (IsChunkVisible(chunk))
                {
                    visibleChunks.Add(chunk);
                }
            }
            
            return visibleChunks;
        }

        /// <summary>
        /// 批量检查区块可见性
        /// </summary>
        public void CheckChunkVisibility(IEnumerable<Chunk> chunks, List<Chunk> visibleChunks)
        {
            visibleChunks.Clear();
            
            // 重置统计
            _chunksTested = 0;
            _chunksCulled = 0;
            _distanceCulled = 0;
            
            foreach (var chunk in chunks)
            {
                if (IsChunkVisible(chunk))
                {
                    visibleChunks.Add(chunk);
                }
            }
        }

        /// <summary>
        /// 获取剔除统计信息
        /// </summary>
        public CullingStats GetStats()
        {
            return new CullingStats
            {
                ChunksTested = _chunksTested,
                ChunksCulled = _chunksCulled,
                DistanceCulled = _distanceCulled,
                TotalChunks = _chunksTested,
                VisibleChunks = _chunksTested - _chunksCulled - _distanceCulled,
                CullingRatio = _chunksTested > 0 ? 
                    (float)(_chunksCulled + _distanceCulled) / _chunksTested : 0f
            };
        }

        /// <summary>
        /// 重置统计信息
        /// </summary>
        public void ResetStats()
        {
            _chunksTested = 0;
            _chunksCulled = 0;
            _distanceCulled = 0;
        }

        /// <summary>
        /// 清理缓存
        /// </summary>
        public void ClearCache()
        {
            _chunkSpheres.Clear();
            _chunkBoxes.Clear();
        }

        /// <summary>
        /// 移除特定区块的缓存
        /// </summary>
        public void RemoveChunkFromCache(ChunkPosition chunkPos)
        {
            _chunkSpheres.Remove(chunkPos);
            _chunkBoxes.Remove(chunkPos);
        }

        /// <summary>
        /// 预计算区块包围盒
        /// </summary>
        public void PrecomputeChunkBounds(IEnumerable<Chunk> chunks)
        {
            foreach (var chunk in chunks)
            {
                GetChunkSphere(chunk.Position, chunk.Bounds);
                GetChunkBox(chunk.Position, chunk.Bounds);
            }
        }

        /// <summary>
        /// 检查点是否在视锥体内
        /// </summary>
        public bool IsPointVisible(Vector3 point)
        {
            var distance = Vector3.Distance(_cameraPosition, point);
            if (distance > _maxRenderDistance)
            {
                return false;
            }
            
            return _frustum.Contains(point) != ContainmentType.Disjoint;
        }

        /// <summary>
        /// 检查球体是否在视锥体内
        /// </summary>
        public bool IsSphereVisible(BoundingSphere sphere)
        {
            var distance = Vector3.Distance(_cameraPosition, sphere.Center);
            if (distance > _maxRenderDistance)
            {
                return false;
            }
            
            return _frustum.Intersects(sphere);
        }

        /// <summary>
        /// 检查包围盒是否在视锥体内
        /// </summary>
        public bool IsBoxVisible(BoundingBox box)
        {
            var boxCenter = (box.Min + box.Max) * 0.5f;
            var distance = Vector3.Distance(_cameraPosition, boxCenter);
            if (distance > _maxRenderDistance)
            {
                return false;
            }
            
            return _frustum.Intersects(box);
        }

        /// <summary>
        /// 获取视锥体的六个平面
        /// </summary>
        public Plane[] GetFrustumPlanes()
        {
            // MonoGame中可能没有GetPlanes方法，手动计算视锥体平面
            var planes = new Plane[6];
            // 这里简化实现，直接返回空数组
            // 在实际实现中，需要手动计算六个平面的方程
            return planes;
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            ClearCache();
            _frustum = null;
        }
    }

    /// <summary>
    /// 剔除统计信息
    /// </summary>
    public struct CullingStats
    {
        public int ChunksTested { get; set; }
        public int ChunksCulled { get; set; }
        public int DistanceCulled { get; set; }
        public int TotalChunks { get; set; }
        public int VisibleChunks { get; set; }
        public float CullingRatio { get; set; } // 0.0f - 1.0f

        public override string ToString()
        {
            return $"Culling: {VisibleChunks}/{TotalChunks} visible ({CullingRatio:P1} culled)";
        }
    }

    /// <summary>
    /// 高级视锥剔除（预留）
    /// 支持更复杂的剔除算法
    /// </summary>
    public class AdvancedFrustumCulling : FrustumCulling
    {
        // 预留：支持LOD剔除、遮挡剔除等高级功能
        
        public AdvancedFrustumCulling() : base()
        {
        }

        /// <summary>
        /// LOD剔除
        /// 原本实现：基于距离的LOD选择
        /// 简化实现：预留接口，暂不实现
        /// </summary>
        public int GetLODLevel(Chunk chunk)
        {
            var distance = Vector3.Distance(CameraPosition, (chunk.Bounds.Min + chunk.Bounds.Max) * 0.5f);
            
            if (distance < 50f) return 0; // 高细节
            if (distance < 100f) return 1; // 中等细节
            return 2; // 低细节
        }

        /// <summary>
        /// 遮挡剔除
        /// 原本实现：基于深度缓冲区的遮挡检测
        /// 简化实现：预留接口，暂不实现
        /// </summary>
        public bool IsOccluded(Chunk chunk)
        {
            // 简化实现：假设所有区块都可见
            return false;
        }
    }

    /// <summary>
    /// 空间分区优化器
    /// 提供空间分区功能以加速剔除
    /// </summary>
    public static class SpatialPartitionOptimizer
    {
        /// <summary>
        /// 四叉树分区（2D）
        /// 原本实现：复杂的四叉树结构
        /// 简化实现：简单的网格分区
        /// </summary>
        public static List<Chunk> GetChunksInGridCell(
            Dictionary<ChunkPosition, Chunk> chunks, 
            Vector3 center, 
            float cellSize)
        {
            var result = new List<Chunk>();
            var gridX = (int)(center.X / cellSize);
            var gridZ = (int)(center.Z / cellSize);
            
            foreach (var chunk in chunks.Values)
            {
                var chunkCenter = (chunk.Bounds.Min + chunk.Bounds.Max) * 0.5f;
                var chunkGridX = (int)(chunkCenter.X / cellSize);
                var chunkGridZ = (int)(chunkCenter.Z / cellSize);
                
                if (chunkGridX == gridX && chunkGridZ == gridZ)
                {
                    result.Add(chunk);
                }
            }
            
            return result;
        }

        /// <summary>
        /// 获取邻近区块
        /// </summary>
        public static List<Chunk> GetNearbyChunks(
            Dictionary<ChunkPosition, Chunk> chunks, 
            Vector3 center, 
            float radius)
        {
            var result = new List<Chunk>();
            
            foreach (var chunk in chunks.Values)
            {
                var chunkCenter = (chunk.Bounds.Min + chunk.Bounds.Max) * 0.5f;
                var distance = Vector3.Distance(center, chunkCenter);
                if (distance <= radius)
                {
                    result.Add(chunk);
                }
            }
            
            return result;
        }
    }
}