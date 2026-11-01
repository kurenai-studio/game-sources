using Box2D.NET;
using DerelictDimension.ECS.PhysicsModule;
using DerelictDimension.Utils.Extensions;
using Friflo.Engine.ECS.Systems;
using Monod.Graphics;
using Monod.Graphics.Fonts;
using System;
using static Box2D.NET.B2Types;
using static Box2D.NET.B2Worlds;

namespace DerelictDimension.ECS.Drawing;

public class DrawHitboxesSystem : BaseSystem
{
    public static B2DebugDraw draw = b2DefaultDebugDraw();
    public static bool Enabled;

    protected override void OnUpdateGroup()
    {
        if (!Enabled) return;
        Renderer.ShapeBegin();
        b2World_Draw(Physics.WorldId, in draw);
        Renderer.ShapeEnd();
        base.OnUpdateGroup();
    }

    protected override void OnAddStore(EntityStore store)
    {
        draw.DrawPointFcn = DrawPoint;
        draw.DrawLineFcn = DrawLine;
        draw.DrawTransformFcn = DrawTransform;
        draw.DrawCircleFcn = DrawCircle;
        draw.DrawSolidCircleFcn = DrawSolidCircle;
        draw.DrawPolygonFcn = DrawPolygon;
        draw.DrawSolidPolygonFcn = DrawSolidPolygon;
        draw.DrawSolidCapsuleFcn = DrawSolidCapsule;
        draw.DrawStringFcn = DrawString;

        base.OnAddStore(store);
    }

    // Size is in screen pixels.
    // Box2D draws solid dots, hence FillCircle.
    private void DrawPoint(in B2Vec2 p, float size, B2HexColor color, object context)
    {
        Renderer.shapeBatch.FillCircle(p.ToXNA() * Physics.PixelsInMeter, size * 0.5f, color.ToXNA());
    }

    private void DrawLine(in B2Vec2 p1, in B2Vec2 p2, B2HexColor color, object context)
    {
        Renderer.shapeBatch.FillLine(p1.ToXNA() * Physics.PixelsInMeter, p2.ToXNA() * Physics.PixelsInMeter, 1f, color.ToXNA());
    }

    // Body origin cross: X axis = red, Y axis = green (Box2D testbed convention).
    // b2World_Draw calls this when drawMass is enabled.
    private void DrawTransform(in B2Transform transform, object context)
    {
        const float axisScale = 0.3f; // meters, same as Box2D's own k_axisScale

        B2Vec2 p = transform.p;
        B2Vec2 px = p + axisScale * B2MathFunction.b2Rot_GetXAxis(transform.q);
        B2Vec2 py = p + axisScale * B2MathFunction.b2Rot_GetYAxis(transform.q);

        Renderer.shapeBatch.FillLine(p.ToXNA() * Physics.PixelsInMeter, px.ToXNA() * Physics.PixelsInMeter, 1f, B2HexColor.b2_colorRed.ToXNA());
        Renderer.shapeBatch.FillLine(p.ToXNA() * Physics.PixelsInMeter, py.ToXNA() * Physics.PixelsInMeter, 1f, B2HexColor.b2_colorGreen.ToXNA());
    }

    private void DrawCircle(in B2Vec2 center, float radius, B2HexColor color, object context)
    {
        Renderer.shapeBatch.BorderCircle(center.ToXNA() * Physics.PixelsInMeter, radius * Physics.PixelsInMeter, color.ToXNA());
    }

    private void DrawSolidCircle(in B2Transform transform, float radius, B2HexColor color, object context)
    {
        // transform.p is already the world-space center: b2World_Draw composes the body transform
        // with the circle's local offset before calling. transform.q is the body rotation — a
        // circle is rotation-invariant, it is only passed in case you want to draw a rotation
        // indicator (a line from center along the axis), which Box2D's own renderer doesn't do.
        Renderer.shapeBatch.FillCircle(transform.p.ToXNA() * Physics.PixelsInMeter, radius * Physics.PixelsInMeter, color.ToXNA());
    }

    // Wireframe outline (drawBounds and drawIslands use this callback): no fill, ~1px stroke.
    private void DrawPolygon(ReadOnlySpan<B2Vec2> vertices, int vertexCount, B2HexColor color, object context)
    {
        var c = color.ToXNA();
        Renderer.shapeBatch.BeginBorderPath(0.5f, c);
        for (int i = 0; i < vertexCount; i++)
            Renderer.shapeBatch.PathTo(vertices[i].ToXNA() * Physics.PixelsInMeter);
        Renderer.shapeBatch.ClosePath();
    }

    private void DrawSolidPolygon(in B2Transform transform, ReadOnlySpan<B2Vec2> vertices, int vertexCount, float radius, B2HexColor color, object context)
    {
        var c = color.ToXNA();

        // Vertices are in shape-LOCAL coordinates and must be transformed.
        Span<Vector2> verts = stackalloc Vector2[vertexCount];
        for (int i = 0; i < vertexCount; i++)
            verts[i] = B2MathFunction.b2TransformPoint(transform, vertices[i]).ToXNA() * Physics.PixelsInMeter;

        // Box2D polygons are convex, so a fan from vertex 0 fills the interior.
        for (int i = 1; i < vertexCount - 1; i++)
            Renderer.shapeBatch.FillTriangle(verts[0], verts[i], verts[i + 1], c);

        float skinRadius = radius * Physics.PixelsInMeter;
        if (skinRadius > 0f)
        {
            Renderer.shapeBatch.BeginFillPath(skinRadius, c);
            for (int i = 0; i < vertexCount; i++)
                Renderer.shapeBatch.PathTo(verts[i]);
            Renderer.shapeBatch.ClosePath();
        }
    }

    // p1/p2 arrive already in world coordinates (Box2D transforms the capsule's local centers).
    private void DrawSolidCapsule(in B2Vec2 p1, in B2Vec2 p2, float radius, B2HexColor color, object context)
    {
        Renderer.shapeBatch.FillLine(p1.ToXNA() * Physics.PixelsInMeter, p2.ToXNA() * Physics.PixelsInMeter, radius * Physics.PixelsInMeter, color.ToXNA());
    }

    private void DrawString(in B2Vec2 p, string s, B2HexColor color, object context)
    {
        Renderer.shapeBatch.DrawString(GlobalFonts.ShapeMenuFont, s, p.ToXNA() * Physics.PixelsInMeter, 20, color.ToXNA());
    }
}
