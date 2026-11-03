using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Text;

using Microsoft.Xna.Framework;

namespace MonoLudo.Shared.Helpers
{
    public static class Render
    {
        // Создайте текстуру круга (выполняется один раз при инициализации)
        public static Texture2D CreateCircleTexture(GraphicsDevice graphicsDevice, int radius, Color color)
        {
            int diameter = radius * 2;
            Texture2D texture = new Texture2D(graphicsDevice, diameter, diameter);
            Color[] colorData = new Color[diameter * diameter];

            for (int y = 0; y < diameter; y++)
            {
                for (int x = 0; x < diameter; x++)
                {
                    int dx = radius - x;
                    int dy = radius - y;
                    if (dx * dx + dy * dy <= radius * radius)
                        colorData[y * diameter + x] = color;
                }
            }

            texture.SetData(colorData);
            return texture;
        }
    }
}
