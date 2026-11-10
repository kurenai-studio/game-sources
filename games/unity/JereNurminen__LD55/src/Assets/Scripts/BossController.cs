using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class BossController : MonoBehaviour
{
    public Vector2[] spawnPositions;
    public GameObject[] minions;
    public GameObject bossSummoningCirclePrefab;
    public float spawnInterval = 4;
    public bool isAwake = false;
    public int enrageAtHealth = 3;
    public float spawnIntervalEnraged = 2;
    public AudioClip onWakeUpSound;
    private Animator animator;
    private Rigidbody2D rb;
    private BoxCollider2D boxCollider;
    private Health health;
    private float timeSinceLastSpawn = 0f;
    private HudController hudController;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        rb = GetComponent<Rigidbody2D>();
        boxCollider = GetComponent<BoxCollider2D>();
        health = GetComponent<Health>();
        hudController = FindAnyObjectByType<HudController>();
    }

    private void SpawnRandomMinionFromRandomCircle()
    {
        var summoningCirclePosition = spawnPositions[Random.Range(0, spawnPositions.Length)];
        var summonController = Instantiate<GameObject>(
            bossSummoningCirclePrefab,
            summoningCirclePosition,
            Quaternion.identity
        );
        summonController
            .GetComponent<BossSummonController>()
            .SetSpawn(minions[Random.Range(0, minions.Length)], summoningCirclePosition, null);
        timeSinceLastSpawn = 0;
    }

    void WakeUp()
    {
        animator.SetTrigger("awake");
        AudioSource.PlayClipAtPoint(onWakeUpSound, transform.position);
    }

    public void OnWakeUpAnimationEnd()
    {
        isAwake = true;
        health.isInvulnerable = false;
        SpawnRandomMinionFromRandomCircle();
    }

    public void onDamage()
    {
        if (!isAwake)
        {
            WakeUp();
            if (health.hitPoints <= enrageAtHealth)
            {
                spawnInterval = spawnIntervalEnraged;
            }
        }
    }

    public void onDeath()
    {
        Debug.Log("Boss is dead");
        animator.SetTrigger("death");
        rb.bodyType = RigidbodyType2D.Static;
        boxCollider.enabled = false;
        isAwake = false;

        var enemies = GameObject.FindGameObjectsWithTag("Enemies");
        Debug.Log("Killing " + enemies.Length + " leftover enemies");
        foreach (var enemy in enemies)
        {
            enemy.GetComponent<Health>().SetHealth(0);
        }
        StartCoroutine(hudController.Win());
    }

    public void PowerDown()
    {
        isAwake = false;
        health.isInvulnerable = true;
        animator.SetTrigger("power_down");
    }

    // Update is called once per frame
    void Update()
    {
        if (isAwake)
        {
            timeSinceLastSpawn += Time.deltaTime;
            if (timeSinceLastSpawn > spawnInterval)
            {
                SpawnRandomMinionFromRandomCircle();
            }
        }
    }

    void OnDrawGizmosSelected()
    {
#if UNITY_EDITOR
        Gizmos.color = Color.red;

        foreach (Vector2 spawnPosition in spawnPositions)
        {
            Gizmos.DrawWireSphere(spawnPosition, 1f);
        }

        Gizmos.color = Color.white;
#endif
    }
}
