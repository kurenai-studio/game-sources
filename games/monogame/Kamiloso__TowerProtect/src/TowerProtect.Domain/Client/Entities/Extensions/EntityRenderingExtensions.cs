using System;
using System.Diagnostics;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering;
using TowerProtect.Domain.Rendering.Model;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Client.Entities.Extensions;

internal static class EntityRenderingExtensions
{
    public static IRenderable Render(this EntityData entity, Guid mainGuid, Stopwatch stopwatch)
    {
        Vec2 position = entity.Position;
        double rotation = entity.Rotation;

        var layer = entity.Guid == mainGuid
            ? Layer.Player
            : Layer.Entity;

        return new Animated<IRenderable>(t => new SpriteGroup(position,
            [
                new Sprite(position, "Rock", layer),
                new Sprite(position + 1.5 * Vec2.Right, "Spawner", layer),
            ]
        ).Rotate(rotation)).Evaluate(stopwatch);
    }
}
