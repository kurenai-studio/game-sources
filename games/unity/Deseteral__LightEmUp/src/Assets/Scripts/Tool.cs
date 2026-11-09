using System;
using System.Collections.Generic;
using DefaultNamespace;
using UnityEngine;
using UnityEngine.UI;
using Random = UnityEngine.Random;

public enum ToolType {
    Gun = 0,
    PlaceCable = 1,
    PlaceLamp = 2,
    PlaceTurret = 3,
}

public class Tool : MonoBehaviour {
    public bool isPlayer = false;
    public float spread = 10f;
    public int shootingDelayMs = 150;
    public ToolType toolType = ToolType.Gun;

    public GameObject bulletPrefab;
    public GameObject lampPrefab;
    public GameObject turretPrefab;
    public GameObject coinPrefab;

    private MapGenerator mapGenerator;
    private CableGrid cableGrid;

    private GameObject bulletsContainer;
    private GameObject devicesContainer;
    private GameObject coinsContainer;

    private GameMaster gameMaster;
    private AudioManager audioManager;
    
    private Text costText;
    private Image costIcon;

    private Dictionary<(int, int), GameObject> devicesMap;

    private Timer shootingDelayTimer = new Timer();

    private float maxPlacingDistance = 5f;

    private void Start() {
        cableGrid = GameObject.Find("CableGrid").GetComponent<CableGrid>();
        mapGenerator = GameObject.Find("MapGenerator").GetComponent<MapGenerator>();
        bulletsContainer = GameObject.Find("BulletsContainer");
        devicesContainer = GameObject.Find("DevicesContainer");
        coinsContainer = GameObject.Find("CoinsContainer");
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();
        
        costText = GameObject.Find("Cost").GetComponent<Text>();
        costIcon = GameObject.Find("CostIcon").GetComponent<Image>();

        devicesMap = new Dictionary<(int, int), GameObject>();

        shootingDelayTimer.Set(0);
    }

    private void FixedUpdate() {
        shootingDelayTimer.Update();

        if (isPlayer) {
            int cost = toolType switch {
                ToolType.Gun => 0,
                ToolType.PlaceCable => 1,
                ToolType.PlaceLamp => 75,
                ToolType.PlaceTurret => 200,
                _ => 0,
            };

            if (cost != 0) {
                costText.text = cost.ToString();
                costIcon.enabled = true;
            } else {
                costText.text = "";
                costIcon.enabled = false;
            }
        }
    }

    public bool Use(Vector2 positionOrDirection) {
        bool didDo = toolType switch {
            ToolType.Gun => Shoot(positionOrDirection),
            ToolType.PlaceCable => PlaceCable(positionOrDirection),
            ToolType.PlaceLamp => PlaceLamp(positionOrDirection),
            ToolType.PlaceTurret => PlaceTurret(positionOrDirection),
            _ => false,
        };

        if (didDo && toolType != ToolType.Gun) {
            audioManager.PlayPlaceItemSound();
        } else if (!didDo && toolType != ToolType.Gun) {
            audioManager.PlayCannotPlaceItemSound();
        }

        return didDo;
    }

    public bool SecondaryUse(Vector2 position) {
        return RemoveItem(position);
    }

    private bool Shoot(Vector2 shootingDirection) {
        if (shootingDelayTimer.Check() == false) return false;

        // Apply spread
        shootingDirection = Quaternion.Euler(0, 0, Random.Range(-spread, spread)) * shootingDirection;

        // Shoot the thing
        var position = transform.position;
        var bulletPosition = (Vector2) position + shootingDirection;

        GameObject bulletGameObject = Instantiate(bulletPrefab, bulletPosition, Quaternion.identity, bulletsContainer.transform);
        bulletGameObject.GetComponent<Bullet>().direction = shootingDirection;

        shootingDelayTimer.Set(shootingDelayMs);
        return true;
    }

    private bool PlaceCable(Vector2 position) {
        if (Vector2.Distance(transform.position, position) > maxPlacingDistance) return false;

        var tilePosition = GetTilePosition(position);

        int cost = 1;
        if (gameMaster.coins < cost) return false;

        bool didPlace = cableGrid.PlaceCable((int) tilePosition.x, (int) tilePosition.y);

        if (didPlace) {
            gameMaster.coins -= cost;
            gameMaster.score += 1;
        }

        return didPlace;
    }

    private bool PlaceDevice(Vector2 position, GameObject devicePrefab, int cost) {
        if (Vector2.Distance(transform.position, position) > maxPlacingDistance) return false;

        var tilePosition = GetTilePosition(position);
        var coord = ((int) tilePosition.x, (int) tilePosition.y);

        if (gameMaster.coins < cost) return false;

        if (devicesMap.ContainsKey(coord) == false) {
            var deviceObject = Instantiate(devicePrefab, tilePosition, Quaternion.identity, devicesContainer.transform);
            devicesMap[coord] = deviceObject;
            gameMaster.coins -= cost;
            gameMaster.score += 25;
            return true;
        }

        return false;
    }

    private bool PlaceLamp(Vector2 position) {
        return PlaceDevice(position, lampPrefab, 75);
    }

    private bool PlaceTurret(Vector2 position) {
        return PlaceDevice(position, turretPrefab, 200);
    }

    private bool RemoveItem(Vector2 position) {
        if (Vector2.Distance(transform.position, position) > maxPlacingDistance) return false;

        var tilePosition = GetTilePosition(position);
        var coord = ((int) tilePosition.x, (int) tilePosition.y);

        // Try remove device
        var device = devicesMap.GetOrDefault(coord, null);
        if (device != null) {
            var devicePosition = device.transform.position;
            devicesMap.Remove(coord);
            Destroy(device.gameObject);

            for (int i = 0; i < Random.Range(1, 5); i++) {
                Instantiate(coinPrefab, devicePosition, Quaternion.identity, coinsContainer.transform);
            }

            return true;
        }

        // Try remove cable
        return cableGrid.RemoveCable((int) tilePosition.x, (int) tilePosition.y);
    }

    private Vector3 GetTilePosition(Vector2 position) {
        var tileX = (int) position.x;
        var tileY = (int) position.y;
        return new Vector3(tileX + 0.5f, tileY + 0.5f, 0);
    }
}