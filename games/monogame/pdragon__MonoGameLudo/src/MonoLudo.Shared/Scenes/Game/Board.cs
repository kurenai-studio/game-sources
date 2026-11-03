//логика игровой доски
using System;
using System.Xml;
using System.Linq;
using MonoLudo.Core;
using MonoLudo.Helpers;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoLudo.Shared.Scenes.Game;
using System.Reflection.Metadata;
//using System.Drawing;
//using static MonoLudo.Game.Board;

namespace MonoLudo.Shared.Scenes.Game;

public class Tile
{
    public short Id { get; set; }
    public int PropertiesBitSet { get; set; }
    public Vector2 Position { get; set; }
    public Config.ColorIndex? Color { get; set; } = Config.ColorIndex.Neutral;

    public Token GetFirstTokenOnTile(Player player)
    {
        foreach (var token in player.Tokens)
        {
            if (token != null && token.Tile != null && token.Tile.Id == Id)
            {
                if (Color == Config.ColorIndex.Neutral || Color == token.PlayerColor && token.IsInHome)
                    return token;
            }
        }
        return null;
    }

    public Rectangle GetRectangle()
    {
        return new Rectangle((int)Position.X - Config.CellSize.X / 2, (int)Position.Y - Config.CellSize.Y / 2, Config.CellSize.X, Config.CellSize.Y);
    }
}


/// <summary>
/// В этом классе следует определить позиции и размеры различных элементов: основное поле, цветные зоны игроков, безопасные клетки, центральный квадрат и т.д.
/// </summary>
public class Board
{
    public Tile Tile { get; set; }
    public const short TILE_NOT_EXIST = -1;
    public Rectangle Bounds { get; }
    public static Dictionary<short, Tile> Tiles = new Dictionary<short, Tile>();
    public static Dictionary<short, Tile>[] HomeTiles = new Dictionary<short, Tile>[4];
    private static short LastNeutralTileId { get { return Tiles.Count > 0?Tiles.Where(t => t.Value!.Color == Config.ColorIndex.Neutral).Last().Value!.Id:(short)0; } }

    Texture2D Background;
    public static Dictionary<Config.ColorIndex, Vector2> PlayerStaringPosition = new(){
        //{ Config.ColorIndex.Blue, new Vector2(920, 920)},
        { Config.ColorIndex.Blue, new Vector2(1460, 825)},
        { Config.ColorIndex.Red, new Vector2(1460, 180)},
        { Config.ColorIndex.Green, new Vector2(310, 180)},
        { Config.ColorIndex.Yellow, new Vector2(310, 825)}
    };



    public Board()
    {
        if (Tiles.Count == 0)
        {
        }
        Bounds = new Rectangle(
            Config.BoardPadding,
            Config.BoardPadding,
            Config.ScreenWidth - 2 * Config.BoardPadding,
            Config.ScreenHeight - 2 * Config.BoardPadding
        );
        //Background = Texture2D.Load(Config.GetBoardTexturePath());
    }

    public enum TokenBasePositionName : short
    {
        Up = 0,
        Down = 1,
        Left = 2,
        Right = 3
    }

    public static readonly Dictionary<TokenBasePositionName, Vector2> TokenStartPosition = new()
    {
        {TokenBasePositionName.Up, new Vector2(0,-Config.CellSize.Y) },
        {TokenBasePositionName.Down, new Vector2(0,Config.CellSize.Y) },
        {TokenBasePositionName.Left, new Vector2(-Config.CellSize.X,0) },
        {TokenBasePositionName.Right, new Vector2(Config.CellSize.X,0) }
    };

    public static Vector2 GetTokenStartPosition(TokenBasePositionName posDirection, Config.ColorIndex player)
    {
        Vector2 pos = PlayerStaringPosition[player];
        return pos + TokenStartPosition[posDirection];
    }

    public void Draw()
    {
        //Graphics.DrawTexture(Background, 0, 0, Color.White);
        DebugTiles();
    }

    public static Tile GetTileById(short id)
    {
        var amountNeutralTile = Tiles.Where(t => t.Value!.Color == Config.ColorIndex.Neutral).Count();
        if ( Tiles.Count + 1 > id)
        {
            if (amountNeutralTile + 1 > id)
            {
                return Tiles.Select(a => a.Value).Where(w => w!.Id == id).FirstOrDefault();
            }
            // TODO: тут баг с зелёными, так как там домашняя это последняя плитка, то  при попытке прыгнуть дальше оно думает что фишка переходит через последнюю нейтральную
            // чтобы его поправить надо сразу возвращать в CalculateDestTile плитку а не ИД плитки и тогда не придётся именно этот метод запускать.
            // 瓷砖已经结束了，所以我们跳过零瓷砖
            // плитки закончились и потому перепрыгиваем через нулевую плитку
            return Tiles.Select(a => a.Value).Where(w => w!.Id == id - Tiles.Count).FirstOrDefault();
        }
        return null;
    }

    /// <summary>
    /// Тут записана базовая логика обработки перехода по плиткам (переход через последнюю плитку на первую, переход на домашнюю и т.д.), по сути сюда можно отправлять
    /// сколько выпало на кубике и текущую плитку, на которой стоит фишка и будет возвращать на какую переходить с учётом условий.
    /// </summary>
    /// <param name="token">Плитка на которой стоит фишка, ход которой требуется рассчитать</param>
    /// <param name="diceValue">сколько выпало на кубике</param>
    /// <returns>Финальная плитка на которую нужно переходить, а ежели вернуло Board. Null то это значит что ходов у фишки нет 
    /// (например фишка стоит в домашнем регионе и ходов выпало на кубике больше чем дойти до дома)</returns>
    /// <exception cref="Exception">Эти исключения могут прорабатывать если пользователь напутает чтото в файле: settings.xml</exception>
    public static Tile CalculateDestTile(Token token, short diceValue)
    {
        //TODO: Добавить вычисления фишек с баз, таким образом это получится единая точка подсчёта. что будет крайне удобно и код станет гораздо чище.
        bool tokenNewBoardRound = false;
        if(token == null || token.Tile == null)
        {
            throw new Exception($"Token empty or don't has tile.Id");
        }
        short sourceId = token.Tile.Id;
        short destId = (short)(sourceId + diceValue)!;
        
        if(sourceId > destId)
        {
            destId = (short)(destId - LastNeutralTileId);
            tokenNewBoardRound = true;
        }
        short sourceTileId = token!.Tile!.Id;
        if (Game.CurrentPlayerIndex != (short)Config.ColorIndex.Neutral)
        {
            short homeEntranceTileId = Config.HomeEntryTile[(Config.ColorIndex)Game.CurrentPlayerIndex];
            if ((sourceTileId <= homeEntranceTileId || tokenNewBoardRound) && destId > homeEntranceTileId)
            {
                short beforeHomeTiles = (short)(homeEntranceTileId - sourceTileId);
                Tile firstHomeTile = Tiles.Select(t => t.Value).FirstOrDefault(w => w?.Color == token.PlayerColor);
                if (firstHomeTile != null)
                {
                    Tile homeTile = Tiles.Select(t => t.Value).Where(w => w?.Color == token.PlayerColor).Last();
                    if (homeTile == null)
                    {
                        throw new Exception($"cant find home tiles for player {token.PlayerColor.ToString()}");
                    }
                    // -1 Потому firstHomeTile.Id что это первая домашняя плитка, а ведь перед ней обычная нейтральная ещё, на которую в домашнюю вход, да мы нейтральную уже посчитали,
                    // однако тогда не корректно начинать считать с неё ибо она сама тогда в расчёте не участвует
                    destId = (short)(firstHomeTile.Id + diceValue - beforeHomeTiles - 1);
                    Tile destTile = Tiles.Select(t => t.Value!).Where(w => w.Color == token.PlayerColor && w.Id == destId).FirstOrDefault();
                    return destTile?.Id <= homeTile.Id ? destTile : null;
                    //return destId <= homeTile.Id?destId:TILE_NOT_EXIST;
                }
            }
        }
        Tile realDestTile = Tiles.Select(t => t.Value!).Where(w => w.Id == destId).FirstOrDefault();
        // Если фишки в преддомовой зоне и выпало на кубике число больше чем дом у этой фракции
        if (realDestTile != null && realDestTile.Color != Config.ColorIndex.Neutral && token.PlayerColor != realDestTile.Color)
        {
            return null;
        }
        return Tiles.Select(t => t.Value!).Where(w => w.Id == destId).FirstOrDefault();
        //return null;
    }

    public static bool TileIsOccupied(Tile tile, short forPlayerId)
    {
        if (tile != null)
        {
            var enemyTokensOnTile = GetEnemyTokensOnTile(tile, forPlayerId);
            return enemyTokensOnTile.Count > 1;
        }
        return true;
    }

    public static List<Token> GetEnemyTokensOnTile(Tile tile, short forPlayerId)
    {
        List<Token> enemyTokensOnTile = new List<Token>();
        if (tile != null)
        {
            var tokens = GetTokensOnTile(tile);
            if (tokens != null)
            {
                enemyTokensOnTile = tokens.Where(t => (short)t.PlayerColor != forPlayerId).ToList();
            }
        }
        return enemyTokensOnTile;
    }

    public static List<Token> GetTokensOnTile(Tile tile)
    {
        List<Token> tokens = new List<Token>();
        if (Game.Players != null)
        {
            foreach (var player in Game.Players)
            {
                if (player != null)
                {
                    tokens.AddRange(player.Tokens.Where(a => a.Tile == tile));
                }
            }
        }
        return tokens;
    }

    public void DebugTiles()
    {
#if DEBUG
        foreach (var tile in Tiles)
        {
            Main.Text(tile.Value.Id.ToString(), tile.Value.Position + new Vector2(Config.CellSize.X/2, 0), Color.DarkBlue);
            DrawRectangleBorder(new Rectangle((int)tile.Value!.Position.X, (int)tile.Value.Position.Y, Config.CellSize.X, Config.CellSize.Y), new Color(128, 128, 1, 255), 1);
        }
#endif
    }

    // Рисуем контур толщиной 2 пикселя
    void DrawRectangleBorder(Rectangle rect, Color color, int thickness)
    {
        // Верхняя линия
        Main.SpriteBatch.Draw(Main.PixelTexture, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        // Нижняя линия
        Main.SpriteBatch.Draw(Main.PixelTexture, new Rectangle(rect.X, rect.Y + rect.Height - thickness, rect.Width, thickness), color);
        // Левая линия
        Main.SpriteBatch.Draw(Main.PixelTexture, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        // Правая линия
        Main.SpriteBatch.Draw(Main.PixelTexture, new Rectangle(rect.X + rect.Width - thickness, rect.Y, thickness, rect.Height), color);
    }

    public static Color Fade(Color color, float alpha)
    {
        return new Color(color.R, color.G, color.B, (byte)(255 * alpha));
    }
}