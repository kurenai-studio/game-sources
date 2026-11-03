using Microsoft.Xna.Framework;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Scenes
{
    public abstract class Scene : Drawable
    {
        public Matrix Transformation { get; protected set; } = Matrix.Identity;
        public Vector2 Scale { get; protected set; }
        public Point WindowSize { get; private set; }
        public void Init(Point windowSize)
        {
            WindowSize = windowSize;
        }
    }
}
