using System.Collections.Generic;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Client.Entities;
using TowerProtect.Domain.Display.Tiles;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.App.Root.Display;

internal class GameplayDisplayRoot(
    IWorldDisplay worldDisplay,
    IEntitiesDisplay entitiesDisplay,
    ICameraView cameraView) : IDisplayRoot
{
    private readonly List<Sprite> _targetSprites = [];

    public IEnumerable<Sprite> DrawNextFrame()
    {
        _targetSprites.Clear();

        worldDisplay.RenderSprites(_targetSprites, cameraView);
        entitiesDisplay.RenderSprites(_targetSprites, cameraView);

        return _targetSprites;
    }
}
