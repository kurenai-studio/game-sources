using GraveDefensor.Engine.Core;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace GraveDefensor.Engine.Designer.ViewModels
{
    /// <summary>
    /// Base class that implements <see cref="INotifyPropertyChanged"/> 
    /// </summary>
    public abstract class NotifiableObject : DisposableObject, INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged([CallerMemberName]string name = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}
