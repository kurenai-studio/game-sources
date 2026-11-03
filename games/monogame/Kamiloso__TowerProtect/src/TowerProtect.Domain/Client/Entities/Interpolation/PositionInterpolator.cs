using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Client.Entities.Interpolation;

internal class PositionInterpolator : InterpolatorBase<Vec2>
{
    protected override Vec2 InterpolateCore(Vec2 p0, Vec2 p1, Vec2 p2, Vec2 p3, double t, double t2, double t3)
    {
        return new Vec2(
            CatmullRom(p0.x, p1.x, p2.x, p3.x, t, t2, t3),
            CatmullRom(p0.y, p1.y, p2.y, p3.y, t, t2, t3)
        );
    }
}
