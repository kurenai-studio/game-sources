using System;
using TowerProtect.Domain.Client.Entities.Interpolation;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Client.Entities.Model;

internal class SmoothEntity : IUpdateAware
{
    private readonly PositionInterpolator _positionItp = new();
    private readonly RotationInterpolator _rotationItp = new();

    private EntityData? _initialEntity;

    public void Tick(EntityData currentEntity, double tickTime)
    {
        _initialEntity ??= currentEntity;

        _positionItp.Tick(currentEntity.Position, tickTime);
        _rotationItp.Tick(currentEntity.Rotation, tickTime);
    }

    public void Update(double deltaTime)
    {
        _positionItp.Update(deltaTime);
        _rotationItp.Update(deltaTime);
    }

    public EntityData Interpolate()
    {
        if (!_initialEntity.HasValue)
            throw new InvalidOperationException("Cannot interpolate before first tick");

        return _initialEntity.Value with
        {
            Position = _positionItp.Interpolate(),
            Rotation = _rotationItp.Interpolate(),
        };
    }
}
