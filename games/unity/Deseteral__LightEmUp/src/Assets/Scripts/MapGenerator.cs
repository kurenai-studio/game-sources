using System.Collections.Generic;
using System.Linq;
using DefaultNamespace;
using UnityEngine;
using UnityEngine.Tilemaps;
using Random = UnityEngine.Random;

public class MapGenerator : MonoBehaviour {
    public Tilemap ground;
    public Tilemap walls;
    public Tilemap wallTops;
    public Tilemap shadow;

    public Tile[] groundTiles;
    public Tile[] wallTiles;
    public Tile wallTopTile;
    public Tile shadowTile;

    public GameObject enemySpawner;

    public int size = 50;
    public (int, int) generatorCoords;
    public (int, int) endpointCoords;

    private bool[,] m;

    private readonly List<(int, int)> DIRECTIONS = new List<(int, int)> {(0, 1), (1, 0), (0, -1), (-1, 0)};
    private readonly List<int> DIRECTIONS_DIAGONAL = new List<int> {-1, 0, 1};

    void Start() {
        bool isValidMap = false;
        Vector3 playerPosition = Vector3.zero;

        int attempts = 0;
        while (!isValidMap) {
            CelluarAutomata();
            RemoveClosedRooms();
            attempts++;

            // Check if map is valid
            var (spawnX, spawnY) = FindSpawnPoint();
            if (spawnX == -1 || spawnY == -1) continue;

            var (endpointX, endpointY, _) = FindEndpointTile(spawnX, spawnY);
            if (endpointX == -1 || endpointY == -1) continue;
            endpointCoords = (endpointX, endpointY);

            isValidMap = true;

            // Set player position
            playerPosition = new Vector3(spawnX + 0.5f, spawnY + 0.5f, 0);
            GameObject.Find("Player").transform.position = playerPosition;

            // Place generator
            foreach (var (dx, dy) in DIRECTIONS) {
                int nx = dx + spawnX;
                int ny = dy + spawnY;
                if (m[nx, ny] == false) {
                    GameObject.Find("Generator").transform.position = new Vector3(nx + 0.5f, ny + 0.5f, 0);
                    generatorCoords = (nx, ny);
                    break;
                }
            }
            
            // Place endpoint
            var endpointGameObject = GameObject.Find("Endpoint");
            endpointGameObject.transform.position = new Vector3(endpointX + 0.5f, endpointY + 0.5f, 0);
            endpointGameObject.GetComponent<Endpoint>().ResetPositionInfo();
            ground.SetTile(new Vector3Int(endpointX, endpointY, 0), groundTiles[0]);
        }

        Debug.Log($"Map generation attempts: {attempts}");

        // Set tiles
        ApplyMapToTilemap();

        // Place spawners
        var spawnersContainer = GameObject.Find("SpawnersContainer");
        foreach (var (spawnerX, spawnerY) in FindEnemySpawnerPositions()) {
            var spawnerPosition = new Vector3(spawnerX + 0.5f, spawnerY + 0.5f);

            // Skip spawner if it is near the player spawn point
            if (Vector3.Distance(playerPosition, spawnerPosition) < 10f) continue;

            Instantiate(enemySpawner, spawnerPosition, Quaternion.identity, spawnersContainer.transform);
        }
    }

    private void CelluarAutomata() {
        m = new bool[size, size];

        int numberOfSteps = 2;
        int birthLimit = 5;
        int deathLimit = 4;
        float chanceToStartAlive = 0.49f;

        // Initialization
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                m[x, y] = Random.Range(0f, 1f) < chanceToStartAlive;
            }
        }

        // Simulation step
        for (int step = 0; step < numberOfSteps; step++) {
            var newMap = new bool[size, size];
            for (int y = 0; y < size; y++) {
                for (int x = 0; x < size; x++) {
                    var nc = CountNeighbours(x, y);
                    if (m[x, y]) {
                        newMap[x, y] = nc < deathLimit ? false : true;
                    } else if (nc > birthLimit) {
                        newMap[x, y] = true;
                    } else {
                        newMap[x, y] = false;
                    }
                }
            }

            m = newMap;
        }

        // Make enclosing walls
        for (int x = 0; x < size; x++) {
            m[x, 0] = true; // top
            m[x, size - 1] = true; // bottom
        }

        for (int y = 0; y < size; y++) {
            m[0, y] = true; // left
            m[size - 1, y] = true; // right
        }
    }

    private int CountNeighbours(int x, int y) {
        int count = 0;
        foreach (int i in DIRECTIONS_DIAGONAL) {
            foreach (int j in DIRECTIONS_DIAGONAL) {
                if (i == 0 && j == 0) continue;
                int nx = x + i;
                int ny = y + j;

                if ((nx < 0 || ny < 0 || nx >= size || ny >= size) || m[nx, ny]) {
                    count++;
                }
            }
        }

        return count;
    }

    private void RemoveClosedRooms() {
        var floodMap = new bool[size, size];
        var queue = new List<(int, int)>();

        floodMap[size / 2, size / 2] = true;
        queue.Add((size / 2, size / 2));

        // Mark neighbours
        while (queue.Count > 0) {
            var (x, y) = queue[0];
            queue.RemoveAt(0);

            foreach (int i in DIRECTIONS_DIAGONAL) {
                foreach (int j in DIRECTIONS_DIAGONAL) {
                    if (i != 0 && j != 0) continue;

                    int nx = x + i;
                    int ny = y + j;

                    if (
                        (nx >= 0 && ny >= 0 && nx < size && ny < size) &&
                        (m[nx, ny] == false && floodMap[nx, ny] == false)
                    ) {
                        floodMap[nx, ny] = true;
                        queue.Add((nx, ny));
                    }
                }
            }
        }

        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                if (m[x, y] == false && floodMap[x, y] == false) m[x, y] = true;
            }
        }
    }

    private (int, int, int) FindEndpointTile(int startX, int startY) {
        var floodMap = new bool[size, size];
        var queue = new List<(int, int, int)>();

        floodMap[startX, startY] = true;
        queue.Add((startX, startY, 0));

        int bestDistance = -1;
        var winningTile = (-1, -1, -1);

        // Mark neighbours
        while (queue.Count > 0) {
            var (x, y, currentDistance) = queue[0];
            queue.RemoveAt(0);

            if (currentDistance > bestDistance) {
                bestDistance = currentDistance;
                winningTile = (x, y, currentDistance);
            }

            foreach (int i in DIRECTIONS_DIAGONAL) {
                foreach (int j in DIRECTIONS_DIAGONAL) {
                    if (i != 0 && j != 0) continue;

                    int nx = x + i;
                    int ny = y + j;

                    if (
                        (nx >= 0 && ny >= 0 && nx < size && ny < size) &&
                        (m[nx, ny] == false && floodMap[nx, ny] == false)
                    ) {
                        floodMap[nx, ny] = true;
                        queue.Add((nx, ny, currentDistance + 1));
                    }
                }
            }
        }

        return winningTile;
    }

    private (int, int) FindSpawnPoint() {
        for (int y = 1; y < (size / 2); y++) {
            for (int distance = 1; distance < (size / 2); distance++) {
                if (m[distance, y] == false) return (distance, y);
                if (m[size - distance - 1, y] == false) return (size - distance - 1, y);
                if (m[distance, size - y - 1] == false) return (distance, size - y - 1);
                if (m[size - distance - 1, size - y - 1] == false) return (size - distance - 1, size - y - 1);
            }
        }

        return (-1, -1);
    }

    private List<(int, int)> FindEnemySpawnerPositions() {
        List<(int, int)> floors = new List<(int, int)>();

        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                if (m[x, y] == false) floors.Add((x, y));
            }
        }

        float percentOfSpawnerTiles = 2f / 100f;
        int floorsToTake = (int) (floors.Count * percentOfSpawnerTiles);
        floors.Shuffle();

        return floors.Take(floorsToTake).ToList();


        // List<(int, int)> positions = new List<(int, int)>();
        // int oneSpawnerPerUnits = 10;
        // int sectionCount = size / oneSpawnerPerUnits;
        //
        // for (int sectionY = 0; sectionY < sectionCount; sectionY++) {
        //     for (int sectionX = 0; sectionX < sectionCount; sectionX++) {
        //         int yStart = sectionY * oneSpawnerPerUnits;
        //         int yEnd = sectionY * oneSpawnerPerUnits + oneSpawnerPerUnits;
        //         int xStart = sectionX * oneSpawnerPerUnits;
        //         int xEnd = sectionX * oneSpawnerPerUnits + oneSpawnerPerUnits;
        //         
        //         for (int y = yStart; y < sectionCount; sectionY++) {
        //             for (int sectionX = 0; sectionX < sectionCount; sectionX++) {
        //                 
        //             }
        //         }
        //     }   
        // }

        // return positions;
    }

    public (int, int)[] FindFirstLampPosition(int spawnX, int spawnY) {
        foreach (var (dx, dy) in DIRECTIONS) {
            int nx = spawnX + dx;
            int ny = spawnY + dy;
            int nnx = spawnX + dx * 2;
            int nny = spawnY + dy * 2;
            if (m[nx, ny] == false && m[nnx, nny] == false) {
                return new[] {(nx, ny), (nnx, nny)};
            }
        }

        return new (int, int)[] {};
    }

    private void ApplyMapToTilemap() {
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                int idx;
                if (Random.Range(0f, 1f) < 0.5f) {
                    idx = 0;
                } else {
                    idx = Random.Range(0, groundTiles.Length);
                }
                ground.SetTile(new Vector3Int(x, y, 0), groundTiles[idx]);
            }
        }

        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                if (m[x, y]) {
                    var pos = new Vector3Int(x, y, 0);
                    walls.SetTile(pos, wallTiles[Random.Range(0, wallTiles.Length)]);
                    wallTops.SetTile(pos, wallTopTile);
                }
            }
        }

        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                shadow.SetTile(new Vector3Int(x, y, 0), shadowTile);
            }
        }
    }

    public bool[,] GetCollisonMap() {
        return m;
    }
}