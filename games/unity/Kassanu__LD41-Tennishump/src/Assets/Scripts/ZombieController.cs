using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ZombieController : MonoBehaviour {

    [SerializeField] float ZombieRotationSpeed = 500f;
    [SerializeField] float WalkingSpeed = 2f;
    [SerializeField] float walkingSpeedVariation = 0.5f;
    private float changedWalkingSpeedVariation = 1f;
    private float finalWalkingSpeed = 1f;
    [SerializeField] int scoreValue = 1;
    private bool dead = false;
    [SerializeField] GameObject ZombiesTarget; // What Zombie will rotate towards

    [SerializeField] GameController gc;

    Transform PlayerTransform;

    private AudioSource audioSource;
    [SerializeField] private AudioClip zombieDeath;
    [SerializeField] private GameObject deathEffect;

    private void Awake()
    {
        this.audioSource = GetComponent<AudioSource>();
        ZombiesTarget = GameObject.Find("/Player");
        gc = GameObject.Find("/GameController").GetComponent<GameController>();

        changedWalkingSpeedVariation = walkingSpeedVariation;
    }

    // Use this for initialization
    void Start () {
        PlayerTransform = ZombiesTarget.transform;
        print(ZombiesTarget);
        CalculateWalkingSpeed();
    }
	
	// Update is called once per frame
	void Update () {
        if (!this.dead) {
            MoveForward();
        }
    }

    private void OnTriggerEnter(Collider collision) {
        if (collision.gameObject.tag == "Ball") {
            Ball ball = collision.gameObject.GetComponent<Ball>();
            if (ball.Active && !this.dead) {
                Instantiate(this.deathEffect, this.transform.position, Quaternion.identity);
                this.audioSource.Stop();
                this.audioSource.PlayOneShot(this.zombieDeath);
                this.dead = true;
                gc.AddToZombieKillCount(1);
                gc.AddToScore(scoreValue);
                gc.ZombiesAlive -= 1;
                Destroy(collision.gameObject);
                Destroy(this.gameObject, 1f);
            }
        }
    }

    private void RotateTowardsPlayer() {
        Vector3 targetDir = PlayerTransform.position - transform.position;
        float step = WalkingSpeed * Time.deltaTime;
        Vector3 newDirection = Vector3.RotateTowards(transform.forward, targetDir, step, 0.0f);
        transform.rotation = Quaternion.LookRotation(newDirection);
    }

    private void MoveForward() {
        // Original Code, commented for safe keeping
        //float step = WalkingSpeed * Time.deltaTime;
        //transform.position += -Vector3.forward * step;

        
        float step = finalWalkingSpeed * Time.deltaTime;
        transform.position += -Vector3.forward * step;
    }

    private void MoveTowardsPlayer() {
        float step = WalkingSpeed * Time.deltaTime;
        Vector3 targetPosition = new Vector3(PlayerTransform.position.x,
                                       this.transform.position.y,
                                       PlayerTransform.position.z);
        transform.position = Vector3.MoveTowards(transform.position, targetPosition, step);
    }

    private void CalculateWalkingSpeed()
    {
        changedWalkingSpeedVariation = gc.ChangeZombieWalkingVariation(walkingSpeedVariation);
        finalWalkingSpeed = WalkingSpeed + Random.Range(0f, changedWalkingSpeedVariation);
        print("Walking Speed is: " + finalWalkingSpeed);
    }
}