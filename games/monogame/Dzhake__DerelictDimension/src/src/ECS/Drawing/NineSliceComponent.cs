namespace DerelictDimension.ECS.Drawing;

public record struct NineSliceComponent : IComponent
{
    /// <summary>
    /// Size of the area to be filled with the sprite.
    /// </summary>
    public Vector2 DrawSize;

    public NineSliceComponent(Vector2 drawSize)
    {
        DrawSize = drawSize;
    }
}
