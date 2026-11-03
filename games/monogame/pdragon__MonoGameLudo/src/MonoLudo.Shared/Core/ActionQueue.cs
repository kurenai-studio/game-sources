using System.Collections.Generic;

namespace MonoLudo.Core
{
    public class ActionQueue
    {
        private Queue<IGameAction> _actions = new Queue<IGameAction>();
        private IGameAction CurrentAction;
        //private event EventHandler? OnComplete;

        public void Enqueue(IGameAction action)
        {
            _actions.Enqueue(action);
            
        }

        public bool Update()
        {
            if (CurrentAction == null && _actions.Count > 0)
            {
                CurrentAction = _actions.Dequeue();
                CurrentAction.Start();
                //CurrentAction.OnComplete += CurrentAction.Complete;
            }

            if (CurrentAction != null)
            {
                CurrentAction.Update();
                if (CurrentAction.IsCompleted)
                {
                    CurrentAction.Complete();
                    CurrentAction = null;
                }
            }

            return _actions.Count > 0 || CurrentAction != null;
        }
    }
}
