using System;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics.Actors;

public static class AtlasParser
{
    private static Sprite[] GetBaseSprites(Texture2DAtlas atlas, string mainText)
    {
        var regions = atlas.Where(x => x.Name.Contains(mainText, StringComparison.OrdinalIgnoreCase)).ToArray();
        var sprites = new Sprite[Enum.GetNames<Direction>().Length];
        
        foreach (var direction in Enum.GetValues<Direction>())
        {
            var key = direction switch
            {
                Direction.Up => "back",
                Direction.Down => "front",
                Direction.Left => "R View",
                Direction.Right => "R View",
                _ => throw new ArgumentOutOfRangeException(nameof(direction), direction, null)
            };
            sprites[(int)direction] = new Sprite(regions.First(x => x.Name.Contains(key, StringComparison.OrdinalIgnoreCase)))
            {
                OriginNormalized = new Vector2(0.5f, 0.5f),
            };
            if (direction == Direction.Left)
                sprites[(int)direction].Effect |= SpriteEffects.FlipHorizontally;
        }
        return sprites;
    }

    public static Sprite[] GetBootSprites(Texture2DAtlas atlas) => GetBaseSprites(atlas, "leg");

    public static Sprite[] GetHeadSprites(Texture2DAtlas atlas) => GetBaseSprites(atlas, "head");
    
    public static Sprite[] GetBodySprites(Texture2DAtlas atlas) => GetBaseSprites(atlas, "body");

    public static Sprite[] GetWeaponSprites(Texture2DAtlas atlas)
    {
        var region = atlas.First(x => x.Name.Contains("weapon", StringComparison.OrdinalIgnoreCase));
        var sprites = new Sprite[Enum.GetNames<Direction>().Length];
        foreach (var direction in Enum.GetValues<Direction>())
        {
            sprites[(int)direction] = new Sprite(region)
            {
                OriginNormalized = new Vector2(0.5f, 0.5f),
            };
            
            //if (direction == Direction.Right)
                sprites[(int)direction].Effect |= SpriteEffects.FlipHorizontally;
        }
        return sprites;
    }
}