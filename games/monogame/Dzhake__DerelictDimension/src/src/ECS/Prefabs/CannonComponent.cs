using System.Linq;

namespace DerelictDimension.ECS.Prefabs;

public record struct CannonInfoComponent : IComponent
{
    public Vector2[]? Points = null;
    public string PrefabPath;
    public float FiringInterval = 1;
    public float ProjectileVelocity = 300;

    //[Ignore]
    //public PrefabAsset Prefab;

    //limit amount of entities shot by this cannon?
    //sound effect (asset)
    //sound volume scale (float)

    public CannonInfoComponent(string prefabPath, float firingInterval = 1, Vector2[]? points = null)
    {
        PrefabPath = prefabPath;
        FiringInterval = firingInterval;
        Points = points;
    }

    public static void CopyValue(in CannonInfoComponent source, ref CannonInfoComponent target, in CopyContext context)
    {
        target.Points = source.Points?.ToArray();
        target.PrefabPath = source.PrefabPath;
        target.FiringInterval = source.FiringInterval;
        target.ProjectileVelocity = source.ProjectileVelocity;
    }
}

public record struct CannonComponent : IComponent
{
    public float TimeUntilNextShot;
}
