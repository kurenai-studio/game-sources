using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Client.Entities.Extensions;
using TowerProtect.Domain.Client.Entities.Model;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Unions;
using TowerProtect.Domain.Rendering;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Client.Entities;

partial interface IEntitiesDisplay : IUpdateAware, ISpriteRenderingAware;

[AutoInterface]
internal class EntitiesDisplay : IEntitiesDisplay
{
    private readonly Swap<Dictionary<Guid, SmoothEntity>> _smoothEntities = new();
    private readonly Stopwatch _sw = Stopwatch.StartNew();

    private Guid _playerGuid;

    public void Tick(FrameUnion frameUnion)
    {
        _playerGuid = frameUnion.PlayerGuid;

        frameUnion.ForEach(entity =>
        {
            var guid = entity.Guid;

            _smoothEntities.Current.TryGetValue(guid, out var smoothEntity);

            smoothEntity ??= new SmoothEntity();
            smoothEntity.Tick(entity, frameUnion.TickTime);

            _smoothEntities.Other[guid] = smoothEntity;
        });

        _smoothEntities.Exchange();
        _smoothEntities.Other.Clear();
    }

    public void Update(double deltaTime)
    {
        foreach (var smoothEntity in _smoothEntities.Current.Values)
        {
            smoothEntity.Update(deltaTime);
        }
    }

    public void RenderSprites(List<Sprite> targetSprites, ICameraView cameraView)
    {
        foreach (var smoothEntity in _smoothEntities.Current.Values)
        {
            var entity = smoothEntity.Interpolate();
            var sprites = entity.Render(_playerGuid, _sw).Sprites;
            targetSprites.AddRange(sprites);
        }
    }
}
