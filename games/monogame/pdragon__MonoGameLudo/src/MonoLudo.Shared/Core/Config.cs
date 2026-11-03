using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;
using MonoLudo.Shared;

namespace MonoLudo.Core;

public static class Config
{
    public static double DeltaTime { get; set; }
    public static Texture2D BackgroundTexture;
    public static Texture2D[] CircleTexture = new Texture2D[4];
    // Window
    public const int ScreenWidth = 1155;
    //public const int ScreenHeight = 1155;
    public const int ScreenHeight = 1200;

    // Players
    public const short MaxPlayers = 4;
    public const int TokensPerPlayer = 4;
    public const float TokenRadius = 15f;

    public const int TargetFPS = 60;

    // Board
    public const int BoardPadding = 50;
    //public const int CellSize = 80;//77;
    public static Point CellSize { get; private set; } = new Point(128, 72);

    //StartPositions
    static public Dictionary<ColorIndex, short> StartPosition
    {
        get
        {
            return new Dictionary<ColorIndex, short>()
            {
                { ColorIndex.Blue, 17 },
                { ColorIndex.Red, 4 },
                { ColorIndex.Green, 43 },
                { ColorIndex.Yellow, 30 }
            };
        }
    }// = new Dictionary<ColorIndex, short>();
    
    public enum ColorIndex : int
    {
        Blue = 0,
        Red = 1,
        Green = 2,
        Yellow = 3,
        Neutral = 4
    }

    public static Dictionary<ColorIndex, short> HomeEntryTile
    {
        get
        {
            return new Dictionary<ColorIndex, short>()
            {
                { ColorIndex.Blue, 15 },
                { ColorIndex.Red, 2 },
                { ColorIndex.Green, 41 },
                { ColorIndex.Yellow, 28 }
            };
        }
    }

    public static readonly Color[] PlayerColors =
    {
        Color.CornflowerBlue, //new(50, 120, 230, 255), // Blue
        Color.Red, //new(230, 50, 50, 255),    // Red
        Color.LightGreen, //new(50, 230, 120, 255),   // Green
        Color.Yellow //new(230, 230, 50, 255)    // Yellow
    };

    public static string GetBoardTexturePath() => "./"+Main.AssetDirectory+"/background.png";
    //public static string GetBoardTexturePath() => "assets\\background.png";


    // Расширение для работы с прозрачностью
    public static Color WithAlpha(this Color color, byte alpha)
        => new(color.R, color.G, color.B, alpha);

    public static Rectangle GetDiceBounds() => new Rectangle(ScreenWidth - 150, ScreenHeight - 150, 100, 100);
    //public static Rectangle GetDiceBounds() => new Rectangle(0, 0, 100, 100);
}