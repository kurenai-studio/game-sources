using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics.Extensions;

public static class SpriteSheetExtensions
{
    public static Texture2DAtlas ToTexture2DAtlas(this FreeTexturePackerReader.SpriteSheet spriteSheet)
    {
        var result = new Texture2DAtlas(spriteSheet.Name, spriteSheet.Texture);
        foreach (var frame in spriteSheet.frames)
        {
            result.CreateRegion(frame.Value.sourceRect, frame.Key);
        }
        return result;
    }
}