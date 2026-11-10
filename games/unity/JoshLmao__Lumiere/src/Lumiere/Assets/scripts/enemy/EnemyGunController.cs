using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyGunController : MonoBehaviour
{
    public Transform Player;
    public float EffectSpawnRate = 10f;

    [SerializeField]
    GameObject m_bulletPrefab;

    [SerializeField]
    AudioClip m_laserSound;

    float m_rotationOffset = 0;
    float m_shootInterval = 3f;
    Coroutine m_activeRoutine = null;
    Transform m_firePosition = null;
    float m_timeToSpawnEffect = 0f;
    EnemyBase m_owner;
    bool m_isPlayerInRange = false;
    AudioSource m_audioSource;
    GameController m_game;
    bool m_playerOnLeftSide = true;

    #region MonoBehaviours
    void Start()
    {
        m_game = FindObjectOfType<GameController>();
        m_owner = GetComponentInParent<EnemyBase>();
        m_firePosition = transform.Find("FirePosition");
        m_audioSource = GetComponent<AudioSource>();
        if (m_audioSource == null)
            Debug.LogError("Missing Audio Source on GameObject '" + gameObject.name + "'");
    }

    void FixedUpdate()
    {
        //Follows aim to player
        Vector3 diff = Player.transform.position - transform.position;
        diff.Normalize();

        float rotZ = Mathf.Atan2(diff.y, diff.x) * Mathf.Rad2Deg;
        transform.rotation = Quaternion.Euler(0f, 0f, rotZ + m_rotationOffset);

        m_isPlayerInRange = Vector3.Distance(transform.position, Player.transform.position) < Constants.ENEMY_RANGE_TO_PLAYER;
        if (m_isPlayerInRange && m_activeRoutine == null)
        {
            //Decide to shoot straight away, or delay and shoot
            bool shouldShootStraightAway = Math.Round((double)UnityEngine.Random.Range(0, 1), 0) == 0;
            if (shouldShootStraightAway && !m_game.IsGameFinished)
            {
                ShootAtPlayer();
            }

            m_activeRoutine = StartCoroutine(StartWaitAndShoot());
            Debug.Log("Player in range. Shooting...");
        }
        else if (!m_isPlayerInRange && m_activeRoutine != null)
        {
            StopCoroutine(m_activeRoutine);
            m_activeRoutine = null;
            Debug.Log("Player went out of range. Stopping...");
        }
    }

    public void OnDestroy()
    {
        if(m_activeRoutine != null)
            StopCoroutine(m_activeRoutine);
    }
    #endregion

    void ShootAtPlayer()
    {
        Vector2 mousePosition = new Vector2(Player.transform.position.x, Player.transform.position.y);
        Vector2 firePointPosition = new Vector2(m_firePosition.position.x, m_firePosition.position.y);
        RaycastHit2D hit = Physics2D.Raycast(m_firePosition.position, mousePosition - firePointPosition, 100, 0);

        if (Time.time >= m_timeToSpawnEffect)
        {
            Effect();
            m_timeToSpawnEffect = Time.time + 1 / EffectSpawnRate;

            m_audioSource.pitch = UnityEngine.Random.Range(0.9f, 1.2f);
            m_audioSource.PlayOneShot(m_laserSound);
        }
    }

    void Effect()
    {
        GameObject bullet = Instantiate(m_bulletPrefab, m_firePosition.position, m_firePosition.rotation);
        bullet.GetComponent<MoveBulletTrail>().InitializeBullet(m_owner.gameObject, m_owner.EnemyGunDamage);
    }

    IEnumerator StartWaitAndShoot()
    {
        m_activeRoutine = StartCoroutine(WaitAndShoot(m_shootInterval));
        yield return null;
    }

    IEnumerator WaitAndShoot(float seconds)
    {
        yield return new WaitForSeconds(seconds);
        if (!m_game.IsGameFinished)
        {
            ShootAtPlayer();
            StartCoroutine(StartWaitAndShoot());
        }
    }
}
