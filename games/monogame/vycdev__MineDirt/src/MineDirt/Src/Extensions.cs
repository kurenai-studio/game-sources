using System;
using Microsoft.Xna.Framework;
using MineDirt.Src.Chunks;

namespace MineDirt.Src;

public static class Extensions
{
    public static Vector3 ToChunkPosition(this Vector3 position) =>
        new(
            (int)Math.Floor(position.X / Chunk.Width) * Chunk.Width,
            0,
            (int)Math.Floor(position.Z / Chunk.Width) * Chunk.Width
        );

    public static Vector3 ToChunkRelativePosition(this Vector3 position) =>
    new(
        ((position.X % Chunk.Width) + Chunk.Width) % Chunk.Width,
        ((position.Y % Chunk.Height) + Chunk.Height) % Chunk.Height,
        ((position.Z % Chunk.Width) + Chunk.Width) % Chunk.Width
    );

    public static int ToIndex(this Vector3 position) =>
        Chunk.GetIndexFromX((int)(position.X))
        + Chunk.GetIndexFromY((int)(position.Y))
        + Chunk.GetIndexFromZ((int)(position.Z));
}
