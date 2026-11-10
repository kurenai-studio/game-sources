using LudumDare57.Enemy;
using LudumDare57.Prop;
using LudumDare57.SO;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace LudumDare57.Manager
{
    public class MapManager : MonoBehaviour
    {
        [SerializeField]
        private MapGenInfo _genInfo;

        [SerializeField]
        private TileInfo[] _tiles;

        [SerializeField]
        private GameObject _blockPrefab;

        [SerializeField]
        private BoxCollider2D _genBoundingBox;

        [SerializeField]
        private GameObject[] _enemyGoodPrefabs, _enemyBadPrefabs;

        [SerializeField]
        private GameObject _exitPrefab;

        private GameObject _mapContainer;

        private const float TileSize = 1.28f;
        private const int GameTopAreaY = -1;

        private void Awake()
        {
            _mapContainer = new GameObject("Map");
            _genBoundingBox.size = new Vector2((_genInfo.MapGenWidth * 2f + 1f) * TileSize, _genBoundingBox.size.y);

            var areaCount = _genInfo.AreaInfo.Length;

            int xStart = 0;
            for (int area = 0; area < areaCount; area++)
            {
                GenerateArea(area, out xStart, Mathf.Lerp(_genInfo.EnemyReactionTime.Max, _genInfo.EnemyReactionTime.Min, (float)area / areaCount), _genInfo.AreaInfo[area]);
            }
            SpawnWall(-_genInfo.MapGenWidth, 1f);
            SpawnWall(_genInfo.MapGenWidth, 1f);

            Instantiate(_exitPrefab, new Vector2(
                x: xStart * TileSize,
                y: (GameTopAreaY - (areaCount * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) + 1.5f) * TileSize
                ), Quaternion.identity);
            for (int y = 0; y < 3; y++)
            {
                for (int x = -_genInfo.MapGenWidth; x <= _genInfo.MapGenWidth; x++)
                {
                    SpawnTile(
                        x: x,
                        y: GameTopAreaY - (areaCount * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - y,
                        destructible: (y != 0 || x != xStart) && Mathf.Abs(x) != _genInfo.MapGenWidth
                        //isObjective: y == 2 && x == 0
                    );
                }
            }
            for (int x = -_genInfo.MapGenWidth; x <= _genInfo.MapGenWidth; x++)
            {
                SpawnTile(
                    x: x,
                    y: GameTopAreaY - (areaCount * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - 3,
                    destructible: false
                );
            }
        }

        private void GenerateArea(int yOffset, out int xStart, float reactTime, LevelSpawnInfo spawnInfo)
        {
            for (int y = 0; y < _genInfo.AreaHeight; y++)
            {
                for (int x = -_genInfo.MapGenWidth; x <= _genInfo.MapGenWidth; x++)
                {
                    SpawnTile(
                        x: x,
                        y: GameTopAreaY - (yOffset * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - y,
                        destructible: (yOffset != 0 || y != 0 || x < 0 || x > 4) && Mathf.Abs(x) != _genInfo.MapGenWidth
                    );
                }
            }
            var size = (int)Random.Range(_genInfo.MapGenWidth, 2f * _genInfo.MapGenWidth / 3f);
            xStart = (int)Random.Range(-_genInfo.MapGenWidth, -_genInfo.MapGenWidth / 2f);
            for (int y = 0; y < _genInfo.AreaInterSpacing; y++)
            {
                for (int x = -_genInfo.MapGenWidth; x <= _genInfo.MapGenWidth; x++)
                {
                    if (x < xStart || x >= size)
                    {
                        SpawnTile(
                            x: x,
                            y: GameTopAreaY - (yOffset * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - _genInfo.AreaHeight - y,
                            destructible: (yOffset != 0 || y != 0 || x < 0 || x > 4) && Mathf.Abs(x) != _genInfo.MapGenWidth
                        );
                    }
                    else if (Mathf.Abs(x) != _genInfo.MapGenWidth)
                    {
                        SpawnTile(
                            x: _genInfo.MapGenWidth,
                            y: GameTopAreaY - (yOffset * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - _genInfo.AreaHeight - y,
                            destructible: false
                        );
                    }
                }
            }
            var enemyCount = Random.Range(spawnInfo.TotalAmount.Min, spawnInfo.TotalAmount.Max + 1);
            var corruptedLeft = spawnInfo.CorruptedAmount.Max == 0 ? 0 : Random.Range(spawnInfo.CorruptedAmount.Min, spawnInfo.CorruptedAmount.Max + 1);
            for (int i = 0; i < enemyCount; i++)
            {
                var spawnX = Random.Range(xStart, xStart + size) * TileSize;
                var spawnY = Random.Range(
                    GameTopAreaY - (yOffset * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - _genInfo.AreaHeight - (_genInfo.AreaInterSpacing - 1f),
                    GameTopAreaY - (yOffset * (_genInfo.AreaHeight + _genInfo.AreaInterSpacing)) - _genInfo.AreaHeight - (_genInfo.AreaInterSpacing / 2f)
                ) * TileSize;
                var possibles = corruptedLeft > 0 ? _enemyBadPrefabs : _enemyGoodPrefabs;
                var en = Instantiate(possibles[Random.Range(0, possibles.Length)], new Vector2(spawnX, spawnY), Quaternion.identity);
                en.GetComponent<AEnemy>().ReactionTime = reactTime;

                if (corruptedLeft > 0) corruptedLeft--;
            }
        }

        private void SpawnWall(int x, float sizeX)
        {
            var wall = new GameObject("Wall", typeof(BoxCollider2D))
            {
                layer = LayerMask.NameToLayer("Map")
            };
            wall.transform.position = new Vector2((x + (sizeX * (x < 0f ? -1f : 1f))) * TileSize, 0f);
            wall.transform.parent = _mapContainer.transform;
            var coll = wall.GetComponent<BoxCollider2D>();
            coll.size = new Vector2(sizeX * TileSize, 100f);
        }

        private void SpawnTile(int x, int y, bool destructible, bool isObjective = false)
        {
            var isOnTop = y == GameTopAreaY;
            IEnumerable<TileInfo> availables = _tiles.Where(x => x.IsDestructible == destructible).OrderBy(x => isOnTop == x.IsOnTop ? 0 : 1);

            var go = Instantiate(_blockPrefab, _mapContainer.transform);
            go.transform.position = new Vector2(x, y) * TileSize;
            if (isObjective)
            {
                availables = availables.Where(x => x.IsObjective);
            }
            if (destructible)
            {
                var bl = go.AddComponent<DestructibleBlock>();
                if (isOnTop)
                {
                    bl.MoneyGained = Random.Range(0, 2);
                }
                else
                {
                    var lucky = Random.Range(0, 100) < _genInfo.GoldChance;
                    if (lucky)
                    {
                        availables = _tiles.Where(x => x.IsValuable);
                        bl.MoneyGained = Random.Range(10, 30);
                    }
                    else bl.MoneyGained = Random.Range(0, 2);
                }
            }
            var first = availables.First();
            go.GetComponent<SpriteRenderer>().sprite = first.Sprites[Random.Range(0, first.Sprites.Length)];
        }
    }
}