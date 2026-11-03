using System.Collections.Generic;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.App.Root.Display;

public interface IDisplayRoot
{
    IEnumerable<Sprite> DrawNextFrame();
}
