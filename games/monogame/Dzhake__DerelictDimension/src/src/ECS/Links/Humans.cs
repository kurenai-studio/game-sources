namespace DerelictDimension.ECS.Links;

public record struct HumanBody : ILinkComponent
{
    public Entity Body;
    public readonly Entity GetIndexedValue() => Body;
    public HumanBody(Entity body)
    {
        Body = body;
    }
}

public record struct HumanHead : ILinkComponent
{
    public Entity Head;
    public readonly Entity GetIndexedValue() => Head;
    public HumanHead(Entity head)
    {
        Head = head;
    }
}

public record struct HumanLeftLeg : ILinkComponent
{
    public Entity LeftLeg;
    public readonly Entity GetIndexedValue() => LeftLeg;
    public HumanLeftLeg(Entity leftLeg)
    {
        LeftLeg = leftLeg;
    }
}

public record struct HumanRightLeg : ILinkComponent
{
    public Entity RightLeg;
    public readonly Entity GetIndexedValue() => RightLeg;
    public HumanRightLeg(Entity rightLeg)
    {
        RightLeg = rightLeg;
    }
}