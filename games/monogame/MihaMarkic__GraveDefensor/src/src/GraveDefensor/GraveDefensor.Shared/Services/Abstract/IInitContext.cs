using GraveDefensor.Engine.Services.Abstract;
using Righthand.MessageBus;

namespace GraveDefensor.Shared.Service.Abstract
{
    public interface IInitContext
    {
        IObjectPool ObjectPool { get; }
        IDispatcher Dispatcher { get; }
    }
}
