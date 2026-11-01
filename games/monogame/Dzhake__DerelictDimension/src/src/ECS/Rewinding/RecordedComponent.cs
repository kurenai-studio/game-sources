namespace DerelictDimension.ECS.Rewinding;

public record struct RecordedComponent(IComponent? Component, bool? EnableEntity, bool ForceStore = false)
{
}
