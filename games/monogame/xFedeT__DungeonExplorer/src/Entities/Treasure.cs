using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Entities;
using DungeonExplorer.Components;
using System;

namespace DungeonExplorer.Entities
{
    /// <summary>
    /// Treasure entity that can be collected by the player
    /// </summary>
    public class Treasure : Entity
    {
        public int Value { get; set; }
        public bool IsCollected { get; private set; }
        private float _bobTimer;
        private Vector2 _originalPosition;

        public Treasure(Vector2 position, Texture2D texture)
        {
            // Add required components
            AddComponent(new TransformComponent(position));
            AddComponent(new RenderComponent(texture));

            Value = 100;
            IsCollected = false;
            _bobTimer = 0f;
            _originalPosition = position;

            // Set up render component
            var render = GetComponent<RenderComponent>();
            render.LayerDepth = 0.3f;
        }

        public override void Update(GameTime gameTime)
        {
            if (IsCollected) return;

            base.Update(gameTime);

            // Bobbing animation effect
            _bobTimer += (float)gameTime.ElapsedGameTime.TotalSeconds * 3f;
            float bobOffset = MathF.Sin(_bobTimer) * 2f;
            
            if (Transform != null)
            {
                Transform.Position = _originalPosition + new Vector2(0, bobOffset);
            }

            // Gentle glow effect by varying transparency
            if (Render != null)
            {
                float alpha = 0.8f + MathF.Sin(_bobTimer * 2f) * 0.2f;
                Render.Tint = Color.White * alpha;
            }
        }

        public void Collect()
        {
            if (IsCollected) return;

            IsCollected = true;
            IsActive = false;

            // Could add collection effect here (particles, sound, etc.)
        }

        public Vector2 GetGridPosition()
        {
            return new Vector2(
                MathF.Floor(Transform.Position.X / 32f),
                MathF.Floor(Transform.Position.Y / 32f)
            );
        }
    }
}