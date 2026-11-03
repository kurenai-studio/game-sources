// ============================================
// RenderComponent.cs - Handles visual representation
// ============================================
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Components;

namespace DungeonExplorer.Components
{
    /// <summary>
    /// Component that handles the visual representation of an entity
    /// </summary>
    public class RenderComponent : IComponent
    {
        public Texture2D Texture { get; set; }
        public Color Tint { get; set; }
        public bool Visible { get; set; }
        public Rectangle? SourceRectangle { get; set; }
        public SpriteEffects SpriteEffects { get; set; }
        public float LayerDepth { get; set; }

        public RenderComponent(Texture2D texture)
        {
            Texture = texture;
            Tint = Color.White;
            Visible = true;
            SourceRectangle = null;
            SpriteEffects = SpriteEffects.None;
            LayerDepth = 0f;
        }

        public void Update(GameTime gameTime)
        {
            // Basic render component doesn't need updates
            // Could be extended for animations, effects, etc.
        }
    }
}