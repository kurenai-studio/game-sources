namespace DerelictDimension.ECS.PhysicsModule;

public record struct OrientedRect
{
    public Vector2 Center;
    public float Width;
    public float Height;
    /// <summary>
    /// Angle in radians.
    /// </summary>
    public float Angle;

    public OrientedRect(Vector2 center, float width, float height, float angle = 0)
    {
        Center = center;
        Width = width;
        Height = height;
        Angle = angle;
    }

    public OrientedRect(float centerX, float centerY, float width, float height, float angle = 0) : this(new(centerX, centerY), width, height, angle) { }

    public override string ToString() => $"Center: {Center}; Width: {Width}; Height: {Height}; Angle: {Angle}";
}
