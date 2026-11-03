using System.Collections.Generic;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Rendering;

public interface ISpriteRenderingAware
{
    void RenderSprites(List<Sprite> targetSprites, ICameraView cameraView);
}
