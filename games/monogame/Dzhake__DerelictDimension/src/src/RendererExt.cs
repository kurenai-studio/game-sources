using DerelictDimension.ECS.PhysicsModule;
using Monod.Graphics;

namespace DerelictDimension;

public static class RendererExt
{
    public static void DrawRotRect(OrientedRect rect, Color? color = null) => Renderer.DrawRotRect(rect.Center.X, rect.Center.Y, rect.Width, rect.Height, rect.Angle, color);
    public static void DrawRotRect(AABB rect, float rotation, Color? color = null) => Renderer.DrawRotRect(rect.Center.X, rect.Center.Y, rect.Width, rect.Height, rotation, color);
}
