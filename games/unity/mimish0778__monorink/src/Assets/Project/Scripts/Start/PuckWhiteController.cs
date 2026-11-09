using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class PuckWhiteController : MonoBehaviour
{
    private const float TransitionEnableDelay = 3f;
    private const float GravityScale = 1f;

    private Rigidbody2D rb;
    private bool canTransition = false;
    private bool hasCollided = false;

    [SerializeField] private FadeController fade;
    [SerializeField] private GameObject startPrompt;

    private void Start()
    {
        rb = GetComponent<Rigidbody2D>();

        StartCoroutine(fade.FadeIn());
        StartCoroutine(WaitForTransitionEnable());
    }

    private void Update()
    {
        if (Input.anyKeyDown && canTransition)
        {
            canTransition = false;
            StartCoroutine(Transition());
        }
    }

    private void OnCollisionEnter2D(Collision2D col)
    {
        if (!hasCollided)
        {
            hasCollided = true;
            rb.gravityScale = 0f;
            Vector2 randomDirection = new Vector2(Random.Range(-1f, 1f), 0.5f).normalized;
            rb.velocity = randomDirection * rb.velocity.magnitude;
        }
    }

    private IEnumerator WaitForTransitionEnable()
    {
        yield return new WaitForSeconds(TransitionEnableDelay);

        canTransition = true;
        rb.gravityScale = GravityScale;
        startPrompt.SetActive(true);
    }

    private IEnumerator Transition()
    {
        yield return StartCoroutine(fade.FadeOut());

        SceneManager.LoadScene("Play");
    }
}
