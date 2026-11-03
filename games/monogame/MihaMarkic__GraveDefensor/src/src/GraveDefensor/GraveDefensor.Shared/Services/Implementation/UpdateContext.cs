using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Shared.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Input.Touch;
using Righthand.Immutable;

namespace GraveDefensor.Shared.Services.Implementation
{
    public readonly struct UpdateContext
    {
        public GameTime GameTime { get; }
        public MouseState? MouseState { get; }
        public TouchState? TouchState { get; }
        public Point? CursorPosition { get; }
        public IObjectPool ObjectPool { get; }

        public UpdateContext(GameTime gameTime, MouseState? mouseState, TouchState? touchState, Point? cursorPosition, IObjectPool objectPool)
        {
            GameTime = gameTime;
            MouseState = mouseState;
            TouchState = touchState;
            CursorPosition = cursorPosition;
            ObjectPool = objectPool;
        }

        public UpdateContext Clone(Param<GameTime>? gameTime = null, Param<MouseState?>? mouseState = null, Param<TouchState?>? touchState = null, Param<Point?>? cursorPosition = null, Param<IObjectPool>? objectPool = null)
        {
            return new UpdateContext(gameTime.HasValue ? gameTime.Value.Value : GameTime,
				mouseState.HasValue ? mouseState.Value.Value : MouseState,
				touchState.HasValue ? touchState.Value.Value : TouchState,
				cursorPosition.HasValue ? cursorPosition.Value.Value : CursorPosition,
				objectPool.HasValue ? objectPool.Value.Value : ObjectPool);
        }

        public override bool Equals(object obj)
        {
            if (obj == null || GetType() != obj.GetType()) return false;
            var o = (UpdateContext)obj;
            return Equals(GameTime, o.GameTime) && Equals(MouseState, o.MouseState) && Equals(TouchState, o.TouchState) && Equals(CursorPosition, o.CursorPosition) && Equals(ObjectPool, o.ObjectPool);}

        public override int GetHashCode()
        {
            unchecked
			{
				int hash = base.GetHashCode();
				hash = hash * 37 + (GameTime != null ? GameTime.GetHashCode() : 0);
				hash = hash * 37 + (MouseState != null ? MouseState.GetHashCode() : 0);
				hash = hash * 37 + (TouchState != null ? TouchState.GetHashCode() : 0);
				hash = hash * 37 + (CursorPosition != null ? CursorPosition.GetHashCode() : 0);
				hash = hash * 37 + (ObjectPool != null ? ObjectPool.GetHashCode() : 0);
				return hash;
			}
        }

        public ButtonState LeftButton
        {
            get
            {
                if (MouseState.HasValue)
                {
                    return MouseState.Value.LeftButton;
                }
                else if (TouchState.HasValue)
                {
                    var touchLocationState = TouchState?.State;
                    switch (touchLocationState)
                    {
                        case TouchLocationState.Pressed:
                        case TouchLocationState.Moved:
                            return ButtonState.Pressed;
                        default:
                            return ButtonState.Released;
                    }
                }
                return ButtonState.Released;
            }
        }
    }
}
