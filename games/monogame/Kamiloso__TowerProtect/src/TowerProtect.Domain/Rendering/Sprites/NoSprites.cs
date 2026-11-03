using System.Collections.Generic;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering;

namespace TowerProtect.Domain.Rendering.Sprites;

public class NoSprites : IRenderable
{
    public Vec2 Position => Vec2.Zero;
    public double Rotation => 0.0;
    public IEnumerable<Sprite> Sprites => [];

    public static NoSprites Instance { get; } = new();
    private NoSprites() { }
}
