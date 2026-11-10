using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyBase : MonoBehaviour, IEnemy
{
    public double Health { get; private set; }
    public double PowerDropped { get; private set; }

    public int ScoreAmount { get { return CalculateScore(); } }
    public double TotalHealth { get; set; }

    /// <summary>
    /// Amount of damage to the players power/health
    /// </summary>
    public double EnemyGunDamage = 10;

    public event Action<EnemyBase> OnEnemyKilled;

    [SerializeField]
    AudioClip m_hurtSound;

    [SerializeField]
    SpriteRenderer[] m_sprites;

    [SerializeField]
    Transform m_leftSideBackpackPosition;

    [SerializeField]
    Transform m_rightSideBackpackPosition;

    [SerializeField]
    GameObject m_backpackFill;

    AudioSource m_audioSource;
    protected bool m_playerOnLeftSide;
    Transform m_playerTransform;

    #region  MonoBehaviours
    protected virtual void Start()
    {
        m_audioSource = GetComponent<AudioSource>();
    }

    protected virtual void FixedUpdate()
    {
        UpdatePlayerChangedSides();
    }

    public virtual void OnTriggerEnter2D(Collider2D col)
    {
        if (col.gameObject.tag == Constants.BULLET_TAG)
        {
            GameObject enemy = col.gameObject;
            MoveBulletTrail moveComponent = enemy.GetComponent<MoveBulletTrail>();
            //Do damage and destroy bullet early
            if (moveComponent.Owner != this.gameObject)
            {
                RecieveHit(moveComponent.Damage);
                moveComponent.DestroyEarly(); //destroy bulley early
            }
        }
    }
    #endregion

    /// <summary>
    /// Check every frame if player has gone over/under enemy and swapped sides
    /// </summary>
    void UpdatePlayerChangedSides()
    {
        if (m_playerTransform.position.x < transform.position.x)
        {
            //Left side
            if (m_playerOnLeftSide)
            {
                OnPlayerChangedSide(false);
                m_playerOnLeftSide = false;
            }
        }
        else
        {
            //Right side

            if (!m_playerOnLeftSide)
            {
                OnPlayerChangedSide(true);
                m_playerOnLeftSide = true;
            }

        }
    }

    public void RecieveHit(double damage)
    {
        Health -= damage;

        Debug.Log("Player hit for '" + damage + "' damage");
        if (Health < 0)
        {
            OnKilled();
        }
        else
        {
            m_audioSource.pitch = UnityEngine.Random.Range(0.9f, 1.2f);
            m_audioSource.PlayOneShot(m_hurtSound);
        }
    }

    public void Initialize(Transform player, double health, double powerDropped, double enemyGunDamage)
    {
        GetComponentInChildren<EnemyGunController>().Player = player;
        m_playerTransform = player;
        Health = health;
        PowerDropped = powerDropped;
        TotalHealth = health;
    }

    void OnKilled()
    {
        Debug.Log("Killed enemy. Dropped '" + PowerDropped + "' power");
        InvokeEnemyKilled();
        Destroy(this.gameObject);
    }

    void InvokeEnemyKilled()
    {
        if (OnEnemyKilled != null)
            OnEnemyKilled.Invoke(this);
    }

    /// <summary>
    /// Way of calculating score for when enemy is killed rather than being set random
    /// </summary>
    /// <returns></returns>
    protected int CalculateScore()
    {
        var first = TotalHealth * PowerDropped;
        return (int)Math.Round(first, 0, MidpointRounding.ToEven);
    }

    /// <summary>
    /// When the player goes past the enemy, flip the enemys sprites to face him
    /// </summary>
    /// <param name="isOnRightSide">is the player on the right side of the enemy</param>
    public void OnPlayerChangedSide(bool isOnRightSide)
    {
        foreach (SpriteRenderer sprite in m_sprites)
            sprite.flipX = !sprite.flipX;

        if(isOnRightSide)
            m_backpackFill.transform.position = m_rightSideBackpackPosition.position;
        else
            m_backpackFill.transform.position = m_leftSideBackpackPosition.position;
    }
}
