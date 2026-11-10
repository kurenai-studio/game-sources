using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BossSummonController : MonoBehaviour
{
    public AudioClip spawnSound;
    private Animator animator;
    private GameObject minionToSpawn;
    private Vector2 spawnPosition;
    private Vector2 targetPosition;
    private BossController bossController;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        bossController = GameObject.Find("Boss").GetComponent<BossController>();
    }

    public void OnSpawnAnimationDone()
    {
        Invoke(nameof(Spawn), 0.5f);
    }

    public void OnDespawnAnimationDone()
    {
        Destroy(gameObject);
    }

    public void SetSpawn(GameObject minion, Vector2 startPosition, Vector2? targetPosition)
    {
        minionToSpawn = minion;
        spawnPosition = startPosition;
        AudioSource.PlayClipAtPoint(spawnSound, spawnPosition);
    }

    void FadeOut()
    {
        animator.SetTrigger("done");
    }

    void Spawn()
    {
        if (bossController != null && bossController.isAwake)
        {
            var minion = Instantiate(minionToSpawn, spawnPosition, Quaternion.identity);
            minion.GetComponent<Health>().SetHealth(1);
        }

        Invoke(nameof(FadeOut), 0.1f);
    }

    // Update is called once per frame
    void Update() { }
}
