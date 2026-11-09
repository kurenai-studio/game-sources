using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MachineController : MonoBehaviour {

    [SerializeField] float MachineRotationSpeed = 1f;
    [SerializeField] float minSpeed, maxSpeed = 150f;

    [SerializeField] GameObject MachinesTarget; // What Machine will rotate towards
    [SerializeField] GameObject Projectile;
    [SerializeField] Transform ProjectileSpawn;

    [SerializeField] float minSpawnTime, maxSpawnTime = 1f;

    [SerializeField] float startDelay = 1f;

    Transform PlayerTransform;
    private Vector3 direction = Vector3.zero;
    private AudioSource audioSource;
    [SerializeField] private AudioClip launchBall;

    private void Awake() {
        this.audioSource = GetComponent<AudioSource>();
    }

    // Use this for initialization
    void Start () {
        PlayerTransform = MachinesTarget.transform;
        Invoke("StartShootingRoutine", this.startDelay);
    }
	
	// Update is called once per frame
	void Update () {
        RotateTowardsPlayer();
        Debug.DrawLine(ProjectileSpawn.position, direction, Color.red);
    }

    private void StartShootingRoutine() {
        StartCoroutine(ShootTheProjectile());
    }

    IEnumerator ShootTheProjectile()
    {
        while(true)
        {
            ShootProjectile();
            yield return new WaitForSeconds(Random.Range(this.minSpawnTime, this.maxSpawnTime));
        }
    }

    private void RotateTowardsPlayer()
    {
        Vector3 targetPostition = new Vector3(PlayerTransform.position.x,
                                       this.transform.position.y,
                                       PlayerTransform.position.z);
        this.transform.LookAt(targetPostition);
    }

    private void ShootProjectile()
    {
        Vector3 newDirection = GetPlayerRotationAngle();
        Vector3 screenPosition = Camera.main.ScreenToWorldPoint(new Vector3(Random.Range(0, Screen.width), Random.Range(0, Screen.height), Camera.main.nearClipPlane));
        direction = screenPosition - ProjectileSpawn.position;
        var projectile = (GameObject)Instantiate(Projectile, ProjectileSpawn.position, Quaternion.LookRotation(direction));
        projectile.GetComponent<Rigidbody>().AddForce(projectile.transform.forward * Random.Range(this.minSpeed, this.maxSpeed));
        this.audioSource.Stop();
        this.audioSource.PlayOneShot(this.launchBall);
        Destroy(projectile, 15.0f);
    }

    private Vector3 GetPlayerRotationAngle()
    {
        Vector3 targetDirection = transform.position - new Vector3(PlayerTransform.position.x, 0, 0); 
        float step = MachineRotationSpeed * Time.deltaTime;
        Vector3 newDirection = Vector3.RotateTowards(transform.forward, targetDirection, step, 0.0f);

        return newDirection;
    }
}
