namespace TowerProtect.Domain.Rendering.Model;

public enum Layer
{
    Effects = 60,
    Solid = 50,
    Unsolid = 40,
    Player = 30,
    Entity = 20,
    Fluid = 10,
    Default = 0,
    Floor = -10,
    Border = -20,
}

public static class LayerExtensions
{
    private const int Min = -100;
    private const int Max = 100;

    public static float ToDepthLayer(this Layer layer)
        => (float)((int)layer - Min) / (Max - Min);
}
