using System;
using System.Collections.Generic;
using System.Linq;
using DefaultNamespace;
using UnityEngine;

public class CableGrid : MonoBehaviour {
    public GameObject cableTilePrefab;
    public GameObject lampPrefab;

    private bool[,] map;
    private Dictionary<(int, int), CableTile> cableTiles = new Dictionary<(int, int), CableTile>();

    private MapGenerator mapGenerator;
    private Endpoint endpoint;
    private ShadowManager shadowManager;

    private static readonly List<(int, int)> DIRECTIONS = new List<(int, int)> {(0, 1), (1, 0), (0, -1), (-1, 0)};
    private static readonly List<(int, int)> DIRECTIONS_WITH_CENTER = DIRECTIONS.Concat(new List<(int, int)> {(0, 0)}).ToList();

    private bool first = true;

    private void Start() {
        mapGenerator = GameObject.Find("MapGenerator").GetComponent<MapGenerator>();
        endpoint = GameObject.Find("Endpoint").GetComponent<Endpoint>();
        shadowManager = GameObject.Find("ShadowManager").GetComponent<ShadowManager>();

        map = new bool[mapGenerator.size, mapGenerator.size];

        // Place first lamp
        var firstLampPositionInfo = mapGenerator.FindFirstLampPosition(mapGenerator.generatorCoords.Item1, mapGenerator.generatorCoords.Item2);
        foreach (var (x, y) in firstLampPositionInfo) PlaceCable(x, y);

        var (lampX, lampY) = firstLampPositionInfo[1];
        Instantiate(lampPrefab, new Vector3(lampX + 0.5f, lampY + 0.5f), Quaternion.identity);
    }

    private void LateUpdate() {
        // Duck tape around "first lamp" bug
        if (first) {
            var playerPosition = GameObject.Find("Player").transform.position;
            int x = (int) playerPosition.x;
            int y = (int) playerPosition.y;
            PlaceCable(x, y);
            RemoveCable(x, y);

            first = false;
        }
    }

    public bool PlaceCable(int x, int y) {
        // Check if cable can be placed
        var (generatorX, generatorY) = mapGenerator.generatorCoords;
        if (x < 0 || y < 0 || x >= mapGenerator.size || y >= mapGenerator.size || mapGenerator.GetCollisonMap()[x, y] || (generatorX == x && generatorY == y) || map[x, y]) return false;

        // Create CableTile game object
        var cableTilePosition = new Vector3(x + 0.5f, y + 0.5f, 0);
        var cableTileGameObject = Instantiate(cableTilePrefab, cableTilePosition, Quaternion.identity, transform);
        var cableTile = cableTileGameObject.GetComponent<CableTile>();
        cableTile.parentGrid = this;

        // Update maps
        cableTiles[(x, y)] = cableTile;
        map[x, y] = true;

        RegenerateEverything();
        return true;
    }

    public bool RemoveCable(int x, int y) {
        // Check if there is cable to be removed
        var coord = (x, y);
        if (cableTiles.Keys.Contains(coord) == false) return false;

        // Destroy game object and update maps
        Destroy(cableTiles[coord].gameObject);
        cableTiles.Remove(coord);
        map[x, y] = false;

        RegenerateEverything();
        return true;
    }

    public void RegenerateEverything() {
        // Regenerate power information
        RegeneratePowerInfo();

        // Regenerate shadow tilemap
        shadowManager.RegenerateShadowMap();

        // Reset sprites on all cables
        foreach (var key in cableTiles.Keys) {
            cableTiles[key].ResetSprites(GetNeighbourCables(key.Item1, key.Item2));
        }
    }

    private List<bool> GetNeighbourCables(int x, int y) {
        var (generatorX, generatorY) = mapGenerator.generatorCoords;
        List<bool> neighbours = new List<bool>();

        foreach (var (i, j) in DIRECTIONS) {
            if (i == 0 && j == 0) continue;
            int nx = x + i;
            int ny = y + j;

            if (nx < 0 || ny < 0 || nx >= mapGenerator.size || ny >= mapGenerator.size) {
                neighbours.Add(false);
            } else if (generatorX == nx && generatorY == ny) {
                neighbours.Add(true);
            } else {
                neighbours.Add(map[nx, ny]);
            }
        }

        return neighbours;
    }

    private void RegeneratePowerInfo() {
        RegenerateCablePowerInfo();
        RegenerateElectricalDevicesPowerInfo();
        endpoint.RegeneratePowerInfo();
    }

    private void RegenerateCablePowerInfo() {
        var cablePositions = cableTiles.Keys.ToList();
        var queue = new List<(int, int)> {mapGenerator.generatorCoords};

        while (queue.Count > 0) {
            var (x, y) = queue[0];
            queue.RemoveAt(0);

            foreach (var (dx, dy) in DIRECTIONS_WITH_CENTER) {
                int nx = x + dx;
                int ny = y + dy;
                var coord = (nx, ny);

                if (cablePositions.Contains(coord)) {
                    cablePositions.Remove(coord);

                    queue.Add(coord);
                    cableTiles[coord].hasPower = true;
                }
            }
        }

        foreach (var coord in cablePositions) {
            cableTiles[coord].hasPower = false;
        }
    }

    private void RegenerateElectricalDevicesPowerInfo() {
        var electricalDevices = FindObjectsOfType<ElectricalDevice>();
        foreach (var electricalDevice in electricalDevices) {
            electricalDevice.RegeneratePowerInfo();
        }
    }

    public bool IsTilePowered(int x, int y) {
        var cableTile = cableTiles.GetOrDefault((x, y), null);
        return cableTile != null ? cableTile.hasPower : false;
    }
}