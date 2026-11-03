using System;
using System.Linq;
using MonoLudo.Core;
using System.Collections.Generic;
using MonoLudo.Shared.Scenes.Game;
using MonoLudo.Shared;
using MonoLudo.Shared.Actions;
using MonoLudo.Shared.Scenes;

namespace MonoLudo.Shared.Scenes.Game;

public class Game
{
    public static Player[] Players { get; private set; }
    public static Dice Dice { get; } = new();
    public static readonly Board Board;
    public static short CurrentPlayerIndex { get; private set; } = 0;
    public bool IsTurnInProgress { get; private set; }
    public short TurnNumber { get; private set; }
    private static short RepeatTurnTimesLeft { get; set; }
    public const short MAX_REPEAT_MOVES = 2;
    public static bool TokenKillEnemy = false;
    public static List<short> WinnerPlayers = new List<short>();
    public static string MainText = "";

    public Game()
    {
        WinnerPlayers = new List<short>();
        Players = new Player[Config.MaxPlayers];
        InitializePlayers();
        InitializeDice();
        CurrentPlayerIndex = 0;

    }

    public static void SetRepeatTurnTimesLeft(short amount = MAX_REPEAT_MOVES)
    {
        RepeatTurnTimesLeft = amount;
    }

    private bool IsNeedRepeatTurn()
    {
        return RepeatTurnTimesLeft > 0;
    }

    private void SetRepeatTurns()
    {
        if (!Players![CurrentPlayerIndex].Tokens.All(t => t.IsInHome) && RepeatTurnTimesLeft == 0 && Dice.GetValue() == 6)
        {
            RepeatTurnTimesLeft = MAX_REPEAT_MOVES;
        }
        else
        {
            if (Dice.GetValue() != 6)
            {
                RepeatTurnTimesLeft = TokenKillEnemy ? RepeatTurnTimesLeft : (short)0;
                TokenKillEnemy = false;
            }
            RepeatTurnTimesLeft = (short)(RepeatTurnTimesLeft > 0 ? RepeatTurnTimesLeft - 1 : RepeatTurnTimesLeft);
        }
    }

    private void InitializePlayers()
    {
        for (var color = (int)Config.ColorIndex.Blue; color <= ((int)Config.ColorIndex.Yellow); color++)
        {
            bool playerPicked = Main.PlayersAvailable.Any(p => (short)p == (short)color);
            if (!playerPicked)
            {
                Players![(int)color] = new Player((Config.ColorIndex)color, Board.PlayerStaringPosition[(Config.ColorIndex)color]);
            }
        }
    }

    private void InitializeDice()
    {
    }

    public void NextTurn()
    {
        bool wasWinPlayer = false;
        if(Players == null)
        {
            return;
        }
        bool gameOver = Players.All(p => p == null || p.CurrentState == Player.State.AlreadyVictory);
        if (gameOver)
        {
            return;
        }

        var playerIsWin = Players[CurrentPlayerIndex].Tokens.All(t => t.IsGoal);
        if (playerIsWin)
        {
            if(Players[CurrentPlayerIndex].CurrentState != Player.State.AlreadyVictory && !Game.WinnerPlayers.Any(c => c.Equals(Config.PlayerColors[CurrentPlayerIndex])))
            {
                Game.WinnerPlayers.Add(CurrentPlayerIndex);
            }
            Players[CurrentPlayerIndex].CurrentState = Player.State.AlreadyVictory;
            //return;
        }

        if(Players[CurrentPlayerIndex] == null){
            SetNextPlayer();
        }

        //while (Players[CurrentPlayerIndex].CurrentState == State.AlreadyVictory)
        while (Players[CurrentPlayerIndex].CurrentState == Player.State.AlreadyVictory && !Players.All(p => p == null || p.CurrentState == Player.State.AlreadyVictory))
        {
            //CurrentPlayerIndex = (CurrentPlayerIndex + 1) % MaxPlayers;
            bool gameOver1 = Players.All(p => p == null || p.CurrentState == Player.State.AlreadyVictory);

            SetNextPlayer();
            wasWinPlayer = true;
        }

        if (!IsNeedRepeatTurn())
        {
            if (!wasWinPlayer)
            {
                //CurrentPlayerIndex = (CurrentPlayerIndex + 1) % MaxPlayers;
                SetNextPlayer();
            }
            TurnNumber++;
        }
        if (!IsNeedRepeatTurn() || Players[CurrentPlayerIndex].CurrentState != Player.State.AlreadyVictory)
        {
            
        }
            

        MainGameScene.Queue.Enqueue(new DiceAction(Dice));
        MainGameScene.Queue.Enqueue(new TimerAction(1f));
        if (IsNeedRepeatTurn() && Players[CurrentPlayerIndex].CurrentState != Player.State.AlreadyVictory)
        {
            Players[CurrentPlayerIndex].CurrentState = Player.State.Start;
        }
    }

    public void SetNextPlayer()
    {
        CurrentPlayerIndex = (short)((CurrentPlayerIndex + 1) % Config.MaxPlayers);
        while (Players![CurrentPlayerIndex] == null)
            CurrentPlayerIndex = (short)((CurrentPlayerIndex + 1) % Config.MaxPlayers);
    }

    public void Update()
    {
        while (Players![CurrentPlayerIndex] == null)
        {
            //CurrentPlayerIndex = (CurrentPlayerIndex + 1) % MaxPlayers;
            SetNextPlayer();
            return;
        }
        if (Players[CurrentPlayerIndex].CurrentState == Player.State.EndTurn || Players[CurrentPlayerIndex].CurrentState == Player.State.AlreadyVictory)
        {
            if(Players[CurrentPlayerIndex] == null)
            {
                return;
            }
            SetRepeatTurns();
            NextTurn();
            if (Players[CurrentPlayerIndex] != null && Players[CurrentPlayerIndex].CurrentState != Player.State.AlreadyVictory)
            {
                Players[CurrentPlayerIndex].CurrentState = Player.State.Start;
                Console.WriteLine((Config.ColorIndex)CurrentPlayerIndex + " player turn");
                MainText = (Config.ColorIndex)CurrentPlayerIndex + " player turn";
            }
        }
        if(Players[CurrentPlayerIndex] == null)
        {
            //CurrentPlayerIndex = (CurrentPlayerIndex + 1) % MaxPlayers;
            SetNextPlayer();
            return;
        }

        switch (Players[CurrentPlayerIndex].CurrentState)
        {
            case Player.State.Start:
                if (Dice.GetValue() > 0)
                {
                    Players[CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                }
                break;
            case Player.State.AwaitToPlayerMove:
                if (Players[CurrentPlayerIndex].Tokens.All(t => t.IsGoal))
                {
                    Console.WriteLine("Player already win, no need to move any more");
                    Players[CurrentPlayerIndex].CurrentState = Player.State.EndTurn;
                }
                var canMoveTokens = Player.GetTokensAllowToMove(Players[CurrentPlayerIndex].Tokens, Dice.GetValue());
                if (canMoveTokens == null)
                {
                    Players[CurrentPlayerIndex].CurrentState = Player.State.EndTurn;
                    return;
                }
                if (canMoveTokens != null && canMoveTokens.Count > 0)
                {
                    switch (canMoveTokens.Count)
                    {
                        case 0:
                            Players[CurrentPlayerIndex].CurrentState = Player.State.EndTurn;
                            break;
                        case 1:
                            
                            Players[CurrentPlayerIndex].AutoMoveToken = canMoveTokens[0];
                            Players[CurrentPlayerIndex].CurrentState = Player.State.AutoMove;
                            break;
                        default:
                            
                            Players[CurrentPlayerIndex].CurrentState = Player.State.ManualMove;
                            break;
                    }
                }
                break;
            case Player.State.AutoMove:
                if (Players[CurrentPlayerIndex].AutoMoveToken == null)
                {
                    Players[CurrentPlayerIndex].CurrentState = Player.State.EndTurn;
                    return;
                }
                if (Dice.GetValue() > 0 && Players[CurrentPlayerIndex].AutoMoveToken != null)
                {
                    MainGameScene.Queue.Enqueue(new AutoMoveAction(Players[CurrentPlayerIndex], Dice, Players[CurrentPlayerIndex].AutoMoveToken));
                    MainGameScene.Queue.Enqueue(new TimerAction(3f));
                }
                break;
            case Player.State.ManualMove:
                MainGameScene.Queue.Enqueue(new SelectObjectAction(Players[CurrentPlayerIndex], new SelectObjectAction.Object() { Player = Players[CurrentPlayerIndex], Type = SelectObjectAction.Object.RequiredCell.WithToken })); // Ожидаем пока игрок не выберит какой фишкой ходить.
                break;
            case Player.State.EndTurn:
                Console.WriteLine($"End of turn by Player {Players[CurrentPlayerIndex].Id} ");
                break;
        }
    }
}