using GraveDefensor.Engine.Core;
using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;

namespace GraveDefensor.Shared.Drawable
{
    public interface IDrawable
    {
        void Draw(IDrawContext context);
        void InitContent(IInitContentContext context);
        void Update(UpdateContext context);
    }
    public abstract class Drawable : IDrawable, IPooledObject
    {
        public virtual void InitContent(IInitContentContext context)
        { }
        public virtual void Update(UpdateContext context)
        { }
        public virtual void Draw(IDrawContext context)
        { }
        public virtual void ReleaseResources(IObjectPool objectPool)
        { }
    }
}
