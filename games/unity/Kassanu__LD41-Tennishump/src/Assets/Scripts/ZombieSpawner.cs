using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ZombieSpawner : MonoBehaviour {

    [SerializeField] GameObject Zombie;
    [SerializeField] GameObject SpawnArea;
    [SerializeField] GameController gc;
    [SerializeField] int maxZombiesAllowed = 4;
    [SerializeField] float ZombieSpawnTime = 2f;
    [SerializeField] float zombieSpawnTimeVariation = 0.25f;
    private float changedZombieSpawnTimeVariation = 1f;
    private float finalZombieSpawnTime = 1f;
    private float fastedSpawnTimeAllowed = 1f;

    [SerializeField] GameObject SpawnFL;
    [SerializeField] GameObject SpawnRL;
    [SerializeField] GameObject SpawnFR;
    [SerializeField] GameObject SpawnRR;

    Transform SpawnAreaScale;

    [SerializeField] float startDelay = 1f;
    private AudioSource audioSource;
    [SerializeField] private AudioClip zombieAnnounce;

    private void Awake()
    {
        SpawnFL = GameObject.Find("FrontLeft");
        SpawnRL = GameObject.Find("BackLeft");
        SpawnFR = GameObject.Find("FrontRight");
        SpawnRR = GameObject.Find("BackRight");

        gc = GameObject.Find("/GameController").GetComponent<GameController>();
        this.audioSource = GetComponent<AudioSource>();
    }

    // Use this for initialization
    void Start () {
        SpawnAreaScale = SpawnArea.transform;
        Invoke("StartSpawningRoutine", this.startDelay);
        changedZombieSpawnTimeVariation = zombieSpawnTimeVariation;
    }

    private void StartSpawningRoutine() {
        this.audioSource.Stop();
        this.audioSource.PlayOneShot(this.zombieAnnounce);
        StartCoroutine(SpawnTheZombies());
    }
    IEnumerator SpawnTheZombies()
    {
        while (true)
        {
            if(gc.ZombiesAlive < maxZombiesAllowed)
            {
                SpawnZombie();
            }
            CalculateSpawnTime();
            print("gc.ZombiesAlive: " + gc.ZombiesAlive);
            yield return new WaitForSeconds(finalZombieSpawnTime);
        }
    }

    private void SpawnZombie() {
        Vector3 SpawnPoint = new Vector3(Random.Range(SpawnFL.transform.position.x,SpawnFR.transform.position.x), 
                                        0.75f, 
                                        Random.Range(SpawnFL.transform.position.z,SpawnRL.transform.position.z));
        var zombie = (GameObject)Instantiate(Zombie, SpawnPoint, new Quaternion(0f,-180f,0f,0f));
        gc.ZombiesAlive += 1;
    }

    private void CalculateSpawnTime()
    {
        changedZombieSpawnTimeVariation = gc.ChangeZombieSpawnTimeVariation(ZombieSpawnTime);
        if (changedZombieSpawnTimeVariation <= (ZombieSpawnTime / 4)) changedZombieSpawnTimeVariation = fastedSpawnTimeAllowed;
        finalZombieSpawnTime = ZombieSpawnTime - Random.Range(0f, changedZombieSpawnTimeVariation);

        print("Spawn Time was: " + finalZombieSpawnTime);
    }
}
