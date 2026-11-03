using System;
using TowerProtect.Domain.Client.Tiles.Model;
using TowerProtect.Domain.Model.Tiles;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Domain.Rendering;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Domain.Client.Tiles.Extensions;

internal static class TileRenderingExtensions
{
    public static IRenderable Render(this TileType self, Vec2Int pos, Func<Vec2Int, TileType?> tileAt)
    {
        if (!self.IsContoured())
            return self.GetMainRenderable(pos);

        Contour PartialContour(Vec2Int delta, Contour target)
            => self.GetContourLevel() > (tileAt(pos + delta)?.GetContourLevel() ?? 0) ? target : 0;

        Contour contour = 0;
        contour |= PartialContour(Vec2Int.Up, Contour.Up);
        contour |= PartialContour(Vec2Int.Down, Contour.Down);
        contour |= PartialContour(Vec2Int.Left, Contour.Left);
        contour |= PartialContour(Vec2Int.Right, Contour.Right);
        contour |= PartialContour(Vec2Int.Right + Vec2Int.Up, Contour.RightUp);
        contour |= PartialContour(Vec2Int.Right + Vec2Int.Down, Contour.RightDown);
        contour |= PartialContour(Vec2Int.Left + Vec2Int.Up, Contour.LeftUp);
        contour |= PartialContour(Vec2Int.Left + Vec2Int.Down, Contour.LeftDown);

        if (contour == 0)
            return self.GetMainRenderable(pos);

        Sprite contourSprite = new(
            TextureName: $"#c:{contour.ToKey()}",
            TextureArea: new Rect(pos),
            DisplayLayer: self.GetDisplayLayer() + 1
        );

        return self.IsInvisible()
            ? new SpriteGroup(pos, [contourSprite])
            : new SpriteGroup(pos, [self.GetMainSprite(pos), contourSprite]);
    }

    private static IRenderable GetMainRenderable(this TileType self, Vec2 position)
        => self.IsInvisible() ? NoSprites.Instance : self.GetMainSprite(position);

    private static Sprite GetMainSprite(this TileType self, Vec2 position)
        => new(position, self.GetTextureName(), self.GetDisplayLayer());
}
