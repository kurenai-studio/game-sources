using System.Numerics;
using Clong.Core.Domain.Enum;

namespace Clong.Core.Ports.Driven;

public interface IForRendering
{
    public void DrawTexture(TextureId texture, Vector2 position);
    public void DrawString(string text, Vector2 position, float scale = 1f, bool alignCentered = true);
}