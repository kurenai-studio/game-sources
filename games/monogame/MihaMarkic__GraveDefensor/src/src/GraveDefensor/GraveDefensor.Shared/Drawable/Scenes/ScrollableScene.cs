using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Scenes
{
    public abstract class ScrollableScene: Scene
    {
        /// <summary>
        /// Keeps track of horizontal offset.
        /// </summary>
        public int Offset { get; private set; }
        public Point Size { get; protected set; }
        public int? LastPressedOrigin { get; private set; }
        /// <summary>
        /// Visible view expressed in scaled unit.
        /// </summary>
        public Rectangle View
        {
            get
            {
                return new Rectangle((int)(Offset / Scale.X), 0, (int)(WindowSize.X / Scale.X), (int)(WindowSize.Y / Scale.Y));
            }
        }
        public UpdateContext OffsetUpdateContext(UpdateContext context)
        {
            if (CanScroll())
            {
                if (context.LeftButton == ButtonState.Pressed)
                {
                    if (LastPressedOrigin.HasValue)
                    {
                        int maxOffset = (int)(Size.X * Scale.X - WindowSize.X);
                        int newOffset = Offset + (LastPressedOrigin.Value - context.CursorPosition.Value.X);
                        Offset = Math.Max(0, Math.Min(maxOffset, newOffset));
                        Transformation = Matrix.CreateScale(Scale.X) * Matrix.CreateTranslation(-Offset, 0, 0);
                    }
                    LastPressedOrigin = context.CursorPosition.Value.X;
                }
                else
                {
                    LastPressedOrigin = null;
                }
            }
            if (context.CursorPosition.HasValue)
            {
                var cursorPosition = context.CursorPosition.Value;
                return context.Clone(cursorPosition: new Point((int)((cursorPosition.X + Offset) / Scale.X), (int)(cursorPosition.Y / Scale.Y)));
            }
            else
            {
                return context;
            }
        }
        protected abstract bool CanScroll();
    }
}
