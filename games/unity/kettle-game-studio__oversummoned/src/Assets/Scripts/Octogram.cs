using System.Collections;
using UnityEngine;

public class Octogram : MonoBehaviour
{
    public ParticleSystem Particles;
    public Transform SpawnPoint;
    public GameObject DemonPrefab;
    public AudioSource spawnSound;

    private Systemd systemd;
    private DemonScript _demon;

    void Start()
    {
        systemd = GameObject.FindAnyObjectByType<Systemd>();
    }

    void Update()
    {
        if (_demon == null)
        {
            var demonConfig = systemd.PopRespawndDemon();
            if (demonConfig != null)
            {
                _demon = Instantiate(DemonPrefab, SpawnPoint.position, SpawnPoint.rotation).GetComponent<DemonScript>();
                _demon.SetConfig(demonConfig, DamageLevel.RandomDamage());
                StartCoroutine(AnimationCoroutine());
                Particles.Play();
                spawnSound.Play();
            }
        }
    }

    void OnTriggerExit(Collider other)
    {
        var exitDemon = other.GetComponent<DemonScript>();
        if (exitDemon != null && exitDemon == _demon)
        {
            StartCoroutine(PrepareForNewDemonCoroutine());
        }
    }

    IEnumerator PrepareForNewDemonCoroutine()
    {
        yield return new WaitForSeconds(5);
        _demon = null;
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
            yield return null;
        }
        transform.localScale = new Vector3(1, 1, 1);
    }
}
