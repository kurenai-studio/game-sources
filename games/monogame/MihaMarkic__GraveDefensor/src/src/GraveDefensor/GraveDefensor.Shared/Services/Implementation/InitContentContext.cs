using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework.Content;

namespace GraveDefensor.Shared.Services.Implementation
{
    public sealed class InitContentContext : IInitContentContext, IObjectPoolContext
    {
        readonly ContentManager content;
        public IObjectPool ObjectPool { get; }
        public InitContentContext(ContentManager content, IObjectPool objectPool)
        {
            this.content = content;
            ObjectPool = objectPool;
        }
        public T Load<T>(string name)
        {
            return content.Load<T>(name);
        }
    }
}
