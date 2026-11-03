using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MineDirt.Src.Noise;
using System;
using System.Collections.Generic;

namespace MineDirt.Src.Chunks;

public class Chunk
{
    public static ushort Width { get; private set; } = 16;
    public static int Height { get; private set; } = 16 * Width;
    public Vector3 Position { get; private set; }
    public Block[] Blocks { get; private set; }
    public ushort BlockCount;
    public VertexBuffer VertexBuffer { get; private set; }
    public IndexBuffer IndexBuffer { get; private set; }

    public bool HasGeneratedTerrain { get; private set; } = false;

    private List<TransparentQuad> _transparentQuads = [];

    public VertexBuffer StaticTransparentVertexBuffer { get; private set; }
    public IndexBuffer StaticTransparentIndexBuffer { get; private set; }

    private VertexBuffer _dynamicTransparentVertexBuffer;
    private IndexBuffer _dynamicTransparentIndexBuffer;
    private int _lastValidDynamicIndexCount = 0;

    private List<SortableQuadInfo> _quadsToSort = [];
    private QuantizedVertex[] _sortedVertexArray;
    private int[] _sortedIndexArray;

    private Vector3 _lastSortCameraPosition = Vector3.Zero;
    private bool _needsResort = false;

    public Chunk(Vector3 position)
    {
        Position = position;
        Blocks = new Block[Width * Height * Width];
    }

    public static int GetXFromIndex(int index) => index % Width;
    public static int GetYFromIndex(int index) => (index / Width) % Height;
    public static int GetZFromIndex(int index) => index / (Width * Height);
    public static int GetIndexFromX(int x) => x;
    public static int GetIndexFromY(int y) => y * Width;
    public static int GetIndexFromZ(int z) => z * Width * Height;

    public void GenerateTerrain()
    {
        Vector3 blockPosition;
        Vector3 worldBlockPosition;

        const float terrainFrequency = 1f;
        const float sandPatchFrequency = 2f;

        const int dirtLayerDepth = 3;
        int seaLevel = Height / 4;
        const int beachHeight = 1;

        for (int x = 0; x < Width; x++)
        {
            for (int z = 0; z < Width; z++)
            {
                float worldX = Position.X + x;
                float worldZ = Position.Z + z;

                float heightNoise = Math.Max(MineDirtGame.Noise.GetNoise(worldX * terrainFrequency, worldZ * terrainFrequency), MineDirtGame.Noise.GetNoise(worldX * terrainFrequency * 1.25f, worldZ * terrainFrequency * 1.25f));
                int maxHeight = (int)(Utils.ScaleNoise(heightNoise, 0.25f, 0.75f) * Height / 2);
                maxHeight = MathHelper.Clamp(maxHeight, 1, Height / 2 - 1);

                float sandNoise = MineDirtGame.Noise.GetNoise(worldX * sandPatchFrequency, worldZ * sandPatchFrequency);
                bool createSandPatch = sandNoise > 0.25f;

                for (int y = 0; y < Height; y++)
                {
                    blockPosition = new Vector3(x, y, z);
                    worldBlockPosition.Y = Position.Y + y;

                    Block block;
                    int blockIndex = GetIndexFromX(x) + GetIndexFromY(y) + GetIndexFromZ(z);

                    if (worldBlockPosition.Y > maxHeight)
                    {
                        if (worldBlockPosition.Y <= seaLevel)
                        {
                            block = new Block(BlockType.Water);
                            BlockCount++;
                        }
                        else
                        {
                            block = new Block(BlockType.Air);
                        }
                    }
                    else
                    {
                        BlockCount++;

                        bool isBeachZone = maxHeight <= seaLevel + beachHeight;

                        if (worldBlockPosition.Y == 0)
                        {
                            block = new Block(BlockType.Bedrock);
                        }
                        else if (createSandPatch && isBeachZone && worldBlockPosition.Y > maxHeight - dirtLayerDepth)
                        {
                            block = new Block(BlockType.Sand);
                        }
                        else if (worldBlockPosition.Y == maxHeight)
                        {
                            block = new Block(worldBlockPosition.Y >= seaLevel ? BlockType.Grass : BlockType.Dirt);
                        }
                        else if (worldBlockPosition.Y > maxHeight - dirtLayerDepth)
                        {
                            block = new Block(BlockType.Dirt);
                        }
                        else
                        {
                            block = new Block(BlockType.Stone);
                        }
                    }

                    Blocks[blockIndex] = block;
                }
            }
        }

        HasGeneratedTerrain = true;
    }

    public ChunkMeshData GenerateMeshData()
    {
        if (BlockCount <= 0)
            return default;

        List<QuantizedVertex> allVertices = [];
        List<int> allIndices = [];
        int vertexOffset = 0;

        List<TransparentQuad> newTransparentQuads = [];
        List<QuantizedVertex> allTransparentVertices = [];
        List<int> allTransparentIndices = [];

        int transparentVertexOffset = 0;

        Vector3 blockPos = new();
        for (int k = 0; k < Blocks.Length; k++)
        {
            Block block = Blocks[k];
            if (block.Type == BlockType.Air) continue;

            blockPos.X = GetXFromIndex(k);
            blockPos.Y = GetYFromIndex(k);
            blockPos.Z = GetZFromIndex(k);

            for (byte faceIndex = 0; faceIndex < 6; faceIndex++)
            {
                if (!IsFaceVisible(k, Block.Faces[faceIndex], out Block? neighborBlock)) continue;

                QuantizedVertex[] faceVertices = BlockRendering.GetFaceVertices(
                    block.Type, faceIndex, blockPos
                );

                if (block.IsOpaque)
                {


                    //TODO: AO for each vertex

                    allVertices.AddRange(faceVertices);
                    for (byte i = 0; i < BlockRendering.Indices.Length; i++)
                        allIndices.Add(BlockRendering.Indices[i] + vertexOffset);
                    vertexOffset += faceVertices.Length;
                }
                else
                {
                    allTransparentVertices.AddRange(faceVertices);
                    for (byte i = 0; i < BlockRendering.Indices.Length; i++)
                        allTransparentIndices.Add(BlockRendering.Indices[i] + transparentVertexOffset);

                    bool isTwoSided = (block.Type == BlockType.Water &&
                       faceIndex == 4 && // Top face
                       neighborBlock?.Type == BlockType.Air);

                    if (isTwoSided)
                    {
                        for (byte i = 0; i < BlockRendering.FlippedIndices.Length; i++)
                            allTransparentIndices.Add(BlockRendering.FlippedIndices[i] + transparentVertexOffset);
                    }

                    Vector3 worldCenterOfBlock = (blockPos + new Vector3(0.5f)) + this.Position;
                    var quad = new TransparentQuad
                    {
                        V0 = faceVertices[0],
                        V1 = faceVertices[1],
                        V2 = faceVertices[2],
                        V3 = faceVertices[3],
                        Center = worldCenterOfBlock, 
                        IsTwoSided = isTwoSided
                    };
                    newTransparentQuads.Add(quad);

                    transparentVertexOffset += faceVertices.Length;
                }
            }
        }

        return new ChunkMeshData()
        {
            Indices = allIndices,
            Vertices = allVertices,
            TransparentIndices = allTransparentIndices,
            TransparentVertices = allTransparentVertices,
            TransparentQuads = newTransparentQuads
        };
    }

    public void GenerateBuffers(ChunkMeshData meshData)
    {
        if (meshData.Indices.Count > 0)
        {
            VertexBuffer = new VertexBuffer(
                MineDirtGame.Graphics.GraphicsDevice,
                typeof(QuantizedVertex),
                meshData.Vertices.Count,
                BufferUsage.WriteOnly
            );

            VertexBuffer.SetData([.. meshData.Vertices]);

            IndexBuffer = new IndexBuffer(
                MineDirtGame.Graphics.GraphicsDevice,
                IndexElementSize.ThirtyTwoBits,
                meshData.Indices.Count,
                BufferUsage.WriteOnly
            );

            IndexBuffer.SetData([.. meshData.Indices]);
        }
        else
        {
            VertexBuffer = null;
            IndexBuffer = null;
        }

        if (meshData.TransparentVertices != null && meshData.TransparentVertices.Count > 0)
        {
            StaticTransparentVertexBuffer = new VertexBuffer(
                MineDirtGame.Graphics.GraphicsDevice, typeof(QuantizedVertex),
                meshData.TransparentVertices.Count, BufferUsage.WriteOnly
            );
            StaticTransparentVertexBuffer.SetData(meshData.TransparentVertices.ToArray());

            StaticTransparentIndexBuffer = new IndexBuffer(
                MineDirtGame.Graphics.GraphicsDevice, IndexElementSize.ThirtyTwoBits,
                meshData.TransparentIndices.Count, BufferUsage.WriteOnly
            );
            StaticTransparentIndexBuffer.SetData(meshData.TransparentIndices.ToArray());

            _transparentQuads = meshData.TransparentQuads;
            _needsResort = true;
        }
        else
        {
            StaticTransparentVertexBuffer = null;
            StaticTransparentIndexBuffer = null;
            _transparentQuads.Clear();
            _needsResort = true;
        }
    }

    bool IsFaceVisible(int blockIndex, short direction, out Block? nbBlock)
    {
        Block block = Blocks[blockIndex];
        int unwrappedNbIndex = blockIndex + direction;
        int unwX = GetXFromIndex(blockIndex) + GetXFromIndex(direction);
        int unwY = GetYFromIndex(blockIndex) + GetYFromIndex(direction);
        int unwZ = GetZFromIndex(blockIndex) + GetZFromIndex(direction);

        nbBlock = null;

        if (unwY < 0 || unwY >= Height)
            return true;

        if (unwX < 0 || unwX >= Width || unwY < 0 || unwY >= Height || unwZ < 0 || unwZ >= Width)
        {
            var worldBlockPos = new Vector3(
                Position.X + unwX,
                Position.Y + unwY,
                Position.Z + unwZ
            );

            if (World.TryGetBlock(worldBlockPos, out Block neighborBlock))
            {
                nbBlock = neighborBlock;
                return !(neighborBlock.Type == block.Type || neighborBlock.IsOpaque);
            }
            else
                return true;
        }

        Block nb = Blocks[unwrappedNbIndex];
        nbBlock = nb;

        return !(nb.Type == block.Type || nb.IsOpaque);
    }

    public bool TryGetBlockChunkNeighbours(int index, out List<Vector3> subchunkPos)
    {
        int x = GetXFromIndex(index);
        int y = GetYFromIndex(index);
        int z = GetZFromIndex(index);

        subchunkPos = [];

        if (x == 0)
            subchunkPos.Add(Position + (new Vector3(-1, 0, 0) * Width));

        if (x == Width - 1)
            subchunkPos.Add(Position + (new Vector3(1, 0, 0) * Width));

        if (y == 0)
            subchunkPos.Add(Position + (new Vector3(0, -1, 0) * Height));

        if (y == Height - 1)
            subchunkPos.Add(Position + (new Vector3(0, 1, 0) * Height));

        if (z == 0)
            subchunkPos.Add(Position + (new Vector3(0, 0, -1) * Width));

        if (z == Width - 1)
            subchunkPos.Add(Position + (new Vector3(0, 0, 1) * Width));

        return subchunkPos.Count > 0;
    }

    public void DrawOpaque(Effect effect)
    {
        if (BlockCount <= 0 || VertexBuffer == null || IndexBuffer == null)
            return;

        effect.Parameters["ChunkWorldPosition"].SetValue(this.Position);

        MineDirtGame.Graphics.GraphicsDevice.SetVertexBuffer(VertexBuffer);
        MineDirtGame.Graphics.GraphicsDevice.Indices = IndexBuffer;

        foreach (EffectPass pass in effect.CurrentTechnique.Passes)
        {
            pass.Apply();
            MineDirtGame.Graphics.GraphicsDevice.DrawIndexedPrimitives(
                PrimitiveType.TriangleList,
                0,
                0,
                IndexBuffer.IndexCount / 3
            );
        }
    }
    
    public void DrawTransparent(Effect effect)
    {
        if (_transparentQuads.Count == 0)
            return;

        effect.Parameters["ChunkWorldPosition"].SetValue(this.Position);

        var graphicsDevice = MineDirtGame.Graphics.GraphicsDevice;

        var cameraPos2D = new Vector2(MineDirtGame.Camera.Position.X, MineDirtGame.Camera.Position.Z);
        var chunkPos2D = new Vector2(this.Position.X, this.Position.Z);
        float distanceSquared2D = Vector2.DistanceSquared(cameraPos2D, chunkPos2D);

        const float SORTING_DISTANCE_SQUARED = 32f * 32f;

        if (distanceSquared2D > SORTING_DISTANCE_SQUARED)
        {
            if (StaticTransparentVertexBuffer == null) return;
            graphicsDevice.SetVertexBuffer(StaticTransparentVertexBuffer);
            graphicsDevice.Indices = StaticTransparentIndexBuffer;
            foreach (EffectPass pass in effect.CurrentTechnique.Passes)
            {
                pass.Apply();
                graphicsDevice.DrawIndexedPrimitives(
                    PrimitiveType.TriangleList, 0, 0,
                    StaticTransparentIndexBuffer.IndexCount / 3
                );
            }
            return;
        }

        var cameraPosition = MineDirtGame.Camera.Position;
        var cameraDistanceSquared = Vector3.DistanceSquared(cameraPosition, _lastSortCameraPosition);

        if (_needsResort || cameraDistanceSquared > (2.0f * 2.0f))
        {
            _needsResort = false;
            _lastSortCameraPosition = cameraPosition;

            _quadsToSort.Clear();
            for (int i = 0; i < _transparentQuads.Count; i++)
            {
                _quadsToSort.Add(new SortableQuadInfo
                {
                    QuadIndex = i,
                    DistanceSquared = Vector3.DistanceSquared(cameraPosition, _transparentQuads[i].Center)
                });
            }
            _quadsToSort.Sort((a, b) => b.DistanceSquared.CompareTo(a.DistanceSquared));

            int quadCount = _quadsToSort.Count;

            int totalIndexCount = 0;
            foreach (var quadInfo in _quadsToSort)
            {
                totalIndexCount += 6; 
                if (_transparentQuads[quadInfo.QuadIndex].IsTwoSided)
                {
                    totalIndexCount += 6;
                }
            }

            int vertexCount = quadCount * 4;

            if (_sortedVertexArray == null || _sortedVertexArray.Length < vertexCount)
                _sortedVertexArray = new QuantizedVertex[vertexCount];
            if (_sortedIndexArray == null || _sortedIndexArray.Length < totalIndexCount)
                _sortedIndexArray = new int[totalIndexCount];

            int currentIndex = 0;
            for (int i = 0; i < quadCount; i++)
            {
                var quad = _transparentQuads[_quadsToSort[i].QuadIndex];
                int vertexOffset = i * 4;
                
                _sortedVertexArray[vertexOffset + 0] = quad.V0;
                _sortedVertexArray[vertexOffset + 1] = quad.V1;
                _sortedVertexArray[vertexOffset + 2] = quad.V2;
                _sortedVertexArray[vertexOffset + 3] = quad.V3;

                _sortedIndexArray[currentIndex++] = vertexOffset + 0;
                _sortedIndexArray[currentIndex++] = vertexOffset + 2;
                _sortedIndexArray[currentIndex++] = vertexOffset + 1;
                _sortedIndexArray[currentIndex++] = vertexOffset + 1;
                _sortedIndexArray[currentIndex++] = vertexOffset + 2;
                _sortedIndexArray[currentIndex++] = vertexOffset + 3;

                if (quad.IsTwoSided)
                {
                    _sortedIndexArray[currentIndex++] = vertexOffset + 0;
                    _sortedIndexArray[currentIndex++] = vertexOffset + 3;
                    _sortedIndexArray[currentIndex++] = vertexOffset + 2;
                    _sortedIndexArray[currentIndex++] = vertexOffset + 0;
                    _sortedIndexArray[currentIndex++] = vertexOffset + 1;
                    _sortedIndexArray[currentIndex++] = vertexOffset + 3;
                }
            }

            if (_dynamicTransparentVertexBuffer == null || _dynamicTransparentVertexBuffer.VertexCount < vertexCount)
            {
                _dynamicTransparentVertexBuffer?.Dispose();
                _dynamicTransparentVertexBuffer = new VertexBuffer(graphicsDevice, typeof(QuantizedVertex), vertexCount, BufferUsage.WriteOnly);
            }
            if (_dynamicTransparentIndexBuffer == null || _dynamicTransparentIndexBuffer.IndexCount < totalIndexCount)
            {
                _dynamicTransparentIndexBuffer?.Dispose();
                _dynamicTransparentIndexBuffer = new IndexBuffer(graphicsDevice, IndexElementSize.ThirtyTwoBits, totalIndexCount, BufferUsage.WriteOnly);
            }

            _dynamicTransparentVertexBuffer.SetData(_sortedVertexArray, 0, vertexCount);
            _dynamicTransparentIndexBuffer.SetData(_sortedIndexArray, 0, totalIndexCount);
            _lastValidDynamicIndexCount = totalIndexCount;
        }

        graphicsDevice.SetVertexBuffer(_dynamicTransparentVertexBuffer);
        graphicsDevice.Indices = _dynamicTransparentIndexBuffer;
        foreach (EffectPass pass in effect.CurrentTechnique.Passes)
        {
            pass.Apply();
            graphicsDevice.DrawIndexedPrimitives(
                PrimitiveType.TriangleList, 0, 0,
                _lastValidDynamicIndexCount / 3
            );
        }
    }
}
