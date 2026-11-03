using System;

namespace TowerProtect.Domain.Model.Entities;

public enum EntityType : byte
{
    Player = default,
    Animal = 1,
    Monster = 2,
    Sniper = 3,
    Insect = 4,
    Operator = 5,
    Drone = 6,
    Projectile = 7,
    Fruit = 8,
    Nest = 9,
}

public static class EntityTypeExtensions
{
    public static string GetTextureName(this EntityType self)
        => Enum.GetName(self) ?? Assets.Unknown;
}
