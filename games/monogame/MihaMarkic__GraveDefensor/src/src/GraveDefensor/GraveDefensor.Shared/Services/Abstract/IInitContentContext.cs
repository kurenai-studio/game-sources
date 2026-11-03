using GraveDefensor.Engine.Services.Abstract;

namespace GraveDefensor.Shared.Service.Abstract
{
    public interface IInitContentContext
    {
        IObjectPool ObjectPool { get; }
        T Load<T>(string name);
    }
}
