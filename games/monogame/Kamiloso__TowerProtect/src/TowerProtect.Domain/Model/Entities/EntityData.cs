using System;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Model.Entities;

public readonly record struct EntityData(
    Guid Guid,
    EntityType Type,
    Vec2 Position,
    double Rotation);
