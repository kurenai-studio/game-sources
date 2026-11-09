using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Tilemaps;

public class ShadowManager : MonoBehaviour {
    private Tile shadowTile;

    private Tilemap wallsTilemap;
    private Tilemap shadowTilemap;
    private MapGenerator mapGenerator;

    private static Vector3Int[] EVERY_SHADOW_POSITION = null;
    private static TileBase[] EVERY_SHADOW_TILE = null;

    private readonly List<(int, int)> DIRECTIONS = new List<(int, int)> {(0, 1), (1, 0), (0, -1), (-1, 0)};

    private void Start() {
        wallsTilemap = GameObject.Find("Walls").GetComponent<Tilemap>();
        shadowTilemap = GameObject.Find("Shadow").GetComponent<Tilemap>();
        mapGenerator = GameObject.Find("MapGenerator").GetComponent<MapGenerator>();
        shadowTile = mapGenerator.shadowTile;

        if (EVERY_SHADOW_POSITION == null || EVERY_SHADOW_TILE == null) {
            EVERY_SHADOW_POSITION = new Vector3Int[mapGenerator.size * mapGenerator.size + mapGenerator.size];
            for (int y = 0; y < mapGenerator.size + 1; y++) {
                for (int x = 0; x < mapGenerator.size; x++) {
                    int idx = x + y * mapGenerator.size;
                    EVERY_SHADOW_POSITION[idx] = new Vector3Int(x, y, 0);
                }
            }

            EVERY_SHADOW_TILE = Enumerable.Repeat<TileBase>(shadowTile, EVERY_SHADOW_POSITION.Length).ToArray();
        }
    }

    public void RegenerateShadowMap() {
        // Shadow everything
        shadowTilemap.SetTiles(EVERY_SHADOW_POSITION, EVERY_SHADOW_TILE);

        // Only set light tiles
        IEnumerable<Vector3Int> positions = new List<Vector3Int>();
        var lampGameObjects = GameObject.FindGameObjectsWithTag("Light");
        foreach (var lampGameObject in lampGameObjects) {
            // Check if lamp has power
            if (lampGameObject.GetComponent<ElectricalDevice>().hasPower == false) continue;

            var lamp = lampGameObject.GetComponent<Lamp>();
            positions = positions.Concat(lamp.GetLightTiles());
        }
        
        List<Vector3Int> litWalls = new List<Vector3Int>();
        foreach (var v3 in positions) {
            foreach (var (dx, dy) in DIRECTIONS) {
                int nx = v3.x + dx;
                int ny = v3.y + dy;
                if (nx < 0 || ny < 0 || nx >= mapGenerator.size || ny >= mapGenerator.size) continue;
                var pos = new Vector3Int(nx, ny, 0);
                if (wallsTilemap.GetTile(pos) != null) {
                    litWalls.Add(pos);   
                }
            }
        }
        
        positions = positions.Concat(litWalls);

        Vector3Int[] positionArray = positions.ToArray();
        TileBase[] tileArray = Enumerable.Repeat<TileBase>(null, positionArray.Length).ToArray();
        shadowTilemap.SetTiles(positionArray, tileArray);
    }
}