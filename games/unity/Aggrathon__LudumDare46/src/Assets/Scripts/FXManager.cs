using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FXManager : MonoBehaviour
{
    public static FXManager active { get; protected set; }

    List<AudioSource> audios;
    int audioIndex = 0;
    [SerializeField] protected AudioSource audioSource;

    List<LineRenderer> tracers;
    int tracerIndex;
    [SerializeField] protected LineRenderer tracer;

    List<ParticleSystem> bloods;
    int bloodIndex;
    [SerializeField] protected ParticleSystem blood;

    List<ParticleSystem> explosions;
    int explosionIndex;
    [SerializeField] protected ParticleSystem explosion;

    private void Start() {
        active = this;

        audios = new List<AudioSource>();
        audios.Add(audioSource);
        for (int i = 0; i < 10; i++)
            audios.Add(Instantiate(audioSource, transform));
        
        tracers = new List<LineRenderer>();
        tracers.Add(tracer);
        tracer.gameObject.SetActive(false);
        for (int i = 0; i < 10; i++)
        {
            var go = Instantiate(tracer, transform);
            go.gameObject.SetActive(false);
            tracers.Add(go);
        }
        
        bloods = new List<ParticleSystem>();
        bloods.Add(blood);
        blood.gameObject.SetActive(false);
        for (int i = 0; i < 10; i++)
        {
            var go = Instantiate(blood, transform);
            go.gameObject.SetActive(false);
            bloods.Add(go);
        }

        explosions = new List<ParticleSystem>();
        explosions.Add(explosion);
        explosion.gameObject.SetActive(false);
        for (int i = 0; i < 10; i++)
        {
            var go = Instantiate(explosion, transform);
            go.gameObject.SetActive(false);
            explosions.Add(go);
        }
    }

    public void PlayAudio(Vector3 pos, AudioClip clip) {
        var aus = audios[audioIndex];
        audioIndex = (audioIndex + 1) % audios.Count;
        aus.transform.position = pos;
        aus.PlayOneShot(clip);
    }

    public void Trace(Vector3 start, Vector3 end) {
        var tr = tracers[tracerIndex];
        tracerIndex = (tracerIndex + 1) % tracers.Count;
        if (tr.gameObject.activeSelf) {
            tr = Instantiate(tracer, transform);
            tr.gameObject.SetActive(false);
            tracers.Add(tr);
        }
        tr.SetPosition(0, start);
        tr.SetPosition(1, end);
        tr.gameObject.SetActive(true);
    }
}
