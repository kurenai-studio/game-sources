using System;
using System.Collections.Generic;
using System.Linq;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering;

namespace TowerProtect.Domain.Rendering.Sprites;

public readonly struct SpriteGroup(Vec2 position, IEnumerable<Sprite> sprites) : IRenderable<SpriteGroup>
{
    private readonly Vec2 _position = position;
    private readonly List<Sprite> _sprites = [.. sprites];

    public Vec2 Position => _position;
    public double Rotation { get; private init; } = 0.0;
    public IEnumerable<Sprite> Sprites => _sprites;

    public SpriteGroup Move(Vec2 deltaPosition)
    {
        if (deltaPosition == Vec2.Zero)
            return this;

        return new SpriteGroup(
            _position + deltaPosition,
            _sprites.Select(s => s.Move(deltaPosition))
        )
        { Rotation = Rotation };
    }

    public SpriteGroup Rotate(double deltaRotation)
    {
        if (deltaRotation == 0.0)
            return this;

        Vec2 pivot = _position;

        return new SpriteGroup(
            _position,
            _sprites.Select(s => s.RotateAround(pivot, deltaRotation))
        )
        { Rotation = (Rotation + deltaRotation) % (Math.PI * 2) };
    }

    public SpriteGroup MoveLocal(Vec2 deltaPositionLocal)
    {
        if (deltaPositionLocal == Vec2.Zero)
            return this;

        Vec2 rotatedDelta = deltaPositionLocal.Rotate(Rotation);

        return Move(rotatedDelta);
    }

    public SpriteGroup RotateAround(Vec2 pivot, double deltaRotation)
    {
        if (deltaRotation == 0.0)
            return this;

        Vec2 offset = _position - pivot;
        Vec2 rotatedOffset = offset.Rotate(deltaRotation);
        Vec2 newPosition = pivot + rotatedOffset;

        return new SpriteGroup(
            newPosition,
            _sprites.Select(s => s.RotateAround(pivot, deltaRotation))
        )
        { Rotation = (Rotation + deltaRotation) % (Math.PI * 2) };
    }
}