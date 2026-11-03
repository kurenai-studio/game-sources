using AutoInterfaceAttributes;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using TowerProtect.Domain.Inventions.Tools;

namespace TowerProtect.Framework.Rendering.Textures;

[AutoInterface]
internal class TextureComponent(
    Game game,
    IContourTextureComponent contourTextureComponent) : GameComponent(game), ITextureComponent
{
    private LazyProvider<string, Texture2D> _textures = null!;

    public override void Initialize()
    {
        _textures = new LazyProvider<string, Texture2D>(AllocateTexture);

        base.Initialize();
    }

    public Texture2D Get(string fullKey) => _textures[fullKey];

    private Texture2D AllocateTexture(string fullKey)
    {
        if (!fullKey.StartsWith('#'))
            return Game.Content.Load<Texture2D>(fullKey);

        if (fullKey.StartsWith("#c:"))
            return contourTextureComponent.CreateByKey(fullKey.Split(':')[1]);

        throw new ContentLoadException($"Invalid texture pattern: {fullKey}");
    }
}
