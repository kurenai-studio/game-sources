using System.Diagnostics;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Monogame.Enchanted.Debug.Inspection;
using MonoGame.Extended;

namespace Monogame.Enchanted.Debug;

public static class DebugHelper
{
    [Conditional("DEBUG")]
    public static void DrawCircle(SpriteBatch spriteBatch, Vector2 center, float r)
    {
        spriteBatch.DrawCircle(center, r, 20, Color.White);
    }

    [Conditional("DEBUG")]
    public static void Inspect(object obj)
    {
        Inspector.Add(obj);
    }
}