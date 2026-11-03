using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Core;
using MCGame.Rendering;
using MCGame.Utils;
using MCGame.Blocks;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace MCGame.Chunks
{
    /// <summary>
    /// 区块管理器
    /// 管理区块的加载、卸载、生成和渲染
    /// 简化实现：使用字典存储区块，基于任务池的异步生成
    /// </summary>
    public class ChunkManager
    {
        // 区块存储
        private readonly ConcurrentDictionary<ChunkPosition, Chunk> _loadedChunks;
        private readonly SimpleObjectPool<Chunk> _chunkPool;

        // 异步生成队列
        private readonly ConcurrentQueue<ChunkPosition> _generationQueue;
        private readonly ConcurrentQueue<Chunk> _meshingQueue;

        // 多线程控制
        private readonly Task[] _generationWorkers;
        private readonly Task[] _meshingWorkers;
        private readonly CancellationTokenSource _cancellationToken;

        // 配置参数
        private readonly int _loadRadius = 5;  // 减少加载半径，避免生成过多区块
        private readonly int _unloadRadius = 8;
        private readonly int _maxConcurrentGeneration = 4;
        private readonly int _maxConcurrentMeshing = 2;

        // 世界设置
        private readonly long _worldSeed;
        private readonly WorldSettings _worldSettings;

        // 性能统计
        private int _chunksGeneratedThisFrame;
        private int _chunksMeshedThisFrame;

        // 引用
        private readonly BlockRegistry _blockRegistry;
        private readonly GraphicsDevice _graphicsDevice;

        public IReadOnlyDictionary<ChunkPosition, Chunk> LoadedChunks => _loadedChunks;
        public int LoadedChunkCount => _loadedChunks.Count;
        public int QueuedGenerationCount => _generationQueue.Count;
        public int QueuedMeshingCount => _meshingQueue.Count;

        public ChunkManager(GraphicsDevice graphicsDevice, BlockRegistry blockRegistry, WorldSettings worldSettings)
        {
            _graphicsDevice = graphicsDevice;
            _blockRegistry = blockRegistry;
            _worldSettings = worldSettings;
            _worldSeed = worldSettings.Seed;

            // 初始化存储
            _loadedChunks = new ConcurrentDictionary<ChunkPosition, Chunk>();
            _generationQueue = new ConcurrentQueue<ChunkPosition>();
            _meshingQueue = new ConcurrentQueue<Chunk>();

            // 初始化对象池
            _chunkPool = new SimpleObjectPool<Chunk>(() => new Chunk(new ChunkPosition(0, 0, 0)), chunk => chunk.Reset(), 10, 50);

            // 初始化多线程工作器
            _cancellationToken = new CancellationTokenSource();
            _generationWorkers = new Task[_maxConcurrentGeneration];
            _meshingWorkers = new Task[_maxConcurrentMeshing];

            // 启动工作线程
            StartWorkers();
        }

        /// <summary>
        /// 启动工作线程
        /// 简化实现：暂时禁用后台工作线程，使用主线程处理
        /// </summary>
        private void StartWorkers()
        {
            // 暂时禁用后台工作线程，避免与主线程竞争
            // 工作将由主线程的ProcessGenerationQueue和ProcessMeshingQueue处理
            Logger.Info("[WORKERS] Background workers disabled - using main thread processing");
        }

        /// <summary>
        /// 区块生成工作器
        /// 简化实现：暂时禁用，避免与主线程竞争
        /// </summary>
        private async Task GenerationWorker()
        {
            // 暂时禁用工作线程，避免与主线程竞争队列
            while (!_cancellationToken.IsCancellationRequested)
            {
                await Task.Delay(1000); // 长时间延迟，减少CPU占用
            }
        }

        /// <summary>
        /// 网格生成工作器
        /// 简化实现：暂时禁用，避免与主线程竞争
        /// </summary>
        private async Task MeshingWorker()
        {
            // 暂时禁用工作线程，避免与主线程竞争队列
            while (!_cancellationToken.IsCancellationRequested)
            {
                await Task.Delay(1000); // 长时间延迟，减少CPU占用
            }
        }

        /// <summary>
        /// 异步生成区块
        /// </summary>
        private async Task GenerateChunkAsync(Chunk chunk)
        {
            try
            {
                chunk.State = ChunkState.Generating;
                Logger.Info($"[ASYNC] Starting terrain generation for chunk {chunk.Position}");

                // 在主线程中生成地形（简化实现）
                await Task.Run(() =>
                {
                    try
                    {
                        Logger.Info($"[TERRAIN] Generating terrain for chunk {chunk.Position}...");
                        chunk.GenerateTerrain(_worldSeed);
                        chunk.State = ChunkState.Ready;
                        chunk.IsLoaded = true;
                        chunk.IsDirty = true;
                        Logger.Info($"[TERRAIN] Terrain generated for chunk {chunk.Position}, added to meshing queue");

                        // 加入网格生成队列
                        _meshingQueue.Enqueue(chunk);
                    }
                    catch (Exception ex)
                    {
                        Logger.Error($"[TERRAIN] Terrain generation failed for chunk {chunk.Position}: {ex.Message}");
                        chunk.State = ChunkState.Unloaded;
                        throw;
                    }
                });
                
                Logger.Info($"[ASYNC] Terrain generation completed for chunk {chunk.Position}");
            }
            catch (Exception ex)
            {
                Logger.Error($"[ASYNC] GenerateChunkAsync failed for chunk {chunk.Position}: {ex.Message}");
                chunk.State = ChunkState.Unloaded;
                throw;
            }
        }

        /// <summary>
        /// 异步生成区块网格
        /// </summary>
        private async Task GenerateChunkMeshAsync(Chunk chunk)
        {
            try
            {
                chunk.State = ChunkState.Meshing;
                Logger.Debug($"Starting mesh generation for chunk {chunk.Position}");

                await Task.Run(() =>
                {
                    try
                    {
                        Logger.Info($"Generating mesh for chunk {chunk.Position}...");
                        var mesher = new ChunkMesher(_blockRegistry, _graphicsDevice);
                        chunk.Mesh = mesher.GenerateMesh(chunk);
                        chunk.IsMeshGenerated = true;
                        chunk.IsDirty = false;
                        chunk.State = ChunkState.Ready;
                        Logger.Info($"Mesh generated for chunk {chunk.Position}");

                        Interlocked.Increment(ref _chunksMeshedThisFrame);
                    }
                    catch (Exception ex)
                    {
                        Logger.Error($"Mesh generation failed for chunk {chunk.Position}: {ex.Message}");
                        chunk.State = ChunkState.Ready;
                        chunk.IsDirty = true; // 标记为脏以便重试
                        throw;
                    }
                });
            }
            catch (Exception ex)
            {
                Logger.Error($"GenerateChunkMeshAsync failed for chunk {chunk.Position}: {ex.Message}");
                chunk.State = ChunkState.Ready;
                chunk.IsDirty = true; // 标记为脏以便重试
                throw;
            }
        }

        /// <summary>
        /// 更新区块管理器
        /// </summary>
        public void Update(Vector3 playerPosition)
        {
            var serilogLogger = Logger.GetSerilogLogger();
            
            // 重置统计
            _chunksGeneratedThisFrame = 0;
            _chunksMeshedThisFrame = 0;

            // 计算玩家所在区块
            var playerChunkPos = ChunkPosition.FromWorldPosition(playerPosition, Chunk.SIZE);
            serilogLogger?.Chunk("Updating chunk manager around player position {PlayerPos} -> {ChunkPos}", playerPosition, playerChunkPos);

            // 更新区块加载
            serilogLogger?.Chunk("Updating chunk loading...");
            Logger.Debug($"Updating chunk loading around player position {playerChunkPos}");
            UpdateChunkLoading(playerChunkPos);

            // 更新区块卸载
            serilogLogger?.Chunk("Updating chunk unloading...");
            UpdateChunkUnloading(playerChunkPos);

            // 处理生成队列
            serilogLogger?.Chunk("Processing generation queue (size: {QueueSize})", _generationQueue.Count);
            ProcessGenerationQueue();

            // 处理网格生成队列
            serilogLogger?.Chunk("Processing meshing queue (size: {QueueSize})", _meshingQueue.Count);
            ProcessMeshingQueue();

            // 更新邻近区块引用
            serilogLogger?.Chunk("Updating chunk neighbors...");
            UpdateChunkNeighbors();
            
            serilogLogger?.Chunk("Chunk manager update completed. Generated: {Generated}, Meshed: {Meshed}", _chunksGeneratedThisFrame, _chunksMeshedThisFrame);
        }

        /// <summary>
        /// 更新区块加载
        /// 修复：限制每帧加载的区块数量，避免卡顿
        /// </summary>
        private void UpdateChunkLoading(ChunkPosition playerChunkPos)
        {
            var serilogLogger = Logger.GetSerilogLogger();
            
            // 计算需要加载的区块范围
            var chunksToLoad = GetChunksInRadius(playerChunkPos, _loadRadius);
            
            // 限制每帧加载的区块数量，避免卡顿
            int maxChunksToLoadPerFrame = 50;
            int chunksLoadedThisFrame = 0;
            
            serilogLogger?.Chunk("Evaluating {TotalChunks} chunks for loading, max {MaxPerFrame}", chunksToLoad.Count, maxChunksToLoadPerFrame);

            foreach (var chunkPos in chunksToLoad)
            {
                if (chunksLoadedThisFrame >= maxChunksToLoadPerFrame)
                {
                    break;
                }
                
                if (!_loadedChunks.ContainsKey(chunkPos))
                {
                    Logger.Debug($"Queueing chunk {chunkPos} for generation");
                    // 先创建区块并添加到loadedChunks，避免重复排队
                    var chunk = GetOrCreateChunk(chunkPos);
                    _loadedChunks.TryAdd(chunkPos, chunk);
                    // 加入生成队列
                    _generationQueue.Enqueue(chunkPos);
                    chunksLoadedThisFrame++;
                }
            }
            
            serilogLogger?.Chunk("Queued {QueuedCount} chunks for generation this frame", chunksLoadedThisFrame);
        }

        /// <summary>
        /// 更新区块卸载
        /// </summary>
        private void UpdateChunkUnloading(ChunkPosition playerChunkPos)
        {
            var chunksToUnload = new List<ChunkPosition>();

            // ConcurrentDictionary是线程安全的，可以直接遍历
            foreach (var chunkPos in _loadedChunks.Keys)
            {
                var distance = GetChunkDistance(playerChunkPos, chunkPos);
                if (distance > _unloadRadius)
                {
                    chunksToUnload.Add(chunkPos);
                }
            }

            foreach (var chunkPos in chunksToUnload)
            {
                UnloadChunk(chunkPos);
            }
        }

        /// <summary>
        /// 更新区块邻近引用
        /// </summary>
        private void UpdateChunkNeighbors()
        {
            // ConcurrentDictionary是线程安全的，可以直接遍历
            foreach (var chunk in _loadedChunks.Values)
            {
                var neighbors = new Chunk[3, 3, 3];

                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        for (int z = -1; z <= 1; z++)
                        {
                            var neighborPos = new ChunkPosition(
                                chunk.Position.X + x,
                                chunk.Position.Y + y,
                                chunk.Position.Z + z
                            );

                            _loadedChunks.TryGetValue(neighborPos, out neighbors[x + 1, y + 1, z + 1]);
                        }
                    }
                }

                chunk.UpdateNeighbors(neighbors);
            }
        }

        /// <summary>
        /// 处理区块生成队列
        /// 修复：确保区块被正确处理，避免队列竞争
        /// </summary>
        private void ProcessGenerationQueue()
        {
            var serilogLogger = Logger.GetSerilogLogger();
            
            // 每帧最多生成一定数量的区块
            int maxPerFrame = 3;
            int processed = 0;
            int initialQueueSize = _generationQueue.Count;
            
            serilogLogger?.Chunk("Processing generation queue: {QueueSize} chunks to process", initialQueueSize);

            while (_generationQueue.TryDequeue(out var chunkPos) && processed < maxPerFrame)
            {
                try
                {
                    // 检查区块是否已存在且已处理
                    if (_loadedChunks.TryGetValue(chunkPos, out var existingChunk))
                    {
                        if (existingChunk.State == ChunkState.Ready || existingChunk.State == ChunkState.Meshing)
                        {
                            serilogLogger?.Chunk("Chunk {ChunkPos} already processed, skipping", chunkPos);
                            continue;
                        }
                    }
                    
                    var chunk = GetOrCreateChunk(chunkPos);
                    
                    // 简化实现：使用同步生成
                    Logger.Info($"[SYNC] Starting terrain generation for chunk {chunk.Position}");
                    chunk.State = ChunkState.Generating;
                    
                    // 生成地形
                    chunk.GenerateTerrain(_worldSeed);
                    chunk.State = ChunkState.Ready;
                    chunk.IsLoaded = true;
                    chunk.IsDirty = true;
                    Logger.Info($"[SYNC] Terrain generated for chunk {chunk.Position}, added to meshing queue");

                    // 加入网格生成队列
                    _meshingQueue.Enqueue(chunk);
                    
                    _chunksGeneratedThisFrame++;
                    processed++;
                }
                catch (Exception ex)
                {
                    Logger.Error($"Failed to generate chunk at {chunkPos}: {ex.Message}");
                    // 生成失败时从loadedChunks中移除，以便重试
                    _loadedChunks.TryRemove(chunkPos, out _);
                }
            }
            
            serilogLogger?.Chunk("Generation queue processing completed: {Processed}/{InitialQueueSize} chunks processed", processed, initialQueueSize);
        }

        /// <summary>
        /// 处理网格生成队列
        /// 修复：确保网格被正确处理，避免重复处理
        /// </summary>
        private void ProcessMeshingQueue()
        {
            var serilogLogger = Logger.GetSerilogLogger();
            
            // 每帧最多生成一定数量的网格
            int maxPerFrame = 3;
            int processed = 0;
            int initialQueueSize = _meshingQueue.Count;
            
            serilogLogger?.Chunk("Processing meshing queue: {QueueSize} chunks to process", initialQueueSize);

            while (_meshingQueue.TryDequeue(out var chunk) && processed < maxPerFrame)
            {
                try
                {
                    // 检查区块是否已经生成网格
                    if (chunk.IsMeshGenerated)
                    {
                        serilogLogger?.Chunk("Chunk {ChunkPos} already meshed, skipping", chunk.Position);
                        continue;
                    }
                    
                    // 检查区块状态
                    if (chunk.State != ChunkState.Ready)
                    {
                        serilogLogger?.Chunk("Chunk {ChunkPos} not ready for meshing (state: {State}), requeuing", chunk.Position, chunk.State);
                        _meshingQueue.Enqueue(chunk); // 重新排队
                        continue;
                    }
                    
                    // 简化实现：使用同步网格生成
                    Logger.Info($"[SYNC] Starting mesh generation for chunk {chunk.Position}");
                    chunk.State = ChunkState.Meshing;
                    
                    // 生成网格
                    var mesher = new ChunkMesher(_blockRegistry, _graphicsDevice);
                    chunk.Mesh = mesher.GenerateMesh(chunk);
                    chunk.IsMeshGenerated = true;
                    chunk.IsDirty = false;
                    chunk.State = ChunkState.Ready;
                    Logger.Info($"[SYNC] Mesh generated for chunk {chunk.Position}");
                    
                    _chunksMeshedThisFrame++;
                    processed++;
                }
                catch (Exception ex)
                {
                    Logger.Error($"Failed to generate mesh for chunk at {chunk.Position}: {ex.Message}");
                    // 网格生成失败时标记为脏以便重试
                    chunk.IsDirty = true;
                    chunk.State = ChunkState.Ready;
                }
            }
            
            serilogLogger?.Chunk("Meshing queue processing completed: {Processed}/{InitialQueueSize} chunks processed", processed, initialQueueSize);
        }

        /// <summary>
        /// 获取指定半径内的区块
        /// </summary>
        private List<ChunkPosition> GetChunksInRadius(ChunkPosition center, int radius)
        {
            var chunks = new List<ChunkPosition>();

            for (int x = -radius; x <= radius; x++)
            {
                for (int y = -radius; y <= radius; y++)
                {
                    for (int z = -radius; z <= radius; z++)
                    {
                        var distance = Math.Sqrt(x * x + y * y + z * z);
                        if (distance <= radius)
                        {
                            chunks.Add(new ChunkPosition(
                                center.X + x,
                                center.Y + y,
                                center.Z + z
                            ));
                        }
                    }
                }
            }

            return chunks;
        }

        /// <summary>
        /// 获取区块间距离
        /// </summary>
        private float GetChunkDistance(ChunkPosition a, ChunkPosition b)
        {
            var dx = a.X - b.X;
            var dy = a.Y - b.Y;
            var dz = a.Z - b.Z;
            return (float)Math.Sqrt(dx * dx + dy * dy + dz * dz);
        }

        /// <summary>
        /// 获取或创建区块
        /// </summary>
        private Chunk GetOrCreateChunk(ChunkPosition position)
        {
            if (_loadedChunks.TryGetValue(position, out var chunk))
            {
                return chunk;
            }

            chunk = _chunkPool.Get();
            chunk.Reset();
            chunk.Position = position;
            chunk.State = ChunkState.Loading;

            _loadedChunks[position] = chunk;
            return chunk;
        }

        /// <summary>
        /// 卸载区块
        /// </summary>
        private void UnloadChunk(ChunkPosition position)
        {
            if (_loadedChunks.TryGetValue(position, out var chunk))
            {
                chunk.Unload();
                _loadedChunks.TryRemove(position, out _);
                _chunkPool.Return(chunk);
            }
        }

        /// <summary>
        /// 获取指定位置的区块
        /// </summary>
        public Chunk GetChunk(ChunkPosition position)
        {
            _loadedChunks.TryGetValue(position, out var chunk);
            return chunk;
        }

        /// <summary>
        /// 获取世界坐标处的区块
        /// </summary>
        public Chunk GetChunkAtWorldPosition(Vector3 worldPosition)
        {
            var chunkPos = ChunkPosition.FromWorldPosition(worldPosition, Chunk.SIZE);
            return GetChunk(chunkPos);
        }

        /// <summary>
        /// 获取指定位置的方块
        /// </summary>
        public BlockData GetBlock(Vector3 worldPosition)
        {
            var chunk = GetChunkAtWorldPosition(worldPosition);
            return chunk?.GetBlockWorld(worldPosition) ?? BlockData.Empty;
        }

        /// <summary>
        /// 设置指定位置的方块
        /// </summary>
        public void SetBlock(Vector3 worldPosition, BlockData block)
        {
            var chunk = GetChunkAtWorldPosition(worldPosition);
            chunk?.SetBlockWorld(worldPosition, block);
        }

        /// <summary>
        /// 获取所有可见区块
        /// </summary>
        public List<Chunk> GetVisibleChunks(FrustumCulling frustumCulling)
        {
            var serilogLogger = Logger.GetSerilogLogger();
            var visibleChunks = new List<Chunk>();

            // ConcurrentDictionary是线程安全的，可以直接遍历
            serilogLogger?.Chunk("Finding visible chunks from {LoadedCount} loaded chunks...", _loadedChunks.Count);
            
            int totalChunks = 0;
            int loadedChunks = 0;
            int meshedChunks = 0;
            int frustumVisibleChunks = 0;

            foreach (var chunk in _loadedChunks.Values)
            {
                totalChunks++;
                
                if (chunk.IsLoaded)
                {
                    loadedChunks++;
                    
                    if (chunk.IsMeshGenerated)
                    {
                        meshedChunks++;
                        
                        if (frustumCulling.IsChunkVisible(chunk))
                        {
                            frustumVisibleChunks++;
                            visibleChunks.Add(chunk);
                        }
                    }
                }
            }
            
            serilogLogger?.Chunk("Visibility stats: Total={Total}, Loaded={Loaded}, Meshed={Meshed}, FrustumVisible={FrustumVisible}, FinalVisible={FinalVisible}", 
                totalChunks, loadedChunks, meshedChunks, frustumVisibleChunks, visibleChunks.Count);

            return visibleChunks;
        }

        /// <summary>
        /// 获取性能统计
        /// </summary>
        public ChunkManagerStats GetStats()
        {
            return new ChunkManagerStats
            {
                LoadedChunks = _loadedChunks.Count,
                QueuedGeneration = _generationQueue.Count,
                QueuedMeshing = _meshingQueue.Count,
                ChunksGeneratedThisFrame = _chunksGeneratedThisFrame,
                ChunksMeshedThisFrame = _chunksMeshedThisFrame,
                PoolSize = _chunkPool.Count
            };
        }

        /// <summary>
        /// 销毁区块管理器
        /// </summary>
        public void Dispose()
        {
            // 取消所有工作线程
            _cancellationToken.Cancel();

            // 等待线程完成
            Task.WaitAll(_generationWorkers.Concat(_meshingWorkers).ToArray());

            // 卸载所有区块
            foreach (var chunk in _loadedChunks.Values)
            {
                chunk.Unload();
            }

            _loadedChunks.Clear();
            _chunkPool.Dispose();
            _cancellationToken.Dispose();
        }
    }

    /// <summary>
    /// 区块管理器统计信息
    /// </summary>
    public struct ChunkManagerStats
    {
        public int LoadedChunks { get; set; }
        public int QueuedGeneration { get; set; }
        public int QueuedMeshing { get; set; }
        public int ChunksGeneratedThisFrame { get; set; }
        public int ChunksMeshedThisFrame { get; set; }
        public int PoolSize { get; set; }
    }
}