using System;
using System.Collections;
using UnityEngine;

public class PentragramScript : MonoBehaviour
{
    public ParticleSystem ParticlesGood;
    public ParticleSystem ParticlesBad;
    public AudioSource soundGood;
    public AudioSource soundBad;

    private Systemd systemd;
    private DemonRequest _request;

    public GameObject Bubble;
    public SpriteRenderer[] Horns;
    public SpriteRenderer[] Features;

    public float FetchDemonTimeout = 5;

    void Start()
    {
        systemd = GameObject.FindAnyObjectByType<Systemd>();
        ApplyRequest();
        StartCoroutine(WaitForRequest(0));
    }

    void OnTriggerEnter(Collider other)
    {
        var demon = other.GetComponent<DemonScript>();
        if (demon != null && !demon.IsHeld)
        {
            if (_request != null && demon.config.MeetsRequest(_request, demon.damageLevel))
            {
                ParticlesGood.Play();
                soundGood.Play();
                systemd.DemonSent(demon.config);
                _request = null;
                ApplyRequest();
                Destroy(demon.gameObject);
                StartCoroutine(AnimationCoroutine());
                StartCoroutine(WaitForRequest(FetchDemonTimeout));
            }
            else
            {
                demon.DemonBody.AddForce((demon.transform.position - transform.position).normalized * 50000);
                ParticlesBad.Play();
                soundBad.Play();
            }
        }
    }

    IEnumerator WaitForRequest(float timeout)
    {
        yield return new WaitForSeconds(timeout);
        while (true)
        {
            _request = systemd.PopDemonRequest();
            if (_request != null)
            {
                ApplyRequest();
                yield return StartCoroutine(AnimationCoroutine());
                yield break;
            }
            yield return null;
        }
    }

    IEnumerator AnimationCoroutine()
    {
        const float timeForChange = 0.5f;
        var timeLeft = timeForChange;
        while (timeLeft > 0)
        {
            var s = Mathf.Sin(timeLeft / timeForChange) * 0.1f + 0.9f;
            var c = Mathf.Cos(timeLeft / timeForChange) * 0.1f + 0.9f;
            transform.localScale = new Vector3(c, s, c);
            timeLeft -= Time.deltaTime;
            yield return new WaitForEndOfFrame();
        }
        transform.localScale = new Vector3(1, 1, 1);
    }

    void ApplyRequest()
    {
        Bubble.SetActive(_request != null);
        if (_request == null) return;

        for (var i = 0; i < Horns.Length; i++)
            Horns[i].enabled = _request.HornsId == i;

        for (var i = 0; i < Features.Length; i++)
            Features[i].enabled = _request.FeatureId == i;
    }
}
