using Microsoft.Xna.Framework;
using DungeonExplorer.Entities;
using DungeonExplorer.World;
using DungeonExplorer.Components;
using System.Collections.Generic;
using System.Linq;
using System;

namespace DungeonExplorer.Systems
{
    /// <summary>
    /// Sistema responsabile della gestione delle collisioni
    /// </summary>
    public class CollisionSystem
    {
        private const float TILE_SIZE = 32f;

        /// <summary>
        /// Controlla le collisioni tra il giocatore e i nemici
        /// </summary>
        public void CheckPlayerEnemyCollisions(Player player, List<Enemy> enemies)
        {
            if (player?.Health == null || player.Health.CurrentHealth <= 0) return;

            var playerBounds = player.GetBounds();

            for (int i = enemies.Count - 1; i >= 0; i--)
            {
                var enemy = enemies[i];
                if (enemy?.Health == null || enemy.Health.CurrentHealth <= 0) 
                {
                    enemies.RemoveAt(i);
                    continue;
                }

                var enemyBounds = enemy.GetBounds();

                if (playerBounds.Intersects(enemyBounds))
                {
                    HandlePlayerEnemyCollision(player, enemy);
                }
            }
        }

        /// <summary>
        /// Controlla le collisioni tra il giocatore e i tesori
        /// </summary>
        public void CheckPlayerTreasureCollisions(Player player, List<Treasure> treasures)
        {
            if (player?.Health == null || player.Health.CurrentHealth <= 0) return;

            var playerBounds = player.GetBounds();

            for (int i = treasures.Count - 1; i >= 0; i--)
            {
                var treasure = treasures[i];
                if (treasure == null || treasure.IsCollected) 
                {
                    treasures.RemoveAt(i);
                    continue;
                }

                var treasureBounds = treasure.GetBounds();

                if (playerBounds.Intersects(treasureBounds))
                {
                    HandlePlayerTreasureCollision(player, treasure, treasures, i);
                }
            }
        }

        /// <summary>
        /// Controlla le collisioni tra un'entità e il mondo (muri)
        /// </summary>
        public void CheckWorldCollisions(Entity entity, Dungeon dungeon)
        {
            if (entity?.Transform == null || dungeon == null) return;

            var entityBounds = entity.GetBounds();
            var originalPosition = entity.Transform.Position;

            // Calcola le tile che l'entità occupa
            int leftTile = (int)(entityBounds.Left / TILE_SIZE);
            int rightTile = (int)(entityBounds.Right / TILE_SIZE);
            int topTile = (int)(entityBounds.Top / TILE_SIZE);
            int bottomTile = (int)(entityBounds.Bottom / TILE_SIZE);

            // Assicurati che i valori siano nei limiti del dungeon
            leftTile = MathHelper.Clamp(leftTile, 0, dungeon.Width - 1);
            rightTile = MathHelper.Clamp(rightTile, 0, dungeon.Width - 1);
            topTile = MathHelper.Clamp(topTile, 0, dungeon.Height - 1);
            bottomTile = MathHelper.Clamp(bottomTile, 0, dungeon.Height - 1);

            bool collisionDetected = false;

            // Controlla tutte le tile che l'entità occupa
            for (int x = leftTile; x <= rightTile; x++)
            {
                for (int y = topTile; y <= bottomTile; y++)
                {
                    if (dungeon.IsWalkable(x, y) == false) // Use dungeon's IsWalkable method
                    {
                        var tileBounds = new Rectangle(
                            x * (int)TILE_SIZE,
                            y * (int)TILE_SIZE,
                            (int)TILE_SIZE,
                            (int)TILE_SIZE
                        );

                        if (entityBounds.Intersects(tileBounds))
                        {
                            collisionDetected = true;
                            ResolveWorldCollision(entity, tileBounds, originalPosition);
                            break;
                        }
                    }
                }
                if (collisionDetected) break;
            }

            // Controlla i limiti del mondo
            CheckWorldBounds(entity, dungeon);
        }

        /// <summary>
        /// Controlla le collisioni tra entità (generico)
        /// </summary>
        public bool CheckEntityCollision(Entity entityA, Entity entityB)
        {
            if (entityA?.Transform == null || entityB?.Transform == null) return false;

            var boundsA = entityA.GetBounds();
            var boundsB = entityB.GetBounds();

            return boundsA.Intersects(boundsB);
        }

        /// <summary>
        /// Controlla le collisioni in un'area circolare
        /// </summary>
        public List<Entity> GetEntitiesInRadius(Vector2 center, float radius, List<Entity> entities)
        {
            var entitiesInRadius = new List<Entity>();

            foreach (var entity in entities)
            {
                if (entity?.Transform == null) continue;

                float distance = Vector2.Distance(center, entity.Transform.Position);
                if (distance <= radius)
                {
                    entitiesInRadius.Add(entity);
                }
            }

            return entitiesInRadius;
        }

        /// <summary>
        /// Gestisce la collisione tra giocatore e nemico
        /// </summary>
        private void HandlePlayerEnemyCollision(Player player, Enemy enemy)
        {
            if (player.Health == null || enemy.Health == null) return;

            // Calcola la direzione del knockback
            Vector2 knockbackDirection = Vector2.Normalize(player.Transform.Position - enemy.Transform.Position);
            if (knockbackDirection == Vector2.Zero)
                knockbackDirection = Vector2.UnitX; // Default direction

            // Applica danno al giocatore
            int damage = enemy.Damage;
            bool playerDied = player.Health.TakeDamage(damage);

            // Applica knockback al giocatore
            if (player.Movement != null)
            {
                player.Transform.Position += knockbackDirection * 20f; // Knockback immediato
            }

            // Il nemico può anche subire un piccolo knockback
            if (enemy.Movement != null)
            {
                enemy.Transform.Position -= knockbackDirection * 10f;
            }
        }

        /// <summary>
        /// Gestisce la collisione tra giocatore e tesoro
        /// </summary>
        private void HandlePlayerTreasureCollision(Player player, Treasure treasure, List<Treasure> treasures, int index)
        {
            // Colleziona il tesoro
            treasure.Collect();
            
            // Aggiungi al punteggio del giocatore
            player.CollectTreasure(treasure.Value);
            
            // Rimuovi dalla lista
            treasures.RemoveAt(index);
        }

        /// <summary>
        /// Risolve la collisione tra un'entità e un muro
        /// </summary>
        private void ResolveWorldCollision(Entity entity, Rectangle wallBounds, Vector2 originalPosition)
        {
            var entityBounds = entity.GetBounds();
            
            // Calcola la sovrapposizione in ogni direzione
            float overlapLeft = (entityBounds.Right - wallBounds.Left);
            float overlapRight = (wallBounds.Right - entityBounds.Left);
            float overlapTop = (entityBounds.Bottom - wallBounds.Top);
            float overlapBottom = (wallBounds.Bottom - entityBounds.Top);

            // Trova la direzione con la minima sovrapposizione per la risoluzione
            float minOverlapX = Math.Min(overlapLeft, overlapRight);
            float minOverlapY = Math.Min(overlapTop, overlapBottom);

            if (minOverlapX < minOverlapY)
            {
                // Risolvi la collisione orizzontale
                if (overlapLeft < overlapRight)
                {
                    // Sposta a sinistra
                    entity.Transform.Position = new Vector2(wallBounds.Left - entityBounds.Width * 0.5f, entity.Transform.Position.Y);
                }
                else
                {
                    // Sposta a destra
                    entity.Transform.Position = new Vector2(wallBounds.Right + entityBounds.Width * 0.5f, entity.Transform.Position.Y);
                }
            }
            else
            {
                // Risolvi la collisione verticale
                if (overlapTop < overlapBottom)
                {
                    // Sposta in alto
                    entity.Transform.Position = new Vector2(entity.Transform.Position.X, wallBounds.Top - entityBounds.Height * 0.5f);
                }
                else
                {
                    // Sposta in basso
                    entity.Transform.Position = new Vector2(entity.Transform.Position.X, wallBounds.Bottom + entityBounds.Height * 0.5f);
                }
            }

            // Ferma il movimento se l'entità ha un componente movimento
            if (entity.Movement != null)
            {
                entity.Movement.Velocity = Vector2.Zero;
            }
        }

        /// <summary>
        /// Controlla che l'entità rimanga nei limiti del mondo
        /// </summary>
        private void CheckWorldBounds(Entity entity, Dungeon dungeon)
        {
            var bounds = entity.GetBounds();
            var worldBounds = new Rectangle(0, 0, dungeon.Width * (int)TILE_SIZE, dungeon.Height * (int)TILE_SIZE);

            Vector2 newPosition = entity.Transform.Position;

            // Limiti orizzontali
            if (bounds.Left < worldBounds.Left)
            {
                newPosition.X = bounds.Width * 0.5f;
            }
            else if (bounds.Right > worldBounds.Right)
            {
                newPosition.X = worldBounds.Right - bounds.Width * 0.5f;
            }

            // Limiti verticali
            if (bounds.Top < worldBounds.Top)
            {
                newPosition.Y = bounds.Height * 0.5f;
            }
            else if (bounds.Bottom > worldBounds.Bottom)
            {
                newPosition.Y = worldBounds.Bottom - bounds.Height * 0.5f;
            }

            entity.Transform.Position = newPosition;
        }

        /// <summary>
        /// Controlla se una posizione è libera da collisioni
        /// </summary>
        public bool IsPositionFree(Vector2 position, Vector2 size, Dungeon dungeon, List<Entity> entitiesToIgnore = null)
        {
            var testBounds = new Rectangle(
                (int)(position.X - size.X * 0.5f),
                (int)(position.Y - size.Y * 0.5f),
                (int)size.X,
                (int)size.Y
            );

            // Controlla collisioni con il mondo
            int leftTile = (int)(testBounds.Left / TILE_SIZE);
            int rightTile = (int)(testBounds.Right / TILE_SIZE);
            int topTile = (int)(testBounds.Top / TILE_SIZE);
            int bottomTile = (int)(testBounds.Bottom / TILE_SIZE);

            leftTile = MathHelper.Clamp(leftTile, 0, dungeon.Width - 1);
            rightTile = MathHelper.Clamp(rightTile, 0, dungeon.Width - 1);
            topTile = MathHelper.Clamp(topTile, 0, dungeon.Height - 1);
            bottomTile = MathHelper.Clamp(bottomTile, 0, dungeon.Height - 1);

            for (int x = leftTile; x <= rightTile; x++)
            {
                for (int y = topTile; y <= bottomTile; y++)
                {
                    if (!dungeon.IsWalkable(x, y))
                    {
                        return false;
                    }
                }
            }

            return true;
        }

        /// <summary>
        /// Raycast semplificato per controlli di visibilità
        /// </summary>
        public bool Raycast(Vector2 start, Vector2 end, Dungeon dungeon, out Vector2 hitPoint)
        {
            hitPoint = end;

            Vector2 direction = end - start;
            float distance = direction.Length();
            direction.Normalize();

            float stepSize = TILE_SIZE * 0.5f;
            int steps = (int)(distance / stepSize);

            for (int i = 0; i <= steps; i++)
            {
                Vector2 currentPoint = start + direction * (i * stepSize);
                
                int tileX = (int)(currentPoint.X / TILE_SIZE);
                int tileY = (int)(currentPoint.Y / TILE_SIZE);

                if (tileX >= 0 && tileX < dungeon.Width && tileY >= 0 && tileY < dungeon.Height)
                {
                    if (!dungeon.IsWalkable(tileX, tileY))
                    {
                        hitPoint = currentPoint;
                        return true; // Hit detected
                    }
                }
            }

            return false; // No hit
        }

        /// <summary>
        /// Controlla collisioni future per prevenire movimenti non validi
        /// </summary>
        public bool WouldCollideWithWorld(Entity entity, Vector2 futurePosition, Dungeon dungeon)
        {
            Vector2 originalPosition = entity.Transform.Position;
            entity.Transform.Position = futurePosition;

            var futureBounds = entity.GetBounds();
            bool wouldCollide = false;

            int leftTile = (int)(futureBounds.Left / TILE_SIZE);
            int rightTile = (int)(futureBounds.Right / TILE_SIZE);
            int topTile = (int)(futureBounds.Top / TILE_SIZE);
            int bottomTile = (int)(futureBounds.Bottom / TILE_SIZE);

            leftTile = MathHelper.Clamp(leftTile, 0, dungeon.Width - 1);
            rightTile = MathHelper.Clamp(rightTile, 0, dungeon.Width - 1);
            topTile = MathHelper.Clamp(topTile, 0, dungeon.Height - 1);
            bottomTile = MathHelper.Clamp(bottomTile, 0, dungeon.Height - 1);

            for (int x = leftTile; x <= rightTile && !wouldCollide; x++)
            {
                for (int y = topTile; y <= bottomTile && !wouldCollide; y++)
                {
                    if (!dungeon.IsWalkable(x, y))
                    {
                        wouldCollide = true;
                    }
                }
            }

            // Ripristina la posizione originale
            entity.Transform.Position = originalPosition;
            return wouldCollide;
        }
    }
}