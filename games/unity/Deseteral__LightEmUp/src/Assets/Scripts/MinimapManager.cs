using UnityEngine;
using UnityEngine.UI;

public class MinimapManager : MonoBehaviour {
    public int radius = 4;

    private MapGenerator mapGenerator;
    private GameObject playerObject;
    private CableGrid cableGrid;

    private Texture2D texture;
    private RawImage minimapUi;

    private static Color WALL_COLOR = new Color(13f / 255f, 66f / 255f, 50f / 255f);
    private static Color GROUND_COLOR = new Color(0x4e / 255f, 0x4e / 255f, 0x4e / 255f);
    private static Color CABLE_COLOR = new Color(0f / 255f, 200f / 255f, 189f / 255f);
    private static Color GENERATOR_COLOR = Color.green;
    private static Color ENDPOINT_COLOR = Color.red;

    private void Start() {
        playerObject = GameObject.Find("Player");
        mapGenerator = GameObject.Find("MapGenerator").GetComponent<MapGenerator>();
        cableGrid = GameObject.Find("CableGrid").GetComponent<CableGrid>();

        minimapUi = GameObject.Find("Minimap").GetComponent<RawImage>();

        texture = new Texture2D(mapGenerator.size, mapGenerator.size) {filterMode = FilterMode.Point};
        for (int y = 0; y < mapGenerator.size; y++) {
            for (int x = 0; x < mapGenerator.size; x++) {
                texture.SetPixel(x, y, Color.black);
            }
        }
    }

    private void FixedUpdate() {
        var collisionMap = mapGenerator.GetCollisonMap();
        var (genX, genY) = mapGenerator.generatorCoords;
        var (endX, endY) = mapGenerator.endpointCoords;
        var playerPosition = playerObject.transform.position;
        int tx = (int) playerPosition.x;
        int ty = (int) playerPosition.y;

        for (int y = ty - radius; y < ty + radius; y++) {
            if (y < 0 || y >= mapGenerator.size) continue;

            for (int x = tx - radius; x < tx + radius; x++) {
                if (x < 0 || x >= mapGenerator.size) continue;

                if (Vector2.Distance(new Vector2(x, y), playerPosition) <= radius) {
                    if (x == genX && y == genY) {
                        texture.SetPixel(x, y, GENERATOR_COLOR);
                    } else if (x == endX && y == endY) {
                        texture.SetPixel(x, y, ENDPOINT_COLOR);
                    } else if (cableGrid.IsTilePowered(x, y)) {
                        texture.SetPixel(x, y, CABLE_COLOR);
                    } else if (collisionMap[x, y]) {
                        texture.SetPixel(x, y, WALL_COLOR);
                    } else {
                        texture.SetPixel(x, y, GROUND_COLOR);
                    }
                }
            }
        }

        texture.Apply();
        minimapUi.texture = texture;
    }
}