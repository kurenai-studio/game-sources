using System;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes;
using Microsoft.Xna.Framework;


namespace MonoLudo.Shared.Actions
{
    public class GameOverAction : IGameAction
    {
        public bool IsCompleted { get; set; }
        //public event Action? OnComplete;

        private static Rectangle _menuButton = new Rectangle(300, 400, 200, 50);

        public GameOverAction() {
        }

        public void Start()
        {
        }

        public void Update()
        {
           
        }

        public void Complete()
        {
            Console.WriteLine("Game Over");
            MainGameScene.GameIsOver = true;
        }
    }
}
