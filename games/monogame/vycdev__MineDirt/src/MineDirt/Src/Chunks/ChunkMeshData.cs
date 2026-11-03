using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MineDirt.Src.Chunks;

public struct ChunkMeshData
{
    public List<QuantizedVertex> Vertices { get; set; }
    public List<int> Indices { get; set; }
    public List<QuantizedVertex> TransparentVertices { get; set; }
    public List<int> TransparentIndices { get; set; }
    public List<TransparentQuad> TransparentQuads { get; set; }
}