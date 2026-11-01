using System;

namespace DerelictDimension.ECS.PhysicsModule;

//TODO (modding:low) "ExtFlagsInfo" - like "ExtEnumInfo" but for flags
[Flags]
public enum CollisionLayer : ulong
{
    None = 0,
    Walls = 1,
    Player = 1 << 1,
    PlayerAttacks = 1 << 2,
    Enemy = 1 << 3,
    EnemyAttacks = 1 << 4,

    All = ulong.MaxValue,
}

