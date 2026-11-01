namespace DerelictDimension.ECS.Rewinding;

public record struct CreatedAtComponent : IComponent
{
    public int Frame;

    public CreatedAtComponent()
    {
        Frame = Rewind.CurrentFrame;
    }
}
