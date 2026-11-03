using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace GraveDefensor.Shared.Drawable
{
    public interface IClickableDrawable: IDrawable
    {
        Point ClickPosition { get; }
        ClickState ClickState { get; }
        bool IsEnabled { get; }
    }
    public abstract class ClickableDrawable : Drawable, IClickableDrawable
    {
        public bool IsEnabled { get; protected set; }
        public ClickState ClickState { get; private set; }
        public Point ClickPosition { get; private set; }
        protected virtual void Init()
        {
            ClickState = ClickState.None;
            IsEnabled = false;
        }
        public override void Update(UpdateContext context)
        {
            if (!IsEnabled)
            {
                ClickState = ClickState.None;
            }
            else
            {
                switch (ClickState)
                {
                    case ClickState.None:
                        if (context.LeftButton == ButtonState.Pressed)
                        {
                            if (IsClickWithinBoundaries(context.CursorPosition.Value))
                            {
                                ClickPosition = context.CursorPosition.Value;
                                ClickState = ClickState.Pressed;
                            }
                        }
                        break;
                    case ClickState.Pressed:
                        if (context.LeftButton == ButtonState.Pressed)
                        {
                            if (ClickPosition != context.CursorPosition.Value)
                            {
                                ClickState = ClickState.Moved;
                            }
                        }
                        else
                        {
                            ClickState = ClickState.Clicked;
                        }
                        break;
                    case ClickState.Clicked:
                        ClickState = ClickState.None;
                        break;
                    case ClickState.Moved:
                        if (context.LeftButton == ButtonState.Released)
                        {
                            ClickState = ClickState.None;
                        }
                        break;
                }
            }
            base.Update(context);
        }
        public virtual bool IsClickWithinBoundaries(Point state) => false;
    }

    public enum ClickState
    {
        None,
        Pressed,
        Clicked,
        Moved
    }
}
