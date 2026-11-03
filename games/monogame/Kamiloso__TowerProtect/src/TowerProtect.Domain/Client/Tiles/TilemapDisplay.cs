using System;
using System.Collections.Generic;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Client.Tiles.Extensions;
using TowerProtect.Domain.Inventions.Tools;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Client.Tiles;

internal class TilemapDisplay(int range, Func<Vec2Int, TileData> populator) : ISpriteRenderingAware
{
    private readonly Area<TileData> _area = new(range, populator);

    public void Set(Vec2Int pos, TileData tileData)
    {
        if (!_area.ContainsKey(pos))
            return;

        _area[pos] = tileData;
    }

    public void RenderSprites(List<Sprite> targetSprites, ICameraView cameraView)
    {
        TileType? TileAt(Vec2Int pos)
            => _area.ContainsKey(pos) ? _area[pos].Type : null;

        cameraView.ExtendedVisionArea.GridIterate(pos =>
        {
            if (!_area.ContainsKey(pos))
                return;

            var sprites = _area[pos].Type.Render(pos, TileAt).Sprites;
            targetSprites.AddRange(sprites);
        });
    }
}
