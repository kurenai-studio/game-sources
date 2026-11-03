// ============================================
// Player.cs - Player entity with input handling
// ============================================

using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Entities;
using DungeonExplorer.Components;

namespace DungeonExplorer.Entities
{
    /// <summary>
    /// Player entity - represents the player character
    /// </summary>
    public class Player : Entity
    {
        public int Score { get; set; }
        public int TreasuresFound { get; set; }

        public Player(Vector2 position, Texture2D texture)
        {
            // Add required components
            AddComponent(new TransformComponent(position));
            AddComponent(new RenderComponent(texture));
            AddComponent(new MovementComponent(120f, 0.85f)); // Slightly faster than enemies
            AddComponent(new HealthComponent(100));

            Score = 0;
            TreasuresFound = 0;

            // Set up render component
            var render = GetComponent<RenderComponent>();
            render.LayerDepth = 0.5f; // Player renders on top of floors, below UI
        }

        public override void Update(GameTime gameTime)
        {
            base.Update(gameTime);

            // Apply movement to transform
            if (Movement != null && Transform != null)
            {
                float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
                Transform.Position += Movement.Velocity * deltaTime;
            }

            // Handle visual feedback for low health
            if (Health != null && Render != null)
            {
                if (Health.IsInvulnerable)
                {
                    // Flash red when taking damage
                    float flash = MathF.Sin((float)gameTime.TotalGameTime.TotalSeconds * 10f);
                    Render.Tint = Color.Lerp(Color.White, Color.Red, (flash + 1f) * 0.3f);
                }
                else if (Health.CurrentHealth < Health.MaxHealth * 0.3f)
                {
                    // Slight red tint when health is low
                    Render.Tint = Color.Lerp(Color.White, Color.Red, 0.2f);
                }
                else
                {
                    Render.Tint = Color.White;
                }
            }
        }

        public void CollectTreasure(int value = 100)
        {
            Score += value;
            TreasuresFound++;
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