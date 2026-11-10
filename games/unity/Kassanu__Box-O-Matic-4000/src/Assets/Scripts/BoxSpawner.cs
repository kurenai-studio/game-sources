using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoxSpawner : MonoBehaviour {

    [SerializeField]
    private Box boxPrefab;

    [SerializeField]
    private int minAmountToSpawn = 1;
    public int MinAmountToSpawn {
        get { return this.minAmountToSpawn; }
        set { this.minAmountToSpawn = value; }
    }

    [SerializeField]
    private int defaultMaxAmountToSpawn = 3;
    public int DefaultMaxAmountToSpawn {
        get { return this.defaultMaxAmountToSpawn; }
        set { this.defaultMaxAmountToSpawn = value; }
    }

    private int maxAmountToSpawn = 1;
    public int MaxAmountToSpawn {
        get { return this.maxAmountToSpawn; }
        set { this.maxAmountToSpawn = value; }
    }

    [SerializeField]
    private float defaultMinimumSpawnTime = 1f;
    public float DefaultMinimumSpawnTime {
        get { return this.defaultMinimumSpawnTime; }
        set { this.defaultMinimumSpawnTime = value; }
    }

    [SerializeField]
    private float minimumSpawnTime = 1f;
    public float MinimumSpawnTime {
        get { return this.minimumSpawnTime; }
        set { this.minimumSpawnTime = value; }
    }

    private float currentMinimumSpawnTime = 2f;
    public float CurrentMinimumSpawnTime {
        get { return this.currentMinimumSpawnTime; }
        set {
            this.currentMinimumSpawnTime = ( ( value < this.MinimumSpawnTime ) ? this.MinimumSpawnTime : ( ( value > this.DefaultMinimumSpawnTime ) ? this.DefaultMinimumSpawnTime : value ) );
        }
    }

    [SerializeField]
    private float defaultMaximumSpawnTime = 1f;
    public float DefaultMaximumSpawnTime {
        get { return this.defaultMaximumSpawnTime; }
        set { this.defaultMaximumSpawnTime = value; }
    }

    [SerializeField]
    private float maximumSpawnTime = 1f;
    public float MaximumSpawnTime {
        get { return this.maximumSpawnTime; }
        set { this.maximumSpawnTime = value; }
    }

    private float currentMaximumSpawnTime = 2f;
    public float CurrentMaximumSpawnTime {
        get { return this.currentMaximumSpawnTime; }
        set {
            this.currentMaximumSpawnTime = ( ( value < this.MaximumSpawnTime ) ? this.MaximumSpawnTime : ( ( value > this.DefaultMaximumSpawnTime ) ? this.DefaultMaximumSpawnTime : value ) );
        }
    }

    private bool gameOver = false;
    public bool GameOver {
        get { return this.gameOver; }
        set { this.gameOver = value; }
    }

    [SerializeField]
    private int boxesToSpawnAtEnd = 10;

    private IEnumerator spawnBoxCoroutine;

    private void Start() {
        this.spawnBoxCoroutine = RepeatedlySpawnBoxes();
        StartCoroutine(this.spawnBoxCoroutine);
    }

    private void Update() {
        if (this.GameOver) {
            StopCoroutine(this.spawnBoxCoroutine);
            while (this.boxesToSpawnAtEnd > 0) {
                int amount = Random.Range(this.minAmountToSpawn, this.maxAmountToSpawn + 1);
                this.InstantiateBoxes(amount);
                this.boxesToSpawnAtEnd -= amount;
            }
        }
    }

    IEnumerator RepeatedlySpawnBoxes() {
        while (true) {
            this.InstantiateBoxes(Random.Range(this.minAmountToSpawn, this.maxAmountToSpawn+1));
            yield return new WaitForSeconds(Random.Range(this.CurrentMinimumSpawnTime, this.CurrentMaximumSpawnTime));
        }
    }

    private void InstantiateBoxes(int amount) {
        for (int i = 0; i < amount; i++) {
            Instantiate(this.boxPrefab, new Vector3(this.transform.position.x, this.transform.position.y + ( i * 1 ), this.transform.position.z), Quaternion.identity, this.transform.parent);
        }
    }

    public void AdjustMinimumSpawnTime(float percentage) {
        this.CurrentMinimumSpawnTime = this.DefaultMinimumSpawnTime - ( ( this.DefaultMinimumSpawnTime - this.MinimumSpawnTime ) * percentage );
    }

    public void AdjustMaximumSpawnTime(float percentage) {
        this.CurrentMaximumSpawnTime = this.DefaultMaximumSpawnTime - ( ( this.DefaultMaximumSpawnTime - this.MaximumSpawnTime ) * percentage );
    }

    public void AdjustSpawnAmount(float percentage) {
        this.MaxAmountToSpawn = this.MinAmountToSpawn + (Mathf.FloorToInt((this.DefaultMaxAmountToSpawn - this.MinAmountToSpawn) * percentage));
    }
}
