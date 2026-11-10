using System.Collections;
using UnityEngine;

public class ExplosionHandler : MonoBehaviour
{
    [SerializeField]
    private float fadeDelay = 0.5f;

    [SerializeField]
    private float fadeDuration = 0.5f;

    private GameObject target;

    [SerializeField]
    private AudioClip explosionSound;
    private AudioSource audioSource;

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        StartCoroutine(FadeOut());
        audioSource.PlayOneShot(explosionSound);
    }

    IEnumerator FadeOut()
    {
        yield return new WaitForSeconds(fadeDelay);

        var sr = GetComponent<SpriteRenderer>();
        Color c = sr.color;
        float elapsed = 0f;

        while (elapsed < fadeDuration)
        {
            elapsed += Time.deltaTime;
            c.a = 1f - Mathf.Clamp01(elapsed / fadeDuration);
            sr.color = c;
            yield return null;
        }

        Destroy(gameObject);
    }

    public void SetTarget(GameObject target)
    {
        this.target = target;
    }

    public void OnDone()
    {
        GameObject.FindObjectOfType<LevelManager>().OnPlayerDeath();
        target.GetComponent<SpriteRenderer>().enabled = false;
    }
}
