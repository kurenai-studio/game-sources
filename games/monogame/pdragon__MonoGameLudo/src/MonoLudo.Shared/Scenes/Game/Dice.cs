using System;
//using System.Numerics;
using MonoLudo.Core;
using Microsoft.Xna.Framework;
using System.Security.Cryptography.X509Certificates;
using Microsoft.Xna.Framework.Graphics;
using static System.Net.Mime.MediaTypeNames;

namespace MonoLudo.Shared.Scenes.Game;

public class Dice
{
    private Rectangle Bounds = Config.GetDiceBounds();
    private static short Value;
    public bool IsRolling { get; private set; }
    private double RollTime;

    public Dice()
    {
        Roll();
    }

    public static void Cheat(short value)
    {
        Value = value;
    }

    public void SetBounds(Rectangle bounds)
    {
        Bounds = new Rectangle(bounds.X, bounds.Y, bounds.Width, bounds.Height);
    }

    public static short GetValue()
    {
        return Value;
    }

    //public Rectangle GetBounds(Rectangle bounds) => Bounds;

    public void Roll()
    {
        //InitRandom();
        IsRolling = true;
        RollTime = 0.4f; // Длительность анимации в секундах

        // Генерация финального значения
        //Value = (rand() % 6) + 1;
        Random rnd = new Random((int)DateTime.Now.Ticks);
        Value = (short)rnd.Next(1, 7);
        //Value = 6;
    }

    public void Draw()
    {
        // Анимация вращения
        if (IsRolling)
        {
            RollTime -= Config.DeltaTime;//Time.GetFrameTime();

            if (RollTime <= 0)
            {
                IsRolling = false;
            }

            // Мигание во время броска
            if ((int)(RollTime * 10) % 2 == 0)
            {
                //Image.DrawRectangleRec(Bounds, ColorIndex.Maroon);
                return;
            }
        }
    }
    public static void OnScreenDraw()
    {
        //TODO: сделать спрайтом потом
        

        string text = Value.ToString();
        //Vector2 textSize = _font.MeasureString(text); // Размер текста в пикселях
        Vector2 textSize = new Vector2(20,30);
        float padding = 20; // Отступ от краёв

        // Позиция в правом нижнем углу с учётом размера текста
        Vector2 position = new Vector2(
            Main.Window.ClientBounds.Width - textSize.X - padding, // X
        Main.Window.ClientBounds.Height - textSize.Y - padding  // Y
        );

        //_spriteBatch.DrawString(_font, text, position, Color.Aqua);
        //Main.Text(Value.ToString(), new Vector2(Main.Window.ClientBounds.X - 200, Main.Window.ClientBounds.Y - 200), Color.Aqua);
        Main.Text(Value.ToString(), position, Color.Aqua);
    }
}