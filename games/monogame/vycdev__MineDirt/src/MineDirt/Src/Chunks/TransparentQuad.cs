using Microsoft.Xna.Framework;

namespace MineDirt.Src.Chunks;

public struct TransparentQuad
{
    public QuantizedVertex V0, V1, V2, V3;
    public Vector3 Center;

    public bool IsTwoSided;
}
