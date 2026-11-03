using System;
using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Engine.Designer.ViewModels
{
    public abstract class ContentViewModel: ViewModel
    {
        public event EventHandler? CloseRequested;
        protected virtual void OnCloseRequested(EventArgs e) => CloseRequested?.Invoke(this, e);
        public virtual Task<bool> CanCloseAsync(CancellationToken ct = default) => Task.FromResult(true);
        public virtual Task CloseAsync() => Task.CompletedTask;
        public virtual Task InitAsync(CancellationToken ct = default) => Task.CompletedTask;
    }
}
