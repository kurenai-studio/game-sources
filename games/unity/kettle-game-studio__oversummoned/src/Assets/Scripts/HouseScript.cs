using System;
using UnityEngine;

public class HouseScript : MonoBehaviour
{
    public Transform House;
    public GameObject DemonPrefab;
    public Transform Spawnpoint;
    public SphereCollider GuardSphere;
    public AudioSource sound;
    public float TimeToWork = 5;
    public float PushStrength = 10000;

    public Action action;
    public int LimbId;
    public GameObject[] Limbs;

    enum State
    {
        Idle,
        Working,
    }

    [Serializable]
    public enum Action
    {
        None,
        Shuffle,
        ReplaceHorns,
        ReplaceFeature,
        CleanBlood,
        Consume,
    }

    private State state = State.Idle;
    private DemonConfiguration demonConfig;
    private DamageLevel damageLevel;
    private float _timeLeft;

    void Start()
    {
        GuardSphere.enabled = false;
        for (var i = 0; i < Limbs.Length; i++)
            Limbs[i].SetActive(i == LimbId); 
    }

    void Update()
    {
        if (state == State.Working)
        {
            var s = Mathf.Sin(Time.time * 10) * 0.1f + 0.9f;
            var c = Mathf.Cos(Time.time * 10) * 0.1f + 0.9f;
            House.localScale = new Vector3(s, c, s);
            _timeLeft -= Time.deltaTime;
            if (_timeLeft < 0)
            {
                state = State.Idle;
                GuardSphere.enabled = false;
                sound.Stop();
                SpawnDemon();
            }
        }
    }

    void SpawnDemon()
    {
        if (action == Action.Consume) return;

        var demon = Instantiate(DemonPrefab, Spawnpoint.position, Spawnpoint.rotation).GetComponent<DemonScript>();
        switch (action)
        {
            case Action.None:
                demon.SetConfig(demonConfig, damageLevel);
                break;

            case Action.Shuffle:
                break;

            case Action.ReplaceHorns:
                demonConfig.HornsId = LimbId;
                demon.SetConfig(demonConfig, damageLevel);
                break;

            case Action.ReplaceFeature:
                demonConfig.FeatureId = LimbId;
                demon.SetConfig(demonConfig, damageLevel);
                break;

            case Action.CleanBlood:
                demon.SetConfig(demonConfig);
                break;
        }
        demon.DemonBody.AddForce(demon.DemonBody.transform.forward * PushStrength);
        demonConfig = null;
        damageLevel = null;
    }

    void OnTriggerEnter(Collider other)
    {
        if (state != State.Idle) return;

        var demon = other.GetComponent<DemonScript>();
        if (demon != null && !demon.IsHeld)
        {
            GuardSphere.enabled = true;
            demonConfig = demon.config;
            damageLevel = demon.damageLevel;
            state = State.Working;
            Destroy(demon.gameObject);
            sound.Play();
            _timeLeft = TimeToWork;
        }
    }
}
