using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GunController : MonoBehaviour
{
    [SerializeField]
    Transform m_firePosition;

    [SerializeField]
    Transform m_bulletTrailPrefab;

    [SerializeField]
    AudioClip m_laserSound;

    public float FireRate = 0f;
    public LayerMask m_hitMask;
    public float EffectSpawnRate = 10f;

    float m_timeToFire = 0f;
    float m_timeToSpawnEffect = 0f;
    PlayerController m_player;
    GameController m_game;
    AudioSource m_audioSource;

    public event Action<double> OnKilledEnemy;

    void Start()
    {
        m_player = transform.parent.GetComponentInParent<PlayerController>();
        m_game = FindObjectOfType<GameController>();
        m_audioSource = GetComponent<AudioSource>();
        if (m_audioSource == null)
            Debug.LogError("Missing Audio Source on GameObject '" + gameObject.name + "'");
    }

    void Update()
    {
        if (m_game.IsGameFinished)
            return;

        if (FireRate == 0)
        {
            if (Input.GetButtonDown("Fire1"))
            {
                Shoot();
            }
        }
        else
        {
            if (Input.GetButton("Fire1") && Time.time > m_timeToFire)
            {
                m_timeToFire = Time.time + 1 / FireRate;
                Shoot();
            }
        }
    }

    void Shoot()
    {
        Vector2 mousePosition = new Vector2(Camera.main.ScreenToWorldPoint(Input.mousePosition).x, Camera.main.ScreenToWorldPoint(Input.mousePosition).y);
        Vector2 firePointPosition = new Vector2(m_firePosition.position.x, m_firePosition.position.y);
        RaycastHit2D hit = Physics2D.Raycast(m_firePosition.position, mousePosition - firePointPosition, 100, m_hitMask);

        if (Time.time >= m_timeToSpawnEffect)
        {
            Effect();
            m_timeToSpawnEffect = Time.time + 1 / EffectSpawnRate;

            //Randomize pitch every shot
            m_audioSource.pitch = UnityEngine.Random.Range(0.8f, 1.2f);
            m_audioSource.PlayOneShot(m_laserSound);
        }

        Debug.DrawLine(firePointPosition, (mousePosition - firePointPosition) * 100, Color.cyan);
        if(hit.collider != null)
        {
            Debug.DrawLine(firePointPosition, hit.point, Color.red);
        }

        m_player.OnShot();
    }

    void Effect()
    {
        var bullet = Instantiate(m_bulletTrailPrefab, m_firePosition.position, m_firePosition.rotation);
        //Pass the amount of damage the bulley will do to the component, then to the enemy
        bullet.GetComponent<MoveBulletTrail>().InitializeBullet(m_player.gameObject, m_player.GunDamage);
    }
}
