using Avalonia.Controls;
using GraveDefensor.Engine.Designer.ViewModels;
using System.Diagnostics;

namespace GraveDefensor.Designer.Views
{
    public abstract class ViewModelUserControl<T>: UserControl
        where T: notnull, ContentViewModel
    {
        public T ViewModel
        {
            [DebuggerStepThrough]
            get => (T)DataContext;
        }
    }
}
