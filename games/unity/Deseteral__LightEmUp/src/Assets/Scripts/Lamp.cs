using System.Collections.Generic;
using UnityEngine;

public class Lamp : MonoBehaviour {
    public Sprite lampOnSprite;
    public Sprite lampOffSprite;

    private static List<(int, int)> LIGHT_MASK = null;

    private ElectricalDevice electricalDevice;
    private SpriteRenderer spriteRenderer;
    private ShadowManager shadowManager;

    private Vector3Int[] lightTiles;

    private void Start() {
        electricalDevice = GetComponent<ElectricalDevice>();
        spriteRenderer = GetComponent<SpriteRenderer>();
        shadowManager = GameObject.Find("ShadowManager").GetComponent<ShadowManager>();

        if (LIGHT_MASK == null) {
            LIGHT_MASK = new List<(int, int)>();

            // var lightMaskStr = new List<string> {
            //     "  xxxxx  ",
            //     " xxxxxxx ",
            //     "xxxxxxxxx",
            //     "xxxxxxxxx",
            //     "xxxx xxxx",
            //     "xxxxxxxxx",
            //     "xxxxxxxxx",
            //     " xxxxxxx ",
            //     "  xxxxx",
            // };
            
            var lightMaskStr = new List<string> {
                "   xxxxx   ",
                "  xxxxxxx  ",
                " xxxxxxxxx ",
                "xxxxxxxxxxx",
                "xxxxxxxxxxx",
                "xxxxx xxxxx",
                "xxxxxxxxxxx",
                "xxxxxxxxxxx",
                " xxxxxxxxx ",
                "  xxxxxxx  ",
                "   xxxxx   ",
            };

            int ss = (lightMaskStr.Count - 1) / 2;
            for (int y = -ss; y <= ss; y++) {
                for (int x = -ss; x <= ss; x++) {
                    if (lightMaskStr[ss + y][ss + x] == 'x') {
                        LIGHT_MASK.Add((x, y));
                    }
                }
            }
        }

        lightTiles = RegenerateLightTiles();
        shadowManager.RegenerateShadowMap();
    }

    private void FixedUpdate() {
        var currentHasPower = electricalDevice.hasPower; // TODO: POTENTIAL PREF PROBLEM
        if (currentHasPower) {
            spriteRenderer.sprite = lampOnSprite;   
        } else {
            spriteRenderer.sprite = lampOffSprite;
        }
    }

    private Vector3Int[] RegenerateLightTiles() {
        var position = transform.position;
        var positions = new List<Vector3Int> {new Vector3Int((int) position.x, (int) position.y, 0)};

        foreach (var (dx, dy) in LIGHT_MASK) {
            Vector3 tilePosition = new Vector3(position.x + dx, position.y + dy, 0);

            if (CanTileSeeLight(tilePosition, position)) {
                int px = (int) tilePosition.x;
                int py = (int) tilePosition.y;
                positions.Add(new Vector3Int(px, py, 0));
            }
        }

        return positions.ToArray();
    }

    private bool CanTileSeeLight(Vector2 start, Vector2 end) {
        int tilemapAndLightsMask = (1 << 8) | (1 << 12);
        RaycastHit2D hit = Physics2D.Linecast(start, end, tilemapAndLightsMask);

        return hit.collider != null && hit.collider.gameObject.CompareTag("Light");
    }

    public Vector3Int[] GetLightTiles() {
        return lightTiles;
    }
}