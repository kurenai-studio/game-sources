using System;
using System.Windows.Input;

namespace GraveDefensor.Engine.Designer.Core
{
    public class RelayCommand<T> : ICommand
    {
        private readonly Func<T, bool>? canExecute;
        private readonly Action<T> execute;

        public event EventHandler? CanExecuteChanged;
        public event EventHandler<ExecutedEventArgs<T>>? Executed;

        public RelayCommand(Action<T> execute) : this(execute, null)
        {
        }

        public RelayCommand(Action<T> execute, Func<T, bool>? canExecute)
        {
            this.execute = execute ?? throw new ArgumentNullException("execute");
            this.canExecute = canExecute;
        }

        bool ICommand.CanExecute(object parameter)
        {
            if (canExecute == null)
            {
                return true;
            }
            return canExecute((T)parameter);
        }
        public virtual bool CanExecute(T parameter)
        {
            return ((ICommand)this).CanExecute(parameter);
        }

        protected virtual void OnExecuted(ExecutedEventArgs<T> e)
        {
            Executed?.Invoke(this, e);
        }

        void ICommand.Execute(object parameter)
        {
            var typedParam = (T)parameter;
            execute(typedParam);
            OnExecuted(new ExecutedEventArgs<T>(typedParam));
        }
        public virtual void Execute(T parameter)
        {
            ((ICommand)this).Execute(parameter);
        }

        public void RaiseCanExecuteChanged()
        {
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }
    }
}
