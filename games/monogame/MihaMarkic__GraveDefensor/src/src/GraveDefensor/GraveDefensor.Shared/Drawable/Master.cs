using GraveDefensor.Shared.Drawable.Scenes;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;

namespace GraveDefensor.Shared.Drawable
{
    public abstract class Master: Drawable
    {
        // TODO release pool resource when scene goes out of scope
        public Scene CurrentScene { get; protected set; }
        public Scene PreviousScene { get; protected set; }
        public override void InitContent(IInitContentContext context)
        {
            PreviousScene?.InitContent(context);
            CurrentScene.InitContent(context);
            base.InitContent(context);
        }
        public override void Update(UpdateContext context)
        {
            PreviousScene?.Update(context);
            CurrentScene.Update(context);
            base.Update(context);
        }
        public override void Draw(IDrawContext context)
        {
            PreviousScene?.Draw(context);
            CurrentScene.Draw(context);
            base.Draw(context);
        }
    }
}
