using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AsteroidSettings : MonoBehaviour
{
    public float tickTime = 1f;
    public GameObject textPrefab;

    public int shipCost = 20;
    public int minShipStock = 50;

    public GameObject shipPrefab;
    public float spawnDist = 0.5f;
}
