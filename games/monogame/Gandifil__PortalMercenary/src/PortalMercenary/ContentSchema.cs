using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Monogame.Enchanted.Content;
using MonoGame.Extended.Graphics;
using MonoGame.Extended.Serialization.Json;
using PortalMercenary.Game;
using PortalMercenary.Graphics.Animations;

namespace PortalMercenary;

public class ContentSchema(ContentManager contentManager)
{
    public readonly ContentLoaderFolder<CharacterOptions> Characters = 
        new(contentManager, "characters/", ".json", new JsonContentLoader());
    
    public readonly Folder<FreeTexturePackerReader.SpriteSheet> FreeTexPackerSpritesheets = new(contentManager, "images/");
    
    public readonly Folder<Texture2D> Textures = new(contentManager, "images/");
    
    public readonly Folder<SoundEffect> Sounds = new(contentManager, "sounds/");
    
    public readonly Folder<Effect> Effects = new(contentManager, "effects/");
    
    public readonly ContentLoaderFolder<SpriteSheet> Spritesheets = 
        new(contentManager, "images/", ".json", new SpriteSheetContentLoader());
}