using GraveDefensor.Engine.Services.Abstract;

namespace GraveDefensor.Engine.Core
{
    public interface IPooledObject
    {
        void ReleaseResources(IObjectPool context);
    }
}
