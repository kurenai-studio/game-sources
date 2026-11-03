
// ============================================
// Systems/RenderSystem.cs
// ============================================
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using DungeonExplorer.Entities;
using DungeonExplorer.World;
using System.Collections.Generic;

namespace DungeonExplorer.Systems
{
    public class RenderSystem
    {
        public void RenderEntity(SpriteBatch spriteBatch, Entity entity)
        {
            if (entity?.Transform == null || entity.Render == null || !entity.Render.Visible)
                return;

            var texture = entity.Render.Texture;
            var position = entity.Transform.Position;
            var rotation = entity.Transform.Rotation;
            var scale = entity.Transform.Scale;
            var origin = entity.Transform.Origin;
            var tint = entity.Render.Tint;
            var sourceRect = entity.Render.SourceRectangle;
            var effects = entity.Render.SpriteEffects;
            var layerDepth = entity.Render.LayerDepth;

            spriteBatch.Draw(
                texture,
                position,
                sourceRect,
                tint,
                rotation,
                origin,
                scale,
                effects,
                layerDepth
            );
        }

        public void RenderDungeon(SpriteBatch spriteBatch, Dungeon dungeon, Dictionary<string, Texture2D> textures)
        {
            if (dungeon?.Tiles == null) return;

            const int TILE_SIZE = 32;

            for (int x = 0; x < dungeon.Width; x++)
            {
                for (int y = 0; y < dungeon.Height; y++)
                {
                    var tile = dungeon.Tiles[x, y];
                    if (tile == null) continue;

                    var position = new Vector2(x * TILE_SIZE, y * TILE_SIZE);
                    Texture2D texture = null;

                    switch (tile.Type)
                    {
                        case TileType.Floor:
                            texture = textures.ContainsKey("floor") ? textures["floor"] : null;
                            break;
                        case TileType.Wall:
                            texture = textures.ContainsKey("wall") ? textures["wall"] : null;
                            break;
                        case TileType.Door:
                            texture = textures.ContainsKey("door") ? textures["door"] : textures.ContainsKey("floor") ? textures["floor"] : null;
                            break;
                        case TileType.Corridor:
                            texture = textures.ContainsKey("floor") ? textures["floor"] : null;
                            break;
                    }

                    if (texture != null)
                    {
                        var tint = tile.Tint;
                        
                        // Special coloring for start/end positions
                        if (tile.IsStartPosition)
                            tint = Color.Green;
                        else if (tile.IsEndPosition)
                            tint = Color.Red;

                        spriteBatch.Draw(texture, position, tint);
                    }
                }
            }
        }
    }
}