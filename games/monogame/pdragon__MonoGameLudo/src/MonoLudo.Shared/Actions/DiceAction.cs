using System;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes.Game;


namespace MonoLudo.Shared.Actions
{
    public class DiceAction : IGameAction
    {
        public bool IsCompleted { get; set; }
        public event Action OnComplete;
        //private Action? Action;
        private Dice Dice { get; set; }

        public DiceAction(Dice dice) {
            OnComplete = Complete;
            Dice = dice;
        }

        public void Start()
        {
            Dice.Roll();
        }

        public void Update()
        {
            if (!Dice.IsRolling)
            {
                //Complete();
                IsCompleted = true;
            }
        }

        public void Complete()
        {
            Console.WriteLine($"Roll dice to: {Dice.GetValue()}");
        }
    }
}
