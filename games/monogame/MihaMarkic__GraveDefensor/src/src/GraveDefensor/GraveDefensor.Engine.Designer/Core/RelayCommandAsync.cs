using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace GraveDefensor.Engine.Designer.Core
{
    public class RelayCommandAsync : ICommand
    {
        private readonly Func<bool>? canExecute;
        private readonly Func<Task> execute;

        public event EventHandler? CanExecuteChanged;

        public RelayCommandAsync(Func<Task> execute) : this(execute, null)
        {
        }

        public RelayCommandAsync(Func<Task> execute, Func<bool>? canExecute)
        {
            this.execute = execute ?? throw new ArgumentNullException("execute");
            this.canExecute = canExecute;
        }

        public virtual bool CanExecute(object parameter)
        {
            if (canExecute == null)
            {
                return true;
            }
            return canExecute();
        }

        public virtual void Execute(object parameter)
        {
            var ignore = execute();
        }

        public void RaiseCanExecuteChanged()
        {
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }
    }
}
