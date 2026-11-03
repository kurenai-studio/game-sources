using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace GraveDefensor.Shared.Drawable.Buttons
{
    public abstract class Button : ClickableDrawable
    {
        public Rectangle Bounds { get; private set; }
        protected void Init(Rectangle bounds)
        {
            Bounds = bounds;
            Init();
        }
        public override void Draw(IDrawContext context)
        {
            if (IsEnabled)
            {
                switch (ClickState)
                {
                    case ClickState.Pressed:
                        context.FillRectangle(Bounds, new Color(Color.Orange, 0.3f));
                        break;
                    case ClickState.None:
                        context.FillRectangle(Bounds, new Color(Color.Orange, 0.05f));
                        break;
                }
            }
            else
            {
                context.FillRectangle(Bounds, new Color(Color.Gray, 0.3f));
            }
            DrawContent(context);
            if (Globals.ShowButtonsInfo)
            {
                DrawInfo(context);
            }
            base.Draw(context);
        }
        public override bool IsClickWithinBoundaries(Point point)
        {
            return Bounds.Contains(point);
        }
        public virtual void DrawContent(IDrawContext context)
        { }
        public virtual void DrawInfo(IDrawContext context)
        {
            Vector2 position = new Vector2(Bounds.Right + 2, Bounds.Top);
            context.DrawString(GlobalContent.Default.InfoFont, ClickState.ToString(), position, Color.Yellow);
            position += new Vector2(0, 20 + 4);
            context.DrawString(GlobalContent.Default.InfoFont, IsEnabled ? "Enabled": "Not enabled", position, Color.Yellow);
        }
    }
}
