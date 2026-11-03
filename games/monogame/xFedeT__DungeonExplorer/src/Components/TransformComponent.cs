// ============================================
// TransformComponent.cs - Position, rotation, scale
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Components;

namespace DungeonExplorer.Components
{
    /// <summary>
    /// Component that handles position, rotation and scale of an entity
    /// </summary>
    public class TransformComponent : IComponent
    {
        public Vector2 Position { get; set; }
        public float Rotation { get; set; }
        public Vector2 Scale { get; set; }
        public Vector2 Origin { get; set; }

        public TransformComponent(Vector2 position)
        {
            Position = position;
            Rotation = 0f;
            Scale = Vector2.One;
            Origin = Vector2.Zero;
        }

        public void Update(GameTime gameTime)
        {
            // Transform component doesn't need active updates
        }

        public Rectangle GetBounds(int width, int height)
        {
            return new Rectangle(
                (int)(Position.X - Origin.X * Scale.X),
                (int)(Position.Y - Origin.Y * Scale.Y),
                (int)(width * Scale.X),
                (int)(height * Scale.Y)
            );
        }
    }
}