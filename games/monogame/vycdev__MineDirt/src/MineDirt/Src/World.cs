using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MineDirt.Src.Chunks;
using MineDirt.Src.Scene;

namespace MineDirt.Src;

public static class World{

    public static EnvironmentSystem Environment {get; private set;}
    public static Sky Sky{get; private set;}

    public static ConcurrentDictionary<Vector3, Chunk> Chunks = [];
    public static ConcurrentQueue<Action> ChunkBufferGenerationQueue = new ConcurrentQueue<Action>();
    private static IOrderedEnumerable<KeyValuePair<Vector3, Chunk>> sortedChunks;
    private static readonly Vector3 chunkCenterModifier = new(Chunk.Width / 2, 0, Chunk.Width / 2);

    public static short RenderDistance { get; private set; } = 16;

    public static TaskProcessor MeshThreadPool = new(); // Number of threads to use for world generation and mesh building
    private const int ChunksPerFrame = 4; // Number of chunks to process per frame

    public static void Initialize() {
        Sky = new(MineDirtGame.Instance.skyboxshader);
        Environment = new(MineDirtGame.Instance.blockShader,Sky);
    }

    private static Vector3 lastCameraChunkPosition = new(0, -1, 0);

    private static Queue<Vector3> chunkLoadQueue = new();

    public static void ReloadChunks()
    {
        lastCameraChunkPosition = new(0, -1, 0);
        Chunks.Clear();
    }

    public static void BreakBlock(Vector3 position)
    {
        if (Chunks.TryGetValue(position.ToChunkPosition(), out Chunk chunk))
        {
            int index = position.ToChunkRelativePosition().ToIndex();
            if (chunk.Blocks[index].Type == BlockType.Air)
                return;

            chunk.Blocks[index] = default;
            chunk.BlockCount--;
            MeshThreadPool.EnqueueTask(() =>
            {
                ChunkMeshData meshData = chunk.GenerateMeshData();

                ChunkBufferGenerationQueue.Enqueue(() => chunk.GenerateBuffers(meshData));
            });

            if (chunk.TryGetBlockChunkNeighbours(index, out List<Vector3> chunkNbPositions))
            {
                foreach (Vector3 chunkNbPos in chunkNbPositions)
                {
                    if (Chunks.TryGetValue(chunkNbPos, out Chunk chunkNb))
                    {
                        MeshThreadPool.EnqueueTask(() =>
                        {
                            ChunkMeshData meshData = chunkNb.GenerateMeshData();

                            ChunkBufferGenerationQueue.Enqueue(() => chunkNb.GenerateBuffers(meshData));
                        });
                    }
                }
            }
        }
    }

    public static void PlaceBlock(Vector3 position, Block block)
    {
        if (position.Y > Chunk.Height || position.Y < 0)
            return;

        if (Chunks.TryGetValue(position.ToChunkPosition(), out Chunk chunk))
        {
            int index = position.ToChunkRelativePosition().ToIndex();
            if (chunk.Blocks[index].Type != BlockType.Air)
                return;

            chunk.Blocks[index] = block;
            chunk.BlockCount++;
            MeshThreadPool.EnqueueTask(() =>
            {
                ChunkMeshData meshData = chunk.GenerateMeshData();

                ChunkBufferGenerationQueue.Enqueue(() => chunk.GenerateBuffers(meshData));
            });

            if (chunk.TryGetBlockChunkNeighbours(index, out List<Vector3> chunkNbPositions))
            {
                foreach (Vector3 chunkNbPos in chunkNbPositions)
                {
                    if (Chunks.TryGetValue(chunkNbPos, out Chunk chunkNb))
                    {
                        MeshThreadPool.EnqueueTask(() =>
                        {
                            ChunkMeshData meshData = chunkNb.GenerateMeshData();

                            ChunkBufferGenerationQueue.Enqueue(() => chunkNb.GenerateBuffers(meshData));
                        });
                    }
                }
            }
        }
    }

    public static void Update()
    {
        if (ChunkBufferGenerationQueue.TryDequeue(out Action generateBuffers))
            generateBuffers();

        // Process chunks from the queue, limited by ChunksPerFrame
        for (int i = 0; i < ChunksPerFrame && chunkLoadQueue.Count > 0; i++)
        {
            Vector3 chunkToLoad = chunkLoadQueue.Dequeue();
            AddChunk(chunkToLoad);
        }

        Vector3 cameraPosition = MineDirtGame.Camera.Position;
        Vector3 cameraChunkPosition = cameraPosition.ToChunkPosition();

        // HashSet for efficient chunk presence checks
        HashSet<Vector3> chunksToKeep = new();

        // Don't update the chunks if the camera hasn't moved to a new chunk
        if (cameraChunkPosition == lastCameraChunkPosition)
            return;

        float renderDistanceSquared =
            RenderDistance * RenderDistance * Chunk.Width * Chunk.Width;

        cameraPosition.Y = 0;

        for (int r = 0; r <= RenderDistance; r++)
        {
            for (int x = -r; x <= r; x++)
            {
                for (int z = -r; z <= r; z++)
                {
                    Vector3 chunkPosition = new(
                        (int)(Math.Floor(cameraPosition.X / Chunk.Width) + x) * Chunk.Width,
                        0, // Assuming Y is always 0 for simplicity
                        (int)(Math.Floor(cameraPosition.Z / Chunk.Width) + z) * Chunk.Width
                    );

                    Vector3 chunkCenter = new(
                        chunkPosition.X + (Chunk.Width / 2),
                        0,
                        chunkPosition.Z + (Chunk.Width / 2)
                    );

                    float distanceSquared = Vector3.DistanceSquared(cameraPosition, chunkCenter);

                    // If the chunk is within the render distance (in squared distance to avoid sqrt)
                    if (distanceSquared <= renderDistanceSquared + 1)
                    {
                        chunksToKeep.Add(chunkPosition);

                        // Queue new chunks for addition if they don't already exist
                        if (!Chunks.ContainsKey(chunkPosition) && !chunkLoadQueue.Contains(chunkPosition))
                            chunkLoadQueue.Enqueue(chunkPosition);
                    }
                }
            }
        }

        // Remove chunks outside the render distance
        foreach (Vector3 item in Chunks.Keys)
            if (!chunksToKeep.Contains(item))
                Chunks.Remove(item, out _);

        lastCameraChunkPosition = cameraChunkPosition;
    }

    private static void AddChunk(Vector3 position)
    {
        // Add the new chunk without generating buffers
        Chunk newChunk = new(position);
        if (!newChunk.HasGeneratedTerrain)
            newChunk.GenerateTerrain();

        Chunks.TryAdd(position, newChunk);
        
        // Add neighboring chunks
        Vector3[] neighbors =
        [
            new Vector3(position.X - Chunk.Width, 0, position.Z), // West
            new Vector3(position.X + Chunk.Width, 0, position.Z), // East
            new Vector3(position.X, 0, position.Z - Chunk.Width), // South
            new Vector3(position.X, 0, position.Z + Chunk.Width), // North
        ];

        foreach (Vector3 item in neighbors)
        {
            if (Chunks.TryGetValue(item, out Chunk chunk))
            {
                MeshThreadPool.EnqueueTask(() =>
                {
                    ChunkMeshData meshData = chunk.GenerateMeshData();

                    ChunkBufferGenerationQueue.Enqueue(() => chunk.GenerateBuffers(meshData));
                });
            }
        }
    }

    public static void DrawChunksOpaque(Effect effect)
    {
        // Get the camera's frustum
        BoundingFrustum frustum = new(MineDirtGame.Camera.View * MineDirtGame.Camera.Projection);
        sortedChunks = Chunks.OrderByDescending(item => Vector3.DistanceSquared(MineDirtGame.Camera.Position, item.Key + chunkCenterModifier));

        foreach (var chunk in sortedChunks)
        {
            // Create a bounding box for the subchunk
            BoundingBox chunkBoundingBox = new(
                chunk.Value.Position - new Vector3(Chunk.Width, Chunk.Height, Chunk.Width),
                chunk.Value.Position + new Vector3(Chunk.Width, Chunk.Height, Chunk.Width)
            );

            // Check if the bounding box is inside the frustum
            if (frustum.Contains(chunkBoundingBox) != ContainmentType.Disjoint)
            {
                // Only draw subchunks within the frustum
                chunk.Value.DrawOpaque(effect);
            }
        }
    }

    public static void DrawChunksTransparent(Effect effect)
    {
        // Get the camera's frustum
        BoundingFrustum frustum = new(MineDirtGame.Camera.View * MineDirtGame.Camera.Projection);

        // Chunks are already sorted from drawing the opaque blocks
        foreach (var chunk in sortedChunks)
        {
            // Create a bounding box for the subchunk
            BoundingBox chunkBoundingBox = new(
                chunk.Value.Position - new Vector3(Chunk.Width, Chunk.Height, Chunk.Width),
                chunk.Value.Position + new Vector3(Chunk.Width, Chunk.Height, Chunk.Width)
            );

            // Check if the bounding box is inside the frustum
            if (frustum.Contains(chunkBoundingBox) != ContainmentType.Disjoint)
            {
                // Only draw subchunks within the frustum
                chunk.Value.DrawTransparent(effect);
            }
        }
    }

    public static bool TryGetBlock(Vector3 position, out Block block)
    {
        if (position.Y < 0 || position.Y >= Chunk.Height)
        {
            block = default;
            return false;
        }

        if (Chunks.TryGetValue(position.ToChunkPosition(), out Chunk chunk))
        {
            block = chunk.Blocks[position.ToChunkRelativePosition().ToIndex()];
            return true;
        }

        block = default;
        return false;
    }

    //returns Position, Face and Block
    public static void RayCast(Ray ray, int distance, out Vector3 pos, out Vector3 face, out Block block){

        Vector3 start = Vector3.Floor(ray.Position);
        int x = (int)start.X;
        int y = (int)start.Y;
        int z = (int)start.Z;
        int stepX = Math.Sign(ray.Direction.X);
        int stepY = Math.Sign(ray.Direction.Y);
        int stepZ = Math.Sign(ray.Direction.Z);

        Vector3 cellbounds = new Vector3(
        x + (stepX > 0 ? 1 : 0),
        y + (stepY > 0 ? 1 : 0),
        z + (stepZ > 0 ? 1 : 0));

        Vector3 tMax = new Vector3(
        (cellbounds.X - ray.Position.X) / ray.Direction.X,
        (cellbounds.Y - ray.Position.Y) / ray.Direction.Y,
        (cellbounds.Z - ray.Position.Z) / ray.Direction.Z);
        if (float.IsNaN(tMax.X)) tMax.X = float.PositiveInfinity;
        if (float.IsNaN(tMax.Y)) tMax.Y = float.PositiveInfinity;
        if (float.IsNaN(tMax.Z)) tMax.Z = float.PositiveInfinity;

        Vector3 tDelta = new Vector3(
        stepX / ray.Direction.X,
        stepY / ray.Direction.Y,
        stepZ / ray.Direction.Z);
        if (float.IsNaN(tDelta.X)) tDelta.X = float.PositiveInfinity;
        if (float.IsNaN(tDelta.Y)) tDelta.Y = float.PositiveInfinity;
        if (float.IsNaN(tDelta.Z)) tDelta.Z = float.PositiveInfinity;

        pos = default; face = default; block = default;
        Vector3 lastPoint = start;

        for (int i = 0; i < distance; i++){

            Vector3 point = new(x,y,z);
            if (tMax.X < tMax.Y && tMax.X < tMax.Z)
            {
                x += stepX;
                tMax.X += tDelta.X;
            }
            else if (tMax.Y < tMax.Z)
            {
                y += stepY;
                tMax.Y += tDelta.Y;
            }
            else
            {
                z += stepZ;
                tMax.Z += tDelta.Z;
            }
            if(TryGetBlock(point, out Block b)){
                if (b.Type == BlockType.Air){
                    lastPoint = point;
                    continue;
                }else{
                    pos = point;
                    face = lastPoint - point;
                    block = b;
                    return;
                }
            }
        }

    }
}
