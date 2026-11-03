using System;
using System.Linq;
//using MonoGame.Actions;
using MonoLudo.Core;
//using System.Numerics;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace MonoLudo.Shared.Scenes.Game;

public class Player
{
    //public Color Color { get; }
    public Token[] Tokens = new Token[Config.TokensPerPlayer];
    public Token AutoMoveToken { get; set; }
    private Token ManualMoveToken { get; set; }
    public Vector2 StartPosition { get; }
    public Tile StartTile { get; }
    public Config.ColorIndex ColorName = Config.ColorIndex.Red;
    public short Id { get; }
    public State CurrentState { get; set; } = State.Ready;

    public enum State
    {
        Ready,
        Start,
        AwaitToPlayerMove,
        AutoMove,
        ManualMove,
        AlreadyVictory,
        EndTurn
    }

    public Player(Config.ColorIndex сolorIndex, Vector2 startPos)
    {
        ColorName = сolorIndex;
        StartPosition = startPos;
        StartTile = null;
        InitializeTokens();
        Id = (short)сolorIndex;
        CurrentState = State.Start;
    }

    private void InitializeTokens()
    {
        for (int i = 0; i < Config.TokensPerPlayer; i++)
        {
            Tokens[i] = new Token((Board.TokenBasePositionName)i, ColorName);
        }
    }

    public void DrawTokens()
    {
        short amount = 1;
        foreach (var token in Tokens)
        {
            if (token.Tile != null)
            {
                var tokensOnTile = Board.GetTokensOnTile(token.Tile);
                amount = (short)tokensOnTile.Count;
            }
            else { amount = 1; }
            token.Draw(amount);
        }
    }

    private void AfterRollDice(short diceValue)
    {
        foreach (var token in Tokens)
        {
            CurrentState = State.AwaitToPlayerMove;
            return;
        }
        CurrentState = State.EndTurn;
    }

    public void AfterPlayerMove(short diceValue)
    {
        if (diceValue != 6)
        {
            CurrentState = State.EndTurn;
            return;
        }
        CurrentState = State.AwaitToPlayerMove;
    }

    //public static Token? GetTokenToAutoMove(Token[] tokens, short diceValue)
    public static List<Token> GetTokensAllowToMove(Token[] tokens, short diceValue)
    {
        var mayMove = new bool[Config.TokensPerPlayer];
        var inBase = new bool[Config.TokensPerPlayer];
        List<Token> tokensThatMayMove = new List<Token>();
        foreach (Token token in tokens)
        {
            if (!token.IsGoal)
            {
                //if (token.Tile != null && CheckForHomeTile((short)(token!.Tile.Id + Dice.GetValue()), token))
                if (token.Tile != null)
                {
                    var tryMoveTo = Board.CalculateDestTile(token, Dice.GetValue()); //lastHomeTile.Value.Id - (short)(token!.Tile.Id + Dice.GetValue());
                    if (tryMoveTo != null)
                    {
                        tokensThatMayMove.Add(token);
                    }
                }
                else
                {
                    inBase[token.Id] = token.IsInBase;
                }

                if (token.IsInBase && diceValue == 6)
                {
                    //if (!Board.TileIsOccupied(token.Tile, Config.StartPosition[token.PlayerColor]))
                    var startTile = Board.Tiles.Where(t => t.Value!.Id == Config.StartPosition[token.PlayerColor]).FirstOrDefault();

                    if (startTile.Value != null && !Board.TileIsOccupied(startTile.Value, (short)token.PlayerColor))
                    {
                        tokensThatMayMove.Add(token);
                    }
                }
            }

        }
        // Все фишки на базе, тогда берём первую
        if (tokens.All(a => a.IsInBase))
        {
            if (diceValue == 6)
            {
                tokensThatMayMove.Clear();
                tokensThatMayMove.Add(tokens[0]);
                return tokensThatMayMove;
            }
            return null;
        }
        if(tokensThatMayMove.Count() > 0)
        {
            return tokensThatMayMove;
        }
        return null;
    }
    public void CheatsTokensToHome()
    {
        //var firstHomeTile = HomeTiles[Id].FirstOrDefault();
        Tile firstHomeTile = Board.Tiles.Select(t => t.Value).Where(t => t?.Color == (Config.ColorIndex)Id).FirstOrDefault();
        foreach (Token token in Tokens)
        {
            if (!token.IsInHome && firstHomeTile != null)
            {
                token.IsInHome = true;
                token.IsInBase = false;
                token.SetTile(firstHomeTile);
            }
        }
    }
    public void CheatsTokensToPreHome()
    {
        Tile firstHomeTile = Board.GetTileById((short)(Config.StartPosition[(Config.ColorIndex)Id] - 3));
        foreach (Token token in Tokens)
        {
            if (!token.IsInHome && firstHomeTile != null)
            {
                token.IsInHome = false;
                token.IsInBase = false;
                token.SetTile(firstHomeTile);
            }
        }
    }
}