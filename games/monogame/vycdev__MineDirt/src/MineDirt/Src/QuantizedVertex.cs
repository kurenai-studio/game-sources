using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Graphics.PackedVector;
using System;

namespace MineDirt.Src;

public struct QuantizedVertex : IVertexType
{
    public float Packed0;
    public float Packed1;
    //public float Packed2;

    public QuantizedVertex(Vector3 blockPos, int textureIndex, int cornerID, int faceIndex)
    {
        int packedUV = (textureIndex << 3) | faceIndex;

        Packed0 = packedUV;

        int bx = (int)blockPos.X & 0xF;    // 4 bits: 0–15
        int bz = (int)blockPos.Z & 0xF;    // 4 bits: 0–15
        cornerID &= 0x7;                   // 3 bits: 0–7
        int by = (int)blockPos.Y & 0xFF;   // 8 bits: 0–255
        //normal &= 0xF;                     // 4 bits: 0–15

        int packed =
              bx
            | (bz << 4)
            | (cornerID << 8)
            | (by << 11);
            //| (normal << 19);

        Packed1 = (float)packed;
    }

    public static readonly VertexDeclaration VertexDeclaration = new(
        new VertexElement(0, VertexElementFormat.Single, VertexElementUsage.TextureCoordinate, 0),
        new VertexElement(4, VertexElementFormat.Single, VertexElementUsage.TextureCoordinate, 1)
        //new VertexElement(8, VertexElementFormat.Single, VertexElementUsage.Color, 0)
    );

    VertexDeclaration IVertexType.VertexDeclaration => VertexDeclaration;
}