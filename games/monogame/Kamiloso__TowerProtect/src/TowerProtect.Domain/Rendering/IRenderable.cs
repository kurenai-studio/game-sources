using System.Collections.Generic;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Rendering;

public interface IRenderable
{
    Vec2 Position { get; }
    double Rotation { get; }
    IEnumerable<Sprite> Sprites { get; }
}

public interface IRenderable<T> : IRenderable where T : IRenderable<T>
{
    T Move(Vec2 deltaPosition);
    T Rotate(double deltaRotation);
    T MoveLocal(Vec2 deltaPositionLocal);
    T RotateAround(Vec2 pivot, double deltaRotation);
}
