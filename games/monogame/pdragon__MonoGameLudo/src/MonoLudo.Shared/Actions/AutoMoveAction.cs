using System;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes.Game;


namespace MonoLudo.Shared.Actions
{
    public class AutoMoveAction : IGameAction
    {
        public bool IsCompleted { get; set; }
        public event Action OnComplete;
        //private Action? Action;
        private Player CurrentPlayer;
        private Dice Dice;
        private Token Token;

        public AutoMoveAction(Player player, Dice dice, Token token) {
            CurrentPlayer = player;
            Dice = dice;
            if(token == null)
            {
                throw new InvalidOperationException("Error 0001: Invalid AutoMoveToken operation");
            }
            Token = token;
            OnComplete = Complete;
        }

        public void Start()
        {
            //Token.AutoMove(Dice.GetValue());
        }

        public void Update()
        {
            Token.Move(Dice.GetValue());
            IsCompleted = true;
        }

        public void Complete()
        {
            if (CurrentPlayer == null)
            {
                throw new InvalidOperationException("Error 0002: Invalid Player operation");
            }
            CurrentPlayer.CurrentState = Player.State.EndTurn;
        }
    }
}
