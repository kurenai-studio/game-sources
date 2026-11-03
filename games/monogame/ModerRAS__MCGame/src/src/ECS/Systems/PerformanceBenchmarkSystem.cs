using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using System.Diagnostics;
using System.Collections.Generic;

namespace MCGame.ECS.Systems
{
    /// <summary>
    /// 性能基准测试系统
    /// 对比传统系统和ECS系统的性能差异
    /// 简化实现：基本的性能统计和对比
    /// </summary>
    public class PerformanceBenchmarkSystem : QuerySystem<PerformanceMarker>
    {
        private readonly Stopwatch _benchmarkStopwatch;
        private readonly Dictionary<string, long> _benchmarkResults;
        private int _benchmarkIteration;
        
        // 性能统计
        private long _totalUpdateTime;
        private long _totalRenderTime;
        private int _totalEntitiesProcessed;
        private int _totalChunksProcessed;
        
        public PerformanceBenchmarkSystem()
        {
            _benchmarkStopwatch = new Stopwatch();
            _benchmarkResults = new Dictionary<string, long>();
            _benchmarkIteration = 0;
        }

        protected override void OnUpdate()
        {
            _benchmarkStopwatch.Restart();
            
            // 收集性能数据
            CollectPerformanceData();
            
            _benchmarkStopwatch.Stop();
            
            // 记录本次更新时间
            var updateTime = _benchmarkStopwatch.ElapsedMilliseconds;
            _totalUpdateTime += updateTime;
            
            // 更新性能标记
            UpdatePerformanceMarkers(updateTime);
        }
        
        /// <summary>
        /// 收集性能数据
        /// </summary>
        private void CollectPerformanceData()
        {
            _totalEntitiesProcessed = 0;
            _totalChunksProcessed = 0;
            
            foreach (var entity in Query.Entities)
            {
                var marker = entity.GetComponent<PerformanceMarker>();
                
                // 统计实体数量
                _totalEntitiesProcessed++;
                
                // 统计区块数量
                if (entity.HasComponent<MCGame.ECS.Components.Chunk>())
                {
                    _totalChunksProcessed++;
                }
                
                // 重置标记
                marker.ProcessedThisFrame = true;
                marker.FrameCount++;
            }
        }
        
        /// <summary>
        /// 更新性能标记
        /// </summary>
        private void UpdatePerformanceMarkers(long updateTime)
        {
            foreach (var entity in Query.Entities)
            {
                if (entity.TryGetComponent<PerformanceMarker>(out var marker))
                {
                    marker.LastUpdateTime = updateTime;
                    marker.TotalUpdateTime += updateTime;
                    marker.AverageUpdateTime = marker.TotalUpdateTime / marker.FrameCount;
                    
                    if (updateTime > marker.MaxUpdateTime)
                    {
                        marker.MaxUpdateTime = updateTime;
                    }
                    
                    if (marker.MinUpdateTime == 0 || updateTime < marker.MinUpdateTime)
                    {
                        marker.MinUpdateTime = updateTime;
                    }
                }
            }
        }
        
        /// <summary>
        /// 获取性能统计信息
        /// </summary>
        public PerformanceStats GetPerformanceStats()
        {
            return new PerformanceStats
            {
                TotalEntities = _totalEntitiesProcessed,
                TotalChunks = _totalChunksProcessed,
                TotalUpdateTime = _totalUpdateTime,
                AverageUpdateTime = _totalEntitiesProcessed > 0 ? 
                    _totalUpdateTime / _totalEntitiesProcessed : 0,
                BenchmarkIteration = _benchmarkIteration
            };
        }
        
        /// <summary>
        /// 开始新的基准测试迭代
        /// </summary>
        public void StartBenchmarkIteration()
        {
            _benchmarkIteration++;
            _totalUpdateTime = 0;
            _totalRenderTime = 0;
            _totalEntitiesProcessed = 0;
            _totalChunksProcessed = 0;
        }
        
        /// <summary>
        /// 重置基准测试数据
        /// </summary>
        public void ResetBenchmark()
        {
            _benchmarkIteration = 0;
            _totalUpdateTime = 0;
            _totalRenderTime = 0;
            _totalEntitiesProcessed = 0;
            _totalChunksProcessed = 0;
            
            _benchmarkResults.Clear();
        }
        
        /// <summary>
        /// 记录基准测试结果
        /// </summary>
        public void RecordBenchmarkResult(string testName, long resultMs)
        {
            _benchmarkResults[testName] = resultMs;
        }
        
        /// <summary>
        /// 获取基准测试结果
        /// </summary>
        public Dictionary<string, long> GetBenchmarkResults()
        {
            return new Dictionary<string, long>(_benchmarkResults);
        }
    }
    
    /// <summary>
    /// 性能统计信息
    /// </summary>
    public struct PerformanceStats
    {
        public int TotalEntities { get; set; }
        public int TotalChunks { get; set; }
        public long TotalUpdateTime { get; set; }
        public long AverageUpdateTime { get; set; }
        public int BenchmarkIteration { get; set; }
        
        public PerformanceStats()
        {
            TotalEntities = 0;
            TotalChunks = 0;
            TotalUpdateTime = 0;
            AverageUpdateTime = 0;
            BenchmarkIteration = 0;
        }
    }
    
    /// <summary>
    /// 性能标记组件
    /// 用于跟踪单个实体的性能数据
    /// </summary>
    public struct PerformanceMarker : IComponent
    {
        public bool ProcessedThisFrame;
        public int FrameCount;
        public long LastUpdateTime;
        public long TotalUpdateTime;
        public long AverageUpdateTime;
        public long MinUpdateTime;
        public long MaxUpdateTime;
        
        public PerformanceMarker()
        {
            ProcessedThisFrame = false;
            FrameCount = 0;
            LastUpdateTime = 0;
            TotalUpdateTime = 0;
            AverageUpdateTime = 0;
            MinUpdateTime = 0;
            MaxUpdateTime = 0;
        }
    }
    
  }