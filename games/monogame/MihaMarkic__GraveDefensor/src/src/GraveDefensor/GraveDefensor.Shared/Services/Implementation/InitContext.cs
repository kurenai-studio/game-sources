using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Service.Abstract;
using Righthand.MessageBus;

namespace GraveDefensor.Shared.Services.Implementation
{
    public sealed class InitContext : IInitContext, IObjectPoolContext
    {
        public IObjectPool ObjectPool { get; }
        public IDispatcher Dispatcher => Globals.Dispatcher;
        public InitContext(IObjectPool objectPool)
        {
            ObjectPool = objectPool;
        }
    }
}
