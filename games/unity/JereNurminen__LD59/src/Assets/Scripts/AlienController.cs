using UnityEngine;
using System.Collections;

public class AlienController : MonoBehaviour
{
    [HideInInspector]
    public LevelManager levelManager;

    [SerializeField]
    private float activationDelay = 2f;

    [SerializeField]
    private float waveDuration = 2f;

    private Animator animator;

    private void Start()
    {
        animator = GetComponent<Animator>();
    }

    IEnumerator Activate()
    {
        yield return new WaitForSeconds(activationDelay);
        animator.SetTrigger("activate");
        StartCoroutine(Wave());
    }

    IEnumerator Wave()
    {
        yield return new WaitForSeconds(waveDuration);
        animator.SetTrigger("remote");
    }

    public void OnPress()
    {
        levelManager.BeamEmUp();
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (!other.CompareTag("Player"))
            return;
        levelManager.OnAlienSeen();
        StartCoroutine(Activate());
    }
}
