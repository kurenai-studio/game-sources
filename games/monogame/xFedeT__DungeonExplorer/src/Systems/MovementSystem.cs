// ============================================
// Systems/MovementSystem.cs
// ============================================
using Microsoft.Xna.Framework;
using DungeonExplorer.Entities;
using DungeonExplorer.Core;

namespace DungeonExplorer.Systems
{
    public class MovementSystem
    {
        public void Update(GameTime gameTime, Player player, InputManager inputManager)
        {
            if (player?.Movement == null || player.Transform == null) return;

            var direction = inputManager.GetMovementDirection();
            
            if (direction != Vector2.Zero)
            {
                player.Movement.AddForce(direction * 500f); // Apply movement force
            }
        }
    }
}