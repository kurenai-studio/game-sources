using MonoLudo.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using MonoLudo.Shared.Scenes.Game;


namespace MonoLudo.Shared.Actions
{
    public class BackToBaseAction : IGameAction
    {
        public bool IsCompleted { get; set; }
        public Token Token { get; set; }
        public Player Player { get; set; }

        public BackToBaseAction(Token token) {
            if (token != null && Game.Players != null)
            {
                Token = token;
                Player = Game.Players[(int)token.PlayerColor];
            }
        }

        public void Start()
        {
            if (Player != null)
            {
                Token.SetInBase(Player);
            }
            Game.TokenKillEnemy = true;
            IsCompleted = true;
        }

        public void Update()
        {
          
        }

        public void Complete()
        {
            Console.WriteLine($"Token back to base");
        }
    }
}
