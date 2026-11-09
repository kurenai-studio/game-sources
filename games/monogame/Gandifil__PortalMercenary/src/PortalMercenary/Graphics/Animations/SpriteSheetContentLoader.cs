using System;
using Microsoft.Xna.Framework.Content;
using MonoGame.Extended.Content;
using MonoGame.Extended.Graphics;
using MonoGame.Extended.Serialization.Json;
using PortalMercenary.Graphics.Extensions;

namespace PortalMercenary.Graphics.Animations;

public class SpriteSheetContentLoader: IContentLoader<SpriteSheet>
{
    private readonly JsonContentLoader _loader = new ();
    
    public SpriteSheet Load(ContentManager contentManager, string path)
    {
        var model = _loader.Load<SpriteSheetModel>(contentManager, path);
        var spriteSheet = G.Content.FreeTexPackerSpritesheets[model.Atlas];

        var result = new SpriteSheet(spriteSheet.Name, spriteSheet.ToTexture2DAtlas());
        foreach (var animation in model.Animations)
        {
            result.DefineAnimation(animation.Name, builder =>
            {
                builder.IsLooping(animation.IsLooping);
                foreach (var frame in animation.Frames)
                {
                    builder.AddFrame(frame.Name, TimeSpan.FromSeconds(frame.Duration));
                }
            });
        }

        return result;
    }
}