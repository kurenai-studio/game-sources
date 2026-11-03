using AutoInterfaceAttributes;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using TowerProtect.Domain.Client.Tiles.Model;

namespace TowerProtect.Framework.Rendering.Textures;

[AutoInterface]
internal class ContourTextureComponent(Game game) : GameComponent(game), IContourTextureComponent
{
    private const int TextureSize = 16;
    private const int TextureArraySize = TextureSize * TextureSize;
    private static readonly Color ContourColor = Color.Black * 1f;

    public Texture2D CreateByKey(string key)
    {
        Contour contour = ContourMethods.FromKey(key);

        int min = 0;
        int max = TextureSize - 1;

        var data = new Color[TextureArraySize];
        for (int i = 0; i < TextureArraySize; i++)
        {
            int x = i % TextureSize;
            int y = i / TextureSize;

            bool fill = (
                ((contour & Contour.Up) != 0 && y == min) ||
                ((contour & Contour.Down) != 0 && y == max) ||
                ((contour & Contour.Left) != 0 && x == min) ||
                ((contour & Contour.Right) != 0 && x == max) ||
                ((contour & Contour.RightUp) != 0 && x == max && y == min) ||
                ((contour & Contour.RightDown) != 0 && x == max && y == max) ||
                ((contour & Contour.LeftUp) != 0 && x == min && y == min) ||
                ((contour & Contour.LeftDown) != 0 && x == min && y == max)
            );

            data[i] = fill ? ContourColor : Color.Transparent;
        }

        var texture = new Texture2D(Game.GraphicsDevice, TextureSize, TextureSize);
        texture.SetData(data);

        return texture;
    }
}
