using System.Collections.Generic;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.App.Root.Display;

internal class MenuDisplayRoot : IDisplayRoot
{
    private readonly List<Sprite> _targetSprites = [];

    public IEnumerable<Sprite> DrawNextFrame()
    {
        // TODO: Implement menu display rendering logic here

        _targetSprites.Clear();
        // fill _sprites here

        return _targetSprites;
    }
}
