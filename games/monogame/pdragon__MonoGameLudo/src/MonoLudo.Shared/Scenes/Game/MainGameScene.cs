using System.Data;
using MonoLudo.Core;
using System.Collections.Generic;
using System.Collections;
//using MonoLudo.Shared.Actions;
using MonoLudo.Shared.Scenes.Game;
using System.Linq;
using Microsoft.Xna.Framework;

namespace MonoLudo.Shared.Scenes
{
    public class MainGameScene
    {
        public static ActionQueue Queue = new ActionQueue();
        Game.Game GameManager;
        Board Board;
        public static bool GameIsOver = false;
        public MainGameScene()
        {
            MainGameScene.GameIsOver = false;
            GameManager = new Game.Game();
            Board = new Board();
            GameManager.SetNextPlayer();
        }

        public void Draw() {
            //Board.Draw();
            Board.DebugTiles();
            Scenes.Game.Game.Dice.Draw();
            foreach (var player in Game.Game.Players!)
            {
                if (player != null)
                {
                    player.DrawTokens();
                }
            }
        }


        public bool Update()
        {
            bool gameOver = Game.Game.Players!.All(s => s == null || s.CurrentState == Player.State.AlreadyVictory);
            //InputHandler.ProcessInput(Game.Game);

            //Board.Draw();
            //Game.Game.Dice.Draw();

            //Timer.Update();
            
            if (!gameOver && !Queue.Update()) // Если в очереди что-то есть то выполняем только очередь
            {
                GameManager.Update();
            }
            if (gameOver)
            {
                //Queue.Enqueue(new GameOverAction());
                return true;
            }
            return false;
        }
    }
}

