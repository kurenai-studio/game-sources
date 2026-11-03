using AutoInterfaceAttributes;
using System;
using TowerProtect.Domain.Model.Vectors;
using static TowerProtect.Domain.Config.CameraConfig;

namespace TowerProtect.Domain.Rendering.Camera;

[AutoInterface]
public class CameraView : ICameraView
{
    public Vec2 Center { get; set; }
    public double Zoom { get; set; }

    public Rect VisionArea => new(Center, AspectRatio >= 1.0
        ? Side * new Vec2(AspectRatio, 1.0)
        : Side * new Vec2(1.0, 1.0 / AspectRatio));

    public Rect ExtendedVisionArea
        => new(Center, VisionArea.Size * CullingRangeMultiplier);

    public double AspectRatio
    {
        private get;
        set
        {
            ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(value, 0.0);
            field = value;
        }
    } = 1.0;

    private double Side => DefaultSide / Math.Pow(2.0, Zoom);

    public void ApplyTransform(Vec2 center, double zoom)
    {
        Center = center;
        Zoom = zoom;
    }

    public void ResetTransform() => ApplyTransform(Vec2.Zero, 0.0);

    public bool IsCulled(Vec2 position)
    {
        Vec2 delta = (Center - position).Abs;
        Vec2 limit = ExtendedVisionArea.Size / 2.0;

        return delta.x > limit.x || delta.y > limit.y;
    }
}
