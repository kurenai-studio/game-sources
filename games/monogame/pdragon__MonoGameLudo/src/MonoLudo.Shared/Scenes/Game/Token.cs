using MonoLudo.Shared.Actions;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes.Game;
using System;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoLudo.Shared;

namespace MonoLudo.Shared.Scenes.Game;

/// <summary>
/// 
/// </summary>
public class Token
{
    public Vector2 Position { get; set; }
    public Tile Tile { get; private set; }
    public Config.ColorIndex PlayerColor { get; set; }
    public bool IsInHome { get; set; } = false;
    public bool IsInBase { get; set; } = true;
    public short Id { get; set; } = 0;
    public Board.TokenBasePositionName StartingPositionName { get; set; }
    public bool IsGoal = false;

    public Token(Board.TokenBasePositionName id, Config.ColorIndex color)
    {
        Position = Board.GetTokenStartPosition(id, color);
        PlayerColor = color;
        Id = (short)id;
        StartingPositionName = id;
        IsInBase = true;

        //CreateCircleTexture(graphicsDevice, int radius, Color color);
    }

    public void SetTile(Tile tile)
    {
        Tile = tile;
        Position = Tile.Position;
    }

    public void SetInBase(Player player)
    {
        if (player.Tokens != null)
        {
            Position = Board.GetTokenStartPosition(StartingPositionName, (Config.ColorIndex)player.Id);
            IsInBase = true;
            Tile = null;
        }
    }

    public void Draw(short amount)
    {
        switch (amount)
        {
            case 1:
                DrawAtPos(Position);
                break;
            case 2:
                DrawAtPos(new Vector2(Position.X + Config.CellSize.X / 4, Position.Y + Config.CellSize.Y / 4), -3);
                DrawAtPos(new Vector2(Position.X - Config.CellSize.X / 4, Position.Y - Config.CellSize.Y / 4), -3);
                break;
            case 3:
                DrawAtPos(new Vector2(Position.X + Config.CellSize.X / 4, Position.Y + Config.CellSize.Y / 4), -3);
                DrawAtPos(new Vector2(Position.X - Config.CellSize.X / 4, Position.Y - Config.CellSize.Y / 4), -3);
                DrawAtPos(new Vector2(Position.X + Config.CellSize.X / 4, Position.Y - Config.CellSize.Y / 4), -3);
                break;
            case 4:
                DrawAtPos(new Vector2(Position.X + Config.CellSize.X / 4, Position.Y + Config.CellSize.Y / 4), -4);
                DrawAtPos(new Vector2(Position.X - Config.CellSize.X / 4, Position.Y - Config.CellSize.Y / 4), -4);
                DrawAtPos(new Vector2(Position.X + Config.CellSize.X / 4, Position.Y - Config.CellSize.Y / 4), -4);
                DrawAtPos(new Vector2(Position.X - Config.CellSize.X / 4, Position.Y + Config.CellSize.Y / 4), -4);
                break;
            default:
                throw new Exception("Error: more than 4 tokens in one tile detected!");
        }
    }

    private void DrawAtPos(Vector2 position, float radiusCorrection = 0)
    {
        float scale = Main.ScaleMatrix.M11; // Масштаб по оси X (предполагается равный Y)
        float scaledRadius = Config.TokenRadius * scale;
        Vector2 positionOnTile = new Vector2(
            (position.X + Config.CellSize.X / 2) - (Config.CircleTexture[(short)PlayerColor].Width / 2) + 10,
            (position.Y + Config.CellSize.Y / 2) - (Config.CircleTexture[(short)PlayerColor].Height / 2) + 10
        );

        // Внешний круг (чёрная обводка)
        Main.SpriteBatch.Draw(
            Config.CircleTexture[(short)PlayerColor],
            //new Vector2(position.X + Config.CellSize.X / 2, position.Y + Config.CellSize.Y / 2),
            positionOnTile,
            null, // Не используйте Rectangle, если нужен масштаб!
            Color.Black,
            0f,
            Vector2.Zero,
            (scaledRadius + 2 + radiusCorrection) / Config.CircleTexture[(short)PlayerColor].Width, // Масштаб
            SpriteEffects.None,
            0f
        );

        // Внутренний круг (цвет игрока)
        Main.SpriteBatch.Draw(
            Config.CircleTexture[(short)PlayerColor],
            //new Vector2(position.X + Config.CellSize.X / 2, position.Y + Config.CellSize.Y / 2),
            positionOnTile,
            null,
            Config.PlayerColors[(short)PlayerColor],
            0f,
            Vector2.Zero,
            (scaledRadius + radiusCorrection) / Config.CircleTexture[(short)PlayerColor].Width,
            SpriteEffects.None,
            0f
        );

        //// Отрисовка
        //Main.SpriteBatch.Draw(
        //    Config.CircleTexture[0],
        //    position,
        //    new Rectangle(0, 0, (int)(Config.TokenRadius + 2 + radiusCorrection), (int)(Config.TokenRadius + 2 + radiusCorrection)),
        //    Color.Black
        //);

        //Main.SpriteBatch.Draw(
        //    Config.CircleTexture[0],
        //    position,
        //    new Rectangle(0, 0, (int)(Config.TokenRadius  + radiusCorrection), (int)(Config.TokenRadius  + radiusCorrection)),
        //    //new Vector2(centerX, centerY) - new Vector2(radius),
        //    Config.PlayerColors[(short)PlayerColor]
        //);
    }

    public bool CanMove(short diceValue)
    {
        if (IsInBase && diceValue != 6)
        {
            return false;
        }
        return true;
    }


    public Token Move(short diceValue)
    {
        Tile destTile;
        short? destTileId = null;
        if (!IsInBase && Tile == null)
        {
            throw new Exception("Tile is empty!!!");
        }

        if (IsInBase)
        {
            // В проверке на то можно ли сюда ходить или нет мы уже проверяли, но это только на автоход,
            // однако в случае с обычным ходом требуется проверять заново
            IsInBase = false;
            
            Tile = Board.GetTileById(Config.StartPosition[PlayerColor]);
            if (Tile != null)
            {
                //var tokensInTile = Board.GetTokensOnTile(Tile);
                Position = Tile.Position;
            }
            if (Tile == null)
            {
                Console.WriteLine($"error: tile {1} not exist", diceValue);
            }
            return this;
        }

        //var fromTile = GetTileById(CalculateDestTile(this, diceValue));
        var fromTile = Board.CalculateDestTile(this, diceValue);
        if (fromTile == null)
        {
            throw new Exception("Token tile is empty!!!");
        }

        Tile = destTile = Board.CalculateDestTile(this, diceValue);
        if (destTile?.Color == Config.ColorIndex.Neutral)
        if (!IsInBase)
        {
            if (Tile == null || Tile.Color == null)
            {
                Console.WriteLine();
                throw new Exception("Tile is empty!");
            }
        }
        if (destTile == null)
        {
            if (!IsInBase)
            {
                Console.WriteLine();
                throw new Exception("Dest Tile id null!");
            }
            return this;
        }

        if (Tile != null)
        {
            Position = Tile.Position;
            // Заходим в домашний регион
            if (destTile != null && (destTile.Color != Config.ColorIndex.Neutral || destTile.Color == this.PlayerColor) && !IsInBase)
            //if (CheckForHomeTile(destTileId ?? 0, this))
            {
                IsInHome = true;
            }
            // TODO: переписать так чтобы она определялась один раз, а не в основном цикле как тут
            //var lastHomeTile = HomeTiles[(short)PlayerColor].Last();
            var lastHomeTile = Board.Tiles.Where(t => t.Value!.Color == PlayerColor).Last();
            if (lastHomeTile.Value == null)
            {
                throw new Exception("Final home tile is not set");
            }
            if (destTile.Id == lastHomeTile.Value.Id && destTile!.Color == PlayerColor)
            {
                IsGoal = true;
            }
        }
        else
        {
            Console.WriteLine($"error: tile {1} not exist", destTileId);
        }
        return this;
    }
}