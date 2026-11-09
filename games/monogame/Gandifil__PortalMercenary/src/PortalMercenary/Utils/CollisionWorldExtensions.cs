using Microsoft.Xna.Framework;
using MonoGame.Extended;
using MonoGame.Extended.Collisions;
using MonoGame.Extended.Collisions.Layers;
using MonoGame.Extended.Tilemaps;

namespace PortalMercenary.Utils;

public static class CollisionWorldExtensions
{
    public const string LAYER_NAME = "environment";
    
    private class CollisionActor: ICollisionActor
    {
        public CollisionActor(int x, int y)
        {
            Id = GetHashCode();
            Shape = new CollisionShape2D(new BoundingBox2D(
                new Vector2(x, y) * Game1.TILE_WIDTH, 
                new Vector2(x + 1, y + 1) * Game1.TILE_WIDTH
                ));
        }
        public int Id { get; }
        public CollisionShape2D Shape { get; }
    }
    
    public static void AddTilemapCollision(this CollisionWorld2D collisionWorld, Tilemap tilemap)
    {
        var spatialHash = new SpatialHash(new SizeF(Game1.TILE_WIDTH, Game1.TILE_HEIGHT));
        collisionWorld.AddLayer(LAYER_NAME, new Layer(spatialHash)
        {
            IsDynamic = false,
        });
        
        var grounded = new bool[tilemap.Width, tilemap.Height];

        foreach (var layer in tilemap.Layers.GetLayers<TilemapTileLayer>())
            if (layer.Name.StartsWith("ground"))
            {
                foreach (var tile in layer.GetTiles())
                {
                    grounded[tile.X, tile.Y] = true;
                }
            }

        for (int x = 0; x < tilemap.Width; x++)
        {
            for (int y = 0; y < tilemap.Height; y++)
            {
                if (!grounded[x, y])
                {
                    collisionWorld.Insert(new CollisionActor(x, y), LAYER_NAME);
                }
            }
        }
    }
}