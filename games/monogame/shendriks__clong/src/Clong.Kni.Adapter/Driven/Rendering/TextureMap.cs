using Clong.Core.Domain.Enum;
using Microsoft.Xna.Framework.Graphics;

namespace Clong.Kni.Adapter.Driven.Rendering;

public class TextureMap
{
    private readonly Dictionary<TextureId, Texture2D> _textures = new();

    public Texture2D this[TextureId t] {
        get => _textures[t];
        init => _textures[t] = value;
    }
}